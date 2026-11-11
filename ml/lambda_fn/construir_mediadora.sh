#!/usr/bin/env bash
# Arma mediadora.zip (Lambda nexa-satisfaccion, python3.13, x86_64). No lleva el modelo: lo lee de S3.
# Uso: ./lambda_fn/construir_mediadora.sh        → deja ml/mediadora.zip
set -euo pipefail

RAIZ="$(cd "$(dirname "$0")/.." && pwd)"
TRABAJO="$(mktemp -d)"
trap 'rm -rf "$TRABAJO"' EXIT

pip install --quiet --target "$TRABAJO" \
  --only-binary=:all: --python-version 3.13 --implementation cp \
  --platform manylinux_2_27_x86_64 --platform manylinux_2_28_x86_64 --platform manylinux_2_17_x86_64 \
  -r "$RAIZ/lambda_fn/requirements-mediadora.txt"

# boto3 ya viene en el runtime de Lambda; pruebas, cachés y encabezados no hacen falta.
rm -rf "$TRABAJO"/boto3* "$TRABAJO"/botocore* "$TRABAJO"/s3transfer*
find "$TRABAJO" -type d \( -name tests -o -name __pycache__ -o -name include \) -prune -exec rm -rf {} +

mkdir -p "$TRABAJO/nexa_ml"
cp "$RAIZ"/nexa_ml/{__init__,caracteristicas,datos,inferencia,satisfaccion,nube}.py "$TRABAJO/nexa_ml/"
cp "$RAIZ/lambda_fn/mediadora.py" "$TRABAJO/"

rm -f "$RAIZ/mediadora.zip"
(cd "$TRABAJO" && zip -qr9 "$RAIZ/mediadora.zip" .)
echo "mediadora.zip: $(du -h "$RAIZ/mediadora.zip" | cut -f1) comprimido, $(du -sh "$TRABAJO" | cut -f1) descomprimido (límite 250 MB)"
