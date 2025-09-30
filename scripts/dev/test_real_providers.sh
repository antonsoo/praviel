#!/usr/bin/env bash
# Tests each provider with real API key from environment variables
# Usage: ANTHROPIC_API_KEY=sk-... OPENAI_API_KEY=sk-... ./test_real_providers.sh

set -euo pipefail

BASE_URL="${API_BASE_URL:-http://127.0.0.1:8000}"
OUTPUT_DIR="${PWD}/artifacts"
mkdir -p "$OUTPUT_DIR"

echo "=== Testing BYOK Providers with Real Keys ==="
echo "Output directory: $OUTPUT_DIR"
echo ""

# Test Anthropic
if [ -n "${ANTHROPIC_API_KEY:-}" ]; then
    echo "🧪 Testing Anthropic (Claude Sonnet 4.5)..."
    curl -s -X POST "${BASE_URL}/lesson/generate" \
        -H "Authorization: Bearer $ANTHROPIC_API_KEY" \
        -H "Content-Type: application/json" \
        -d '{
            "provider": "anthropic",
            "model": "claude-sonnet-4-5",
            "language": "grc",
            "profile": "beginner",
            "sources": ["daily"],
            "exercise_types": ["match", "translate"],
            "k_canon": 0
        }' | jq '.' > "$OUTPUT_DIR/lesson_anthropic.json"

    if [ $? -eq 0 ]; then
        echo "✅ Anthropic: SUCCESS"
        echo "   Saved to: $OUTPUT_DIR/lesson_anthropic.json"
    else
        echo "❌ Anthropic: FAILED"
    fi
    echo ""
else
    echo "⏭️  Skipping Anthropic (ANTHROPIC_API_KEY not set)"
    echo ""
fi

# Test OpenAI
if [ -n "${OPENAI_API_KEY:-}" ]; then
    echo "🧪 Testing OpenAI (GPT-5-mini)..."
    curl -s -X POST "${BASE_URL}/lesson/generate" \
        -H "Authorization: Bearer $OPENAI_API_KEY" \
        -H "Content-Type: application/json" \
        -d '{
            "provider": "openai",
            "model": "gpt-5-mini",
            "language": "grc",
            "profile": "beginner",
            "sources": ["daily"],
            "exercise_types": ["match", "alphabet"],
            "k_canon": 0
        }' | jq '.' > "$OUTPUT_DIR/lesson_openai.json"

    if [ $? -eq 0 ]; then
        echo "✅ OpenAI: SUCCESS"
        echo "   Saved to: $OUTPUT_DIR/lesson_openai.json"
    else
        echo "❌ OpenAI: FAILED"
    fi
    echo ""
else
    echo "⏭️  Skipping OpenAI (OPENAI_API_KEY not set)"
    echo ""
fi

# Test Google
if [ -n "${GOOGLE_API_KEY:-}" ]; then
    echo "🧪 Testing Google (Gemini 2.5 Flash)..."
    curl -s -X POST "${BASE_URL}/lesson/generate" \
        -H "Authorization: Bearer $GOOGLE_API_KEY" \
        -H "Content-Type: application/json" \
        -d '{
            "provider": "google",
            "model": "gemini-2.5-flash",
            "language": "grc",
            "profile": "beginner",
            "sources": ["daily"],
            "exercise_types": ["match"],
            "k_canon": 0
        }' | jq '.' > "$OUTPUT_DIR/lesson_google.json"

    if [ $? -eq 0 ]; then
        echo "✅ Google: SUCCESS"
        echo "   Saved to: $OUTPUT_DIR/lesson_google.json"
    else
        echo "❌ Google: FAILED"
    fi
    echo ""
else
    echo "⏭️  Skipping Google (GOOGLE_API_KEY not set)"
    echo ""
fi

# Test Echo (no key needed)
echo "🧪 Testing Echo (offline fallback)..."
curl -s -X POST "${BASE_URL}/lesson/generate" \
    -H "Content-Type: application/json" \
    -d '{
        "provider": "echo",
        "language": "grc",
        "profile": "beginner",
        "sources": ["daily"],
        "exercise_types": ["match", "alphabet", "translate"],
        "k_canon": 0
    }' | jq '.' > "$OUTPUT_DIR/lesson_echo.json"

if [ $? -eq 0 ]; then
    echo "✅ Echo: SUCCESS"
    echo "   Saved to: $OUTPUT_DIR/lesson_echo.json"
else
    echo "❌ Echo: FAILED"
fi
echo ""

echo "=== Provider Testing Complete ==="
echo "Review outputs in: $OUTPUT_DIR"
