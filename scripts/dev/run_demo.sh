#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

cd "$ROOT"

docker compose up -d db
python -m alembic -c alembic.ini upgrade head

pushd client/flutter_reader >/dev/null
flutter build web
popd >/dev/null

PYTHONPATH=backend SERVE_FLUTTER_WEB=1 ALLOW_DEV_CORS=1 exec uvicorn app.main:app --host 127.0.0.1 --port 8000 --reload
