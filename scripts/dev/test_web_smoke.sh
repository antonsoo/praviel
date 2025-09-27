#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
ARTIFACTS="${ROOT}/artifacts"
REPORT_PATH="${ARTIFACTS}/e2e_web_report.json"
LOG_PATH="${ARTIFACTS}/e2e_web_console.log"
BASE_URL="${API_BASE_URL:-http://127.0.0.1:8000}"

mkdir -p "${ARTIFACTS}"
rm -f "${REPORT_PATH}" "${LOG_PATH}"
: >"${LOG_PATH}"

if command -v python3 >/dev/null 2>&1; then
  PYTHON_BIN=python3
elif command -v python >/dev/null 2>&1; then
  PYTHON_BIN=python
else
  echo "[web-test] Python interpreter not found on PATH." | tee -a "${LOG_PATH}" >&2
  exit 1
fi

usage() {
  cat <<'USAGE'
Usage: test_web_smoke.sh [--base-url <url>] [--report <path>]

Runs the Flutter web integration smoke test using flutter drive. Produces
artifacts/e2e_web_report.json and artifacts/e2e_web_console.log regardless of
result. Requires a compatible chromedriver listening on tcp/4444; falls back to
web-server on Chrome absence.
USAGE
}

port_open() {
  "${PYTHON_BIN}" - <<'PY'
import socket
try:
    sock = socket.create_connection(('127.0.0.1', 4444), timeout=0.5)
except OSError:
    print('0', end='')
else:
    sock.close()
    print('1', end='')
PY
}

start_chromedriver() {
  if [[ -n "${CHROMEDRIVER:-}" && -x "${CHROMEDRIVER}" ]]; then
    echo "[web-test] Using CHROMEDRIVER=${CHROMEDRIVER}" | tee -a "${LOG_PATH}"
    DRIVER_BIN="${CHROMEDRIVER}"
  else
    for candidate in "${ROOT}/tools/chromedriver/chromedriver" \
                      "${ROOT}/tools/chromedriver/chromedriver-linux64/chromedriver" \
                      "${ROOT}/tools/chromedriver/chromedriver-mac-arm64/chromedriver" \
                      "${ROOT}/tools/chromedriver/chromedriver-mac-x64/chromedriver" \
                      "${ROOT}/tools/chromedriver/chromedriver-win64/chromedriver.exe"; do
      if [[ -x "${candidate}" ]]; then
        DRIVER_BIN="${candidate}"
        break
      fi
    done
  if [[ -z "${DRIVER_BIN:-}" ]]; then
    if DRIVER_PATH=$(command -v chromedriver 2>/dev/null); then
      DRIVER_BIN="${DRIVER_PATH}"
    fi
  fi
  fi
  if [[ -z "${DRIVER_BIN:-}" ]]; then
    return 0
  fi
  if [[ $(port_open) == '1' ]]; then
    echo "[web-test] chromedriver already listening on 4444" | tee -a "${LOG_PATH}"
    return 0
  fi
  "${DRIVER_BIN}" --port=9515 --allowed-origins=* >/dev/null 2>&1 &
  CHROMEDRIVER_PID=$!
  disown "${CHROMEDRIVER_PID}" 2>/dev/null || true
  sleep 2
}

stop_chromedriver() {
  if [[ -n "${CHROMEDRIVER_PID:-}" ]]; then
    kill "${CHROMEDRIVER_PID}" >/dev/null 2>&1 || true
    wait "${CHROMEDRIVER_PID}" 2>/dev/null || true
    unset CHROMEDRIVER_PID
  fi
}

trap stop_chromedriver EXIT

