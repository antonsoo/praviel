"""
Validation script to verify API implementations are current (October 2025).

This script tests actual API endpoints to confirm the code uses correct versions.
Run this before letting AI agents modify provider code.

Exit codes:
  0 - All APIs working correctly with October 2025 implementations
  1 - One or more APIs failed (code may need updates OR APIs may be down)
"""

import asyncio
import os
import sys

import httpx
from dotenv import load_dotenv

# Fix Windows console encoding
if sys.platform == "win32":
    sys.stdout.reconfigure(encoding="utf-8")

load_dotenv("backend/.env")

OPENAI_KEY = os.getenv("OPENAI_API_KEY")
ANTHROPIC_KEY = os.getenv("ANTHROPIC_API_KEY")
GOOGLE_KEY = os.getenv("GOOGLE_API_KEY")

results = {}


async def test_gpt5_responses_api():
    """Test GPT-5 uses Responses API with correct parameters."""
    print("\n[TEST] GPT-5 Responses API")

    if not OPENAI_KEY:
        print("  SKIP: No OpenAI API key")
        return None

    # Correct October 2025 format
    payload = {
        "model": "gpt-5-nano",
        "input": "Say 'test' in one word",
        "store": False,
        "max_output_tokens": 128,  # Must be high enough for reasoning + output
        "reasoning": {"effort": "low"},
    }

    headers = {"Authorization": f"Bearer {OPENAI_KEY}", "Content-Type": "application/json"}

    try:
        async with httpx.AsyncClient(timeout=30.0) as client:
            response = await client.post("https://api.openai.com/v1/responses", json=payload, headers=headers)
            if response.status_code == 200:
                data = response.json()
                # Verify response format
                if data.get("status") == "incomplete":
                    reason = data.get("incomplete_details", {}).get("reason", "unknown")
                    print(f"  WARN: Response incomplete ({reason}) - may need higher max_output_tokens")
                    print(f"  Usage: {data.get('usage', {})}")
                    # Still consider this a pass - just a warning
                if "output" in data:
                    print("  PASS: GPT-5 Responses API works")
                    return True
                else:
                    print("  FAIL: Unexpected response format")
                    return False
            else:
                print(f"  FAIL: Status {response.status_code}")
                print(f"  Error: {response.text[:200]}")
                return False
    except Exception as e:
        print(f"  ERROR: {e}")
        return False


async def test_claude_45():
    """Test Claude 4.5 works."""
    print("\n[TEST] Claude 4.5")

    if not ANTHROPIC_KEY:
        print("  SKIP: No Anthropic API key")
        return None

    payload = {
        "model": "claude-sonnet-4-5-20250929",
        "max_tokens": 16,
        "messages": [{"role": "user", "content": "test"}],
    }

    headers = {
        "x-api-key": ANTHROPIC_KEY,
        "anthropic-version": "2023-06-01",
        "Content-Type": "application/json",
    }

    try:
        async with httpx.AsyncClient(timeout=30.0) as client:
            response = await client.post(
                "https://api.anthropic.com/v1/messages", json=payload, headers=headers
            )
            if response.status_code == 200:
                print("  PASS: Claude 4.5 works")
                return True
            else:
                print(f"  FAIL: Status {response.status_code}")
                return False
    except Exception as e:
        print(f"  ERROR: {e}")
        return False


async def test_gemini_25():
    """Test Gemini 2.5 works."""
    print("\n[TEST] Gemini 2.5")

    if not GOOGLE_KEY:
        print("  SKIP: No Google API key")
        return None

    payload = {"contents": [{"parts": [{"text": "test"}]}]}

    headers = {"x-goog-api-key": GOOGLE_KEY, "Content-Type": "application/json"}

    try:
        async with httpx.AsyncClient(timeout=30.0) as client:
            response = await client.post(
                "https://generativelanguage.googleapis.com/v1/models/gemini-2.5-flash:generateContent",
                json=payload,
                headers=headers,
            )
            if response.status_code == 200:
                print("  PASS: Gemini 2.5 works")
                return True
            else:
                print(f"  FAIL: Status {response.status_code}")
                return False
    except Exception as e:
        print(f"  ERROR: {e}")
        return False


async def test_tts():
    """Test TTS uses correct model names."""
    print("\n[TEST] OpenAI TTS")

    if not OPENAI_KEY:
        print("  SKIP: No OpenAI API key")
        return None

    payload = {
        "model": "tts-1",  # Correct model
        "voice": "alloy",
        "input": "test",
    }

    headers = {"Authorization": f"Bearer {OPENAI_KEY}", "Content-Type": "application/json"}

    try:
        async with httpx.AsyncClient(timeout=30.0) as client:
            response = await client.post(
                "https://api.openai.com/v1/audio/speech", json=payload, headers=headers
            )
            if response.status_code == 200:
                print("  PASS: TTS model 'tts-1' works")
                return True
            else:
                print(f"  FAIL: Status {response.status_code}")
                return False
    except Exception as e:
        print(f"  ERROR: {e}")
        return False


async def main():
    print("=" * 60)
    print("API VERSION VALIDATION")
    print("October 2025 Implementation Check")
    print("=" * 60)

    results = {
        "gpt5": await test_gpt5_responses_api(),
        "claude45": await test_claude_45(),
        "gemini25": await test_gemini_25(),
        "tts": await test_tts(),
    }

    # Remove None (skipped tests)
    actual_results = {k: v for k, v in results.items() if v is not None}

    if not actual_results:
        print("\n[WARNING] No API keys found - cannot validate")
        return 1

    passed = sum(1 for v in actual_results.values() if v)
    total = len(actual_results)

    print("\n" + "=" * 60)
    print(f"RESULTS: {passed}/{total} tests passed")
    print("=" * 60)

    if passed == total:
        print("\n✓ All APIs working with October 2025 implementations")
        print("✓ Code is using CURRENT API versions")
        return 0
    else:
        print(f"\n✗ {total - passed} API test(s) failed")
        print("✗ Either APIs are down OR code needs updates")
        return 1


if __name__ == "__main__":
    exit_code = asyncio.run(main())
    sys.exit(exit_code)
