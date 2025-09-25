#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
ARTIFACT_DIR="$ROOT/artifacts"

mkdir -p "$ARTIFACT_DIR"

pushd "$ROOT/client/flutter_reader" >/dev/null
flutter pub get
dart analyze --format=json > "$ARTIFACT_DIR/dart_analyze.json"
popd >/dev/null
