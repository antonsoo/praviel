#!/usr/bin/env bash
set -euo pipefail

ROOT="$(git rev-parse --show-toplevel)"
cd "$ROOT"

cleanup() {
  scripts/dev/serve_uvicorn.sh stop >/dev/null 2>&1 || true
}
trap cleanup EXIT

echo "[chat] Starting Postgres via docker compose"
docker compose up -d db

echo "[chat] Applying migrations"
python -m alembic -c alembic.ini upgrade head

START_ARGS=(--log-level warning)
if [[ -n "${CHAT_SMOKE_PORT:-}" ]]; then
  START_ARGS+=(--port "${CHAT_SMOKE_PORT}")
fi

LESSONS_ENABLED=1 \
ALLOW_DEV_CORS=1 \
  scripts/dev/serve_uvicorn.sh start "${START_ARGS[@]}"

PORT_FILE="${ROOT}/artifacts/uvicorn.port"
HOST=127.0.0.1
if [[ -f "$PORT_FILE" ]]; then
  PORT=$(<"$PORT_FILE")
else
  PORT="${CHAT_SMOKE_PORT:-8000}"
fi

echo "[chat] Testing /chat/converse with athenian_merchant"
PAYLOAD='{"message":"χαῖρε","persona":"athenian_merchant","provider":"echo"}'
curl --fail --silent --show-error \
  -H 'Content-Type: application/json' \
  -X POST "http://${HOST}:${PORT}/chat/converse" \
  -d "${PAYLOAD}"
echo

echo "[chat] Testing /lesson/generate with text_range"
PAYLOAD='{"language":"grc","profile":"beginner","text_range":{"ref_start":"1.1","ref_end":"1.5"},"exercise_types":["match","cloze"],"provider":"echo"}'
curl --fail --silent --show-error \
  -H 'Content-Type: application/json' \
  -X POST "http://${HOST}:${PORT}/lesson/generate" \
  -d "${PAYLOAD}"
echo

echo "[chat] Testing /lesson/generate with register=colloquial"
PAYLOAD='{"language":"grc","profile":"beginner","register":"colloquial","exercise_types":["match","translate"],"provider":"echo"}'
curl --fail --silent --show-error \
  -H 'Content-Type: application/json' \
  -X POST "http://${HOST}:${PORT}/lesson/generate" \
  -d "${PAYLOAD}"
echo

echo "[chat] All smoke tests passed!"
