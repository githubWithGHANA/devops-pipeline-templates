#!/usr/bin/env bash
set -euo pipefail

echo "== Stopping previous revision =="
cd /opt/sample-app

if docker compose ps -q app >/dev/null 2>&1; then
  docker compose down || true
fi

echo "== Previous revision stopped =="
