"""Lambda mediadora sin nube: una Nube falsa en memoria y viajes sintéticos."""
import base64
import importlib
import json
import sys
import time
from datetime import datetime, timedelta, timezone
from pathlib import Path

import jwt
import pytest

from nexa_ml import satisfaccion as sat
from generador_viajes import generar

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "lambda_fn"))
mediadora = importlib.import_module("mediadora")

SECRETO = base64.b64encode(b"s" * 48).decode()


def token(roles=("ROLE_ADMIN",), segundos=600, secreto=SECRETO):
    return jwt.encode({"sub": "admin@nexa.co", "roles": list(roles), "exp": int(time.time()) + segundos},
                      base64.b64decode(secreto), algorithm="HS256")


class PredictorFalso:
    def probabilidades(self, x):
        return [[0.9, 0.1] for _ in x]


class NubeFalsa:
    def __init__(self, viajes, publicado=False, entrenadora=True):
        self.viajes = viajes
        self.items = {}
        self.lanzados = []
        self.programado = None
        self.publicado = publicado
        self.entrenadora = entrenadora

    def secreto_jwt(self):
        return SECRETO

    def viajes_finalizados(self, desde, hasta, limite=20_000):
        from nexa_ml.caracteristicas import a_fecha

        return [v for v in self.viajes if desde <= a_fecha(v["fechaFinalizacion"]) < hasta][:limite]

    def conteos_notas(self):
        salida = {}
        for lado, campo in sat.CAMPO_NOTA.items():
            notas = [v[campo] for v in self.viajes if v.get(campo) is not None]
            salida[lado] = {"calificaciones": len(notas), "no": sum(1 for n in notas if n < 4)}
        return salida

    def finalizados_desde(self, desde):
        return 5

    def modelo_publicado(self):
        if not self.publicado:
            return None, None, None
        meta = {"modo": "real", "entrenadoEn": "2026-11-08T02:14:00-05:00", "datos": {"viajes": 478},
                "umbrales": {"satisfaccion_pasajero": 0.45, "satisfaccion_conductor": 0.5},
                "resultados": {"red_neuronal": {"prueba": {"satisfaccion_pasajero": {"evaluable": True, "pr_auc": 0.4}}}},
                "supera_bases": {"satisfaccion_pasajero": False}}
        factores = {"pasajero": {"importancia": [{"variable": "minutos_hasta_aceptacion",
                                                  "etiqueta": "Espera hasta que un conductor acepta", "pesoPct": 22.0}],
                                 "otrosFactores": {"cantidad": 20, "pesoMaximoPct": 5.0}, "curvas": []}}
        return {"version": 3, "prefijo": "modelos/v3/"}, meta, factores

    def predictor(self):
        return PredictorFalso() if self.publicado else None

    def programacion(self):
        p = self.items.get("programacion")
        return (dict(p) if p else dict(sat.PROGRAMACION_INICIAL)), None

    def guardar_programacion(self, p, momento):
        self.items["programacion"] = p

    def programar(self, p):
        self.programado = p

    def entrenamientos(self):
        return sorted((v for v in self.items.values() if v.get("tipo") == "entrenamiento"),
                      key=lambda r: r["fecha"], reverse=True)

    def entrenamiento(self, ident):
        return self.items.get(ident)

    def guardar_entrenamiento(self, r):
        self.items[r["id"]] = dict(r)

    def cancelar_entrenamiento(self, ident):
        r = self.items[ident]
        if r["estado"] in sat.ESTADOS_FINALES:
            return False
        r.update(estado="CANCELADO", cancelar=True)
        return True

    def lanzar_entrenamiento(self, carga):
        self.lanzados.append(carga)
        return self.entrenadora

    def fin_ultimo_modelo(self):
        return None


def evento(metodo, ruta, q=None, cuerpo=None, tok="ok"):
    cab = {} if tok is None else {"Authorization": f"Bearer {token() if tok == 'ok' else tok}"}
    e = {"rawPath": ruta, "requestContext": {"http": {"method": metodo}}, "headers": cab,
         "queryStringParameters": q}
    if cuerpo is not None:
        e["body"] = json.dumps(cuerpo)
    return e


def llamar(n, *a, **k):
    r = mediadora.atender_http(evento(*a, **k), n)
    return r["statusCode"], (json.loads(r["body"]) if r.get("body") else None)


