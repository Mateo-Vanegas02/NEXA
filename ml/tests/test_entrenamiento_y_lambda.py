"""Prueba de punta a punta con datos SINTÉTICOS: entrena, exporta a TFLite y llama a la Lambda."""
import importlib
import json
import sys
from pathlib import Path

import numpy as np
import pytest

from nexa_ml import caracteristicas as car
from nexa_ml import datos, entrenar
from nexa_ml.sinteticos import generar

RAIZ = Path(__file__).resolve().parents[1]


@pytest.fixture(scope="module")
def artefactos(tmp_path_factory):
    salida = tmp_path_factory.mktemp("artefactos")
    meta = entrenar.ejecutar(generar(3000), salida, fuente="SINTETICOS")
    return salida, meta


def test_viajes_sin_ninguna_nota_se_descartan():
    viajes = generar(50)
    viajes[0]["calificacionConductor"] = viajes[0]["calificacionPasajero"] = None
    conjunto = datos.construir(viajes)
    assert conjunto.descartados >= 1
    assert conjunto.y.shape == (conjunto.n, len(car.OBJETIVOS))
    assert set(np.unique(conjunto.y)) <= {-1.0, 0.0, 1.0}


def test_no_entrena_con_pocos_datos(tmp_path):
    with pytest.raises(entrenar.DatosInsuficientes, match="satisfaccion_"):
        entrenar.ejecutar(generar(60), tmp_path)


def test_entrena_los_dos_lados_y_exporta(artefactos):
    salida, meta = artefactos
    assert {p.name for p in salida.iterdir()} >= {"modelo.keras", "modelo.tflite", "metadatos.json"}
    assert meta["diferencia_max_tflite_vs_keras"] <= 1e-4
    assert set(meta["umbrales"]) == set(car.OBJETIVOS)
    for objetivo in car.OBJETIVOS:
        red = meta["resultados"]["red_neuronal"]["prueba"][objetivo]
        assert red["evaluable"]
        # En los datos sintéticos hay señal real en ambos lados: el modelo debe ganarle al azar.
        assert red["roc_auc"] > 0.65, objetivo
        assert red["pr_auc"] > red["prevalencia"], objetivo


@pytest.fixture(scope="module")
def monkeypatch_module():
    with pytest.MonkeyPatch.context() as mp:
        yield mp


@pytest.fixture(scope="module")
def lambda_fn(artefactos, monkeypatch_module):
    salida, _ = artefactos
    monkeypatch_module.setenv("NEXA_MODELO_DIR", str(salida))
    monkeypatch_module.syspath_prepend(str(RAIZ / "lambda_fn"))
    sys.modules.pop("handler", None)
    return importlib.import_module("handler")


def test_lambda_devuelve_los_dos_lados(lambda_fn):
    r = lambda_fn.lambda_handler({"viajes": generar(3, semilla=99)}, None)
    assert len(r["predicciones"]) == 3
    p = r["predicciones"][0]
    assert p["id"] == "sintetico-0"
    for clave in ("satisfaccionPasajero", "satisfaccionConductor"):
        assert p[clave]["satisfaccion"] in {"si", "no"}
        assert 0 <= p[clave]["probabilidadNo"] <= 1


def test_lambda_por_url_con_token(lambda_fn, monkeypatch):
    monkeypatch.setenv("NEXA_ML_TOKEN", "secreto")
    evento = {"body": json.dumps({"viaje": generar(1)[0]}), "headers": {"X-Nexa-Token": "secreto"}}
    r = lambda_fn.lambda_handler(evento, None)
    assert r["statusCode"] == 200
    assert len(json.loads(r["body"])["predicciones"]) == 1

    evento["headers"] = {"x-nexa-token": "otro"}
    assert lambda_fn.lambda_handler(evento, None)["statusCode"] == 401


def test_lambda_rechaza_entradas_malas(lambda_fn):
    assert lambda_fn.lambda_handler({"body": "{no es json"}, None)["statusCode"] == 400
    assert lambda_fn.lambda_handler({"body": json.dumps({"viajes": []})}, None)["statusCode"] == 400
    assert "error" in lambda_fn.lambda_handler({"viajes": [{"distanciaKM": 1}] * 101}, None)
