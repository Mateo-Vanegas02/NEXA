"""Lambda mediadora `nexa-satisfaccion`: la API del panel de satisfacción del admin (contrato v0.2).

La app Flutter llama a la URL de la función con `Authorization: Bearer <JWT de NEXA>`. Esta función valida
el JWT (HS256, mismo `JWT_SECRET` de la web, rol ADMIN) y responde leyendo:
  - MongoDB Atlas (solo lectura) para la satisfacción observada y los datos disponibles,
  - S3 para el modelo publicado (métricas, factores y el .tflite para los viajes en riesgo),
  - DynamoDB para la programación y el historial de entrenamientos.
No entrena: "Entrenar ahora" y la programación lanzan la tarea de entrenamiento en ECS Fargate
(`nexa_ml.entrenadora`), que usa solo viajes reales: ya no hay entrenamiento con datos sintéticos.

EventBridge Scheduler también la invoca con {"accion": "entrenar_programado"}.
"""
from __future__ import annotations

import base64
import json
import logging
from datetime import datetime, timedelta, timezone
from typing import Any, Callable

import jwt  # PyJWT

from nexa_ml import satisfaccion as sat

log = logging.getLogger()
log.setLevel(logging.INFO)

_NUBE = None


def _nube():
    global _NUBE
    if _NUBE is None:
        from nexa_ml.nube import Nube

        _NUBE = Nube()
    return _NUBE


# --------------------------------------------------------------------------- HTTP
def _respuesta(estado: int, cuerpo: Any = None) -> dict:
    r = {"statusCode": estado, "headers": {"Content-Type": "application/json", "Cache-Control": "no-store"}}
    if cuerpo is not None:
        r["body"] = json.dumps(cuerpo, ensure_ascii=False)
    return r


def _error(estado: int, codigo: str, mensaje: str) -> dict:
    return _respuesta(estado, {"error": codigo, "mensaje": mensaje})


def _admin(evento: dict, secreto: str) -> dict | None:
    """Devuelve una respuesta de error si el token no sirve; None si es un admin válido."""
    cabeceras = {k.lower(): v for k, v in (evento.get("headers") or {}).items()}
    auth = cabeceras.get("authorization", "")
    if not auth.lower().startswith("bearer "):
        return _error(401, "no_autenticado", "Inicia sesión de nuevo.")
    try:
        claims = jwt.decode(auth[7:].strip(), base64.b64decode(secreto), algorithms=["HS256"],
                            options={"require": ["exp", "sub"]})
    except jwt.ExpiredSignatureError:
        return _error(401, "sesion_vencida", "Tu sesión venció. Inicia sesión de nuevo.")
    except jwt.InvalidTokenError:
        return _error(401, "no_autenticado", "Inicia sesión de nuevo.")
    roles = claims.get("roles") or []
    if isinstance(roles, str):
        roles = [roles]
    if not ({"ROLE_ADMIN", "ADMIN"} & set(roles)):
        return _error(403, "solo_admin", "Esta sección es solo para administradores.")
    return None


# --------------------------------------------------------------------------- rutas
def _historial_y_activo(n) -> tuple[list[dict], dict | None]:
    registros = n.entrenamientos()
    activo = next((r for r in registros if r.get("estado") not in sat.ESTADOS_FINALES), None)
    return [sat.vista_historial(r) for r in registros[:10]], (sat.vista_entrenamiento(activo) if activo else None)


def _programacion_vista(n) -> dict:
    p, guardada = n.programacion()
    return {**p, "proxima": sat.proxima(p, guardada=guardada)}


def _riesgo(n, lado: str, limite: int) -> dict:
    actual, meta, factores = n.modelo_publicado()
    predictor = n.predictor() if actual else None
    if not predictor or not meta:
        return {"umbral": 0.0, "modo": sat.modo_de(meta), "total": 0, "viajes": []}
    viajes = n.viajes_finalizados(datetime.now(timezone.utc) - timedelta(days=30), datetime.now(timezone.utc))
    pendientes = [v for v in viajes if any(v.get(c) is None for c in sat.CAMPO_NOTA.values())]
    if not pendientes:
        return {"umbral": round(min(meta["umbrales"].values()), 2), "modo": sat.modo_de(meta), "total": 0,
                "viajes": []}
    from nexa_ml import caracteristicas as car

    probs = predictor.probabilidades([car.calcular(v) for v in pendientes])
    return sat.riesgo(pendientes, probs, meta["umbrales"], lado, limite, sat.modo_de(meta),
                      (factores or {}).get("medias"))


