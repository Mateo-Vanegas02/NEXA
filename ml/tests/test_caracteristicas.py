import math

from nexa_ml import caracteristicas as car

VIAJE = {
    "solicitadoEn": "2026-11-06T22:00:00Z",       # 17:00 en Bogotá, viernes
    "fechaAceptacion": "2026-11-06T22:03:00Z",
    "fechaLlegada": "2026-11-06T22:10:00Z",
    "fechaInicio": "2026-11-06T22:12:00Z",
    "fechaFinalizacion": "2026-11-06T22:32:00Z",
    "distanciaKM": 5.0,
    "duracionEstimadaMin": 16.0,
    "minutosEspera": 2.0,
    "tarifa": 9000,
    "deudaCobrada": 800,
    "desglose": {"tarifaBase": 9000, "descuentoNivel": 270, "recargoEspera": 0, "extraVoluntario": 1000,
                 "totalPasajero": 9730, "comisionPct": 0.19, "gananciaConductor": 8290},
    "nivelPasajero": 3,
    "conductor": {"nivel": 2},
    "metodoPago": "Efectivo",
    "calificacionConductor": 5,   # nota del pasajero al conductor
    "calificacionPasajero": 2,    # nota del conductor al pasajero
}


def valores(viaje):
    return dict(zip(car.CARACTERISTICAS, car.calcular(viaje)))


def test_calcula_todas_las_variables_en_orden():
    v = valores(VIAJE)
    assert len(car.calcular(VIAJE)) == len(car.CARACTERISTICAS)
    assert v["duracion_min"] == 20
    assert v["razon_duracion"] == 20 / 16
    assert v["minutos_hasta_aceptacion"] == 3
    assert v["minutos_hasta_llegada"] == 7
    assert v["total_pasajero"] == 9730
    assert v["precio_por_km"] == 9730 / 5
    assert v["extra_voluntario"] == 1000
    assert v["deuda_cobrada"] == 800
    assert v["ganancia_conductor"] == 8290
    assert v["ganancia_por_minuto"] == 8290 / 29   # de aceptar (22:03) a terminar (22:32)
    assert v["fraccion_cobrada"] == 1
    assert v["nivel_conductor"] == 2
    assert "pago_efectivo" not in v and "comision_pct" not in v  # retiradas en la versión 3


def test_la_hora_se_toma_en_bogota():
    v = valores(VIAJE)
    hora = 17 + 32 / 60
    assert math.isclose(v["hora_sin"], math.sin(2 * math.pi * hora / 24), abs_tol=1e-9)
    assert v["fin_de_semana"] == 0  # viernes


def test_datos_faltantes_no_rompen():
    v = valores({"distanciaKM": 2, "fechaFinalizacion": "2026-11-07T15:00:00Z"})
    assert v["duracion_min"] == 0 and v["minutos_hasta_llegada"] == 0 and v["ganancia_por_minuto"] == 0
    assert v["nivel_pasajero"] == 1 and v["nivel_conductor"] == 1


def test_una_etiqueta_por_lado_del_viaje():
    # Pasajero puso 5 (sí satisfecho); conductor puso 2 (no satisfecho).
    assert car.etiquetas(VIAJE) == [0.0, 1.0]
    assert car.etiquetas({**VIAJE, "calificacionConductor": 3.5}) == [1.0, 1.0]
    assert car.etiquetas({**VIAJE, "calificacionConductor": 4}) == [0.0, 1.0]


def test_lado_sin_nota_queda_sin_etiqueta():
    assert car.etiquetas({**VIAJE, "calificacionPasajero": None}) == [0.0, car.SIN_ETIQUETA]
    assert car.etiquetas({}) == [car.SIN_ETIQUETA, car.SIN_ETIQUETA]


def test_ninguna_variable_usa_calificaciones():
    assert not any("calific" in nombre for nombre in car.CARACTERISTICAS)
    otro = {**VIAJE, "calificacionConductor": 1, "calificacionPasajero": 5}
    assert car.calcular(VIAJE) == car.calcular(otro)


def test_acepta_fechas_de_mongoexport():
    viaje = {**VIAJE, "fechaFinalizacion": {"$date": "2026-11-06T22:32:00Z"}}
    assert car.calcular(viaje) == car.calcular(VIAJE)


def test_viaje_completo_se_acepta():
    assert car.motivo_descarte(VIAJE) is None


def test_viajes_antiguos_sin_llegada_se_descartan():
    antiguo = {k: v for k, v in VIAJE.items() if k != "fechaLlegada"}
    assert car.motivo_descarte(antiguo) == "incompleto"
    sin_desglose = {**VIAJE, "desglose": {}}
    assert car.motivo_descarte(sin_desglose) == "incompleto"
    assert car.motivo_descarte({**VIAJE, "calificacionConductor": None, "calificacionPasajero": None}) \
        == "sin calificaciones"


def test_fechas_de_dos_zonas_horarias_se_corrigen_o_descartan():
    # Antes de corregir el reloj, solicitadoEn quedaba 5 h atrás en un servidor en UTC: se corrige.
    desfasado = {**VIAJE, "solicitadoEn": "2026-11-06T17:00:00Z"}
    assert car.motivo_descarte(desfasado) is None
    assert car.calcular(desfasado) == car.calcular(VIAJE)
    # Un desfase distinto al conocido sigue descartándose.
    raro = {**VIAJE, "solicitadoEn": "2026-11-06T15:00:00Z"}
    assert car.motivo_descarte(raro) == "fechas inconsistentes"
    al_reves = {**VIAJE, "fechaInicio": "2026-11-06T22:40:00Z"}  # inicia después de terminar
    assert car.motivo_descarte(al_reves) == "fechas inconsistentes"


def test_corrige_el_desfase_de_5_horas_de_azure():
    from datetime import datetime, timedelta, timezone

    from nexa_ml import caracteristicas as car

    aceptado = datetime(2026, 11, 9, 20, 0, tzinfo=timezone.utc)
    base = {"fechaAceptacion": aceptado, "fechaLlegada": aceptado + timedelta(minutes=2),
            "fechaInicio": aceptado + timedelta(minutes=4), "fechaFinalizacion": aceptado + timedelta(minutes=10),
            "desglose": {"totalPasajero": 9000, "gananciaConductor": 7000}, "calificacionConductor": 5}
    con_desfase = {**base, "solicitadoEn": aceptado - timedelta(minutes=300, seconds=40)}
    valores = dict(zip(car.CARACTERISTICAS, car.calcular(con_desfase)))
    assert abs(valores["minutos_hasta_aceptacion"] - 40 / 60) < 1e-6
    assert car.motivo_descarte(con_desfase) is None
    # Una espera de 4 a 5 h no es el desfase conocido: se sigue descartando.
    raro = {**base, "solicitadoEn": aceptado - timedelta(minutes=260)}
    assert car.motivo_descarte(raro) == "fechas inconsistentes"


def test_viaje_sin_calificar_completo_sirve_para_predecir():
    sin_notas = {**VIAJE, "calificacionConductor": None, "calificacionPasajero": None}
    assert car.motivo_descarte(sin_notas) == "sin calificaciones"
    assert car.motivo_incompleto(sin_notas) is None
    assert car.motivo_incompleto({k: v for k, v in sin_notas.items() if k != "fechaLlegada"}) == "incompleto"
    assert car.motivo_incompleto({**sin_notas, "desglose": {}}) == "incompleto"
