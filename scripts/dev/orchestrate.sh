#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
ARTIFACT_DIR="${ROOT}/artifacts"
STATE_FILE="${ARTIFACT_DIR}/orchestrate_state.json"
SERVE_SCRIPT="${ROOT}/scripts/dev/serve_uvicorn.sh"
STEP_RUNNER="${ROOT}/scripts/dev/step.sh"
DEFAULT_STEP_IDLE_TIMEOUT="${STEP_IDLE_TIMEOUT:-120}"
DEFAULT_STEP_HARD_TIMEOUT="${STEP_HARD_TIMEOUT:-900}"

if command -v python3 >/dev/null 2>&1; then
  PYTHON_BIN=python3
else
  PYTHON_BIN=python
fi

mkdir -p "${ARTIFACT_DIR}"

usage() {
  cat <<'USAGE'
Usage: orchestrate.sh <command> [options]

Commands:
  up [--port <port>] [--host <host>] [--flutter] [--log-level <level>]
      Bring up dependencies, apply migrations, launch API, and record state.
  smoke
      Run API contract smokes against the live server.
  e2e-web [--require-flutter]
      Run headless Flutter web integration test against the live server.
  down [--keep-db]
      Stop the API server and docker compose services (optionally keep db container).
  status
      Show orchestrator state and server health.
  logs
      Tail the latest uvicorn log via serve helper.
USAGE
}

error() {
  echo "[orchestrate] $*" >&2
  exit 1
}

require_state() {
  if [[ ! -f "${STATE_FILE}" ]]; then
    error "orchestrator state not found; run 'orchestrate.sh up' first"
  fi
}

write_state() {
  local host="$1"
  local port="$2"
  local pid="$3"
  local log_file="$4"
  local started_at
  started_at="$(date -u '+%Y-%m-%dT%H:%M:%SZ')"

  STATE_PATH="${STATE_FILE}" \
  ORCH_HOST="${host}" \
  ORCH_PORT="${port}" \
  ORCH_PID="${pid}" \
  ORCH_LOG="${log_file}" \
  ORCH_STARTED="${started_at}" \
  ORCH_ARTIFACTS="${ARTIFACT_DIR}" \
  "${PYTHON_BIN}" - <<'PY'
import json
import os

state_path = os.environ["STATE_PATH"]
data = {
    "host": os.environ["ORCH_HOST"],
    "port": int(os.environ["ORCH_PORT"]),
    "pid": int(os.environ["ORCH_PID"]),
    "log_file": os.environ.get("ORCH_LOG", ""),
    "artifacts": os.environ["ORCH_ARTIFACTS"],
    "started_at": os.environ["ORCH_STARTED"],
}
with open(state_path, "w", encoding="utf-8") as fh:
    json.dump(data, fh, indent=2)
PY
}

