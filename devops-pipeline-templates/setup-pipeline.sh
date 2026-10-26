#!/usr/bin/env bash
set -euo pipefail

# Resolve script dir so the template package can live anywhere in the repo.
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATE_ROOT="$SCRIPT_DIR/templates"

usage() {
  cat <<EOF
Usage: $0 <stack> <app-name> <ec2-destination>

Copies the sanitized template into the current directory and adjusts the app name.

Examples:
  $0 nodejs my-app /opt/my-app
EOF
  exit 1
}

STACK="${1:-}"
APP_NAME="${2:-}"
DEST="${3:-}"

if [ -z "$STACK" ] || [ -z "$APP_NAME" ] || [ -z "$DEST" ]; then
  usage
fi

TEMPLATE_DIR="$TEMPLATE_ROOT/$STACK"
if [ ! -d "$TEMPLATE_DIR" ]; then
  echo "Unsupported or missing stack template: $STACK" >&2
  echo "Available stacks:" >&2
  for d in "$TEMPLATE_ROOT"/*/; do
    [ -d "$d" ] && echo "  - $(basename "$d")"
  done
  exit 1
fi

TARGET="$(pwd)"
echo "== Installing $STACK template into $TARGET for app=$APP_NAME dest=$DEST =="

# Copy only the selected stack template into the current directory.
cp -R "$TEMPLATE_DIR"/. "$TARGET/"

# Sanitize app-name references.
find "$TARGET" -type f -exec sed -i "s/\${APP_NAME:-app}/$APP_NAME/g" {} +
find "$TARGET" -type f -exec sed -i "s|/opt/\${APP_NAME:-app}|$DEST|g" {} +
find "$TARGET" -type f -exec sed -i "s|/opt/app|$DEST|g" {} +

chmod +x "$TARGET"/scripts/*.sh 2>/dev/null || true
# Bring the shipped pre-push hook into the repo root's .githooks so the
# setup script can copy it into .git/hooks next.
if [ -d "$TARGET/devops-pipeline-templates/.githooks" ] && [ ! -d "$TARGET/.githooks" ]; then
  cp -R "$TARGET/devops-pipeline-templates/.githooks" "$TARGET/.githooks"
fi
chmod +x "$TARGET"/.githooks/pre-push 2>/dev/null || true

# Install the shipped pre-push hook into the repo so it fires on git push.
HOOK_SRC="$TARGET/.githooks/pre-push"
if [ -d "$TARGET/.git" ] && [ -f "$HOOK_SRC" ]; then
  mkdir -p "$TARGET/.git/hooks"
  cp -f "$HOOK_SRC" "$TARGET/.git/hooks/pre-push"
  chmod +x "$TARGET/.git/hooks/pre-push"
fi

echo "== Setup complete. Review and replace placeholders in deploy.env / .env.example before pushing. =="
