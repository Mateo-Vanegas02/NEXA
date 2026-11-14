"""Serie de la gráfica de satisfacción: se agrupa según el largo del período y cada punto dice con
cuántas notas se calculó, para que el panel no presente 1 nota como si fuera una tendencia."""
from datetime import date, datetime

from nexa_ml import satisfaccion as sat


def viaje(dia: date, nota_conductor=None, nota_pasajero=None, hora=12):
    return {"fechaFinalizacion": datetime(dia.year, dia.month, dia.day, hora, tzinfo=sat.ZONA),
            "calificacionConductor": nota_conductor, "calificacionPasajero": nota_pasajero}


def test_siete_dias_va_por_dia_con_todos_los_dias_aunque_esten_vacios():
    viajes = [viaje(date(2026, 11, 9), 5), viaje(date(2026, 11, 9), 2), viaje(date(2026, 11, 14), 5, 4)]
    s = sat.serie(viajes, date(2026, 11, 8), date(2026, 11, 14))
    assert s["agrupacion"] == "dia"
    assert s["minimoNotas"] == sat.MIN_NOTAS_PUNTO
    assert [p["clave"] for p in s["puntos"]] == [f"2026-11-{d:02d}" for d in range(8, 15)]
    lunes = s["puntos"][1]
    assert lunes["pasajeroPct"] == 50.0 and lunes["pasajeroNotas"] == 2
    assert lunes["conductorPct"] is None and lunes["conductorNotas"] == 0
    assert s["puntos"][0]["pasajeroPct"] is None and s["puntos"][0]["pasajeroNotas"] == 0
    ultimo = s["puntos"][-1]
    assert ultimo["pasajeroPct"] == 100.0 and ultimo["conductorPct"] == 100.0 and ultimo["conductorNotas"] == 1


def test_treinta_dias_va_por_semana_recortada_al_periodo():
    s = sat.serie([viaje(date(2026, 10, 16), 5), viaje(date(2026, 11, 14), 1)], date(2026, 10, 16), date(2026, 11, 14))
    assert s["agrupacion"] == "semana"
    claves = [p["clave"] for p in s["puntos"]]
    assert claves[0] == "2026-W42" and claves[-1] == "2026-W46" and len(claves) == 5
    # el primer tramo empieza en el día pedido, no en el lunes de esa semana
    assert s["puntos"][0]["desde"] == "2026-10-16" and s["puntos"][0]["hasta"] == "2026-10-18"
    assert s["puntos"][-1]["desde"] == "2026-11-09" and s["puntos"][-1]["hasta"] == "2026-11-14"
    assert s["puntos"][0]["pasajeroPct"] == 100.0 and s["puntos"][-1]["pasajeroPct"] == 0.0


def test_noventa_dias_sigue_por_semana_y_un_ano_va_por_mes():
    assert sat.serie([], date(2026, 8, 17), date(2026, 11, 14))["agrupacion"] == "semana"
    s = sat.serie([viaje(date(2026, 3, 2), 5)], date(2025, 11, 15), date(2026, 11, 14))
    assert s["agrupacion"] == "mes"
    assert s["puntos"][0]["clave"] == "2025-11" and s["puntos"][0]["desde"] == "2025-11-15"
    assert s["puntos"][-1]["clave"] == "2026-11" and len(s["puntos"]) == 13
    marzo = next(p for p in s["puntos"] if p["clave"] == "2026-03")
    assert marzo["pasajeroNotas"] == 1


def test_la_fecha_cuenta_en_hora_de_bogota():
    # 23:30 en Bogotá del día 9 es el 10 en UTC: debe contar en el 9
    noche = {"fechaFinalizacion": "2026-11-10T04:30:00Z", "calificacionConductor": 5}
    s = sat.serie([noche], date(2026, 11, 8), date(2026, 11, 14))
    assert s["puntos"][1]["pasajeroNotas"] == 1


def test_el_resumen_trae_la_serie_del_periodo_y_la_tendencia_con_notas():
    hoy = date(2026, 11, 14)
    r = sat.resumen([viaje(hoy, 5)], [], [viaje(hoy, 5)], date(2026, 11, 8), hoy, "real", 0, None)
    assert r["serie"]["agrupacion"] == "dia" and len(r["serie"]["puntos"]) == 7
    assert r["tendencia"][-1]["pasajeroNotas"] == 1 and r["tendencia"][-1]["conductorNotas"] == 0