run_step() {
  local name="${1:-}"
  if [[ -z "${name}" ]]; then
    error "run_step requires a step name"
  fi
  shift || true
  local idle="${DEFAULT_STEP_IDLE_TIMEOUT}"
  local hard="${DEFAULT_STEP_HARD_TIMEOUT}"
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --idle-timeout)
        [[ $# -lt 2 ]] && error "--idle-timeout requires a value"
        idle="$2"
        shift 2
        ;;
      --hard-timeout)
        [[ $# -lt 2 ]] && error "--hard-timeout requires a value"
        hard="$2"
        shift 2
        ;;
      --)
        shift
        break
        ;;
      *)
        break
        ;;
    esac
  done
  if [[ $# -eq 0 ]]; then
    error "run_step '${name}' requires a command"
  fi
  local log_path="${ARTIFACT_DIR}/step_${name}.log"
  local heartbeat_path="${ARTIFACT_DIR}/step_${name}.hb"
  local -a cmd=("$@")
  "${STEP_RUNNER}" \
    --name "${name}" \
    --log "${log_path}" \
    --heartbeat "${heartbeat_path}" \
    --idle-timeout "${idle}" \
    --hard-timeout "${hard}" \
    -- "${cmd[@]}"
}

wait_for_db() {
  if [[ "${ORCHESTRATE_SKIP_DB:-0}" == "1" ]]; then
    if "${PYTHON_BIN}" - <<'PY'
import os
import socket
import sys
import time

host = os.environ.get("ORCHESTRATE_DB_HOST", "127.0.0.1")
port = int(os.environ.get("ORCHESTRATE_DB_PORT", "5432"))
finish = time.time() + 30
while time.time() < finish:
    try:
        with socket.create_connection((host, port), timeout=1):
            sys.exit(0)
    except OSError:
        time.sleep(0.5)
print(f"database {host}:{port} did not become ready", file=sys.stderr)
sys.exit(1)
PY
    then
      echo "::DBREADY::OK"
      return 0
    else
      error "database failed to become ready"
    fi
  fi

  local attempts=30
  for attempt in $(seq 1 "${attempts}"); do
    if docker compose exec -T db pg_isready -U app -d app >/dev/null 2>&1; then
      echo "::DBREADY::OK"
      return 0
    fi
    sleep 1
  done

  error "database failed to become ready"
}
function wait_for_db_port() {
  local host="127.0.0.1"
  local port="5433"

  if [[ "${ORCHESTRATE_SKIP_DB:-0}" == "1" ]]; then
    host="${ORCHESTRATE_DB_HOST:-127.0.0.1}"
    port="${ORCHESTRATE_DB_PORT:-5432}"
  else
    local mapping
    mapping="$(docker compose port db 5432 2>/dev/null | head -n1 || true)"
    if [[ -n "${mapping}" ]]; then
      host="${mapping%:*}"
      port="${mapping##*:}"
      [[ "${host}" == "0.0.0.0" ]] && host="127.0.0.1"
      host="${host#[}"
      host="${host%]}"
    fi
  fi

  DB_HOST_VALUE="${host}" \
  DB_PORT_VALUE="${port}" \
  "${PYTHON_BIN}" - <<'PY'
import os
import socket
import sys
import time

host = os.environ["DB_HOST_VALUE"]
port = int(os.environ["DB_PORT_VALUE"])
deadline = time.time() + 30
while time.time() < deadline:
    try:
        with socket.create_connection((host, port), timeout=1):
            sys.exit(0)
    except OSError:
        time.sleep(0.5)
print(f"database port {host}:{port} did not become reachable", file=sys.stderr)
sys.exit(1)
PY

  # Export detected host/port for use by Alembic and other tools
  export DETECTED_DB_HOST="${host}"
  export DETECTED_DB_PORT="${port}"
  echo "::DBPORT::${host}:${port}"
}

resolve_base_url() {
  if [[ -f "${STATE_FILE}" ]]; then
    STATE_PATH="${STATE_FILE}" "${PYTHON_BIN}" - <<'PY'
import json
import os

with open(os.environ["STATE_PATH"], "r", encoding="utf-8") as fh:
    state = json.load(fh)
host = state.get("host") or "127.0.0.1"
port = state.get("port") or 8000
print(f"http://{host}:{port}")
PY
  else
    echo "http://127.0.0.1:8000"
  fi
}

command_up() {
  local port="8000"
  local host="127.0.0.1"
  local flutter="0"
  local log_level="info"

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --port)
        [[ $# -lt 2 ]] && error "--port requires a value"
        port="$2"
        shift 2
        ;;
      --host)
        [[ $# -lt 2 ]] && error "--host requires a value"
        host="$2"
        shift 2
        ;;
      --flutter)
        flutter="1"
        shift
        ;;
      --log-level)
        [[ $# -lt 2 ]] && error "--log-level requires a value"
        log_level="$2"
        shift 2
        ;;
      --help|-h)
        usage
        exit 0
        ;;
      *)
        error "unknown option for up: $1"
        ;;
    esac
  done

  cd "${ROOT}"

  # Note: Cannot use 'local' here due to trap scope issues with set -u
  cleanup_needed=1
  cleanup() {
    local status=$?
    if (( cleanup_needed == 1 )); then
      echo "[orchestrate] up failed; cleaning up" >&2
      "${SERVE_SCRIPT}" stop >/dev/null 2>&1 || true
      docker compose down -v >/dev/null 2>&1 || true
    fi
    exit $status
  }
  trap cleanup EXIT

  if [[ "${ORCHESTRATE_SKIP_DB:-0}" != "1" ]]; then
    run_step "db_up" --hard-timeout 120 -- docker compose up -d db
  fi
  wait_for_db
  wait_for_db_port

  # Construct DATABASE_URL with detected port if available (BEFORE running alembic!)
  # Must override BOTH DATABASE_URL and DATABASE_URL_SYNC since env.py checks DATABASE_URL_SYNC first
  local -a db_env_overrides=()
  if [[ -n "${DETECTED_DB_HOST:-}" && -n "${DETECTED_DB_PORT:-}" ]]; then
    db_env_overrides+=("DATABASE_URL=postgresql+asyncpg://app:app@${DETECTED_DB_HOST}:${DETECTED_DB_PORT}/app")
    db_env_overrides+=("DATABASE_URL_SYNC=postgresql+psycopg://app:app@${DETECTED_DB_HOST}:${DETECTED_DB_PORT}/app")
  fi

  # Run alembic with the correct DATABASE_URL and DATABASE_URL_SYNC
  if [[ ${#db_env_overrides[@]} -gt 0 ]]; then
    run_step "alembic" --hard-timeout 180 -- env "${db_env_overrides[@]}" ${PYTHON_BIN} -m alembic -c alembic.ini upgrade head
  else
    run_step "alembic" --hard-timeout 180 -- ${PYTHON_BIN} -m alembic -c alembic.ini upgrade head
  fi

  local -a env_vars=(LESSONS_ENABLED=1 TTS_ENABLED=1 ALLOW_DEV_CORS=1 REDIS_URL=redis://localhost:6379)
  if [[ ${#db_env_overrides[@]} -gt 0 ]]; then
    env_vars+=("${db_env_overrides[@]}")
  fi
  if [[ "${flutter}" == "1" ]]; then
    env_vars+=(SERVE_FLUTTER_WEB=1)
  fi

  run_step "uvicorn_start" --hard-timeout 180 -- env "${env_vars[@]}" "${SERVE_SCRIPT}" start --host "${host}" --port "${port}" --log-level "${log_level}"

  local pid_file="${ARTIFACT_DIR}/uvicorn.pid"
  local port_file="${ARTIFACT_DIR}/uvicorn.port"
  [[ -f "${pid_file}" ]] || error "uvicorn pid file missing"
  [[ -f "${port_file}" ]] || error "uvicorn port file missing"

  local actual_pid
  actual_pid="$(<"${pid_file}")"
  local actual_port
  actual_port="$(<"${port_file}")"
  local log_file
  log_file=$(ls -1t "${ARTIFACT_DIR}"/uvicorn_*.log 2>/dev/null | head -n 1 || true)

  local health_url="http://${host}:${actual_port}/health"
  if ! curl -fsS "${health_url}" >/dev/null 2>&1; then
    echo "[orchestrate] warning: health probe failed at ${health_url}" >&2
  fi

  write_state "${host}" "${actual_port}" "${actual_pid}" "${log_file}"
  echo "[orchestrate] state written to ${STATE_FILE}"
  echo "::READY::${host}:${actual_port}"

  cleanup_needed=0
  trap - EXIT
}

command_smoke() {
  require_state
  local base_url
  base_url="$(resolve_base_url)"
  echo "[orchestrate] running API contract smokes against ${base_url}"
  export ORCHESTRATOR_STATE_PATH="${STATE_FILE}"
  cd "${ROOT}"
  run_step "flutter_analyze" -- bash "${ROOT}/scripts/dev/analyze_flutter.sh"

  # Construct DATABASE_URL with detected port if available (for test fixtures)
  local db_url="postgresql+asyncpg://app:app@localhost:5433/app"
  local db_url_sync="postgresql+psycopg://app:app@localhost:5433/app"
  if [[ -n "${DETECTED_DB_HOST:-}" && -n "${DETECTED_DB_PORT:-}" ]]; then
    db_url="postgresql+asyncpg://app:app@${DETECTED_DB_HOST}:${DETECTED_DB_PORT}/app"
    db_url_sync="postgresql+psycopg://app:app@${DETECTED_DB_HOST}:${DETECTED_DB_PORT}/app"
  fi

  run_step "contracts_pytest" -- env API_BASE_URL="${base_url}" DATABASE_URL="${db_url}" DATABASE_URL_SYNC="${db_url_sync}" pytest -q backend/app/tests/test_contracts.py
}

command_e2e_web() {
  require_state
  local require_flutter=0
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --require-flutter)
        require_flutter=1
        shift
        ;;
      --help|-h)
        echo "Usage: orchestrate.sh e2e-web [--require-flutter]"
        return 0
        ;;
      *)
        error "unknown option for e2e-web: $1"
        ;;
    esac
  done
  if (( require_flutter == 1 )) && ! command -v flutter >/dev/null 2>&1; then
    error "Flutter SDK is required for e2e-web; install Flutter or rerun without --require-flutter."
  fi
  local base_url
  base_url="$(resolve_base_url)"
  echo "[orchestrate] running Flutter web E2E against ${base_url}"
  cd "${ROOT}"
  run_step "e2e_web" -- env API_BASE_URL="${base_url}" bash "${ROOT}/scripts/dev/test_web_smoke.sh" --base-url "${base_url}"
}

command_down() {
  local keep_db=0
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --keep-db)
        keep_db=1
        shift
        ;;
      --help|-h)
        usage
        exit 0
        ;;
      *)
        error "unknown option for down: $1"
        ;;
    esac
  done
  cd "${ROOT}"
  "${SERVE_SCRIPT}" stop || true
  if (( keep_db == 1 )); then
    docker compose down >/dev/null 2>&1 || true
  else
    docker compose down -v >/dev/null 2>&1 || true
  fi
  rm -f "${STATE_FILE}"
  echo "[orchestrate] teardown complete"
}

command_status() {
  cd "${ROOT}"
  if [[ -f "${STATE_FILE}" ]]; then
    echo "[orchestrate] state:"
    cat "${STATE_FILE}"
  else
    echo "[orchestrate] state file missing"
  fi
  "${SERVE_SCRIPT}" status || true
}

command_logs() {
  cd "${ROOT}"
  "${SERVE_SCRIPT}" logs
}

COMMAND=${1:-}
if [[ -z "${COMMAND}" ]]; then
  usage
  exit 1
fi
shift || true

case "${COMMAND}" in
  up)
    command_up "$@"
    ;;
  smoke)
    command_smoke "$@"
    ;;
  e2e-web)
    command_e2e_web "$@"
    ;;
  down)
    command_down "$@"
    ;;
  status)
    command_status "$@"
    ;;
  logs)
    command_logs "$@"
    ;;
  --help|-h)
    usage
    ;;
  *)
    error "unknown command: ${COMMAND}"
    ;;
esac