@pytest.fixture
def viajes_recientes():
    viajes = generar(1200)
    # Los sintéticos empiezan en agosto de 2026: se corren para que terminen hoy.
    from nexa_ml.caracteristicas import a_fecha

    corrimiento = datetime.now(timezone.utc) - max(a_fecha(v["fechaFinalizacion"]) for v in viajes) - timedelta(hours=1)
    for v in viajes:
        for campo in ("fechaHora", "solicitadoEn", "fechaAceptacion", "fechaLlegada", "fechaInicio", "fechaFinalizacion"):
            if v.get(campo):
                v[campo] = a_fecha(v[campo]) + corrimiento
    return viajes


def test_sin_token_401_y_no_admin_403(viajes_recientes):
    n = NubeFalsa(viajes_recientes)
    assert llamar(n, "GET", "/modelo", tok=None)[0] == 401
    assert llamar(n, "GET", "/modelo", tok=token(segundos=-10))[1]["error"] == "sesion_vencida"
    assert llamar(n, "GET", "/modelo", tok=token(secreto=base64.b64encode(b"x" * 48).decode()))[0] == 401
    assert llamar(n, "GET", "/modelo", tok=token(roles=["ROLE_PASAJERO"]))[0] == 403


def test_resumen_observado(viajes_recientes):
    estado, r = llamar(NubeFalsa(viajes_recientes), "GET", "/resumen")
    assert estado == 200
    assert r["modo"] == "sin_modelo" and r["riesgoTotal"] == 0 and r["factorPrincipal"] is None
    assert 0 < r["pasajero"]["satisfechosPct"] <= 100
    assert r["pasajero"]["calificaciones"] > 0 and 0 < r["pasajero"]["tasaRespuestaPct"] <= 100
    assert 1 <= len(r["tendencia"]) <= 12
    assert r["tendencia"][-1]["semana"] == sat.semana_iso(datetime.now(sat.ZONA))


def test_modelo_sin_publicar_muestra_datos(viajes_recientes):
    estado, r = llamar(NubeFalsa(viajes_recientes), "GET", "/modelo")
    assert estado == 200 and r["version"] is None and r["variables"] == 25
    assert r["datos"]["minimos"] == {"calificaciones": 300, "no": 30}
    assert r["programacion"]["activa"] is False and r["programacion"]["proxima"] is None
    assert r["entrenamientoActivo"] is None and r["historial"] == []


def test_modelo_publicado_factores_y_riesgo(viajes_recientes):
    n = NubeFalsa(viajes_recientes, publicado=True)
    _, m = llamar(n, "GET", "/modelo")
    assert m["version"] == 3 and m["metricas"]["pasajero"]["redPrAuc"] == 0.4
    _, f = llamar(n, "GET", "/factores", {"lado": "pasajero"})
    assert f["importancia"][0]["pesoPct"] == 22.0 and f["version"] == 3
    _, rg = llamar(n, "GET", "/riesgo", {"lado": "todos", "limite": "5"})
    assert rg["total"] > 0 and len(rg["viajes"]) == 5
    assert all(v["lado"] == "pasajero" and len(v["id"]) == 4 for v in rg["viajes"])
    _, res = llamar(n, "GET", "/resumen")
    assert res["factorPrincipal"]["etiqueta"] == "Espera hasta que un conductor acepta"
    assert res["riesgoTotal"] == rg["total"]


def test_entrenar_cancelar_y_conflicto(viajes_recientes):
    n = NubeFalsa(viajes_recientes)
    assert n.conteos_notas()["pasajero"]["calificaciones"] >= 300
    estado, r = llamar(n, "POST", "/entrenamientos", {"demo": "true"})  # demo se ignora: siempre real
    assert estado == 202 and "demo" not in n.lanzados[0]
    assert n.entrenamientos()[0]["modo"] == "real"
    assert llamar(n, "POST", "/entrenamientos")[1]["error"] == "entrenamiento_en_curso"
    _, e = llamar(n, "GET", f"/entrenamientos/{r['id']}")
    assert e["estado"] == "EN_COLA" and set(e["pasos"]) == set(sat.PASOS)
    assert llamar(n, "DELETE", f"/entrenamientos/{r['id']}")[0] == 204
    assert llamar(n, "DELETE", f"/entrenamientos/{r['id']}")[0] == 409
    _, m = llamar(n, "GET", "/modelo")
    assert m["historial"][0]["estado"] == "CANCELADO" and m["entrenamientoActivo"] is None


