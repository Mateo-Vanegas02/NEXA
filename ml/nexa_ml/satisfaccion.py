"""Reglas puras del panel de satisfacción del admin (contrato v0.2, `mobile/docs/CONTRATO_SATISFACCION.md`).

Sin AWS ni MongoDB: reciben viajes (documentos de `servicios`) y datos ya leídos y devuelven los JSON del
contrato. Así se prueban sin nube y la Lambda mediadora solo junta las piezas.
"""
from __future__ import annotations

import math
import re
from datetime import date, datetime, timedelta, timezone
from typing import Any, Iterable, Mapping
from zoneinfo import ZoneInfo

from . import caracteristicas as car

ZONA = ZoneInfo("America/Bogota")
NOTA_SATISFECHO = car.NOTA_SATISFECHO
MINIMO_NOTAS = 300
MINIMO_NO = 30
MAX_SEMANAS = 12
#: Agrupación de la gráfica del panel según el largo del período (días, inclusive).
MAX_DIAS_POR_DIA = 14
MAX_DIAS_POR_SEMANA = 182
#: Con menos notas que esto un punto se muestra como dato débil (el panel lo dibuja tenue).
MIN_NOTAS_PUNTO = 10

#: lado del contrato → campo de Mongo con la nota que pone ese lado
CAMPO_NOTA = {"pasajero": "calificacionConductor", "conductor": "calificacionPasajero"}
#: lado del contrato → objetivo del modelo
OBJETIVO = {"pasajero": "satisfaccion_pasajero", "conductor": "satisfaccion_conductor"}
LADOS = ("pasajero", "conductor")

DIAS = ("LUN", "MAR", "MIE", "JUE", "VIE", "SAB", "DOM")
_DIA_CRON = dict(zip(DIAS, ("MON", "TUE", "WED", "THU", "FRI", "SAT", "SUN")))
FRECUENCIAS = ("diaria", "semanal", "cada_horas")
ESTADOS_FINALES = {"PUBLICADO", "GUARDADO_SIN_PUBLICAR", "SIN_DATOS_NUEVOS", "FALLIDO", "CANCELADO",
                   "DATOS_INSUFICIENTES"}
PROGRAMACION_INICIAL = {
    "activa": False, "frecuencia": "semanal", "dias": ["DOM"], "hora": "02:00", "cadaHoras": None,
    "soloConDatosNuevos": True, "minimoViajesNuevos": 20, "publicarSoloSiMejora": True,
}


class ErrorContrato(ValueError):
    """Error con código y mensaje para la app: {"error": codigo, "mensaje": texto}."""

    def __init__(self, estado: int, codigo: str, mensaje: str):
        super().__init__(mensaje)
        self.estado, self.codigo, self.mensaje = estado, codigo, mensaje


# --------------------------------------------------------------------------- fechas
def ahora() -> datetime:
    return datetime.now(ZONA)


def iso(fecha: datetime | None) -> str | None:
    if fecha is None:
        return None
    if fecha.tzinfo is None:  # pymongo entrega UTC sin zona
        fecha = fecha.replace(tzinfo=timezone.utc)
    return fecha.astimezone(ZONA).isoformat(timespec="seconds")


def dia(texto: str | None, defecto: date) -> date:
    if not texto:
        return defecto
    try:
        return date.fromisoformat(texto)
    except ValueError as e:
        raise ErrorContrato(400, "fecha_invalida", "La fecha debe ser AAAA-MM-DD.") from e


def inicio_del_dia(d: date) -> datetime:
    return datetime(d.year, d.month, d.day, tzinfo=ZONA)


def periodo(desde_txt: str | None, hasta_txt: str | None, hoy: date | None = None) -> tuple[date, date]:
    hoy = hoy or ahora().date()
    hasta = dia(hasta_txt, hoy)
    desde = dia(desde_txt, hasta - timedelta(days=29))
    if desde > hasta:
        raise ErrorContrato(400, "fecha_invalida", "La fecha inicial es posterior a la final.")
    if (hasta - desde).days > 366:
        raise ErrorContrato(400, "fecha_invalida", "El período máximo es de un año.")
    return desde, hasta