while [[ $# -gt 0 ]]; do
  case "$1" in
    --base-url)
      [[ $# -lt 2 ]] && { echo "--base-url requires a value" | tee -a "${LOG_PATH}" >&2; exit 1; }
      BASE_URL="$2"
      shift 2
      ;;
    --report)
      [[ $# -lt 2 ]] && { echo "--report requires a value" | tee -a "${LOG_PATH}" >&2; exit 1; }
      REPORT_PATH="$2"
      shift 2
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    *)
      echo "Unknown option: $1" | tee -a "${LOG_PATH}" >&2
      usage
      exit 1
      ;;
  esac
done

declare -a REASONS=()
add_reason() {
  local value="$1"
  [[ -z "${value}" ]] && return
  REASONS+=("${value}")
}

result="success"
device="chrome"
run_tests=true
if ! command -v flutter >/dev/null 2>&1; then
  echo "[web-test] Flutter SDK is required for the smoke test." | tee -a "${LOG_PATH}" >&2
  result="failure"
  device="unavailable"
  add_reason "flutter_missing"
  run_tests=false
fi

if [[ "${run_tests}" == "true" ]]; then
  start_chromedriver
  if DEVICES_JSON="$(flutter devices --machine 2>/dev/null)"; then
    if [[ -z "${DEVICES_JSON}" ]]; then
      device="web-server"
      add_reason "devices_query_empty"
    else
      if ! DEVICES_JSON="${DEVICES_JSON}" "${PYTHON_BIN}" - <<'PY'
import json
import os
import sys

payload = os.environ.get("DEVICES_JSON", "")
try:
    data = json.loads(payload)
except Exception:
    sys.exit(2)
for entry in data:
    if isinstance(entry, dict) and entry.get("id") == "chrome":
        sys.exit(0)
sys.exit(1)
PY
      then
        status=$?
        device="web-server"
        if [[ $status -eq 2 ]]; then
          add_reason "devices_parse_failed"
        else
          add_reason "chrome_missing"
        fi
      fi
    fi
  else
    device="web-server"
    add_reason "devices_query_failed"
  fi
fi

TEST_STATUS=0
if [[ "${run_tests}" == "true" ]]; then
  start_chromedriver
  pushd "${ROOT}/client/flutter_reader" >/dev/null
  export API_BASE_URL="${BASE_URL}"
  set +e
  flutter drive \
    -d web-server \
    --browser-name="${device}" \
    --driver integration_test/driver.dart \
    --target integration_test/lesson_flow_smoke_test.dart \
    --driver-port 9515 \
    --dart-define=INTEGRATION_TEST=true 2>&1 | tee -a "${LOG_PATH}"
  TEST_STATUS=${PIPESTATUS[0]}
  set -e
  unset API_BASE_URL
  popd >/dev/null

  if [[ ${TEST_STATUS} -ne 0 ]]; then
    result="failure"
    add_reason "test_failed"
  fi
else
  echo "[web-test] Skipping flutter test execution due to missing prerequisites." | tee -a "${LOG_PATH}"
  TEST_STATUS=1
fi

finalize() {
  local reasons_payload=""
  if [[ ${#REASONS[@]} -gt 0 ]]; then
    reasons_payload="$(printf '%s\n' "${REASONS[@]}")"
  fi

  local final_result
  final_result="$(
    REPORT_PATH="${REPORT_PATH}" \
    LOG_PATH="${LOG_PATH}" \
    RESULT="${result}" \
    DEVICE="${device}" \
    BASE_URL="${BASE_URL}" \
    REASONS_PAYLOAD="${reasons_payload}" \
    "${PYTHON_BIN}" - <<'PY'
import datetime
import json
import os
import pathlib

report_path = pathlib.Path(os.environ['REPORT_PATH'])
log_path = pathlib.Path(os.environ['LOG_PATH'])
result = os.environ['RESULT']
device = os.environ['DEVICE']
base_url = os.environ['BASE_URL']
reasons_payload = os.environ.get('REASONS_PAYLOAD', '')

payload = {
    'timestamp': datetime.datetime.utcnow().replace(microsecond=0).isoformat() + 'Z',
    'result': result,
    'platform': device,
    'base_url': base_url,
    'log_path': str(log_path.resolve()) if log_path.exists() else str(log_path),
}
reasons = [line.strip() for line in reasons_payload.splitlines() if line.strip()]
if reasons:
    payload['reasons'] = reasons

summary = None
if log_path.exists():
    try:
        content = log_path.read_text(encoding='utf-8', errors='ignore')
    except Exception:
        content = ''
    for line in content.splitlines():
        line = line.strip()
        if not line:
            continue
        if line.startswith('{"result"'):
            try:
                summary = json.loads(line)
            except json.JSONDecodeError:
                continue
if summary:
    payload['summary'] = summary
    if isinstance(summary.get('result'), str):
        payload['result'] = summary['result']
    failures = summary.get('failureDetails')
    if failures:
        payload['failures'] = failures

report_path.write_text(json.dumps(payload, indent=2), encoding='utf-8')
print(payload['result'], end='')
PY
  )"
  local status=$?
  if [[ ${status} -ne 0 ]]; then
    echo "[web-test] Failed to write report" | tee -a "${LOG_PATH}" >&2
    exit ${status}
  fi

  if [[ "${final_result}" != "success" ]]; then
    exit 1
  fi
  exit 0
}

finalize
