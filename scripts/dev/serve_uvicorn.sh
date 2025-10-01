#!/usr/bin/env bash
set -euo pipefail

SCRIPT_NAME=$(basename "$0")
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
ARTIFACT_DIR="${ROOT}/artifacts"
PID_FILE="${ARTIFACT_DIR}/uvicorn.pid"
PORT_FILE="${ARTIFACT_DIR}/uvicorn.port"

mkdir -p "${ARTIFACT_DIR}"

usage() {
  cat <<EOF
Usage: $SCRIPT_NAME <start|stop|status|logs> [options]

Commands:
  start     Start uvicorn in the background
  stop      Stop the running uvicorn process
  status    Show process and /health status
  logs      Tail the latest uvicorn log file

Options for start:
  --port <port>     Bind to a specific port (default: auto)
  --host <host>     Bind to a specific host (default: 127.0.0.1)
  --no-reload       Disable uvicorn reload (default: reload enabled)
  --reload          Explicitly enable reload
  --flutter         Enable Flutter web static serving
  --log-level <lv>  Override uvicorn log level (default: info)
EOF
}

atomic_write() {
  local value="$1"
  local path="$2"
  local tmp="${path}.tmp"
  printf '%s\n' "$value" >"$tmp"
  mv -f "$tmp" "$path"
}

is_pid_running() {
  local pid="$1"
  if [[ -z "$pid" ]]; then
    return 1
  fi
  kill -0 "$pid" >/dev/null 2>&1
}

pick_port() {
  if command -v python3 >/dev/null 2>&1; then
    python3 - <<'PY'
import socket
with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as sock:
    sock.bind(("127.0.0.1", 0))
    print(sock.getsockname()[1])
PY
    return
  fi
  if command -v python >/dev/null 2>&1; then
    python - <<'PY'
import socket
with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as sock:
    sock.bind(("127.0.0.1", 0))
    print(sock.getsockname()[1])
PY
    return
  fi
  echo 8000
}

ensure_pythonpath() {
  local backend="${ROOT}/backend"
  if [[ -z "${PYTHONPATH:-}" ]]; then
    export PYTHONPATH="$backend"
    return
  fi
  case ":${PYTHONPATH}:" in
    *:"${backend}":*) ;;
    *) export PYTHONPATH="${backend}:${PYTHONPATH}" ;;
  esac
}

wait_for_health() {
  local url="$1"
  local pid="$2"
  for attempt in $(seq 1 30); do
    if curl -fsS "$url" >/dev/null 2>&1; then
      return 0
    fi
    if ! is_pid_running "$pid"; then
      return 2
    fi
    sleep 1
  done
  return 1
}