def test_entrenar_sin_datos_queda_en_historial_aunque_pida_demo(viajes_recientes):
    n = NubeFalsa(viajes_recientes[:50])
    estado, r = llamar(n, "POST", "/entrenamientos", {"demo": "true"})
    assert estado == 422 and r["error"] == "datos_insuficientes"
    assert n.entrenamientos()[0]["estado"] == "DATOS_INSUFICIENTES"


def test_sin_entrenadora_desplegada_503(viajes_recientes):
    n = NubeFalsa(viajes_recientes, entrenadora=False)
    estado, r = llamar(n, "POST", "/entrenamientos")
    assert estado == 503 and n.entrenamientos()[0]["estado"] == "FALLIDO"


def test_programacion_valida_e_invalida(viajes_recientes):
    n = NubeFalsa(viajes_recientes)
    estado, p = llamar(n, "PUT", "/programacion", cuerpo={"activa": True, "frecuencia": "semanal",
                                                           "dias": ["DOM", "MIE"], "hora": "02:00"})
    assert estado == 200 and p["dias"] == ["MIE", "DOM"] and p["proxima"]
    assert sat.expresion_programacion(n.programado) == "cron(0 2 ? * WED,SUN *)"
    assert llamar(n, "PUT", "/programacion", cuerpo={"frecuencia": "cada_horas", "cadaHoras": 0})[0] == 400
    assert llamar(n, "PUT", "/programacion", cuerpo={"hora": "25:00"})[0] == 400


def test_programado_sin_datos_nuevos(viajes_recientes):
    n = NubeFalsa(viajes_recientes)
    n.items["programacion"] = {**sat.PROGRAMACION_INICIAL, "activa": True, "minimoViajesNuevos": 20}
    assert mediadora.entrenar_programado(n)["resultado"] == "sin_datos_nuevos"
    assert n.entrenamientos()[0]["estado"] == "SIN_DATOS_NUEVOS"


def test_proxima_y_expresiones():
    lunes = datetime(2026, 11, 9, 10, 0, tzinfo=sat.ZONA)
    semanal = {**sat.PROGRAMACION_INICIAL, "activa": True}
    assert sat.proxima(semanal, desde=lunes) == "2026-11-15T02:00:00-05:00"
    diaria = {**semanal, "frecuencia": "diaria", "hora": "23:30"}
    assert sat.proxima(diaria, desde=lunes) == "2026-11-09T23:30:00-05:00"
    assert sat.expresion_programacion(diaria) == "cron(30 23 * * ? *)"
    horas = {**semanal, "frecuencia": "cada_horas", "cadaHoras": 6}
    assert sat.expresion_programacion(horas) == "rate(6 hours)"
    assert sat.proxima(horas, desde=lunes, guardada=lunes - timedelta(hours=1)) == "2026-11-09T15:00:00-05:00"


def test_motivos_y_lugar():
    m = sat.motivos({"minutos_hasta_aceptacion": 7, "finalizado_antes_del_destino": 1, "minutos_espera": 1})
    assert [x["variable"] for x in m] == ["minutos_hasta_aceptacion", "finalizado_antes_del_destino"]
    assert m[0]["texto"] == "Esperó 7 min a que aceptaran" and m[0]["severidad"] == "alta"
    assert sat.lugar("Bocagrande, Avenida San Martín, Cartagena") == "Bocagrande"


def test_riesgo_omite_viajes_incompletos(viajes_recientes):
    from nexa_ml import caracteristicas as car

    pendientes = [v for v in viajes_recientes if any(v.get(c) is None for c in sat.CAMPO_NOTA.values())]
    assert len(pendientes) >= 2
    rotos = pendientes[: len(pendientes) // 2]
    for v in rotos:
        v.pop("fechaLlegada", None)
    vistos = []

    class PredictorQueAnota(PredictorFalso):
        def probabilidades(self, x):
            vistos.extend(x)
            return super().probabilidades(x)

    n = NubeFalsa(viajes_recientes, publicado=True)
    n.predictor = lambda: PredictorQueAnota()
    estado, rg = llamar(n, "GET", "/riesgo", {"lado": "todos", "limite": "500"})
    assert estado == 200
    esperados = [v for v in pendientes if car.motivo_incompleto(v) is None]
    assert len(vistos) == len(esperados) < len(pendientes)
