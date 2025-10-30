#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"

DEMO_PORT="${DEMO_PORT:-8000}"

docker compose up -d db
python -m alembic -c alembic.ini upgrade head

pushd client/flutter_reader >/dev/null
flutter pub get
flutter build web --pwa-strategy none --base-href /app/
popd >/dev/null

cleanup() {
  scripts/dev/serve_uvicorn.sh stop >/dev/null 2>&1 || true
}
trap cleanup EXIT

LESSONS_ENABLED=1 \
TTS_ENABLED=1 \
ALLOW_DEV_CORS=1 \
LOG_LEVEL=${LOG_LEVEL:-INFO} \
SERVE_FLUTTER_WEB=1 \
  scripts/dev/serve_uvicorn.sh start --flutter --port "$DEMO_PORT"

PORT_FILE="${ROOT}/artifacts/uvicorn.port"
if [[ -f "$PORT_FILE" ]]; then
  DEMO_PORT=$(<"$PORT_FILE")
fi

echo "Demo server ready at http://127.0.0.1:${DEMO_PORT}/app/"
echo "Streaming logs. Press Ctrl+C to stop."

scripts/dev/serve_uvicorn.sh logs
