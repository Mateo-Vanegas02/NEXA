"""Predicción con el modelo .tflite usando LiteRT, sin TensorFlow completo (~60 MB frente a ~1,3 GB)."""
from __future__ import annotations

from pathlib import Path

import numpy as np

try:  # paquete actual de Google para TFLite/LiteRT
    from ai_edge_litert.interpreter import Interpreter
except ImportError:  # pragma: no cover - respaldo para entornos con TensorFlow instalado
    from tensorflow.lite.python.interpreter import Interpreter  # type: ignore


class Predictor:
    def __init__(self, ruta_modelo: str | Path):
        self._interprete = Interpreter(model_path=str(ruta_modelo))
        self._entrada = self._interprete.get_input_details()[0]
        self._salida = self._interprete.get_output_details()[0]
        self.n_caracteristicas = int(self._entrada["shape"][-1])
        self.n_objetivos = int(self._salida["shape"][-1])

    def probabilidades(self, x) -> np.ndarray:
        """(n, objetivos): probabilidad de 'no' satisfecho de cada lado."""
        x = np.asarray(x, dtype=np.float32).reshape(-1, self.n_caracteristicas)
        if len(x) == 0:
            return np.zeros((0, self.n_objetivos), dtype=np.float32)
        self._interprete.resize_tensor_input(self._entrada["index"], list(x.shape))
        self._interprete.allocate_tensors()
        self._interprete.set_tensor(self._entrada["index"], x)
        self._interprete.invoke()
        return self._interprete.get_tensor(self._salida["index"]).reshape(-1, self.n_objetivos).copy()
