#!/usr/bin/env bash
set -euo pipefail

ROOT="$(git rev-parse --show-toplevel)"
PROJECT="$ROOT/client/flutter_reader"
ARTIFACTS="$ROOT/artifacts"
OUT="$ARTIFACTS/dart_analyze.json"

mkdir -p "$ARTIFACTS"
cd "$PROJECT"

if command -v dart >/dev/null 2>&1; then
  PUB_CMD=(dart --disable-analytics pub get)
elif command -v flutter >/dev/null 2>&1; then
  PUB_CMD=(flutter pub get)
else
  # Check if we should skip when Flutter is unavailable (e.g., CI environments without Flutter)
  if [[ "${CI:-}" == "true" ]] || [[ "${GITHUB_ACTIONS:-}" == "true" ]]; then
    echo "[analyze] Flutter/Dart not available in CI environment, skipping Flutter analysis"
    exit 0
  fi
  echo "[analyze] Neither 'dart' nor 'flutter' is available on PATH. Install Flutter SDK." >&2
  exit 1
fi

echo "[analyze] Running ${PUB_CMD[*]}"
if ! "${PUB_CMD[@]}"; then
  echo "[analyze] pub get failed; aborting." >&2
  exit 1
fi

if ! command -v dart >/dev/null 2>&1; then
  echo "[analyze] Dart SDK is unavailable; install Flutter (which bundles dart)." >&2
  exit 1
fi

TMP="$(mktemp)"
ANALYZE_STATUS=0
set +e
if ! dart analyze --format=json >"$TMP"; then
  ANALYZE_STATUS=$?
fi
set -e

mv "$TMP" "$OUT"

python - "$OUT" <<'PY'
import json
import pathlib
import sys

path = pathlib.Path(sys.argv[1])
try:
    data = json.loads(path.read_text(encoding='utf-8'))
except Exception as exc:  # noqa: BLE001
    print(f"[analyze] Failed to read {path.name}: {exc}", file=sys.stderr)
    sys.exit(1)

diagnostics = data.get('diagnostics', [])
errors = [d for d in diagnostics if d.get('severity') == 'error']
if errors:
    print(f"[analyze] Analyzer reported {len(errors)} error(s). See {path}.", file=sys.stderr)
    sys.exit(2)
PY
PY_STATUS=$?
if [[ $PY_STATUS -ne 0 ]]; then
  exit $PY_STATUS
fi

if [[ $ANALYZE_STATUS -ne 0 ]]; then
  echo "[analyze] dart analyze exited with status $ANALYZE_STATUS" >&2
  exit $ANALYZE_STATUS
fi

echo "[analyze] Report saved to $OUT"