def semana_iso(fecha: datetime) -> str:
    anio, semana, _ = fecha.astimezone(ZONA).isocalendar()
    return f"{anio}-W{semana:02d}"


# --------------------------------------------------------------------------- resumen
def _pct(parte: int, total: int) -> float | None:
    return round(100.0 * parte / total, 1) if total else None


def lado_resumen(viajes: list[Mapping[str, Any]], lado: str) -> dict:
    """Satisfacción observada de un lado: % de notas de 4 o 5, tasa de respuesta y cuántas notas."""
    campo = CAMPO_NOTA[lado]
    notas = [float(v[campo]) for v in viajes if v.get(campo) is not None]
    satisfechas = sum(1 for n in notas if n >= NOTA_SATISFECHO)
    return {
        "satisfechosPct": _pct(satisfechas, len(notas)),
        "tasaRespuestaPct": _pct(len(notas), len(viajes)) or 0.0,
        "calificaciones": len(notas),
    }


def resumen(actual: list[Mapping], anterior: list[Mapping], semanas: list[Mapping], desde: date, hasta: date,
            modo: str, riesgo_total: int, factor_principal: dict | None) -> dict:
    """GET /resumen. `actual`/`anterior`: viajes finalizados del período y del anterior de igual duración;
    `semanas`: viajes finalizados de las últimas 12 semanas hasta `hasta` (para la tendencia)."""
    salida = {"desde": desde.isoformat(), "hasta": hasta.isoformat(), "modo": modo}
    for lado in LADOS:
        hoy = lado_resumen(actual, lado)
        antes = lado_resumen(anterior, lado)
        variacion = None
        if hoy["satisfechosPct"] is not None and antes["satisfechosPct"] is not None:
            variacion = round(hoy["satisfechosPct"] - antes["satisfechosPct"], 1)
        salida[lado] = {"satisfechosPct": hoy["satisfechosPct"], "variacionPts": variacion,
                        "tasaRespuestaPct": hoy["tasaRespuestaPct"], "calificaciones": hoy["calificaciones"]}
    salida["tendencia"] = tendencia(semanas, hasta)
    salida["serie"] = serie(actual, desde, hasta)
    salida["riesgoTotal"] = int(riesgo_total)
    salida["factorPrincipal"] = factor_principal
    return salida


def tendencia(viajes: Iterable[Mapping], hasta: date) -> list[dict]:
    """Hasta 12 semanas ISO terminando en la de `hasta`; una semana sin notas va con null."""
    fin = inicio_del_dia(hasta)
    claves = [semana_iso(fin - timedelta(weeks=i)) for i in range(MAX_SEMANAS - 1, -1, -1)]
    por_semana: dict[str, list[Mapping]] = {k: [] for k in claves}
    for v in viajes:
        f = car.a_fecha(v.get("fechaFinalizacion"))
        if f is not None and semana_iso(f) in por_semana:
            por_semana[semana_iso(f)].append(v)
    puntos = []
    for clave in claves:
        grupo = por_semana[clave]
        puntos.append({"semana": clave, **_valores(grupo)})
    # No se muestran las semanas vacías del principio (antes de que hubiera viajes).
    while puntos and puntos[0]["pasajeroPct"] is None and puntos[0]["conductorPct"] is None:
        puntos.pop(0)
    return puntos


def _valores(grupo: list[Mapping]) -> dict:
    p, c = lado_resumen(grupo, "pasajero"), lado_resumen(grupo, "conductor")
    return {"pasajeroPct": p["satisfechosPct"], "pasajeroNotas": p["calificaciones"],
            "conductorPct": c["satisfechosPct"], "conductorNotas": c["calificaciones"]}