start_server() {
  local host="127.0.0.1"
  local port=""
  local reload="true"
  local flutter=""
  local log_level=""

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --port)
        [[ $# -lt 2 ]] && { echo "error: --port requires a value" >&2; exit 1; }
        port="$2"
        shift 2
        ;;
      --host)
        [[ $# -lt 2 ]] && { echo "error: --host requires a value" >&2; exit 1; }
        host="$2"
        shift 2
        ;;
      --no-reload)
        reload="false"
        shift
        ;;
      --reload)
        reload="true"
        shift
        ;;
      --flutter)
        flutter="1"
        shift
        ;;
      --log-level)
        [[ $# -lt 2 ]] && { echo "error: --log-level requires a value" >&2; exit 1; }
        log_level="$2"
        shift 2
        ;;
      --help|-h)
        usage
        exit 0
        ;;
      *)
        echo "Unknown option for start: $1" >&2
        exit 1
        ;;
    esac
  done

  if [[ -f "$PID_FILE" ]]; then
    local existing
    existing=$(<"$PID_FILE")
    if is_pid_running "$existing"; then
      echo "uvicorn already running (pid=$existing)" >&2
      exit 0
    fi
    rm -f "$PID_FILE" "$PORT_FILE"
  fi

  if [[ -z "$port" ]]; then
    port=$(pick_port)
  fi

  ensure_pythonpath
  export ALLOW_DEV_CORS="${ALLOW_DEV_CORS:-1}"
  export LESSONS_ENABLED="${LESSONS_ENABLED:-1}"
  export TTS_ENABLED="${TTS_ENABLED:-1}"
  if [[ -n "$flutter" ]]; then
    export SERVE_FLUTTER_WEB=1
  fi
  if [[ -n "$log_level" ]]; then
    export LOG_LEVEL="${log_level^^}"
  fi

  local log_file="${ARTIFACT_DIR}/uvicorn_$(date +%Y%m%d_%H%M%S).log"

  local -a python_cmd
  if [[ -n "${UVICORN_PYTHON:-}" ]]; then
    read -r -a python_cmd <<<"${UVICORN_PYTHON}"
  else
    if command -v python3 >/dev/null 2>&1; then
      python_cmd=(python3)
    else
      python_cmd=(python)
    fi
  fi

  if ! command -v "${python_cmd[0]}" >/dev/null 2>&1; then
    echo "error: python executable '${python_cmd[0]}' not found" >&2
    exit 1
  fi

  local -a cmd=("${python_cmd[@]}" -m uvicorn app.main:app --app-dir "${ROOT}/backend" --host "$host" --port "$port")
  if [[ "${reload}" == "true" ]]; then
    if [[ ! "${UVICORN_RELOAD:-1}" =~ ^(0|false|no)$ ]]; then
      cmd+=(--reload)
    fi
  fi
  local level="${log_level:-${UVICORN_LOG_LEVEL:-info}}"
  cmd+=(--log-level "$level")

  cd "$ROOT"
  if command -v nohup >/dev/null 2>&1; then
    nohup "${cmd[@]}" >>"$log_file" 2>&1 < /dev/null &
  elif command -v setsid >/dev/null 2>&1; then
    setsid "${cmd[@]}" >>"$log_file" 2>&1 &
  else
    "${cmd[@]}" >>"$log_file" 2>&1 &
  fi
  local pid=$!

  atomic_write "$pid" "$PID_FILE"
  atomic_write "$port" "$PORT_FILE"

  local health_url="http://${host}:${port}/health"
  if ! wait_for_health "$health_url" "$pid"; then
    echo "Timed out waiting for $health_url" >&2
    kill "$pid" >/dev/null 2>&1 || true
    exit 1
  fi

  echo "uvicorn started pid=$pid host=$host port=$port log=$log_file"
}

stop_server() {
  if [[ ! -f "$PID_FILE" ]]; then
    echo "uvicorn not running"
    return 0
  fi
  local pid
  pid=$(<"$PID_FILE")
  if ! is_pid_running "$pid"; then
    rm -f "$PID_FILE" "$PORT_FILE"
    echo "uvicorn not running (stale pid $pid removed)"
    return 0
  fi
  kill "$pid" >/dev/null 2>&1 || true
  for attempt in $(seq 1 20); do
    if ! is_pid_running "$pid"; then
      break
    fi
    sleep 0.5
  done
  if is_pid_running "$pid"; then
    kill -9 "$pid" >/dev/null 2>&1 || true
  fi
  rm -f "$PID_FILE" "$PORT_FILE"
  echo "uvicorn stopped pid=$pid"
}

status_server() {
  if [[ ! -f "$PID_FILE" ]]; then
    echo "uvicorn not running"
    return 1
  fi
  local pid
  pid=$(<"$PID_FILE")
  if ! is_pid_running "$pid"; then
    rm -f "$PID_FILE" "$PORT_FILE"
    echo "uvicorn not running (stale pid $pid removed)"
    return 1
  fi
  local port="unknown"
  if [[ -f "$PORT_FILE" ]]; then
    port=$(<"$PORT_FILE")
  fi
  local host="127.0.0.1"
  local health_url="http://${host}:${port}/health"
  if curl -fsS "$health_url" >/dev/null 2>&1; then
    echo "uvicorn running pid=$pid host=$host port=$port health=ok"
  else
    echo "uvicorn running pid=$pid host=$host port=$port health=unreachable"
    return 2
  fi
}

logs_server() {
  local latest
  latest=$(ls -1t "${ARTIFACT_DIR}"/uvicorn_*.log 2>/dev/null | head -n 1 || true)
  if [[ -z "$latest" ]]; then
    echo "No uvicorn log files found in ${ARTIFACT_DIR}" >&2
    exit 1
  fi
  tail -n 200 -f "$latest"
}

COMMAND=${1:-}
if [[ -z "$COMMAND" ]]; then
  usage
  exit 1
fi
shift || true

case "$COMMAND" in
  start)
    start_server "$@"
    ;;
  stop)
    stop_server
    ;;
  status)
    status_server
    ;;
  logs)
    logs_server
    ;;
  --help|-h)
    usage
    ;;
  *)
    usage
    exit 1
    ;;
esac
