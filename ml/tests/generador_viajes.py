"""Viajes FALSOS solo para las pruebas (pytest). No están en el paquete nexa_ml: ni la entrenadora, ni la Lambda,
ni los comandos pueden entrenar con ellos. No son datos reales de NEXA.

El dinero sigue las reglas reales de `modelo-nexa.properties` (modelo v2.3):
  - tarifa base = max(4.000, redondeo a 100 de 3.000 + 1.200·km)
  - descuento del pasajero = min(1 %·nivel, 5 %) de la tarifa desde el nivel 2, tope 800
  - recargo por espera = 400 por minuto después de 5 min de gracia, máximo 10 min
  - comisión del conductor por nivel 1–5 = 20/19/18/16/15 % de la tarifa base
  - ganancia del conductor = tarifa·(1 − comisión) + recargo + extra (el extra no paga comisión)
  - cobro anticipado: si terminó antes de la mitad del recorrido se cobra la mitad

Las reglas de satisfacción, en cambio, son INVENTADAS solo para comprobar que el modelo aprende algo;
no son hipótesis validadas sobre pasajeros ni conductores:
  - pasajero: menos satisfecho con esperas largas, retrasos y precio alto por km;
  - conductor: menos satisfecho cuando espera mucho al pasajero, recoge lejos y gana poco por minuto.
"""
from __future__ import annotations

from datetime import datetime, timedelta, timezone

import numpy as np

COMISION_POR_NIVEL = (0.20, 0.19, 0.18, 0.16, 0.15)


def _tarifa_base(km: float) -> float:
    return float(max(4000, round((3000 + 1200 * km) / 100) * 100))


def _nota(rng, no_satisfecho: bool) -> float:
    return float(rng.choice([1, 2, 3]) if no_satisfecho else rng.choice([4, 5, 5, 5]))


def generar(n: int = 2000, semilla: int = 7, sin_nota_pasajero: float = 0.15,
            sin_nota_conductor: float = 0.30) -> list[dict]:
    rng = np.random.default_rng(semilla)
    base = datetime(2026, 8, 1, 10, 0, tzinfo=timezone.utc)
    viajes = []
    for i in range(n):
        distancia = round(float(np.clip(rng.gamma(2.2, 2.2), 0.5, 25)), 2)
        estimada = distancia / 22 * 60
        retraso = float(np.clip(rng.lognormal(0, 0.35), 0.5, 4))
        espera_aceptar = float(rng.exponential(2.5))
        recogida_km = float(rng.uniform(0.2, 4))
        llegada = 2 + recogida_km * float(rng.uniform(2, 4))
        espera = float(np.clip(rng.exponential(2.5), 0, 15))
        nivel_pasajero = int(rng.integers(1, 6))
        nivel_conductor = int(rng.integers(1, 6))

        anticipado = rng.random() < 0.05
        fraccion = 0.5 if anticipado and rng.random() < 0.6 else 1.0
        duracion = estimada * retraso * (rng.uniform(0.2, 0.9) if anticipado else 1.0)

        tarifa_base = _tarifa_base(distancia * fraccion)
        descuento = min(0.01 * nivel_pasajero, 0.05) * tarifa_base if nivel_pasajero >= 2 else 0.0
        descuento = round(min(descuento, 800.0))
        extra = float(rng.choice([0, 0, 0, 0, 500, 1000, 2000]))
        recargo = 400 * min(max(espera - 5, 0.0), 5.0)
        deuda = float(rng.choice([1500, 2000, 3000])) if rng.random() < 0.05 else 0.0
        total = tarifa_base - descuento + recargo + extra
        comision = COMISION_POR_NIVEL[nivel_conductor - 1]
        ganancia = round(tarifa_base * (1 - comision) + recargo + extra)
        minutos_trabajo = llegada + espera + duracion

        solicitado = base + timedelta(minutes=float(i * 37 + rng.integers(0, 30)))
        aceptado = solicitado + timedelta(minutes=espera_aceptar)
        llego = aceptado + timedelta(minutes=llegada)
        inicio = llego + timedelta(minutes=espera)
        fin = inicio + timedelta(minutes=duracion)

        logit_p = (-2.6 + 1.4 * (retraso - 1) + 0.25 * max(espera_aceptar - 5, 0)
                   + 0.18 * max(llegada - 8, 0) + 0.0004 * (total / distancia - 1500)
                   + 0.8 * anticipado + rng.normal(0, 0.3))
        logit_c = (-2.4 + 0.35 * max(espera - 3, 0) + 0.5 * max(recogida_km - 2, 0)
                   - 0.004 * (ganancia / minutos_trabajo - 300) - 0.0006 * extra + rng.normal(0, 0.3))
        no_p = rng.random() < 1 / (1 + np.exp(-logit_p))
        no_c = rng.random() < 1 / (1 + np.exp(-logit_c))

        viajes.append({
            "_id": f"sintetico-{i}",
            "estado": "FINALIZADO",
            "solicitadoEn": solicitado.isoformat(),
            "fechaAceptacion": aceptado.isoformat(),
            "fechaLlegada": llego.isoformat(),
            "fechaInicio": inicio.isoformat(),
            "fechaFinalizacion": fin.isoformat(),
            "distanciaKM": round(distancia, 2),
            "duracionEstimadaMin": round(estimada, 1),
            "distanciaRecogidaKm": round(recogida_km, 2),
            "minutosEspera": round(espera, 1),
            "tarifa": total,
            "metodoPago": "efectivo",
            "extraVoluntario": extra,
            "olaAceptacion": int(min(4, 1 + espera_aceptar // 1.2)),
            "nivelPasajero": nivel_pasajero,
            "conductor": {"nivel": nivel_conductor},
            "finalizadoAntesDelDestino": anticipado,
            "fraccionCobrada": fraccion,
            "deudaCobrada": deuda,
            "desglose": {"tarifaBase": tarifa_base, "descuentoNivel": descuento, "recargoEspera": recargo,
                          "extraVoluntario": extra, "totalPasajero": total, "comisionPct": comision,
                          "gananciaConductor": ganancia},
            "calificacionConductor": None if rng.random() < sin_nota_pasajero else _nota(rng, no_p),
            "calificacionPasajero": None if rng.random() < sin_nota_conductor else _nota(rng, no_c),
        })
    return viajes