def agrupacion(desde: date, hasta: date) -> str:
    dias = (hasta - desde).days + 1
    return "dia" if dias <= MAX_DIAS_POR_DIA else "semana" if dias <= MAX_DIAS_POR_SEMANA else "mes"


def _tramo(d: date, agrup: str) -> tuple[str, date, date]:
    """Clave, primer y último día del tramo que contiene `d`."""
    if agrup == "dia":
        return d.isoformat(), d, d
    if agrup == "semana":
        anio, semana, dia_semana = d.isocalendar()
        lunes = d - timedelta(days=dia_semana - 1)
        return f"{anio}-W{semana:02d}", lunes, lunes + timedelta(days=6)
    primero = d.replace(day=1)
    siguiente = (primero + timedelta(days=32)).replace(day=1)
    return f"{d.year}-{d.month:02d}", primero, siguiente - timedelta(days=1)


def serie(viajes: Iterable[Mapping], desde: date, hasta: date) -> dict:
    """Gráfica del período: por día (hasta 14 días), por semana (hasta 26 semanas) o por mes.
    Incluye todos los tramos del período, aunque no tengan notas, recortados a `desde`/`hasta`,
    y cuántas notas hay detrás de cada porcentaje."""
    agrup = agrupacion(desde, hasta)
    tramos: dict[str, tuple[date, date]] = {}
    d = desde
    while d <= hasta:
        clave, ini, fin = _tramo(d, agrup)
        tramos[clave] = (max(ini, desde), min(fin, hasta))
        d = fin + timedelta(days=1)
    grupos: dict[str, list[Mapping]] = {k: [] for k in tramos}
    for v in viajes:
        f = car.a_fecha(v.get("fechaFinalizacion"))
        if f is None:
            continue
        clave = _tramo(f.astimezone(ZONA).date(), agrup)[0]
        if clave in grupos:
            grupos[clave].append(v)
    return {"agrupacion": agrup, "minimoNotas": MIN_NOTAS_PUNTO,
            "puntos": [{"clave": k, "desde": ini.isoformat(), "hasta": fin.isoformat(), **_valores(grupos[k])}
                       for k, (ini, fin) in tramos.items()]}


# --------------------------------------------------------------------------- datos para entrenar
def datos_modelo(conteos: Mapping[str, Mapping[str, int]]) -> dict:
    """`datos` de GET /modelo: notas y 'no' por lado frente a los mínimos del entrenamiento."""
    salida = {lado: {"calificaciones": int(conteos[lado]["calificaciones"]), "no": int(conteos[lado]["no"])}
              for lado in LADOS}
    salida["minimos"] = {"calificaciones": MINIMO_NOTAS, "no": MINIMO_NO}
    salida["suficientes"] = all(salida[l]["calificaciones"] >= MINIMO_NOTAS and salida[l]["no"] >= MINIMO_NO
                                for l in LADOS)
    return salida


# --------------------------------------------------------------------------- modelo publicado
def metricas_modelo(meta: Mapping[str, Any] | None) -> dict:
    vacio = {"redPrAuc": None, "regresionPrAuc": None, "supera": False}
    if not meta:
        return {lado: dict(vacio) for lado in LADOS}
    resultados = meta.get("resultados") or {}
    salida = {}
    for lado in LADOS:
        obj = OBJETIVO[lado]
        red = ((resultados.get("red_neuronal") or {}).get("prueba") or {}).get(obj) or {}
        log = ((resultados.get("regresion_logistica") or {}).get("prueba") or {}).get(obj) or {}
        salida[lado] = {
            "redPrAuc": round(red["pr_auc"], 3) if red.get("evaluable") and red.get("pr_auc") is not None else None,
            "regresionPrAuc": round(log["pr_auc"], 3) if log.get("evaluable") and log.get("pr_auc") is not None else None,
            "supera": bool((meta.get("supera_bases") or {}).get(obj)),
        }
    return salida


