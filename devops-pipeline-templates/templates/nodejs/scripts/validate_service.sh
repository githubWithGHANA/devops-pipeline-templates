#!/usr/bin/env bash
set -euo pipefail

DEST="/opt/sample-app"
cd "$DEST"

echo "== Validating deployment =="

if ! docker compose ps >/dev/null 2>&1; then
  echo "ERROR: docker compose is not available in $DEST"
  exit 1
fi

APP_CONTAINER_ID="$(docker compose ps -q app || true)"
if [ -z "$APP_CONTAINER_ID" ]; then
  echo "ERROR: app container is not running."
  exit 1
fi

HEALTH_URL="http://localhost:${APP_PORT:-8080}/health"
MAX_RETRIES=12
SLEEP_SECONDS=5

for i in $(seq 1 "$MAX_RETRIES"); do
  HTTP_CODE="$(curl -sS -o /dev/null -w "%{http_code}" "$HEALTH_URL" || true)"
  if [ "$HTTP_CODE" = "200" ]; then
    echo "Health endpoint responded OK (HTTP $HTTP_CODE)."
    break
  fi
  echo "Health check attempt $i/$MAX_RETRIES failed (HTTP ${HTTP_CODE:-none}). Retrying in ${SLEEP_SECONDS}s..."
  sleep "$SLEEP_SECONDS"
done

if [ "${HTTP_CODE:-}" != "200" ]; then
  echo "ERROR: health endpoint did not return 200 after $MAX_RETRIES attempts (last HTTP ${HTTP_CODE:-none})."
  echo "Dumping application logs:"
  docker logs --tail 100 "$APP_CONTAINER_ID" || true
  exit 1
fi

echo "== Deployment validation successful =="
