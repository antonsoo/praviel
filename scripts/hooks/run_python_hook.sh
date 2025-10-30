#!/usr/bin/env bash
# Cross-platform Python wrapper for pre-commit hooks
# Tries python3, python, then py (Windows launcher)

SCRIPT="$1"
shift

if command -v python3 &> /dev/null; then
    exec python3 "$SCRIPT" "$@"
elif command -v python &> /dev/null; then
    exec python "$SCRIPT" "$@"
elif command -v py &> /dev/null; then
    exec py "$SCRIPT" "$@"
else
    echo "Error: No Python interpreter found (tried python3, python, py)" >&2
    exit 1
fi