def modelo(actual: Mapping[str, Any] | None, meta: Mapping[str, Any] | None, datos: dict, programacion: dict,
           activo: dict | None, historial: list[dict]) -> dict:
    """GET /modelo. `actual`: puntero `modelos/actual.json`; `meta`: metadatos del modelo publicado."""
    publicado = bool(actual and meta)
    return {
        "version": int(actual["version"]) if publicado else None,
        "entrenadoEn": (meta or {}).get("entrenadoEn") if publicado else None,
        "viajes": int(((meta or {}).get("datos") or {}).get("viajes") or 0) if publicado else 0,
        "variables": len((meta or {}).get("caracteristicas") or car.CARACTERISTICAS),
        "modo": modo_de(meta),
        "metricas": metricas_modelo(meta if publicado else None),
        "datos": datos,
        "programacion": programacion,
        "entrenamientoActivo": activo,
        "historial": historial,
    }


def modo_de(meta: Mapping[str, Any] | None) -> str:
    return "real" if meta and meta.get("modo") == "real" else "sin_modelo"


# --------------------------------------------------------------------------- factores
def factores(lado: str, version: int | None, meta: Mapping | None, publicados: Mapping | None) -> dict:
    if lado not in LADOS:
        raise ErrorContrato(400, "lado_invalido", "El lado debe ser pasajero o conductor.")
    del_lado = (publicados or {}).get(lado) or {}
    return {
        "lado": lado, "modo": modo_de(meta), "version": version,
        "importancia": del_lado.get("importancia") or [],
        "otrosFactores": del_lado.get("otrosFactores") or {"cantidad": 0, "pesoMaximoPct": 0.0},
        "curvas": del_lado.get("curvas") or [],
    }


# --------------------------------------------------------------------------- viajes en riesgo
_MOTIVOS = (
    # variable, umbral "media", umbral "alta", texto
    ("minutos_hasta_aceptacion", 3.0, 6.0, "Esperó {v:.0f} min a que aceptaran"),
    ("minutos_hasta_llegada", 8.0, 15.0, "El conductor tardó {v:.0f} min en llegar"),
    ("minutos_espera", 4.0, 8.0, "El conductor esperó {v:.0f} min en el punto"),
    ("finalizado_antes_del_destino", 0.5, 0.5, "El viaje terminó antes del destino"),
    ("recargo_espera", 1.0, 2000.0, "Se cobró ${v:,.0f} de recargo por espera"),
    ("extra_voluntario", 500.0, 2000.0, "Subió la oferta ${v:,.0f} para conseguir conductor"),
)


def motivos(valores: Mapping[str, float], medias: Mapping[str, float] | None = None) -> list[dict]:
    """Las variables del viaje que más se alejan de lo normal, en texto para el admin (máximo 3).

    Con `medias` (las del entrenamiento) un valor cuenta si supera 1,3× la media ("media") o 2× ("alta");
    sin ellas se usan umbrales fijos razonables para mototaxi en Cartagena."""
    encontrados = []
    for variable, umbral_media, umbral_alta, texto in _MOTIVOS:
        v = float(valores.get(variable) or 0.0)
        if v <= 0:
            continue
        media = (medias or {}).get(variable)
        if media and media > 0 and variable != "finalizado_antes_del_destino":
            razon = v / media
            if razon < 1.3:
                continue
            severidad = "alta" if razon >= 2 else "media"
        else:
            if v < umbral_media:
                continue
            severidad = "alta" if v >= umbral_alta else "media"
            razon = v / umbral_media
        encontrados.append((severidad == "alta", razon, {
            "variable": variable, "texto": texto.format(v=v).replace(",", "."), "severidad": severidad}))
    encontrados.sort(key=lambda e: (e[0], e[1]), reverse=True)
    return [m for _, _, m in encontrados[:3]]


