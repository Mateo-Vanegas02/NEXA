"""Variables de entrada y variables objetivo, calculadas desde un viaje (documento `servicios` de MongoDB).

Este módulo NO depende de TensorFlow: lo usan el entrenamiento y la función Lambda, así el viaje se
transforma exactamente igual al entrenar y al predecir.

Objetivo: la SATISFACCIÓN, medida en los dos lados del viaje (un modelo, dos salidas):
  - satisfaccion_pasajero ← `calificacionConductor`: la nota que el pasajero le pone al conductor.
  - satisfaccion_conductor ← `calificacionPasajero`: la nota que el conductor le pone al pasajero.
Cada lado es "si" con 4 o 5 estrellas y "no" con 1 a 3. Si un lado no calificó, ese lado no tiene
etiqueta y no cuenta para el entrenamiento (el otro sí).

Solo se usan datos que existen al terminar el viaje y ANTES de calificar. Nunca una calificación
como entrada: ni la del mismo viaje ni la del otro lado (fuga de información).
"""
from __future__ import annotations

import math
from datetime import datetime, timedelta, timezone
from typing import Any, Mapping
from zoneinfo import ZoneInfo

VERSION_CARACTERISTICAS = 3
ZONA = ZoneInfo("America/Bogota")

#: Orden de las salidas del modelo.
OBJETIVOS: tuple[str, ...] = ("satisfaccion_pasajero", "satisfaccion_conductor")
#: Campo de Mongo de donde sale cada objetivo (quién califica a quién).
CAMPO_OBJETIVO = {
    "satisfaccion_pasajero": "calificacionConductor",   # el pasajero califica al conductor
    "satisfaccion_conductor": "calificacionPasajero",   # el conductor califica al pasajero
}
#: Con esta nota o más, la satisfacción es "si".
NOTA_SATISFECHO = 4.0
SIN_ETIQUETA = -1.0

CARACTERISTICAS: tuple[str, ...] = (
    # Recorrido
    "distancia_km",
    "duracion_min",
    "duracion_estimada_min",
    "razon_duracion",               # duración real / estimada
    "finalizado_antes_del_destino",
    "fraccion_cobrada",
    # Esperas (las sufre el pasajero o el conductor)
    "minutos_hasta_aceptacion",     # pasajero esperando conductor
    "distancia_recogida_km",
    "minutos_hasta_llegada",        # pasajero viendo llegar al conductor
    "minutos_espera",               # conductor esperando al pasajero en el punto
    "ola_aceptacion",
    # Dinero del pasajero
    "tarifa_base",
    "total_pasajero",
    "precio_por_km",
    "descuento_nivel",
    "recargo_espera",
    "extra_voluntario",
    "deuda_cobrada",
    # Dinero del conductor
    "ganancia_conductor",
    "ganancia_por_minuto",          # desde que aceptó hasta que terminó
    # Personas y contexto
    "nivel_pasajero",
    "nivel_conductor",
    "hora_sin",
    "hora_cos",
    "fin_de_semana",
)
# Retiradas en la versión 3 por no aportar información: pago_efectivo (hoy todo es efectivo) y
# comision_pct (sale directamente del nivel del conductor, que ya es una variable).

#: Campos sin los cuales un viaje no describe un viaje real completo. Los viajes anteriores al viaje real
#: en vivo (oct. 2026) no tienen llegada ni esperas y se descartan en vez de rellenarlos con ceros.
CAMPOS_OBLIGATORIOS = ("solicitadoEn", "fechaAceptacion", "fechaLlegada", "fechaInicio", "fechaFinalizacion")
#: Una espera hasta la aceptación mayor que esto indica fechas guardadas con zonas horarias distintas
#: (antes de la corrección del reloj, solicitadoEn quedaba 5 h atrás en servidores en UTC).
MAX_MINUTOS_HASTA_ACEPTACION = 240.0
#: Desfase conocido: en Azure (JVM en UTC, antes del arreglo de zona horaria) `solicitadoEn` se guardaba con el
#: reloj de Bogotá y las demás fechas en UTC, así que queda exactamente 5 h antes. Una espera hasta la
#: aceptación entre 5 h y 5 h + 30 min se corrige restando esas 5 h (nadie espera 5 h a un mototaxi).
DESFASE_ZONA_MIN = 300.0
VENTANA_DESFASE_MIN = 30.0


