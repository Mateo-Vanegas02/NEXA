"""Trabajo de entrenamiento (corre en ECS Fargate): solo con viajes reales de Atlas.

Lo lanza la Lambda mediadora (`POST /entrenamientos` o la programación) con el id del registro de DynamoDB:

    python -m nexa_ml.entrenadora --id e-20261111-1230 [--publicar-siempre]

Pasos (los ve la app en la pantalla "Entrenando"):
  1. exportar  — lee los viajes finalizados y calificados de Atlas (usuario de solo lectura).
  2. entrenar  — red neuronal y regresión logística de referencia (TensorFlow); se puede cancelar.
  3. comparar  — métricas, importancia por permutación, curvas por tramos y medias para los motivos.
  4. publicar  — sube `modelos/vN/` a S3 y, si corresponde, mueve `modelos/actual.json` a esa versión.

Nunca usa datos sintéticos: sin los mínimos de calificaciones termina en DATOS_INSUFICIENTES.
"""
from __future__ import annotations

import argparse
import json
import logging
import os
import sys
import tempfile
import time
from datetime import datetime, timedelta, timezone
from pathlib import Path
from typing import Any

import numpy as np

from . import caracteristicas as car
from . import datos, metricas
from . import satisfaccion as sat

log = logging.getLogger("entrenadora")

#: Etiqueta larga (lista de importancia) y corta (chip de la curva) de cada variable.
ETIQUETAS: dict[str, tuple[str, str]] = {
    "distancia_km": ("Distancia del viaje", "Distancia"),
    "duracion_min": ("Duración del viaje", "Duración"),
    "duracion_estimada_min": ("Duración estimada al cotizar", "Duración estimada"),
    "razon_duracion": ("Duración real frente a la estimada", "Real vs. estimada"),
    "finalizado_antes_del_destino": ("Viaje terminado antes del destino", "Terminó antes"),
    "fraccion_cobrada": ("Parte de la tarifa cobrada", "Fracción cobrada"),
    "minutos_hasta_aceptacion": ("Espera hasta que un conductor acepta", "Espera a aceptar"),
    "distancia_recogida_km": ("Distancia del conductor a la recogida", "Distancia a recoger"),
    "minutos_hasta_llegada": ("Tiempo del conductor en llegar", "Llegada del conductor"),
    "minutos_espera": ("Espera del conductor en el punto", "Espera en el punto"),
    "ola_aceptacion": ("Ola del despacho en que se aceptó", "Ola de despacho"),
    "tarifa_base": ("Tarifa del viaje", "Tarifa"),
    "total_pasajero": ("Total que pagó el pasajero", "Total pagado"),
    "precio_por_km": ("Precio por kilómetro", "Precio por km"),
    "descuento_nivel": ("Descuento por nivel", "Descuento"),
    "recargo_espera": ("Recargo por espera", "Recargo de espera"),
    "extra_voluntario": ("Extra voluntario del pasajero", "Extra voluntario"),
    "deuda_cobrada": ("Deuda cobrada en el viaje", "Deuda cobrada"),
    "ganancia_conductor": ("Ganancia del conductor", "Ganancia"),
    "ganancia_por_minuto": ("Ganancia del conductor por minuto", "Ganancia por minuto"),
    "nivel_pasajero": ("Nivel del pasajero", "Nivel pasajero"),
    "nivel_conductor": ("Nivel del conductor", "Nivel conductor"),
    "hora_sin": ("Hora del día", "Hora"),
    "hora_cos": ("Hora del día (fase)", "Hora (fase)"),
    "fin_de_semana": ("Viaje en fin de semana", "Fin de semana"),
}
_UNIDAD = {"distancia_km": " km", "distancia_recogida_km": " km", "duracion_min": " min",
           "duracion_estimada_min": " min", "minutos_hasta_aceptacion": " min", "minutos_hasta_llegada": " min",
           "minutos_espera": " min", "ganancia_por_minuto": " $/min"}
_DINERO = {"tarifa_base", "total_pasajero", "precio_por_km", "descuento_nivel", "recargo_espera",
           "extra_voluntario", "deuda_cobrada", "ganancia_conductor"}
_BINARIAS = {"finalizado_antes_del_destino", "fin_de_semana"}
_SIN_CURVA = {"hora_sin", "hora_cos"}  # no tienen tramos legibles