def lugar(texto: Any) -> str:
    """El primer tramo de la dirección (el barrio o el sitio), sin números de casa."""
    if not texto:
        return ""
    primero = str(texto).split(",")[0].strip()
    return re.sub(r"\s+#.*$", "", primero)[:60]


def riesgo(viajes: list[Mapping], probabilidades, umbrales: Mapping[str, float], lado: str, limite: int,
           modo: str, medias: Mapping[str, float] | None = None) -> dict:
    """GET /riesgo. `probabilidades[i][k]`: prob. de 'no' del viaje i para el objetivo k (orden de OBJETIVOS)."""
    if lado not in ("todos", *LADOS):
        raise ErrorContrato(400, "lado_invalido", "El lado debe ser todos, pasajero o conductor.")
    lados = LADOS if lado == "todos" else (lado,)
    umbral_menor = min((umbrales[OBJETIVO[l]] for l in lados), default=0.5)
    encontrados = []
    for viaje, fila in zip(viajes, probabilidades):
        valores = dict(zip(car.CARACTERISTICAS, car.calcular(viaje)))
        for l in lados:
            if viaje.get(CAMPO_NOTA[l]) is not None:
                continue  # ese lado ya calificó: no está "en riesgo", ya se sabe
            k = car.OBJETIVOS.index(OBJETIVO[l])
            p = float(fila[k])
            if p < umbrales[OBJETIVO[l]] or not math.isfinite(p):
                continue
            ident = str(viaje.get("_id") or viaje.get("id") or "")
            encontrados.append({
                "id": ident[-4:].upper(),
                "fecha": iso(car.a_fecha(viaje.get("fechaFinalizacion"))),
                "origen": lugar(viaje.get("origen")),
                "destino": lugar(viaje.get("destino")),
                "distanciaKm": round(float(viaje.get("distanciaKM") or 0.0), 1),
                "lado": l,
                "probabilidadNo": round(p, 2),
                "motivos": motivos(valores, medias),
            })
    encontrados.sort(key=lambda v: v["probabilidadNo"], reverse=True)
    return {"umbral": round(umbral_menor, 2), "modo": modo, "total": len(encontrados),
            "viajes": encontrados[:max(1, min(limite, 200))]}


# --------------------------------------------------------------------------- programación
def validar_programacion(cuerpo: Mapping[str, Any]) -> dict:
    """PUT /programacion: devuelve la programación limpia o lanza 400 programacion_invalida."""
    def error(texto):
        raise ErrorContrato(400, "programacion_invalida", texto)

    if not isinstance(cuerpo, Mapping):
        error("Se espera un objeto JSON.")
    p = {**PROGRAMACION_INICIAL, **{k: cuerpo[k] for k in PROGRAMACION_INICIAL if k in cuerpo}}
    if not isinstance(p["activa"], bool):
        error("activa debe ser verdadero o falso.")
    if p["frecuencia"] not in FRECUENCIAS:
        error("La frecuencia debe ser diaria, semanal o cada_horas.")
    if not isinstance(p["hora"], str) or not re.fullmatch(r"([01]\d|2[0-3]):[0-5]\d", p["hora"]):
        error("La hora debe tener el formato HH:mm.")
    if p["frecuencia"] == "semanal":
        dias = p["dias"]
        if not isinstance(dias, list) or not dias or any(d not in DIAS for d in dias):
            error("Elige al menos un día de la semana.")
        p["dias"] = [d for d in DIAS if d in dias]
    else:
        p["dias"] = []
    if p["frecuencia"] == "cada_horas":
        horas = p["cadaHoras"]
        if not isinstance(horas, int) or isinstance(horas, bool) or not 1 <= horas <= 168:
            error("Cada cuántas horas debe ser un número entre 1 y 168.")
    else:
        p["cadaHoras"] = None
    for clave in ("soloConDatosNuevos", "publicarSoloSiMejora"):
        if not isinstance(p[clave], bool):
            error(f"{clave} debe ser verdadero o falso.")
    minimo = p["minimoViajesNuevos"]
    if not isinstance(minimo, int) or isinstance(minimo, bool) or not 1 <= minimo <= 10_000:
        error("El mínimo de viajes nuevos debe ser un número entre 1 y 10000.")
    return p


