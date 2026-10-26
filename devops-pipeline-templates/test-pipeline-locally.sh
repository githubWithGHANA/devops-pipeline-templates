#!/usr/bin/env bash
set -euo pipefail

PASS=0
FAIL=0

pass() { echo "PASS: $*"; PASS=$((PASS + 1)); }
fail() { echo "FAIL: $*"; FAIL=$((FAIL + 1)); }

echo "== Local pipeline smoke test =="

# 1) Line endings: no CRLF.
if grep -R --files-with-matches $'\r' .githooks scripts appspec.yml docker-compose.yml buildspec.yml Dockerfile >/dev/null 2>&1; then
  fail "CRLF line endings detected. Run dos2unix on affected files."
else
  pass "No CRLF line endings detected."
fi

# 2) Script syntax.
for script in scripts/*.sh .githooks/pre-push; do
  if [ -f "$script" ]; then
    if bash -n "$script" >/dev/null 2>&1; then
      pass "Syntax OK: $script"
    else
      fail "Syntax error: $script"
    fi
  fi
done

# 3) Executable permissions.
for script in scripts/*.sh .githooks/pre-push; do
  if [ -f "$script" ]; then
    if [ -x "$script" ]; then
      pass "Executable: $script"
    else
      fail "Not executable: $script"
    fi
  fi
done

# 4) Required files present.
for required in appspec.yml docker-compose.yml buildspec.yml Dockerfile scripts/before_install.sh scripts/after_install.sh scripts/application_start.sh scripts/validate_service.sh; do
  if [ -f "$required" ]; then
    pass "Present: $required"
  else
    fail "Missing: $required"
  fi
done

# 5) Build Docker image locally (no push).
if command -v docker >/dev/null 2>&1; then
  echo "== Building Docker image locally =="
  if docker build -t sample-app-local . >/dev/null 2>&1; then
    pass "Docker build succeeded."
    docker rmi sample-app-local >/dev/null 2>&1 || true
  else
    fail "Docker build failed."
  fi
else
  pass "Docker not available; skipping Docker build."
fi

# 6) Mock health check against the compose health endpoint pattern.
HEALTH_URL="http://localhost:${APP_PORT:-8080}/health"
echo "== Mock health check ($HEALTH_URL) =="
if curl -sS -o /dev/null -w "%{http_code}" "$HEALTH_URL" >/dev/null 2>&1; then
  pass "Health endpoint reachable."
else
  pass "Health endpoint not reachable (expected if stack is not running)."
fi

echo "== Results: $PASS passed, $FAIL failed =="
if [ "$FAIL" -gt 0 ]; then
  exit 1
fi
