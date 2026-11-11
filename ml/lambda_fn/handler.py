"""Función AWS Lambda: predice la satisfacción del pasajero y del conductor en un viaje.

Entrada (invocación directa o URL de función / API Gateway con cuerpo JSON):
    {"viajes": [ {<campos del Servicio de NEXA>}, ... ]}   (máximo 100 por llamada)   o   {"viaje": {...}}
Salida:
    {"version": "...", "predicciones": [
        {"id": "...",
         "satisfaccionPasajero":  {"satisfaccion": "si", "probabilidadNo": 0.12},
         "satisfaccionConductor": {"satisfaccion": "no", "probabilidadNo": 0.71}}, ...]}

Si existe la variable NEXA_ML_TOKEN, se exige la cabecera `x-nexa-token` con ese valor.
Pensado para que lo llame el backend Java, no la app: la app habla con el backend.
"""
from __future__ import annotations

import base64
import hmac
import json
import logging
import os
from pathlib import Path

from nexa_ml import caracteristicas as car
from nexa_ml.inferencia import Predictor

log = logging.getLogger()
log.setLevel(logging.INFO)

MAX_VIAJES = 100
_DIR = Path(os.environ.get("NEXA_MODELO_DIR", Path(__file__).parent / "modelo"))
_CLAVES = {"satisfaccion_pasajero": "satisfaccionPasajero", "satisfaccion_conductor": "satisfaccionConductor"}

# Se carga una vez por contenedor (arranque en frío), no en cada invocación.
_META = json.loads((_DIR / "metadatos.json").read_text(encoding="utf-8"))
if _META["version_caracteristicas"] != car.VERSION_CARACTERISTICAS:
    raise RuntimeError("El modelo se entrenó con otra versión de las características")
_PREDICTOR = Predictor(_DIR / "modelo.tflite")
_UMBRALES = [float(_META["umbrales"][o]) for o in car.OBJETIVOS]


def _respuesta(estado: int, cuerpo: dict, http: bool) -> dict:
    if not http:
        return cuerpo if estado == 200 else {"error": cuerpo.get("error"), "estado": estado}
    return {"statusCode": estado, "headers": {"Content-Type": "application/json"},
            "body": json.dumps(cuerpo, ensure_ascii=False)}


def _cuerpo(evento: dict) -> tuple[dict, bool]:
    if "body" not in evento:  # invocación directa con el SDK
        return evento, False
    cuerpo = evento.get("body") or "{}"
    if evento.get("isBase64Encoded"):
        cuerpo = base64.b64decode(cuerpo).decode("utf-8")
    return json.loads(cuerpo), True


def _autorizado(evento: dict) -> bool:
    esperado = os.environ.get("NEXA_ML_TOKEN")
    if not esperado:
        return True
    cabeceras = {k.lower(): v for k, v in (evento.get("headers") or {}).items()}
    return hmac.compare_digest(cabeceras.get("x-nexa-token", ""), esperado)


def lambda_handler(evento, contexto):
    try:
        datos, http = _cuerpo(evento if isinstance(evento, dict) else {})
    except (ValueError, UnicodeDecodeError):
        return _respuesta(400, {"error": "JSON inválido"}, True)
    if http and not _autorizado(evento):
        return _respuesta(401, {"error": "No autorizado"}, http)

    viajes = datos.get("viajes")
    if viajes is None and isinstance(datos.get("viaje"), dict):
        viajes = [datos["viaje"]]
    if not isinstance(viajes, list) or not viajes or not all(isinstance(v, dict) for v in viajes):
        return _respuesta(400, {"error": "Se espera {\"viajes\": [ {...}, ... ]}"}, http)
    if len(viajes) > MAX_VIAJES:
        return _respuesta(400, {"error": f"Máximo {MAX_VIAJES} viajes por llamada"}, http)

    try:
        x = [car.calcular(v) for v in viajes]
    except ValueError as e:
        return _respuesta(400, {"error": str(e)}, http)

    probabilidades = _PREDICTOR.probabilidades(x)
    predicciones = []
    for i, (viaje, fila) in enumerate(zip(viajes, probabilidades)):
        item = {"id": str(viaje.get("id") or viaje.get("_id") or i)}
        for k, objetivo in enumerate(car.OBJETIVOS):
            p_no = float(fila[k])
            item[_CLAVES[objetivo]] = {"satisfaccion": "no" if p_no >= _UMBRALES[k] else "si",
                                       "probabilidadNo": round(p_no, 4)}
        predicciones.append(item)
    log.info("predicciones=%d version=%s", len(predicciones), _META["version"])
    return _respuesta(200, {"version": _META["version"], "predicciones": predicciones}, http)
