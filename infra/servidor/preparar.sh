#!/bin/bash
# Se ejecuta en el servidor (como root, en /opt/nexa) cada vez que GitHub Actions despliega.
# 1) arma .env desde Parameter Store, 2) entra a ECR, 3) baja la imagen TAG y reinicia,
# 4) espera a que la web responda. Ningún secreto queda en el repositorio ni en GitHub.
set -euo pipefail
cd /opt/nexa
REGION=us-east-2
REGISTRO=040666550968.dkr.ecr.us-east-2.amazonaws.com
: "${TAG:?Falta TAG (commit de la imagen)}"

umask 077
aws ssm get-parameters-by-path --region "$REGION" --path /nexa/prod --with-decryption \
  --query 'Parameters[].[Name,Value]' --output text \
  | sed -E 's#^/nexa/prod/##; s#\t#=#' > .env.nuevo
for clave in MONGODB_URI JWT_SECRET GEMINI_API_KEY SPRING_MAIL_USERNAME SPRING_MAIL_PASSWORD APP_BASE_URL DOMINIO; do
  grep -q "^${clave}=" .env.nuevo || { echo "Falta /nexa/prod/${clave} en Parameter Store" >&2; rm -f .env.nuevo; exit 1; }
done
mv .env.nuevo .env
chmod 600 .env

aws ecr get-login-password --region "$REGION" | docker login --username AWS --password-stdin "$REGISTRO"

export TAG
docker compose -f docker-compose.aws.yml pull
docker compose -f docker-compose.aws.yml up -d --remove-orphans

# La web tarda en arrancar (Spring + conexión a Atlas): hasta 4 minutos.
for i in $(seq 1 48); do
  if docker exec nexa bash -c 'exec 3<>/dev/tcp/127.0.0.1/8080' 2>/dev/null; then
    echo "NEXA responde en el puerto 8080 (imagen ${TAG})"
    docker image prune -af --filter "until=72h" >/dev/null || true
    exit 0
  fi
  sleep 5
done
echo "NEXA no arrancó a tiempo. Últimas líneas del log:" >&2
docker logs --tail 80 nexa >&2 || true
exit 1
