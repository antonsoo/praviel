#!/usr/bin/env bash
set -euo pipefail

if ! command -v sh >/dev/null 2>&1; then
  echo "[git-env] sh executable not found on PATH" >&2
  exit 1
fi

if ! command -v bash >/dev/null 2>&1; then
  echo "[git-env] bash executable not found on PATH" >&2
  exit 1
fi

printf '[git-env] sh=%s; bash=%s
' "$(command -v sh)" "$(command -v bash)"
