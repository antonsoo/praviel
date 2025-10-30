#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"

ARTIFACTS="$ROOT/artifacts"
mkdir -p "$ARTIFACTS"

cleanup() {
  scripts/dev/serve_uvicorn.sh stop >/dev/null 2>&1 || true
  docker compose down >/dev/null 2>&1 || true
}
trap cleanup EXIT

docker compose up -d db >/dev/null
for attempt in $(seq 1 30); do
  if docker compose exec -T db pg_isready -U app -d app >/dev/null 2>&1; then
    break
  fi
  sleep 1
  if [[ $attempt -eq 30 ]]; then
    echo "Database failed to become ready" >&2
    exit 1
  fi
done

python -m alembic -c alembic.ini upgrade head

START_ARGS=(--port 8000 --log-level info)
LESSONS_ENABLED=1 \
ALLOW_DEV_CORS=1 \
  scripts/dev/serve_uvicorn.sh start "${START_ARGS[@]}"

PORT_FILE="$ROOT/artifacts/uvicorn.port"
if [[ -f "$PORT_FILE" ]]; then
  PORT=$(<"$PORT_FILE")
else
  PORT=8000
fi

BASE="http://127.0.0.1:${PORT}"

curl -sS -X POST "${BASE}/reader/analyze?include={"\"lsj\"":true,"\"smyth\"":true}" \
  -H 'Content-Type: application/json' \
  -d '{"q":"????? ?????"}' | python -m json.tool > "$ARTIFACTS/reader_analyze.json"

curl -sS -X POST "${BASE}/lesson/generate" \
  -H 'Content-Type: application/json' \
  -d '{"language":"grc","profile":"beginner","sources":["daily","canon"],"exercise_types":["alphabet","match","cloze","translate"],"k_canon":1,"include_audio":false,"provider":"echo"}' | python -m json.tool > "$ARTIFACTS/lesson_generate.json"

echo "Headless smoke complete. Artifacts written to $ARTIFACTS"
