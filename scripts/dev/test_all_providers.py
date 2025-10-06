#!/usr/bin/env python3
"""Comprehensive test of all AI providers (OpenAI, Anthropic, Google)."""

import asyncio
import json
import os
import sys

import httpx
from dotenv import load_dotenv

# Fix Windows console encoding
if sys.platform == "win32":
    sys.stdout.reconfigure(encoding="utf-8")

load_dotenv("backend/.env")

OPENAI_API_KEY = os.getenv("OPENAI_API_KEY")
ANTHROPIC_API_KEY = os.getenv("ANTHROPIC_API_KEY")
GOOGLE_API_KEY = os.getenv("GOOGLE_API_KEY")


async def test_openai_gpt5_nano():
    """Test OpenAI GPT-5-nano with Responses API."""
    print("\n=== OPENAI: GPT-5-nano (Responses API) ===")

    if not OPENAI_API_KEY:
        print("SKIP: OPENAI_API_KEY not set")
        return None

    payload = {
        "model": "gpt-5-nano-2025-08-07",
        "input": 'Generate JSON: {"greeting": "hello in Greek"}',
        "store": False,
        "text": {"format": {"type": "json_object"}},
        "max_output_tokens": 256,  # Increased to allow for reasoning + output
        "reasoning": {"effort": "low"},
    }

    headers = {
        "Authorization": f"Bearer {OPENAI_API_KEY}",
        "Content-Type": "application/json",
    }

    try:
        async with httpx.AsyncClient(timeout=30.0) as client:
            response = await client.post("https://api.openai.com/v1/responses", headers=headers, json=payload)
            response.raise_for_status()
            data = response.json()

            # Extract text
            output_items = data.get("output", [])
            if not output_items:
                print("❌ FAIL - No output array in response")
                return False

            for item in output_items:
                if item.get("type") == "message":
                    content_items = item.get("content", [])
                    for content in content_items:
                        if content.get("type") == "output_text":
                            text = content.get("text")
                            parsed = json.loads(text)
                            print(f"✅ PASS - Model: {data.get('model')}")
                            print(f"   Response: {parsed}")
                            return True

        print("❌ FAIL - No output_text found in response")
        return False
    except Exception as e:
        print(f"❌ FAIL - {e}")
        if hasattr(e, "response"):
            try:
                error_data = e.response.json()
                print(f"   Error details: {error_data}")
            except Exception:
                print(f"   Response: {e.response.text[:200]}")
        return False


async def test_anthropic_claude45():
    """Test Anthropic Claude 4.5 Sonnet."""
    print("\n=== ANTHROPIC: Claude 4.5 Sonnet ===")

    if not ANTHROPIC_API_KEY:
        print("SKIP: ANTHROPIC_API_KEY not set")
        return None

    payload = {
        "model": "claude-sonnet-4-5-20250929",
        "max_tokens": 128,
        "messages": [{"role": "user", "content": "Say hello in Greek"}],
    }

    headers = {
        "x-api-key": ANTHROPIC_API_KEY,
        "anthropic-version": "2023-06-01",
        "Content-Type": "application/json",
    }

    try:
        async with httpx.AsyncClient(timeout=30.0) as client:
            response = await client.post(
                "https://api.anthropic.com/v1/messages", headers=headers, json=payload
            )
            response.raise_for_status()
            data = response.json()

            text = data["content"][0]["text"]
            print(f"✅ PASS - Model: {data.get('model')}")
            print(f"   Response: {text}")
            return True
    except Exception as e:
        print(f"❌ FAIL - {e}")
        if hasattr(e, "response"):
            try:
                error_data = e.response.json()
                print(f"   Error details: {error_data}")
            except Exception:
                print(f"   Response: {e.response.text[:200]}")
        return False


async def test_google_gemini25():
    """Test Google Gemini 2.5 Flash."""
    print("\n=== GOOGLE: Gemini 2.5 Flash ===")

    if not GOOGLE_API_KEY:
        print("SKIP: GOOGLE_API_KEY not set")
        return None

    payload = {"contents": [{"parts": [{"text": "Say hello in Greek"}]}]}

    headers = {
        "x-goog-api-key": GOOGLE_API_KEY,
        "Content-Type": "application/json",
    }

    try:
        async with httpx.AsyncClient(timeout=30.0) as client:
            response = await client.post(
                "https://generativelanguage.googleapis.com/v1/models/gemini-2.5-flash:generateContent",
                headers=headers,
                json=payload,
            )
            response.raise_for_status()
            data = response.json()

            text = data["candidates"][0]["content"]["parts"][0]["text"]
            print("✅ PASS")
            print(f"   Response: {text}")
            return True
    except Exception as e:
        print(f"❌ FAIL - {e}")
        if hasattr(e, "response"):
            try:
                error_data = e.response.json()
                print(f"   Error details: {error_data}")
            except Exception:
                print(f"   Response: {e.response.text[:200]}")
        return False


async def main():
    print("=" * 60)
    print("COMPREHENSIVE PROVIDER TEST")
    print("October 2025 Model APIs")
    print("=" * 60)

    results = {
        "OpenAI GPT-5-nano": await test_openai_gpt5_nano(),
        "Anthropic Claude 4.5": await test_anthropic_claude45(),
        "Google Gemini 2.5": await test_google_gemini25(),
    }

    print("\n" + "=" * 60)
    print("SUMMARY")
    print("=" * 60)

    for provider, result in results.items():
        if result is None:
            status = "SKIP"
        elif result:
            status = "✅ PASS"
        else:
            status = "❌ FAIL"
        print(f"{provider:30} {status}")

    tested = [r for r in results.values() if r is not None]
    if tested:
        passed = sum(1 for r in tested if r)
        print(f"\nResult: {passed}/{len(tested)} providers passed")

        if passed == len(tested):
            print("✅ All tested providers working correctly!")
            return 0
        else:
            print("❌ Some providers failed")
            return 1
    else:
        print("\n⚠️ No API keys configured - cannot test")
        return 2


if __name__ == "__main__":
    sys.exit(asyncio.run(main()))
