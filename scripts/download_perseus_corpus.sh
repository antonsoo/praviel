#!/bin/bash
#
# Download Perseus Digital Library Corpus
# Downloads TEI XML texts from Perseus GitHub repositories
#
# Usage: bash scripts/download_perseus_corpus.sh
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
DATA_DIR="$PROJECT_ROOT/data/vendor/perseus"

echo "=== Downloading Perseus Digital Library Corpus ==="
echo "Target directory: $DATA_DIR"
echo ""

# Create data directory
mkdir -p "$DATA_DIR"
cd "$DATA_DIR"

# Download Greek Literature
echo "=== Downloading Greek Literature ==="
if [ -d "canonical-greekLit" ]; then
    echo "Greek Literature already exists, updating..."
    cd canonical-greekLit
    git pull
    cd ..
else
    echo "Cloning Greek Literature repository..."
    git clone --depth 1 https://github.com/PerseusDL/canonical-greekLit.git
fi

# Download Latin Literature
echo ""
echo "=== Downloading Latin Literature ==="
if [ -d "canonical-latinLit" ]; then
    echo "Latin Literature already exists, updating..."
    cd canonical-latinLit
    git pull
    cd ..
else
    echo "Cloning Latin Literature repository..."
    git clone --depth 1 https://github.com/PerseusDL/canonical-latinLit.git
fi

echo ""
echo "=== Download Complete ==="
echo ""
echo "Downloaded repositories:"
echo "  - $DATA_DIR/canonical-greekLit/"
echo "  - $DATA_DIR/canonical-latinLit/"
echo ""
echo "Next steps:"
echo "  1. Run: python scripts/ingest_perseus_texts.py"
echo "  2. This will parse TEI XML and populate the database"
echo ""
echo "License: CC-BY-SA-4.0"
echo "Source: https://github.com/PerseusDL"
