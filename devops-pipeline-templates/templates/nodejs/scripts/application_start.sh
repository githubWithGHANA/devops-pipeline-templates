#!/usr/bin/env bash
set -euo pipefail

DEST="/opt/sample-app"
cd "$DEST"

echo "== Starting application =="
docker compose pull
docker compose up -d --wait --wait-timeout 300
docker compose ps

echo "== Application started =="