def get_resumen(n, q: dict, _cuerpo) -> dict:
    desde, hasta = sat.periodo(q.get("desde"), q.get("hasta"))
    dias = (hasta - desde).days + 1
    ini, fin = sat.inicio_del_dia(desde), sat.inicio_del_dia(hasta) + timedelta(days=1)
    ini_semanas = min(ini - timedelta(days=dias), fin - timedelta(weeks=sat.MAX_SEMANAS))
    todos = n.viajes_finalizados(ini_semanas, fin)

    def entre(a, b):
        from nexa_ml.caracteristicas import a_fecha

        return [v for v in todos if (f := a_fecha(v.get("fechaFinalizacion"))) is not None and a <= f < b]

    actual, meta, factores = n.modelo_publicado()
    principal = None
    importancia = ((factores or {}).get("pasajero") or {}).get("importancia") or []
    if importancia:
        principal = {"lado": "pasajero", "etiqueta": importancia[0]["etiqueta"]}
    try:
        total_riesgo = _riesgo(n, "todos", 200)["total"] if actual else 0
    except Exception:  # el resumen no se cae si falla la predicción
        log.exception("No se pudo calcular el riesgo para el resumen")
        total_riesgo = 0
    return sat.resumen(entre(ini, fin), entre(ini - timedelta(days=dias), ini),
                       entre(fin - timedelta(weeks=sat.MAX_SEMANAS), fin), desde, hasta,
                       sat.modo_de(meta), total_riesgo, principal)


def get_factores(n, q: dict, _cuerpo) -> dict:
    actual, meta, factores = n.modelo_publicado()
    return sat.factores(q.get("lado", "pasajero"), int(actual["version"]) if actual else None, meta, factores)


def get_riesgo(n, q: dict, _cuerpo) -> dict:
    try:
        limite = int(q.get("limite", 50))
    except ValueError as e:
        raise sat.ErrorContrato(400, "limite_invalido", "El límite debe ser un número.") from e
    return _riesgo(n, q.get("lado", "todos"), limite)


def get_modelo(n, _q, _cuerpo) -> dict:
    actual, meta, _ = n.modelo_publicado()
    historial, activo = _historial_y_activo(n)
    return sat.modelo(actual, meta, sat.datos_modelo(n.conteos_notas()), _programacion_vista(n), activo, historial)


def post_entrenamientos(n, q: dict, _cuerpo, origen: str = "manual", publicar_solo_si_mejora: bool = True):
    # `?demo=true` (contrato v0.2) se ignora: el entrenamiento es siempre con datos reales.
    _, activo = _historial_y_activo(n)
    if activo:
        raise sat.ErrorContrato(409, "entrenamiento_en_curso", "Ya hay un entrenamiento en curso.")
    ident = sat.nuevo_id()
    registro = sat.registro_inicial(ident, origen)
    if not sat.datos_modelo(n.conteos_notas())["suficientes"]:
        registro.update(estado="DATOS_INSUFICIENTES", mensaje="Todavía no hay suficientes calificaciones.")
        n.guardar_entrenamiento(registro)
        raise sat.ErrorContrato(422, "datos_insuficientes",
                                "Todavía no hay suficientes calificaciones para entrenar con datos reales.")
    n.guardar_entrenamiento(registro)
    if not n.lanzar_entrenamiento({"id": ident, "origen": origen,
                                   "publicarSoloSiMejora": publicar_solo_si_mejora}):
        registro.update(estado="FALLIDO", mensaje="El entrenamiento todavía no está desplegado en AWS.")
        n.guardar_entrenamiento(registro)
        raise sat.ErrorContrato(503, "entrenamiento_no_disponible",
                                "El entrenamiento todavía no está desplegado en AWS.")
    return 202, {"id": ident}


def get_entrenamiento(n, ident: str) -> dict:
    r = n.entrenamiento(ident)
    if not r:
        raise sat.ErrorContrato(404, "no_existe", "Ese entrenamiento no existe.")
    return sat.vista_entrenamiento(r)


