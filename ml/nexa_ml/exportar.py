"""Exporta el dataset de minería tal como lo ve el modelo: una fila por viaje, las 25 variables de
entrada y las dos clases (SI / NO / ? cuando ese lado no calificó). Sirve para revisar los datos en
Excel o WEKA y para el entregable académico.

Ejemplos:
    python -m nexa_ml.exportar --mongo-uri "$NEXA_MONGO_URI" --csv dataset.csv --arff dataset.arff
    python -m nexa_ml.exportar --json viajes.json --csv dataset.csv
"""
from __future__ import annotations

import argparse
import csv
import os
from pathlib import Path
from typing import Any, Iterable, Mapping

from . import caracteristicas as car
from . import datos

RELACION = "nexa_satisfaccion_viajes_v2"
ENTEROS = {"ola_aceptacion", "nivel_pasajero", "nivel_conductor", "finalizado_antes_del_destino", "fin_de_semana"}
DECIMALES = {"hora_sin": 4, "hora_cos": 4, "fraccion_cobrada": 2, "razon_duracion": 3}
COLUMNAS = ("id_viaje", "fecha_finalizacion", *car.CARACTERISTICAS, *car.OBJETIVOS)


def _clase(valor: float) -> str:
    return "?" if valor == car.SIN_ETIQUETA else ("NO" if valor == 1.0 else "SI")


def filas(viajes: Iterable[Mapping[str, Any]]) -> list[dict]:
    """Mismo filtro y mismo cálculo que el entrenamiento (datos.construir), ordenado por fecha."""
    resultado = []
    for i, viaje in enumerate(viajes):
        if car.motivo_descarte(viaje):
            continue
        y = car.etiquetas(viaje)
        fin = car.a_fecha(viaje.get("fechaFinalizacion"))
        x = car.calcular(viaje)
        fila: dict[str, Any] = {
            "id_viaje": str(viaje.get("_id") or viaje.get("id") or i),
            "fecha_finalizacion": fin.astimezone(car.ZONA).replace(tzinfo=None),
        }
        for nombre, valor in zip(car.CARACTERISTICAS, x):
            fila[nombre] = int(round(valor)) if nombre in ENTEROS else round(valor, DECIMALES.get(nombre, 2))
        for nombre, valor in zip(car.OBJETIVOS, y):
            fila[nombre] = _clase(valor)
        resultado.append(fila)
    resultado.sort(key=lambda f: f["fecha_finalizacion"])
    return resultado


def a_csv(registros: list[dict], ruta: Path) -> None:
    with open(ruta, "w", newline="", encoding="utf-8") as f:
        w = csv.DictWriter(f, fieldnames=COLUMNAS)
        w.writeheader()
        for r in registros:
            w.writerow({**r, "fecha_finalizacion": r["fecha_finalizacion"].strftime("%Y-%m-%d %H:%M:%S")})


def declaracion_arff(nombre: str) -> str:
    if nombre == "id_viaje":
        return f"@attribute {nombre} string"
    if nombre == "fecha_finalizacion":
        return f'@attribute {nombre} date "yyyy-MM-dd HH:mm:ss"'
    if nombre in car.OBJETIVOS:
        return f"@attribute {nombre} {{SI,NO}}"
    return f"@attribute {nombre} {'integer' if nombre in ENTEROS else 'numeric'}"


def a_arff(registros: list[dict], ruta: Path) -> None:
    lineas = [f"@relation {RELACION}", ""] + [declaracion_arff(c) for c in COLUMNAS] + ["", "@data"]
    for r in registros:
        valores = []
        for c in COLUMNAS:
            v = r[c]
            if c == "id_viaje":
                v = f"'{v}'"
            elif c == "fecha_finalizacion":
                v = f"\"{v.strftime('%Y-%m-%d %H:%M:%S')}\""
            valores.append(str(v))
        lineas.append(",".join(valores))
    Path(ruta).write_text("\n".join(lineas) + "\n", encoding="utf-8")


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    fuente = parser.add_mutually_exclusive_group(required=True)
    fuente.add_argument("--mongo-uri")
    fuente.add_argument("--json")
    parser.add_argument("--base", default=os.environ.get("NEXA_MONGO_BASE", "nexa"))
    parser.add_argument("--csv", type=Path)
    parser.add_argument("--arff", type=Path)
    args = parser.parse_args(argv)

    if args.json:
        viajes = datos.desde_json(args.json)
    else:
        viajes = datos.desde_mongo(args.mongo_uri, args.base)
    registros = filas(viajes)
    if args.csv:
        a_csv(registros, args.csv)
    if args.arff:
        a_arff(registros, args.arff)
    print(f"{len(registros)} viajes exportados")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
