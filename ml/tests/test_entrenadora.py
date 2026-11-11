"""Trabajo de entrenamiento con una nube falsa. Los viajes salen del generador de pruebas en vez de Atlas
(solo en las pruebas: la entrenadora real lee únicamente viajes de MongoDB)."""
import json

import pytest

from nexa_ml import datos, entrenadora
from nexa_ml import satisfaccion as sat
from generador_viajes import generar


class NubeFalsa:
    param_mongo = "/nexa/ml/MONGODB_URI"
    base = "motvirsweb"

    def __init__(self):
        self.archivos, self.items = {}, {}
        self.cancelar_en = None

    def secreto(self, nombre):
        return "mongodb+srv://falso"

    def entrenamiento(self, ident):
        r = self.items.get(ident)
        if r is not None and self.cancelar_en and r.get("epoca") and r["epoca"] >= self.cancelar_en:
            r["cancelar"] = True
        return dict(r) if r else None

    def guardar_entrenamiento(self, r):
        self.items[r["id"]] = dict(r)

    def entrenamientos(self):
        return list(self.items.values())

    def modelo_publicado(self):
        actual = self.archivos.get("modelos/actual.json")
        if not actual:
            return None, None, None
        actual = json.loads(actual)
        meta = json.loads(self.archivos[actual["prefijo"] + "metadatos.json"])
        fac = json.loads(self.archivos[actual["prefijo"] + "factores.json"])
        return actual, meta, fac

    def subir(self, clave, contenido, tipo):
        self.archivos[clave] = contenido

    def subir_json(self, clave, valor):
        self.archivos[clave] = json.dumps(valor, default=str)


@pytest.fixture
def con_viajes(monkeypatch):
    def usar(n):
        viajes = generar(n)
        monkeypatch.setattr(datos, "desde_mongo", lambda uri, base: viajes)
    return usar


def _registro(nube, ident="e-1"):
    nube.guardar_entrenamiento(sat.registro_inicial(ident, "manual"))
    return ident


def test_entrena_publica_y_explica(con_viajes):
    con_viajes(1500)
    nube = NubeFalsa()
    r = entrenadora.correr(nube, _registro(nube))
    assert r["estado"] == "PUBLICADO", r.get("mensaje")
    assert r["modo"] == "real" and r["version"] == 1 and r["progresoPct"] == 100
    assert set(r["pasos"].values()) == {"hecho"}
    assert "viajes completos" in r["detalleExportar"]
    actual, meta, fac = nube.modelo_publicado()
    assert actual == {"version": 1, "prefijo": "modelos/v1/"} and meta["modo"] == "real"
    assert "modelos/v1/modelo.tflite" in nube.archivos
    for lado in sat.LADOS:
        imp = fac[lado]["importancia"]
        assert 1 <= len(imp) <= 5 and imp == sorted(imp, key=lambda i: -i["pesoPct"])
        assert sum(i["pesoPct"] for i in imp) <= 100.1 and all(i["etiqueta"] for i in imp)
        assert len(fac[lado]["curvas"]) <= 3
        for c in fac[lado]["curvas"]:
            assert len(c["tramos"]) >= 2 and c["hallazgo"]
    assert set(fac["medias"]) >= {"minutos_hasta_aceptacion", "minutos_espera"}
    # El panel entiende lo publicado.
    m = sat.modelo(actual, meta, sat.datos_modelo({l: {"calificaciones": 400, "no": 50} for l in sat.LADOS}),
                   dict(sat.PROGRAMACION_INICIAL), None, [])
    assert m["version"] == 1 and m["modo"] == "real"


def test_sin_datos_suficientes_no_entrena(con_viajes):
    con_viajes(120)
    nube = NubeFalsa()
    r = entrenadora.correr(nube, _registro(nube))
    assert r["estado"] == "DATOS_INSUFICIENTES" and "modelos/actual.json" not in nube.archivos


def test_cancelar_durante_el_entrenamiento(con_viajes):
    con_viajes(1500)
    nube = NubeFalsa()
    nube.cancelar_en = 5
    r = entrenadora.correr(nube, _registro(nube))
    assert r["estado"] == "CANCELADO" and "modelos/actual.json" not in nube.archivos


def test_reglas_de_publicacion():
    real = {"modo": "real", "resultados": {"red_neuronal": {"prueba": {
        "a": {"evaluable": True, "pr_auc": 0.60}, "b": {"evaluable": True, "pr_auc": 0.40}}}}}
    peor = {"resultados": {"red_neuronal": {"prueba": {"a": {"evaluable": True, "pr_auc": 0.30}}}}}
    assert entrenadora.decidir_publicacion(peor, None, True)[0]
    assert entrenadora.decidir_publicacion(peor, {"modo": "demo"}, True)[0]
    assert not entrenadora.decidir_publicacion(peor, real, True)[0]
    assert entrenadora.decidir_publicacion(peor, real, False)[0]
