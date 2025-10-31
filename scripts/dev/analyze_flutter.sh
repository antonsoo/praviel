#!/usr/bin/env bash
set -euo pipefail

ROOT="$(git rev-parse --show-toplevel)"
PROJECT="$ROOT/client/flutter_reader"
ARTIFACTS="$ROOT/artifacts"
OUT="$ARTIFACTS/dart_analyze.json"

mkdir -p "$ARTIFACTS"
cd "$PROJECT"

FLUTTER_BIN=""
if [[ -n "${FLUTTER_ROOT:-}" ]] && [[ -x "${FLUTTER_ROOT}/bin/flutter" ]]; then
  FLUTTER_BIN="${FLUTTER_ROOT}/bin/flutter"
elif command -v flutter >/dev/null 2>&1; then
  FLUTTER_BIN="$(command -v flutter)"
fi

if [[ -n "$FLUTTER_BIN" ]]; then
  echo "[analyze] Using flutter binary at $FLUTTER_BIN"
  echo "[analyze] Running flutter pub get"
  if ! "$FLUTTER_BIN" pub get; then
    echo "[analyze] flutter pub get failed; aborting." >&2
    exit 1
  fi
else
  if [[ "${CI:-}" == "true" ]] || [[ "${GITHUB_ACTIONS:-}" == "true" ]]; then
    echo "[analyze] Flutter SDK not available in CI environment, skipping Flutter analysis"
    exit 0
  fi
  echo "[analyze] Flutter SDK is required but not found on PATH." >&2
  exit 1
fi
DART_BIN=""
if [[ -n "${FLUTTER_ROOT:-}" ]] && [[ -x "${FLUTTER_ROOT}/bin/dart" ]]; then
  DART_BIN="${FLUTTER_ROOT}/bin/dart"
elif command -v dart >/dev/null 2>&1; then
  DART_BIN="$(command -v dart)"
fi

if [[ -z "$DART_BIN" ]]; then
  echo "[analyze] Dart SDK is unavailable; install Flutter (which bundles dart)." >&2
  exit 1
fi

TMP="$(mktemp)"
ANALYZE_STATUS=0
set +e
if ! "$DART_BIN" analyze --format=json >"$TMP"; then
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
