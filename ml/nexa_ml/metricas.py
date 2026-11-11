"""Métricas de clasificación binaria en NumPy (sin scikit-learn, para no inflar dependencias)."""
from __future__ import annotations

import numpy as np


def roc_auc(y: np.ndarray, p: np.ndarray) -> float:
    """Probabilidad de que un positivo reciba más puntaje que un negativo (empates cuentan 1/2)."""
    y = np.asarray(y).astype(bool)
    pos, neg = p[y], p[~y]
    if len(pos) == 0 or len(neg) == 0:
        return float("nan")
    orden = np.argsort(np.concatenate([pos, neg]), kind="mergesort")
    rangos = np.empty(len(orden), dtype=float)
    valores = np.concatenate([pos, neg])[orden]
    i = 0
    while i < len(valores):  # rango promedio para empates
        j = i
        while j + 1 < len(valores) and valores[j + 1] == valores[i]:
            j += 1
        rangos[orden[i:j + 1]] = (i + j) / 2 + 1
        i = j + 1
    suma_pos = rangos[: len(pos)].sum()
    return float((suma_pos - len(pos) * (len(pos) + 1) / 2) / (len(pos) * len(neg)))


def pr_auc(y: np.ndarray, p: np.ndarray) -> float:
    """Precisión promedio (área bajo la curva precisión-exhaustividad)."""
    y = np.asarray(y).astype(int)
    if y.sum() == 0:
        return float("nan")
    orden = np.argsort(-p, kind="mergesort")
    y_ord = y[orden]
    vp = np.cumsum(y_ord)
    precision = vp / np.arange(1, len(y_ord) + 1)
    return float((precision * y_ord).sum() / y.sum())


def en_umbral(y: np.ndarray, p: np.ndarray, umbral: float) -> dict:
    pred = p >= umbral
    y = np.asarray(y).astype(bool)
    vp = int((pred & y).sum())
    fp = int((pred & ~y).sum())
    fn = int((~pred & y).sum())
    vn = int((~pred & ~y).sum())
    precision = vp / (vp + fp) if vp + fp else 0.0
    recall = vp / (vp + fn) if vp + fn else 0.0
    especificidad = vn / (vn + fp) if vn + fp else 0.0
    f1 = 2 * precision * recall / (precision + recall) if precision + recall else 0.0
    return {
        "umbral": round(float(umbral), 4),
        "precision": round(precision, 4),
        "recall": round(recall, 4),
        "f1": round(f1, 4),
        "exactitud_balanceada": round((recall + especificidad) / 2, 4),
        "matriz": {"vp": vp, "fp": fp, "fn": fn, "vn": vn},
    }


def mejor_umbral(y: np.ndarray, p: np.ndarray) -> float:
    """Umbral que maximiza F1 de la clase 'insatisfecho' (se elige en validación, nunca en prueba)."""
    candidatos = np.unique(np.round(p, 4))
    if len(candidatos) > 400:
        candidatos = np.quantile(p, np.linspace(0.01, 0.99, 199))
    mejor, mejor_f1 = 0.5, -1.0
    for u in candidatos:
        f1 = en_umbral(y, p, float(u))["f1"]
        if f1 > mejor_f1:
            mejor, mejor_f1 = float(u), f1
    return mejor


def resumen(y: np.ndarray, p: np.ndarray, umbral: float) -> dict:
    return {
        "roc_auc": round(roc_auc(y, p), 4),
        "pr_auc": round(pr_auc(y, p), 4),
        "prevalencia": round(float(np.mean(y)), 4),
        **en_umbral(y, p, umbral),
    }