def expresion_programacion(p: Mapping[str, Any]) -> str:
    """Expresión de EventBridge Scheduler (zona America/Bogota)."""
    hh, mm = (int(x) for x in p["hora"].split(":"))
    if p["frecuencia"] == "diaria":
        return f"cron({mm} {hh} * * ? *)"
    if p["frecuencia"] == "semanal":
        return f"cron({mm} {hh} ? * {','.join(_DIA_CRON[d] for d in p['dias'])} *)"
    n = int(p["cadaHoras"])
    return f"rate({n} {'hour' if n == 1 else 'hours'})"


def proxima(p: Mapping[str, Any], desde: datetime | None = None, guardada: datetime | None = None) -> str | None:
    """Próxima ejecución en hora de Bogotá; None si está apagada."""
    if not p.get("activa"):
        return None
    ref = (desde or ahora()).astimezone(ZONA)
    if p["frecuencia"] == "cada_horas":
        base = (guardada or ref).astimezone(ZONA)
        paso = timedelta(hours=int(p["cadaHoras"]))
        siguiente = base + paso
        while siguiente <= ref:
            siguiente += paso
        return siguiente.replace(microsecond=0).isoformat()
    hh, mm = (int(x) for x in p["hora"].split(":"))
    for i in range(0, 8):
        candidato = (ref + timedelta(days=i)).replace(hour=hh, minute=mm, second=0, microsecond=0)
        if candidato <= ref:
            continue
        if p["frecuencia"] == "semanal" and DIAS[candidato.weekday()] not in p["dias"]:
            continue
        return candidato.isoformat()
    return None


# --------------------------------------------------------------------------- entrenamientos
PASOS = ("exportar", "entrenar", "comparar", "publicar")


def nuevo_id(momento: datetime | None = None) -> str:
    return "e-" + (momento or ahora()).astimezone(ZONA).strftime("%Y%m%d-%H%M%S")


def registro_inicial(ident: str, origen: str, momento: datetime | None = None) -> dict:
    """Registro EN_COLA de un entrenamiento. Siempre con viajes reales (no hay modo demo)."""
    return {
        "id": ident, "tipo": "entrenamiento", "fecha": (momento or ahora()).isoformat(timespec="seconds"),
        "origen": origen, "estado": "EN_COLA", "progresoPct": 0, "epoca": None, "epocas": None,
        "pasos": {p: "pendiente" for p in PASOS}, "detalleExportar": None, "mensaje": None,
        "terminaEstimado": None, "version": None, "modo": "real", "cancelar": False,
    }


def vista_entrenamiento(r: Mapping[str, Any]) -> dict:
    """GET /entrenamientos/{id}: solo los campos del contrato."""
    return {
        "id": r["id"], "estado": r.get("estado", "EN_COLA"), "progresoPct": int(r.get("progresoPct") or 0),
        "epoca": _entero(r.get("epoca")), "epocas": _entero(r.get("epocas")),
        "pasos": {p: (r.get("pasos") or {}).get(p, "pendiente") for p in PASOS},
        "detalleExportar": r.get("detalleExportar"), "mensaje": r.get("mensaje"),
        "terminaEstimado": r.get("terminaEstimado"),
    }


def vista_historial(r: Mapping[str, Any]) -> dict:
    return {"id": r["id"], "fecha": r.get("fecha"), "origen": r.get("origen", "manual"),
            "version": _entero(r.get("version")), "estado": r.get("estado"), "modo": "real",
            "mensaje": r.get("mensaje")}


def _entero(v: Any) -> int | None:
    return None if v is None else int(v)
