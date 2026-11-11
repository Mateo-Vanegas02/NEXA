import numpy as np

from nexa_ml import metricas


def test_auc_perfecto_aleatorio_e_invertido():
    y = np.array([0, 0, 1, 1])
    assert metricas.roc_auc(y, np.array([0.1, 0.2, 0.8, 0.9])) == 1.0
    assert metricas.roc_auc(y, np.array([0.9, 0.8, 0.2, 0.1])) == 0.0
    assert metricas.roc_auc(y, np.array([0.5, 0.5, 0.5, 0.5])) == 0.5


def test_pr_auc():
    y = np.array([0, 0, 0, 1])
    assert metricas.pr_auc(y, np.array([0.1, 0.2, 0.3, 0.9])) == 1.0  # el positivo queda primero
    assert metricas.pr_auc(y, np.array([0.9, 0.8, 0.7, 0.1])) == 0.25  # el positivo queda último


def test_matriz_en_umbral():
    r = metricas.en_umbral(np.array([0, 1, 1, 0]), np.array([0.2, 0.7, 0.4, 0.6]), 0.5)
    assert r["matriz"] == {"vp": 1, "fp": 1, "fn": 1, "vn": 1}
    assert r["precision"] == 0.5 and r["recall"] == 0.5
