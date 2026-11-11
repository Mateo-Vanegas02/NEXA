"""Red de Keras con dos salidas: probabilidad de que el pasajero y el conductor NO queden satisfechos.

Un solo modelo para los dos lados: comparten lo que describe el viaje (esperas, precio, recorrido) y
cada lado tiene su propia capa final. Así un lado con pocas notas aprovecha lo que aprende el otro.
"""
from __future__ import annotations

import numpy as np
import tensorflow as tf
import keras

from .caracteristicas import OBJETIVOS


@keras.saving.register_keras_serializable(package="nexa")
class EntropiaConMascara(keras.losses.Loss):
    """Entropía cruzada binaria que ignora los lados sin nota (etiqueta -1) y pesa la clase rara.

    `pesos` tiene, por objetivo, [peso de "si", peso de "no"]: compensa que casi todo sea 4–5 estrellas.
    """

    def __init__(self, pesos, name="entropia_con_mascara", **kwargs):
        super().__init__(name=name, **kwargs)
        self.pesos = [[float(a), float(b)] for a, b in pesos]

    def call(self, y_true, y_pred):
        y_true = tf.cast(y_true, y_pred.dtype)
        mascara = tf.cast(y_true >= 0, y_pred.dtype)
        y = tf.clip_by_value(y_true, 0.0, 1.0)
        p = tf.clip_by_value(y_pred, 1e-7, 1.0 - 1e-7)
        pesos = tf.constant(self.pesos, dtype=y_pred.dtype)            # (objetivos, 2)
        peso = (1.0 - y) * pesos[:, 0] + y * pesos[:, 1]               # (n, objetivos)
        entropia = -(y * tf.math.log(p) + (1.0 - y) * tf.math.log(1.0 - p))
        total = tf.reduce_sum(entropia * peso * mascara, axis=-1)
        return total / tf.maximum(tf.reduce_sum(mascara, axis=-1), 1.0)

    def get_config(self):
        return {**super().get_config(), "pesos": self.pesos}


def pesos_clase(y: np.ndarray) -> list[list[float]]:
    """Por objetivo: [peso "si", peso "no"], con n / (2 · casos de esa clase) entre los etiquetados."""
    pesos = []
    for k in range(y.shape[1]):
        etiquetados = y[:, k][y[:, k] >= 0]
        n, no = len(etiquetados), int(etiquetados.sum())
        si = n - no
        pesos.append([n / (2 * si), n / (2 * no)] if si and no else [1.0, 1.0])
    return pesos


def _normalizador(x_entrenamiento: np.ndarray) -> keras.layers.Normalization:
    # La normalización va DENTRO del modelo: el .tflite recibe las variables crudas.
    capa = keras.layers.Normalization(name="normalizacion")
    capa.adapt(x_entrenamiento)
    return capa


def red_neuronal(x_ent: np.ndarray, y_ent: np.ndarray, semilla: int = 42) -> keras.Model:
    keras.utils.set_random_seed(semilla)
    reg = keras.regularizers.l2(1e-3)
    entrada = keras.Input(shape=(x_ent.shape[1],), dtype="float32", name="viaje")
    h = _normalizador(x_ent)(entrada)
    h = keras.layers.Dense(32, activation="relu", kernel_regularizer=reg, name="comun_1")(h)
    h = keras.layers.Dropout(0.25)(h)
    h = keras.layers.Dense(16, activation="relu", kernel_regularizer=reg, name="comun_2")(h)
    h = keras.layers.Dropout(0.25)(h)
    cabezas = []
    for objetivo in OBJETIVOS:  # una rama pequeña por lado del viaje
        c = keras.layers.Dense(8, activation="relu", kernel_regularizer=reg, name=f"{objetivo}_oculta")(h)
        cabezas.append(keras.layers.Dense(1, activation="sigmoid", name=objetivo)(c))
    salida = keras.layers.Concatenate(name="prob_no_satisfecho")(cabezas)
    return _compilar(keras.Model(entrada, salida, name="nexa_satisfaccion"), y_ent)


def regresion_logistica(x_ent: np.ndarray, y_ent: np.ndarray, semilla: int = 42) -> keras.Model:
    """Línea base: si la red no le gana a esto, no vale la pena la red."""
    keras.utils.set_random_seed(semilla)
    entrada = keras.Input(shape=(x_ent.shape[1],), dtype="float32", name="viaje")
    h = _normalizador(x_ent)(entrada)
    salida = keras.layers.Dense(len(OBJETIVOS), activation="sigmoid",
                                kernel_regularizer=keras.regularizers.l2(1e-3))(h)
    return _compilar(keras.Model(entrada, salida, name="base_logistica"), y_ent)


def _compilar(modelo: keras.Model, y_ent: np.ndarray) -> keras.Model:
    modelo.compile(optimizer=keras.optimizers.Adam(1e-3), loss=EntropiaConMascara(pesos_clase(y_ent)))
    return modelo


def entrenar(modelo: keras.Model, x_ent, y_ent, x_val, y_val, epocas: int = 300) -> keras.callbacks.History:
    parada = keras.callbacks.EarlyStopping(monitor="val_loss", patience=25, restore_best_weights=True)
    return modelo.fit(x_ent, y_ent, validation_data=(x_val, y_val), epochs=epocas, batch_size=64,
                      callbacks=[parada], verbose=0)


def a_tflite(modelo: keras.Model) -> bytes:
    """Convierte a TensorFlow Lite (LiteRT): lo usan la Lambda (ai-edge-litert) y Flutter (tflite_flutter)."""
    conversor = tf.lite.TFLiteConverter.from_keras_model(modelo)
    conversor.target_spec.supported_ops = [tf.lite.OpsSet.TFLITE_BUILTINS]  # sin Select TF ops
    return conversor.convert()