EPOCAS_MAX = 300
MAX_IMPORTANCIA = 5


class Cancelado(Exception):
    pass


# --------------------------------------------------------------------------- factores
def _pr_auc_lado(y: np.ndarray, p: np.ndarray, k: int) -> float | None:
    m = y[:, k] >= 0
    if m.sum() < 10 or y[m, k].min() == y[m, k].max():
        return None
    return metricas.pr_auc(y[m, k], p[m, k])


def importancia_permutacion(predecir, x: np.ndarray, y: np.ndarray, k: int, repeticiones: int = 3,
                            semilla: int = 7) -> dict[str, float]:
    """Cuánto empeora el PR-AUC del lado k al desordenar cada variable (0 si no empeora)."""
    base = _pr_auc_lado(y, predecir(x), k)
    if base is None:
        return {}
    rng = np.random.default_rng(semilla)
    caidas = {}
    for j, nombre in enumerate(car.CARACTERISTICAS):
        total = 0.0
        for _ in range(repeticiones):
            xp = x.copy()
            xp[:, j] = rng.permutation(xp[:, j])
            total += base - (_pr_auc_lado(y, predecir(xp), k) or base)
        caidas[nombre] = max(0.0, total / repeticiones)
    return caidas


def _fmt(variable: str, v: float) -> str:
    if variable in _DINERO:
        return f"${v:,.0f}".replace(",", ".")
    if variable in ("nivel_pasajero", "nivel_conductor", "ola_aceptacion"):
        return f"{v:.0f}"
    if variable in ("razon_duracion", "fraccion_cobrada"):
        return f"{v:.2f}".replace(".", ",")
    texto = f"{v:.1f}".rstrip("0").rstrip(".").replace(".", ",")
    return texto + _UNIDAD.get(variable, "")


def curva(variable: str, x: np.ndarray, y: np.ndarray, k: int) -> dict | None:
    """Satisfacción observada por tramos de una variable (solo viajes donde ese lado calificó)."""
    j = car.CARACTERISTICAS.index(variable)
    m = y[:, k] >= 0
    valores, no = x[m, j], y[m, k]
    if len(valores) < 20:
        return None
    if variable in _BINARIAS:
        grupos = [("No", valores < 0.5), ("Sí", valores >= 0.5)]
    else:
        cortes = np.unique(np.quantile(valores, [0, 0.25, 0.5, 0.75, 1.0]))
        if len(cortes) < 3:
            return None
        grupos = []
        for i in range(len(cortes) - 1):
            a, b = cortes[i], cortes[i + 1]
            sel = (valores >= a) & ((valores <= b) if i == len(cortes) - 2 else (valores < b))
            grupos.append((f"{_fmt(variable, a)}–{_fmt(variable, b)}", sel))
    tramos = []
    for etiqueta, sel in grupos:
        n = int(sel.sum())
        if n:
            tramos.append({"etiqueta": etiqueta, "satisfechosPct": round(100.0 * float((no[sel] == 0).mean()), 1),
                           "viajes": n})
    if len(tramos) < 2:
        return None
    mejor = max(tramos, key=lambda t: t["satisfechosPct"])
    peor = min(tramos, key=lambda t: t["satisfechosPct"])
    diferencia = round(mejor["satisfechosPct"] - peor["satisfechosPct"])
    larga, corta = ETIQUETAS[variable]
    if diferencia >= 1:
        hallazgo = (f"En el tramo {peor['etiqueta']} la satisfacción es {diferencia} puntos menor que en "
                    f"{mejor['etiqueta']}. {peor['viajes']} de {int(m.sum())} viajes están en ese tramo.")
    else:
        hallazgo = f"La satisfacción casi no cambia según {larga.lower()}."
    return {"variable": variable, "etiqueta": corta, "tramos": tramos, "hallazgo": hallazgo}


