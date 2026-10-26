#!/usr/bin/env bash
set -euo pipefail

echo "== AfterInstall: preparing deploy bundle =="
DEST="/opt/sample-app"
mkdir -p "$DEST"

for file in docker-compose.yml image_definition.env deploy.env*; do
  if [ -f "$file" ]; then
    cp -- "$file" "$DEST/$file"
  fi
done

echo "== Bundle installed in $DEST =="
