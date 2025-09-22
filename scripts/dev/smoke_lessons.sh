#!/usr/bin/env bash
set -euo pipefail

ROOT="$(git rev-parse --show-toplevel)"
cd "$ROOT"

echo "[lessons] Starting Postgres via docker compose"
docker compose up -d db

echo "[lessons] Applying migrations"
python -m alembic -c alembic.ini upgrade head

export PYTHONPATH="${ROOT}/backend"
export LESSONS_ENABLED=1

PORT=${LESSON_SMOKE_PORT:-8000}
HOST=127.0.0.1

echo "[lessons] Launching API on ${HOST}:${PORT}"
uvicorn app.main:app --host "${HOST}" --port "${PORT}" --log-level warning &
SERVER_PID=$!
trap 'kill ${SERVER_PID} 2>/dev/null || true' EXIT

sleep 3

PAYLOAD='{"language":"grc","profile":"beginner","sources":["daily","canon"],"exercise_types":["alphabet","match","cloze","translate"],"k_canon":2,"include_audio":false,"provider":"echo"}'

echo "[lessons] Hitting /lesson/generate"
curl --fail --silent --show-error \
  -H 'Content-Type: application/json' \
  -X POST "http://${HOST}:${PORT}/lesson/generate" \
  -d "${PAYLOAD}"
echo
