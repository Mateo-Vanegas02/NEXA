import numpy as np

from nexa_ml import caracteristicas as car
from nexa_ml import datos, exportar
from generador_viajes import generar


def test_exporta_lo_mismo_que_usa_el_entrenamiento():
    viajes = generar(200, semilla=3)
    registros = exportar.filas(viajes)
    conjunto = datos.construir(viajes)
    assert len(registros) == conjunto.n
    assert list(registros[0]) == list(exportar.COLUMNAS)
    clases = {r[o] for r in registros for o in car.OBJETIVOS}
    assert clases <= {"SI", "NO", "?"} and "?" in clases
    no_pasajero = sum(r["satisfaccion_pasajero"] == "NO" for r in registros)
    assert no_pasajero == conjunto.no_satisfechos(0)


def test_arff_y_csv(tmp_path):
    registros = exportar.filas(generar(30, semilla=5))
    exportar.a_arff(registros, tmp_path / "d.arff")
    exportar.a_csv(registros, tmp_path / "d.csv")
    texto = (tmp_path / "d.arff").read_text(encoding="utf-8")
    assert texto.startswith(f"@relation {exportar.RELACION}")
    assert "@attribute satisfaccion_conductor {SI,NO}" in texto
    assert texto.count("@attribute") == len(exportar.COLUMNAS)
    lineas_csv = (tmp_path / "d.csv").read_text(encoding="utf-8").strip().splitlines()
    assert len(lineas_csv) == len(registros) + 1


def test_sinteticos_siguen_las_reglas_de_tarifa():
    for v in generar(300, semilla=11):
        d, km = v["desglose"], v["distanciaKM"] * v["fraccionCobrada"]
        assert d["tarifaBase"] == max(4000, round((3000 + 1200 * km) / 100) * 100)
        assert d["descuentoNivel"] <= 800
        assert np.isclose(d["totalPasajero"],
                          d["tarifaBase"] - d["descuentoNivel"] + d["recargoEspera"] + d["extraVoluntario"])
        assert d["comisionPct"] == (0.20, 0.19, 0.18, 0.16, 0.15)[v["conductor"]["nivel"] - 1]
