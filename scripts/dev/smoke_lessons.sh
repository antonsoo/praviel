#!/usr/bin/env bash
set -euo pipefail

ROOT="$(git rev-parse --show-toplevel)"
cd "$ROOT"

cleanup() {
  scripts/dev/serve_uvicorn.sh stop >/dev/null 2>&1 || true
}
trap cleanup EXIT

echo "[lessons] Starting Postgres via docker compose"
docker compose up -d db

echo "[lessons] Applying migrations"
python -m alembic -c alembic.ini upgrade head

START_ARGS=(--log-level warning)
if [[ -n "${LESSON_SMOKE_PORT:-}" ]]; then
  START_ARGS+=(--port "${LESSON_SMOKE_PORT}")
fi

LESSONS_ENABLED=1 \
ALLOW_DEV_CORS=1 \
  scripts/dev/serve_uvicorn.sh start "${START_ARGS[@]}"

PORT_FILE="${ROOT}/artifacts/uvicorn.port"
HOST=127.0.0.1
if [[ -f "$PORT_FILE" ]]; then
  PORT=$(<"$PORT_FILE")
else
  PORT="${LESSON_SMOKE_PORT:-8000}"
fi

PAYLOAD='{"language":"grc","profile":"beginner","sources":["daily","canon"],"exercise_types":["alphabet","match","cloze","translate"],"k_canon":2,"include_audio":false,"provider":"echo"}'

echo "[lessons] Hitting /lesson/generate"
curl --fail --silent --show-error \
  -H 'Content-Type: application/json' \
  -X POST "http://${HOST}:${PORT}/lesson/generate" \
  -d "${PAYLOAD}"
echo
