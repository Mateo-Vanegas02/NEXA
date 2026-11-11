"""Entrena, evalúa y exporta el modelo de satisfacción (pasajero y conductor).

Ejemplos:
    python -m nexa_ml.entrenar --mongo-uri "$NEXA_MONGO_URI" --base nexa --salida artefactos/
    python -m nexa_ml.entrenar --json viajes.json --salida artefactos/
"""
from __future__ import annotations

import argparse
import json
import os
import sys
from datetime import datetime, timezone
from pathlib import Path

import numpy as np

from . import caracteristicas as car
from . import datos, metricas

#: Por objetivo. Por debajo de esto la evaluación no dice nada confiable (ni para J48 ni para una red).
MINIMO_NOTAS = 300
MINIMO_NO_SATISFECHOS = 30


class DatosInsuficientes(Exception):
    pass


def dividir_por_tiempo(conjunto: datos.Conjunto, val: float = 0.15, prueba: float = 0.15):
    """Entrena con el pasado y evalúa con viajes posteriores, como ocurrirá en producción."""
    orden = np.argsort(conjunto.fechas, kind="mergesort")
    n = len(orden)
    cortes = int(n * (1 - val - prueba)), int(n * (1 - prueba))
    partes = orden[: cortes[0]], orden[cortes[0]: cortes[1]], orden[cortes[1]:]
    return [(conjunto.x[i], conjunto.y[i]) for i in partes]


def _revisar_datos(conjunto: datos.Conjunto) -> list[str]:
    problemas = []
    for k, objetivo in enumerate(car.OBJETIVOS):
        notas, no = conjunto.etiquetados(k), conjunto.no_satisfechos(k)
        if notas < MINIMO_NOTAS or no < MINIMO_NO_SATISFECHOS:
            problemas.append(f"{objetivo}: {notas} notas ({no} 'no'); se necesitan {MINIMO_NOTAS} y "
                             f"{MINIMO_NO_SATISFECHOS} 'no'")
    return problemas


def _evaluar(y: np.ndarray, p: np.ndarray, umbrales: list[float] | None = None) -> tuple[dict, list[float]]:
    """Métricas por objetivo usando solo los viajes donde ese lado calificó."""
    salida, elegidos = {}, []
    for k, objetivo in enumerate(car.OBJETIVOS):
        m = y[:, k] >= 0
        yk, pk = y[m, k], p[m, k]
        if len(yk) == 0 or yk.min() == yk.max():
            salida[objetivo] = {"evaluable": False, "notas": int(len(yk))}
            elegidos.append(0.5 if umbrales is None else umbrales[k])
            continue
        umbral = metricas.mejor_umbral(yk, pk) if umbrales is None else umbrales[k]
        elegidos.append(umbral)
        salida[objetivo] = {"evaluable": True, "notas": int(len(yk)), **metricas.resumen(yk, pk, umbral)}
    return salida, elegidos