def factores(predecir, conjunto: datos.Conjunto, prueba: tuple[np.ndarray, np.ndarray]) -> dict:
    """factores.json: importancia por permutación (sobre prueba), curvas observadas y medias."""
    x_pru, y_pru = prueba
    salida: dict[str, Any] = {"medias": {n: round(float(conjunto.x[:, j].mean()), 4)
                                         for j, n in enumerate(car.CARACTERISTICAS)} if conjunto.n else {}}
    for lado in sat.LADOS:
        k = car.OBJETIVOS.index(sat.OBJETIVO[lado])
        caidas = importancia_permutacion(predecir, x_pru, y_pru, k)
        total = sum(caidas.values())
        pesos = sorted(((n, 100.0 * c / total) for n, c in caidas.items() if c > 0), key=lambda t: t[1],
                       reverse=True) if total > 0 else []
        top, resto = pesos[:MAX_IMPORTANCIA], pesos[MAX_IMPORTANCIA:]
        curvas = []
        for nombre, _ in pesos:
            if len(curvas) == 3:
                break
            if nombre in _SIN_CURVA:
                continue
            c = curva(nombre, conjunto.x, conjunto.y, k)
            if c:
                curvas.append(c)
        salida[lado] = {
            "importancia": [{"variable": n, "etiqueta": ETIQUETAS[n][0], "pesoPct": round(p, 1)} for n, p in top],
            "otrosFactores": {"cantidad": len(resto), "pesoMaximoPct": round(resto[0][1], 1) if resto else 0.0},
            "curvas": curvas,
        }
    return salida


# --------------------------------------------------------------------------- publicar
def calidad(meta: dict | None) -> float | None:
    """PR-AUC promedio de la red en prueba (lados evaluables); None si no se puede medir."""
    if not meta:
        return None
    prueba = ((meta.get("resultados") or {}).get("red_neuronal") or {}).get("prueba") or {}
    valores = [m["pr_auc"] for m in prueba.values() if m.get("evaluable") and m.get("pr_auc") is not None]
    return float(np.mean(valores)) if valores else None


def decidir_publicacion(nuevo: dict, anterior: dict | None, solo_si_mejora: bool) -> tuple[bool, str]:
    if not solo_si_mejora:
        return True, "Publicado (la programación publica siempre)."
    q_nuevo, q_ant = calidad(nuevo), calidad(anterior)
    if anterior is None or anterior.get("modo") != "real":
        return True, "Primer modelo entrenado con datos reales."
    if q_nuevo is None:
        return False, "No se pudo medir el modelo nuevo: se conserva el publicado."
    if q_ant is None or q_nuevo >= q_ant - 0.005:
        return True, f"PR-AUC promedio {q_nuevo:.3f} (antes {q_ant:.3f})." if q_ant is not None else "Publicado."
    return False, f"No mejora al publicado (PR-AUC {q_nuevo:.3f} frente a {q_ant:.3f})."


# --------------------------------------------------------------------------- trabajo
class Progreso:
    """Escribe el avance en el registro de DynamoDB y revisa si el admin canceló."""

    def __init__(self, nube, ident: str):
        self.nube, self.ident = nube, ident
        self.registro = nube.entrenamiento(ident) or sat.registro_inicial(ident, "manual")
        self.registro.update(modo="real", cancelar=bool(self.registro.get("cancelar")))

    def cancelado(self) -> bool:
        actual = self.nube.entrenamiento(self.ident) or {}
        return bool(actual.get("cancelar")) or actual.get("estado") == "CANCELADO"

    def guardar(self, **cambios) -> None:
        pasos = cambios.pop("pasos", None)
        if pasos:
            self.registro["pasos"] = {**self.registro.get("pasos", {}), **pasos}
        self.registro.update(cambios)
        self.nube.guardar_entrenamiento(self.registro)


def _callback_progreso(progreso: Progreso, inicio: float):
    import tensorflow as tf

    class AlAvanzar(tf.keras.callbacks.Callback):
        def on_epoch_end(self, epoca, logs=None):
            n = epoca + 1
            if n % 5 and n != 1:
                return
            if progreso.cancelado():
                raise Cancelado()
            por_epoca = (time.time() - inicio) / n
            termina = datetime.now(sat.ZONA) + timedelta(seconds=por_epoca * max(0, 120 - n) + 30)
            progreso.guardar(epoca=n, epocas=EPOCAS_MAX, progresoPct=int(10 + 60 * min(n, 120) / 120),
                             terminaEstimado=termina.isoformat(timespec="seconds"))

    return AlAvanzar()