def solicitado_corregido(viaje: Mapping[str, Any]) -> datetime | None:
    """`solicitadoEn` (o `fechaHora`) corregido del desfase de 5 h de los viajes guardados en Azure."""
    solicitado = a_fecha(viaje.get("solicitadoEn")) or a_fecha(viaje.get("fechaHora"))
    aceptado = a_fecha(viaje.get("fechaAceptacion"))
    if solicitado is not None and aceptado is not None:
        espera = (aceptado - solicitado).total_seconds() / 60.0
        if DESFASE_ZONA_MIN <= espera <= DESFASE_ZONA_MIN + VENTANA_DESFASE_MIN:
            return solicitado + timedelta(minutes=DESFASE_ZONA_MIN)
    return solicitado


def a_fecha(valor: Any) -> datetime | None:
    """Convierte lo que guarde Mongo (datetime) o envíe el backend (texto ISO) a datetime con zona."""
    if valor is None:
        return None
    if isinstance(valor, datetime):
        fecha = valor
    elif isinstance(valor, str):
        texto = valor.strip()
        if not texto:
            return None
        fecha = datetime.fromisoformat(texto.replace("Z", "+00:00"))
    elif isinstance(valor, Mapping) and "$date" in valor:  # exportación JSON extendida de Mongo
        return a_fecha(valor["$date"])
    else:
        raise ValueError(f"Fecha no reconocida: {valor!r}")
    if fecha.tzinfo is None:
        # pymongo devuelve fechas sin zona que están en UTC.
        fecha = fecha.replace(tzinfo=timezone.utc)
    return fecha


def _minutos(desde: datetime | None, hasta: datetime | None, tope: float = 120.0) -> float:
    if desde is None or hasta is None:
        return 0.0
    minutos = (hasta - desde).total_seconds() / 60.0
    return float(min(max(minutos, 0.0), tope))


def _num(valor: Any, defecto: float = 0.0) -> float:
    if valor is None:
        return defecto
    try:
        numero = float(valor)
    except (TypeError, ValueError):
        return defecto
    return numero if math.isfinite(numero) else defecto