def ejecutar(viajes: list[dict], salida: Path, permitir_pocos_datos: bool = False, fuente: str = "",
             callbacks: dict | None = None, extra: dict | None = None) -> dict:
    """Entrena la red y la regresión logística de referencia y deja en `salida` el .keras, el .tflite y
    `metadatos.json`. `callbacks`: por nombre de modelo, callbacks de Keras extra (progreso, cancelar).
    `extra`: si se pasa, se llena con la red, el conjunto y la partición (para calcular los factores)."""
    from . import modelo as mod  # TensorFlow solo se carga al entrenar

    conjunto = datos.construir(viajes)
    problemas = _revisar_datos(conjunto)
    if problemas and not permitir_pocos_datos:
        raise DatosInsuficientes("; ".join(problemas))

    (x_ent, y_ent), (x_val, y_val), (x_pru, y_pru) = dividir_por_tiempo(conjunto)

    resultados = {}
    modelos = {"red_neuronal": mod.red_neuronal(x_ent, y_ent),
               "regresion_logistica": mod.regresion_logistica(x_ent, y_ent)}
    umbrales_red = None
    for nombre, m in modelos.items():
        historia = mod.entrenar(m, x_ent, y_ent, x_val, y_val, callbacks=(callbacks or {}).get(nombre))
        validacion, umbrales = _evaluar(y_val, m.predict(x_val, verbose=0))
        prueba, _ = _evaluar(y_pru, m.predict(x_pru, verbose=0), umbrales)
        resultados[nombre] = {"epocas": len(historia.history["loss"]), "validacion": validacion, "prueba": prueba}
        if nombre == "red_neuronal":
            umbrales_red = umbrales

    supera_bases = {}
    for objetivo in car.OBJETIVOS:
        red = resultados["red_neuronal"]["prueba"][objetivo]
        log = resultados["regresion_logistica"]["prueba"][objetivo]
        supera_bases[objetivo] = bool(
            red.get("evaluable") and log.get("evaluable")
            and red["pr_auc"] > log["pr_auc"] + 0.01 and red["pr_auc"] > 1.5 * red["prevalencia"]
        )

    red = modelos["red_neuronal"]
    salida.mkdir(parents=True, exist_ok=True)
    red.save(salida / "modelo.keras")
    (salida / "modelo.tflite").write_bytes(mod.a_tflite(red))
    diferencia = _comparar_tflite(salida / "modelo.tflite", red, x_pru)

    metadatos = {
        "nombre": "nexa_satisfaccion",
        "version": datetime.now(timezone.utc).strftime("%Y%m%d%H%M%S"),
        "version_caracteristicas": car.VERSION_CARACTERISTICAS,
        "caracteristicas": list(car.CARACTERISTICAS),
        "objetivos": {o: {"campo": car.CAMPO_OBJETIVO[o], "si": f"nota >= {car.NOTA_SATISFECHO:g}"}
                      for o in car.OBJETIVOS},
        "salida": "probabilidad de 'no' satisfecho, una columna por objetivo en el orden de 'objetivos'",
        "umbrales": dict(zip(car.OBJETIVOS, [round(u, 4) for u in umbrales_red])),
        "fuente": fuente,
        "datos": {
            "viajes": conjunto.n,
            "descartados": conjunto.descartados,
            "motivos_descarte": conjunto.motivos,
            "desde": str(conjunto.fechas.min()) if conjunto.n else None,
            "hasta": str(conjunto.fechas.max()) if conjunto.n else None,
            "por_objetivo": {o: {"notas": conjunto.etiquetados(k), "no": conjunto.no_satisfechos(k)}
                             for k, o in enumerate(car.OBJETIVOS)},
            "entrenamiento": int(len(y_ent)), "validacion": int(len(y_val)), "prueba": int(len(y_pru)),
            "advertencias": problemas,
        },
        "resultados": resultados,
        "supera_bases": supera_bases,
        "diferencia_max_tflite_vs_keras": diferencia,
    }
    (salida / "metadatos.json").write_text(json.dumps(metadatos, indent=2, ensure_ascii=False), encoding="utf-8")
    if extra is not None:
        extra.update(red=red, conjunto=conjunto,
                     particion={"entrenamiento": (x_ent, y_ent), "validacion": (x_val, y_val), "prueba": (x_pru, y_pru)})
    return metadatos


def _comparar_tflite(ruta: Path, red, x: np.ndarray) -> float:
    """El .tflite debe dar lo mismo que Keras; si no, no se publica."""
    from .inferencia import Predictor

    if len(x) == 0:
        return 0.0
    diferencia = float(np.max(np.abs(Predictor(ruta).probabilidades(x) - red.predict(x, verbose=0))))
    if diferencia > 1e-4:
        raise RuntimeError(f"El modelo TFLite difiere de Keras en {diferencia:.2e}")
    return diferencia
    return round(diferencia, 8)


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    fuente = parser.add_mutually_exclusive_group(required=True)
    fuente.add_argument("--mongo-uri", default=None, help="URI de MongoDB (mejor por la variable NEXA_MONGO_URI)")
    fuente.add_argument("--json", help="Archivo exportado con mongoexport (arreglo o JSON por líneas)")
    parser.add_argument("--base", default=os.environ.get("NEXA_MONGO_BASE", "nexa"))
    parser.add_argument("--salida", type=Path, default=Path("artefactos"))
    parser.add_argument("--permitir-pocos-datos", action="store_true")
    args = parser.parse_args(argv)

    if args.json:
        viajes, origen = datos.desde_json(args.json), f"json:{Path(args.json).name}"
    else:
        viajes, origen = datos.desde_mongo(args.mongo_uri, args.base), f"mongo:{args.base}"

    try:
        meta = ejecutar(viajes, args.salida, args.permitir_pocos_datos, origen)
    except DatosInsuficientes as e:
        print(f"No se entrena: {e}", file=sys.stderr)
        return 2
    print(f"Viajes: {meta['datos']['viajes']}  ·  {meta['datos']['por_objetivo']}")
    for objetivo in car.OBJETIVOS:
        print(f"\n{objetivo}  (¿la red supera las bases?: {meta['supera_bases'][objetivo]})")
        for nombre in ("red_neuronal", "regresion_logistica"):
            r = meta["resultados"][nombre]["prueba"][objetivo]
            if r.get("evaluable"):
                print(f"  {nombre:20s} PR-AUC {r['pr_auc']}  ROC-AUC {r['roc_auc']}  recall 'no' {r['recall']}"
                      f"  prevalencia {r['prevalencia']}")
            else:
                print(f"  {nombre:20s} no evaluable ({r['notas']} notas en prueba)")
    for aviso in meta["datos"]["advertencias"]:
        print(f"AVISO (pocos datos): {aviso}")
    print(f"\nArtefactos en {args.salida}/ (modelo.keras, modelo.tflite, metadatos.json)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