def correr(nube, ident: str, solo_si_mejora: bool = True) -> dict:
    progreso = Progreso(nube, ident)
    if progreso.cancelado():
        return progreso.registro
    from . import entrenar

    try:
        progreso.guardar(estado="EXPORTANDO", progresoPct=2, pasos={"exportar": "en_curso"})
        viajes = datos.desde_mongo(nube.secreto(nube.param_mongo), nube.base)
        conjunto = datos.construir(viajes)
        progreso.guardar(detalleExportar=f"{conjunto.n} viajes completos · {conjunto.descartados} descartados",
                         progresoPct=8, pasos={"exportar": "hecho"})
        problemas = entrenar._revisar_datos(conjunto)
        if problemas:
            progreso.guardar(estado="DATOS_INSUFICIENTES", mensaje="; ".join(problemas), progresoPct=100)
            return progreso.registro

        progreso.guardar(estado="ENTRENANDO", progresoPct=10, epoca=0, epocas=EPOCAS_MAX,
                         pasos={"entrenar": "en_curso"})
        extra: dict = {}
        with tempfile.TemporaryDirectory() as carpeta:
            salida = Path(carpeta)
            meta = entrenar.ejecutar(viajes, salida, fuente="mongodb:motvirsweb.servicios",
                                     callbacks={"red_neuronal": [_callback_progreso(progreso, time.time())]},
                                     extra=extra)
            if progreso.cancelado():
                raise Cancelado()
            progreso.guardar(estado="COMPARANDO", progresoPct=75, pasos={"entrenar": "hecho", "comparar": "en_curso"},
                             terminaEstimado=None)
            red = extra["red"]
            predecir = lambda x: red.predict(x, verbose=0)  # noqa: E731
            fac = factores(predecir, extra["conjunto"], extra["particion"]["prueba"])

            actual, meta_anterior, _ = nube.modelo_publicado()
            version = int(actual["version"]) + 1 if actual else 1
            for previo in nube.entrenamientos():  # versiones guardadas sin publicar también cuentan
                version = max(version, int(previo.get("version") or 0) + 1)
            meta.update(modo="real", version_publica=version,
                        entrenadoEn=datetime.now(sat.ZONA).isoformat(timespec="seconds"))
            publicar, motivo = decidir_publicacion(meta, meta_anterior, solo_si_mejora)

            progreso.guardar(estado="PUBLICANDO", progresoPct=90, version=version,
                             pasos={"comparar": "hecho", "publicar": "en_curso"})
            prefijo = f"modelos/v{version}/"
            nube.subir(prefijo + "modelo.tflite", (salida / "modelo.tflite").read_bytes(), "application/octet-stream")
            nube.subir_json(prefijo + "metadatos.json", meta)
            nube.subir_json(prefijo + "factores.json", fac)
            if publicar:
                nube.subir_json("modelos/actual.json", {"version": version, "prefijo": prefijo})
            progreso.guardar(estado="PUBLICADO" if publicar else "GUARDADO_SIN_PUBLICAR", progresoPct=100,
                             pasos={"publicar": "hecho"}, mensaje=motivo)
            return progreso.registro
    except Cancelado:
        progreso.guardar(estado="CANCELADO", mensaje="Cancelado por el admin", terminaEstimado=None)
        return progreso.registro
    except Exception as e:  # el admin ve el motivo en el historial
        log.exception("El entrenamiento %s falló", ident)
        progreso.guardar(estado="FALLIDO", mensaje=f"{type(e).__name__}: {str(e)[:200]}", terminaEstimado=None)
        raise


def main(argv: list[str] | None = None) -> int:
    logging.basicConfig(level=logging.INFO, format="%(asctime)s %(levelname)s %(message)s")
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument("--id", default=os.environ.get("ENTRENAMIENTO_ID"), help="id del registro en DynamoDB")
    p.add_argument("--publicar-siempre", action="store_true",
                   default=os.environ.get("PUBLICAR_SOLO_SI_MEJORA", "true").lower() == "false")
    a = p.parse_args(argv)
    if not a.id:
        p.error("Falta --id (o la variable ENTRENAMIENTO_ID)")
    from .nube import Nube

    registro = correr(Nube(), a.id, solo_si_mejora=not a.publicar_siempre)
    log.info("Entrenamiento %s: %s — %s", a.id, registro.get("estado"), registro.get("mensaje"))
    return 0 if registro.get("estado") not in ("FALLIDO",) else 1


if __name__ == "__main__":
    sys.exit(main())