def delete_entrenamiento(n, ident: str):
    if not n.entrenamiento(ident):
        raise sat.ErrorContrato(404, "no_existe", "Ese entrenamiento no existe.")
    if not n.cancelar_entrenamiento(ident):
        raise sat.ErrorContrato(409, "ya_termino", "Ese entrenamiento ya terminó.")
    return 204, None


def put_programacion(n, _q, cuerpo) -> dict:
    p = sat.validar_programacion(cuerpo)
    momento = sat.ahora()
    n.programar(p)
    n.guardar_programacion(p, momento)
    return {**p, "proxima": sat.proxima(p, desde=momento, guardada=momento)}


_RUTAS: dict[tuple[str, str], Callable] = {
    ("GET", "/resumen"): get_resumen,
    ("GET", "/factores"): get_factores,
    ("GET", "/riesgo"): get_riesgo,
    ("GET", "/modelo"): get_modelo,
    ("POST", "/entrenamientos"): post_entrenamientos,
    ("PUT", "/programacion"): put_programacion,
}


def atender_http(evento: dict, n) -> dict:
    http = (evento.get("requestContext") or {}).get("http") or {}
    metodo = http.get("method", "GET").upper()
    ruta = (evento.get("rawPath") or http.get("path") or "/").rstrip("/") or "/"
    if metodo == "OPTIONS":
        return _respuesta(204)
    denegado = _admin(evento, n.secreto_jwt())
    if denegado:
        return denegado
    q = evento.get("queryStringParameters") or {}
    try:
        cuerpo = None
        if evento.get("body"):
            texto = evento["body"]
            if evento.get("isBase64Encoded"):
                texto = base64.b64decode(texto).decode("utf-8")
            cuerpo = json.loads(texto)
        if ruta.startswith("/entrenamientos/") and ruta.count("/") == 2:
            ident = ruta.split("/")[2]
            if metodo == "GET":
                return _respuesta(200, get_entrenamiento(n, ident))
            if metodo == "DELETE":
                estado, _ = delete_entrenamiento(n, ident)
                return _respuesta(estado)
        manejador = _RUTAS.get((metodo, ruta))
        if not manejador:
            return _error(404, "ruta_no_existe", "Esa ruta no existe.")
        resultado = manejador(n, q, cuerpo)
        if isinstance(resultado, tuple):
            return _respuesta(*resultado)
        return _respuesta(200, resultado)
    except sat.ErrorContrato as e:
        return _error(e.estado, e.codigo, e.mensaje)
    except json.JSONDecodeError:
        return _error(400, "json_invalido", "El cuerpo no es un JSON válido.")
    except Exception:
        log.exception("Error atendiendo %s %s", metodo, ruta)
        return _error(500, "error_interno", "No se pudo completar la consulta. Intenta de nuevo.")


def entrenar_programado(n) -> dict:
    """Lo invoca EventBridge Scheduler. Respeta 'solo con datos nuevos' y no choca con uno en curso."""
    p, _ = n.programacion()
    if not p.get("activa"):
        return {"resultado": "programacion_apagada"}
    if p.get("soloConDatosNuevos"):
        nuevos = n.finalizados_desde(n.fin_ultimo_modelo())
        if nuevos < int(p.get("minimoViajesNuevos") or 1):
            registro = sat.registro_inicial(sat.nuevo_id(), "programado")
            registro.update(estado="SIN_DATOS_NUEVOS",
                            mensaje=f"Solo {nuevos} viajes calificados nuevos (mínimo {p['minimoViajesNuevos']}).")
            n.guardar_entrenamiento(registro)
            return {"resultado": "sin_datos_nuevos", "nuevos": nuevos}
    try:
        estado, cuerpo = post_entrenamientos(n, {}, None, origen="programado",
                                             publicar_solo_si_mejora=bool(p.get("publicarSoloSiMejora", True)))
        return {"resultado": "lanzado", **cuerpo}
    except sat.ErrorContrato as e:
        return {"resultado": e.codigo}


def lambda_handler(evento, _contexto):
    evento = evento if isinstance(evento, dict) else {}
    n = _nube()
    if evento.get("accion") == "entrenar_programado":
        resultado = entrenar_programado(n)
        log.info("entrenamiento programado: %s", resultado)
        return resultado
    return atender_http(evento, n)
