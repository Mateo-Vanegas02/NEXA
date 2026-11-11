#!/usr/bin/env bash
# Arma lambda.zip para el runtime python3.13 (x86_64) con LiteRT, sin TensorFlow.
# Uso: ./lambda_fn/construir.sh artefactos/      (carpeta con modelo.tflite y metadatos.json)
set -euo pipefail

ARTEFACTOS="${1:?Indica la carpeta con modelo.tflite y metadatos.json}"
RAIZ="$(cd "$(dirname "$0")/.." && pwd)"
TRABAJO="$(mktemp -d)"
trap 'rm -rf "$TRABAJO"' EXIT

pip install --quiet --target "$TRABAJO" \
  --only-binary=:all: --python-version 3.13 --implementation cp \
  --platform manylinux_2_27_x86_64 --platform manylinux_2_28_x86_64 --platform manylinux_2_17_x86_64 \
  -r "$RAIZ/lambda_fn/requirements.txt"

# Pruebas, cachés y encabezados no hacen falta en la Lambda.
find "$TRABAJO" -type d \( -name tests -o -name __pycache__ -o -name include \) -prune -exec rm -rf {} +

mkdir -p "$TRABAJO/nexa_ml" "$TRABAJO/modelo"
cp "$RAIZ/nexa_ml/__init__.py" "$RAIZ/nexa_ml/caracteristicas.py" "$RAIZ/nexa_ml/inferencia.py" "$TRABAJO/nexa_ml/"
cp "$RAIZ/lambda_fn/handler.py" "$TRABAJO/"
cp "$ARTEFACTOS/modelo.tflite" "$ARTEFACTOS/metadatos.json" "$TRABAJO/modelo/"

rm -f "$RAIZ/lambda.zip"
(cd "$TRABAJO" && zip -qr9 "$RAIZ/lambda.zip" .)
echo "lambda.zip: $(du -h "$RAIZ/lambda.zip" | cut -f1) comprimido, $(du -sh "$TRABAJO" | cut -f1) descomprimido (límite 250 MB)"
