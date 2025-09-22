#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"

ARTIFACTS="$ROOT/artifacts"
mkdir -p "$ARTIFACTS"

docker compose up -d db >/dev/null
for _ in {1..30}; do
  if docker compose exec -T db pg_isready -U app -d app >/dev/null 2>&1; then
    break
  fi
  sleep 1
done

python -m alembic -c alembic.ini upgrade head

export LESSONS_ENABLED=1
export ALLOW_DEV_CORS=1
export LOG_LEVEL=INFO

python -m uvicorn app.main:app --app-dir backend --host 127.0.0.1 --port 8000 >/tmp/uvicorn.log 2>&1 &
API_PID=$!
trap 'kill $API_PID 2>/dev/null || true; docker compose down >/dev/null 2>&1' EXIT

for _ in {1..30}; do
  if curl -fsS http://127.0.0.1:8000/health >/dev/null; then
    break
  fi
  sleep 1
done

curl -sS -X POST 'http://127.0.0.1:8000/reader/analyze?include={"lsj":true,"smyth":true}' \
  -H 'Content-Type: application/json' \
  -d '{"q":"Μῆνιν ἄειδε"}' | python -m json.tool > "$ARTIFACTS/reader_analyze.json"

curl -sS -X POST http://127.0.0.1:8000/lesson/generate \
  -H 'Content-Type: application/json' \
  -d '{"language":"grc","profile":"beginner","sources":["daily","canon"],"exercise_types":["alphabet","match","cloze","translate"],"k_canon":1,"include_audio":false,"provider":"echo"}' | python -m json.tool > "$ARTIFACTS/lesson_generate.json"

echo "Headless smoke complete. Artifacts written to $ARTIFACTS"
