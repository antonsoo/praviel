#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"

ARTIFACTS="$ROOT/artifacts"
mkdir -p "$ARTIFACTS"

export TTS_ENABLED=1
export ALLOW_DEV_CORS=1
export LOG_LEVEL=INFO
export PYTHONPATH="$ROOT/backend"

docker compose up -d db >/dev/null
for _ in {1..30}; do
  if docker compose exec -T db pg_isready -U app -d app >/dev/null 2>&1; then
    break
  fi
  sleep 1
done

python -m alembic -c alembic.ini upgrade head

python -m uvicorn app.main:app --app-dir backend --host 127.0.0.1 --port 8000 >/tmp/uvicorn-tts.log 2>&1 &
API_PID=$!
trap 'kill $API_PID 2>/dev/null || true; docker compose down >/dev/null 2>&1' EXIT

for _ in {1..30}; do
  if curl -fsS http://127.0.0.1:8000/health >/dev/null; then
    break
  fi
  sleep 1
done

BODY='{"text":"χαῖρε κόσμε","provider":"echo"}'
RESPONSE=$(curl -sS -X POST http://127.0.0.1:8000/tts/speak \
  -H 'Content-Type: application/json' \
  -d "$BODY")

printf '%s' "$RESPONSE" | python -m json.tool > "$ARTIFACTS/tts_echo.json"

python - "$ARTIFACTS/tts_echo.wav" <<'PY'
import base64
import json
import sys

data = json.loads(sys.stdin.read())
with open(sys.argv[1], 'wb') as fh:
    fh.write(base64.b64decode(data['audio']['b64']))
print(f"Wrote {sys.argv[1]}")
PY

unset TTS_ENABLED ALLOW_DEV_CORS LOG_LEVEL PYTHONPATH

echo "TTS smoke complete."
