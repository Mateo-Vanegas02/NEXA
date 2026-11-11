"""Lectura de viajes para entrenar: directo de MongoDB o desde un archivo JSON exportado."""
from __future__ import annotations

import json
from collections import Counter
from dataclasses import dataclass, field
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Iterable, Mapping

import numpy as np

from . import caracteristicas as car

CAMPOS = (
    "fechaHora", "solicitadoEn", "fechaAceptacion", "fechaLlegada", "fechaInicio", "fechaFinalizacion",
    "distanciaKM", "duracionEstimadaMin", "distanciaRecogidaKm", "minutosEspera", "tarifa", "metodoPago",
    "extraVoluntario", "olaAceptacion", "nivelPasajero", "finalizadoAntesDelDestino", "fraccionCobrada",
    "deudaCobrada", "conductor.nivel", "desglose", "calificacionConductor", "calificacionPasajero",
)


@dataclass
class Conjunto:
    x: np.ndarray            # (n, len(CARACTERISTICAS)) float32
    y: np.ndarray            # (n, len(OBJETIVOS)) float32: 1 = no satisfecho, 0 = satisfecho, -1 = sin nota
    fechas: np.ndarray       # (n,) datetime64 para dividir por tiempo
    descartados: int         # viajes que no sirven (ver `motivos`)
    motivos: dict = field(default_factory=dict)  # motivo -> cantidad (sin calificaciones, incompleto, ...)

    @property
    def n(self) -> int:
        return int(self.y.shape[0])

    def etiquetados(self, k: int) -> int:
        return int((self.y[:, k] >= 0).sum())

    def no_satisfechos(self, k: int) -> int:
        return int((self.y[:, k] == 1).sum())


def construir(viajes: Iterable[Mapping[str, Any]]) -> Conjunto:
    filas, etiquetas, fechas, motivos = [], [], [], Counter()
    for viaje in viajes:
        motivo = car.motivo_descarte(viaje)
        if motivo:
            motivos[motivo] += 1
            continue
        fin = car.a_fecha(viaje.get("fechaFinalizacion"))
        filas.append(car.calcular(viaje))
        etiquetas.append(car.etiquetas(viaje))
        fechas.append(np.datetime64(fin.astimezone(timezone.utc).replace(tzinfo=None), "s"))
    return Conjunto(
        x=np.asarray(filas, dtype=np.float32).reshape(-1, len(car.CARACTERISTICAS)),
        y=np.asarray(etiquetas, dtype=np.float32).reshape(-1, len(car.OBJETIVOS)),
        fechas=np.asarray(fechas, dtype="datetime64[s]"),
        descartados=sum(motivos.values()),
        motivos=dict(motivos),
    )


def desde_json(ruta: str | Path) -> list[dict]:
    """Lee un arreglo JSON o JSON por líneas (salida de `mongoexport`)."""
    texto = Path(ruta).read_text(encoding="utf-8").strip()
    if texto.startswith("["):
        return json.loads(texto)
    return [json.loads(linea) for linea in texto.splitlines() if linea.strip()]


def desde_mongo(uri: str, base: str, desde: datetime | None = None, limite: int = 200_000) -> list[dict]:
    """Viajes FINALIZADOS con al menos una calificación (del pasajero o del conductor).

    Por defecto solo los del modelo de tarifas v2.2 (marcador `niveles-v2.2` en `migraciones`),
    igual que el servicio J48: los viajes anteriores tenían otras tarifas.
    """
    from pymongo import MongoClient  # import tardío: la Lambda no necesita pymongo

    with MongoClient(uri, serverSelectionTimeoutMS=10_000) as cliente:
        db = cliente[base]
        if desde is None:
            marcador = db["migraciones"].find_one({"_id": "niveles-v2.2"})
            if marcador and marcador.get("fecha"):
                desde = car.a_fecha(marcador["fecha"])
        filtro: dict[str, Any] = {
            "estado": "FINALIZADO",
            "fechaLlegada": {"$ne": None},  # solo viajes del viaje real en vivo (con llegada y esperas)
            "$or": [{campo: {"$ne": None}} for campo in car.CAMPO_OBJETIVO.values()],
        }
        if desde is not None:
            filtro["fechaFinalizacion"] = {"$gte": desde}
        proyeccion = {campo: 1 for campo in CAMPOS}
        cursor = db["servicios"].find(filtro, proyeccion).sort("fechaFinalizacion", 1).limit(limite)
        return list(cursor)