def calcular(viaje: Mapping[str, Any]) -> list[float]:
    """Devuelve las variables en el orden de CARACTERISTICAS."""
    desglose = viaje.get("desglose") or {}
    conductor = viaje.get("conductor") or {}

    inicio = a_fecha(viaje.get("fechaInicio"))
    fin = a_fecha(viaje.get("fechaFinalizacion"))
    solicitado = solicitado_corregido(viaje)
    aceptado = a_fecha(viaje.get("fechaAceptacion"))
    llegada = a_fecha(viaje.get("fechaLlegada"))

    distancia = max(_num(viaje.get("distanciaKM")), 0.0)
    duracion = _minutos(inicio, fin, tope=240.0)
    estimada = max(_num(viaje.get("duracionEstimadaMin")), 0.0)
    razon = min(duracion / estimada, 5.0) if estimada >= 1.0 else 1.0

    tarifa = _num(viaje.get("tarifa"))
    tarifa_base = _num(desglose.get("tarifaBase"), tarifa)
    total = _num(desglose.get("totalPasajero"), tarifa)
    ganancia = _num(desglose.get("gananciaConductor"))
    minutos_trabajo = _minutos(aceptado or inicio, fin, tope=300.0)

    referencia = fin or inicio or solicitado
    if referencia is not None:
        local = referencia.astimezone(ZONA)
        hora = local.hour + local.minute / 60.0
        fin_semana = 1.0 if local.weekday() >= 5 else 0.0
    else:
        hora, fin_semana = 12.0, 0.0
    angulo = 2.0 * math.pi * hora / 24.0

    valores = {
        "distancia_km": distancia,
        "duracion_min": duracion,
        "duracion_estimada_min": estimada,
        "razon_duracion": razon,
        "finalizado_antes_del_destino": 1.0 if viaje.get("finalizadoAntesDelDestino") else 0.0,
        "fraccion_cobrada": _num(viaje.get("fraccionCobrada"), 1.0),
        "minutos_hasta_aceptacion": _minutos(solicitado, aceptado),
        "distancia_recogida_km": max(_num(viaje.get("distanciaRecogidaKm")), 0.0),
        "minutos_hasta_llegada": _minutos(aceptado, llegada),
        "minutos_espera": min(max(_num(viaje.get("minutosEspera")), 0.0), 60.0),
        "ola_aceptacion": _num(viaje.get("olaAceptacion")),
        "tarifa_base": tarifa_base,
        "total_pasajero": total,
        "precio_por_km": total / max(distancia, 0.5),
        "descuento_nivel": _num(desglose.get("descuentoNivel")),
        "recargo_espera": _num(desglose.get("recargoEspera")),
        "extra_voluntario": _num(desglose.get("extraVoluntario"), _num(viaje.get("extraVoluntario"))),
        "deuda_cobrada": _num(viaje.get("deudaCobrada")),
        "ganancia_conductor": ganancia,
        "ganancia_por_minuto": ganancia / minutos_trabajo if minutos_trabajo >= 1.0 else 0.0,
        "nivel_pasajero": _num(viaje.get("nivelPasajero"), 1.0),
        "nivel_conductor": _num(conductor.get("nivel"), 1.0),
        "hora_sin": math.sin(angulo),
        "hora_cos": math.cos(angulo),
        "fin_de_semana": fin_semana,
    }
    return [valores[nombre] for nombre in CARACTERISTICAS]


def motivo_descarte(viaje: Mapping[str, Any]) -> str | None:
    """Por qué un viaje no sirve para entrenar ni exportar, o None si sirve."""
    if all(v == SIN_ETIQUETA for v in etiquetas(viaje)):
        return "sin calificaciones"
    return motivo_incompleto(viaje)


def motivo_incompleto(viaje: Mapping[str, Any]) -> str | None:
    """Por qué no se pueden calcular las variables de un viaje, o None si se pueden.

    Es el mismo filtro del entrenamiento sin mirar las calificaciones: lo usa también la predicción de
    riesgo, para que un viaje sin fechas o sin desglose no reciba variables rellenadas con cero.
    """
    try:
        fechas = {campo: a_fecha(viaje.get(campo)) for campo in CAMPOS_OBLIGATORIOS}
    except ValueError:
        return "fechas inválidas"
    faltan = [campo for campo, fecha in fechas.items() if fecha is None]
    if faltan:
        return "incompleto"
    desglose = viaje.get("desglose") or {}
    if desglose.get("totalPasajero") is None or desglose.get("gananciaConductor") is None:
        return "incompleto"
    fechas["solicitadoEn"] = solicitado_corregido(viaje)
    orden = [fechas[c] for c in CAMPOS_OBLIGATORIOS]
    espera_aceptacion = (fechas["fechaAceptacion"] - fechas["solicitadoEn"]).total_seconds() / 60.0
    if any(b < a for a, b in zip(orden, orden[1:])) or espera_aceptacion > MAX_MINUTOS_HASTA_ACEPTACION:
        return "fechas inconsistentes"
    return None


def etiquetas(viaje: Mapping[str, Any]) -> list[float]:
    """Una etiqueta por objetivo: 1 = NO satisfecho, 0 = satisfecho, -1 = ese lado no calificó.

    El modelo aprende la probabilidad de "no": es la clase rara (casi todo es 4–5 estrellas) y la
    que interesa detectar.
    """
    resultado = []
    for objetivo in OBJETIVOS:
        nota = viaje.get(CAMPO_OBJETIVO[objetivo])
        if nota is None:
            resultado.append(SIN_ETIQUETA)
        else:
            resultado.append(1.0 if float(nota) < NOTA_SATISFECHO else 0.0)
    return resultado
