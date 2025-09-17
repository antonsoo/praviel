#!/usr/bin/env bash
set -euo pipefail

# Usage: scripts/dev/run_mvp.sh [path/to/tei.xml]
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TEI_INPUT="${1:-${ROOT_DIR}/tests/fixtures/perseus_sample_annotated_greek.xml}"
ALEMBIC_INI="${ROOT_DIR}/backend/alembic.ini"

export PYTHONPATH="${ROOT_DIR}/backend"
export PYTHONIOENCODING="utf-8"

PYTHON_CMD=("python")
if ! command -v "${PYTHON_CMD[0]}" >/dev/null 2>&1; then
  if command -v python3 >/dev/null 2>&1; then
    PYTHON_CMD=("python3")
  elif command -v py >/dev/null 2>&1; then
    PYTHON_CMD=("py" "-3")
  else
    echo "Python interpreter not found; activate the project environment." >&2
    exit 1
  fi
fi

echo "[MVP] Bringing up DB (docker compose up -d db)"
docker compose up -d db

# Wait for readiness (inside container via pg_isready)
DB_READY_TIMEOUT=60
echo "[MVP] Waiting for Postgres readiness (timeout: ${DB_READY_TIMEOUT}s)..."
remaining_attempts=$DB_READY_TIMEOUT
until docker compose exec -T db pg_isready -U postgres -d postgres >/dev/null 2>&1; do
  sleep 1
  remaining_attempts=$((remaining_attempts-1))
  if [ "$remaining_attempts" -le 0 ]; then
    echo "Database failed to become ready after ${DB_READY_TIMEOUT} seconds. Check the logs below for details."
    docker compose logs db | tail -n 100
    exit 1
  fi
done

echo "[MVP] Applying migrations"
alembic -c "${ALEMBIC_INI}" upgrade head

# Use DATABASE_URL if provided; otherwise CLI defaults will kick in (5433).
echo "[MVP] Ingesting TEI sample: ${TEI_INPUT}"
"${PYTHON_CMD[@]}" -m pipeline.perseus_ingest --tei "${TEI_INPUT}" --language grc --ensure-table
