#!/usr/bin/env bash
# Despliega NEXA con Docker Compose (build multi-etapa; compila dentro de Docker).
# Uso:  ./deploy.sh              -> usa la base de datos de MONGODB_URI (.env)
#       NEXA_LOCAL_DB=1 ./deploy.sh  -> levanta además un MongoDB local (perfil local-db)
set -euo pipefail
cd "$(dirname "$0")"

if [ ! -f .env ]; then
  echo "Falta el archivo .env. Copia .env.example a .env y completa los valores." >&2
  exit 1
fi

PERFIL=()
[ "${NEXA_LOCAL_DB:-0}" = "1" ] && PERFIL=(--profile local-db)

echo "Construyendo y levantando NEXA..."
docker compose "${PERFIL[@]}" up -d --build

echo "Esperando a que el servicio esté saludable (máx. 3 min)..."
for _ in $(seq 1 36); do
  estado=$(docker inspect --format '{{.State.Health.Status}}' nexa-backend 2>/dev/null || echo "starting")
  [ "$estado" = "healthy" ] && { echo "NEXA está en línea: http://localhost:8080"; exit 0; }
  sleep 5
done

echo "El servicio no quedó saludable a tiempo. Últimos registros:" >&2
docker compose logs --tail 50 nexa-backend >&2
exit 1
