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

export PYTHONPATH="${ROOT}/backend"
export TTS_ENABLED=1
export ALLOW_DEV_CORS=1
export LOG_LEVEL=${LOG_LEVEL:-INFO}

HOST=127.0.0.1
PORT=8000

WITH_DB=${SMOKE_TTS_DB:-1}
if [[ "$WITH_DB" == "1" ]]; then
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
fi

START_ARGS=(--port "$PORT" --log-level info)
TTS_ENABLED=1 \
ALLOW_DEV_CORS=1 \
  scripts/dev/serve_uvicorn.sh start "${START_ARGS[@]}"

PORT_FILE="$ROOT/artifacts/uvicorn.port"
if [[ -f "$PORT_FILE" ]]; then
  PORT=$(<"$PORT_FILE")
fi
BASE="http://${HOST}:${PORT}"

BODY='{"text":"????? ?????","provider":"echo"}'
RESPONSE=$(curl -sS -X POST "${BASE}/tts/speak" \
  -H 'Content-Type: application/json' \
  -d "$BODY")

printf '%s' "$RESPONSE" | python -m json.tool > "$ARTIFACTS/tts_echo.json"

python - "$ARTIFACTS/tts_echo.json" "$ARTIFACTS/tts_echo.wav" <<'PY'
import base64
import json
import pathlib
import sys

json_path = pathlib.Path(sys.argv[1])
audio_path = pathlib.Path(sys.argv[2])
data = json.loads(json_path.read_text(encoding='utf-8'))
audio_path.write_bytes(base64.b64decode(data['audio']['b64']))
print(f"Wrote {audio_path}")
PY

echo "TTS smoke complete. Artifacts written to $ARTIFACTS"
