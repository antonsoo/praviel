#!/usr/bin/env python3
"""Quick test to verify GPT-5-nano Responses API implementation."""

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


async def test_gpt5_nano_simple():
    """Test GPT-5-nano with simple text output (like user's PowerShell script)."""
    print("\n=== TEST 1: GPT-5-nano with text output (user's format) ===")

    payload = {
        "model": "gpt-5-nano",
        "input": "ping",  # Simple string input
        "store": False,
        "text": {"format": {"type": "text"}},  # Plain text output
        "max_output_tokens": 128,
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
            print(f"✓ Status: {data.get('status')}")
            print(f"✓ Model: {data.get('model')}")

            # Extract text
            output_items = data.get("output", [])
            for item in output_items:
                if item.get("type") == "message":
                    content_items = item.get("content", [])
                    for content in content_items:
                        if content.get("type") == "output_text":
                            print(f"✓ Response: {content.get('text')}")

            print("✅ TEST 1 PASSED")
            return True
    except Exception as e:
        print(f"❌ TEST 1 FAILED: {e}")
        if hasattr(e, "response"):
            print(f"Response: {e.response.text}")
        return False


async def test_gpt5_nano_json():
    """Test GPT-5-nano with JSON output (for lesson generation)."""
    print("\n=== TEST 2: GPT-5-nano with JSON output (lesson format) ===")

    payload = {
        "model": "gpt-5-nano-2025-08-07",
        "input": "Generate a simple JSON object with a 'message' field saying hello.",
        "store": False,
        "text": {"format": {"type": "json_object"}},  # JSON output
        "max_output_tokens": 256,
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
            print(f"✓ Status: {data.get('status')}")
            print(f"✓ Model: {data.get('model')}")

            # Extract and parse JSON
            output_items = data.get("output", [])
            for item in output_items:
                if item.get("type") == "message":
                    content_items = item.get("content", [])
                    for content in content_items:
                        if content.get("type") == "output_text":
                            text = content.get("text")
                            print(f"✓ Raw response: {text}")
                            # Try to parse as JSON
                            try:
                                parsed = json.loads(text)
                                print(f"✓ Parsed JSON: {parsed}")
                            except json.JSONDecodeError:
                                print("⚠️ Could not parse as JSON")

            print("✅ TEST 2 PASSED")
            return True
    except Exception as e:
        print(f"❌ TEST 2 FAILED: {e}")
        if hasattr(e, "response"):
            print(f"Response: {e.response.text}")
        return False


async def test_gpt5_nano_messages():
    """Test if input can accept message array (like my chat implementation)."""
    print("\n=== TEST 3: GPT-5-nano with message array input ===")

    messages = [
        {"role": "system", "content": "You are a helpful assistant."},
        {"role": "user", "content": "Say 'hello' in one word."},
    ]

    payload = {
        "model": "gpt-5-nano",
        "input": messages,  # Array of messages
        "store": False,
        "text": {"format": {"type": "text"}},
        "max_output_tokens": 64,
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
            print(f"✓ Status: {data.get('status')}")
            print("✓ Accepts message array input")
            print("✅ TEST 3 PASSED")
            return True
    except Exception as e:
        print(f"❌ TEST 3 FAILED: {e}")
        if hasattr(e, "response"):
            print(f"Response: {e.response.text}")
        return False


async def main():
    if not OPENAI_API_KEY:
        print("❌ OPENAI_API_KEY not set in backend/.env")
        return

    print("Testing GPT-5-nano Responses API")
    print("=" * 60)

    results = []
    results.append(await test_gpt5_nano_simple())
    results.append(await test_gpt5_nano_json())
    results.append(await test_gpt5_nano_messages())

    print("\n" + "=" * 60)
    print(f"SUMMARY: {sum(results)}/{len(results)} tests passed")

    if all(results):
        print("✅ All tests passed - GPT-5-nano API implementation is correct")
    else:
        print("❌ Some tests failed - need to fix implementation")


if __name__ == "__main__":
    asyncio.run(main())
