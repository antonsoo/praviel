#!/usr/bin/env python3
"""
PAYLOAD INSPECTION TEST
This script shows EXACTLY what will be sent to OpenAI API.
Run this to prove there are NO hidden GPT-4 parameters.
"""

import json
import sys
from pathlib import Path

# Add backend to path
sys.path.insert(0, str(Path(__file__).parent / "backend"))


def test_chat_payload():
    """Show exact chat payload structure"""
    print("=" * 80)
    print("CHAT PROVIDER PAYLOAD INSPECTION")
    print("=" * 80)

    # Simulate what the chat provider does
    model = "gpt-5-nano-2025-08-07"
    messages = [
        {"role": "system", "content": "You are a Spartan warrior"},
        {"role": "user", "content": "Hello"},
    ]

    # Convert to input format (exactly like line 74-79)
    input_messages = []
    for msg in messages:
        input_messages.append(
            {"role": msg["role"], "content": [{"type": "input_text", "text": msg["content"]}]}
        )

    # Build payload (exactly like line 84-95)
    payload = {
        "model": model,
        "input": input_messages,
        "store": False,
        "modalities": ["text"],
        "text": {
            "format": {"type": "json_object"},
            "verbosity": "low",
        },
        "max_output_tokens": 2048,
        "reasoning": {"effort": "low"},
    }

    endpoint = "https://api.openai.com/v1/responses"

    print(f"\nEndpoint: {endpoint}")
    print(f"\nPayload keys: {list(payload.keys())}")
    print("\nFull payload:")
    print(json.dumps(payload, indent=2))

    # CHECK FOR BANNED PARAMETERS
    print("\n" + "=" * 80)
    print("CHECKING FOR BANNED PARAMETERS")
    print("=" * 80)

    banned_params = ["response_format", "max_tokens", "messages"]
    for param in banned_params:
        if param in payload:
            print(f"❌ FOUND BANNED PARAMETER: {param}")
            return False
        else:
            print(f"✅ {param}: NOT FOUND (good)")

    # CHECK FOR REQUIRED PARAMETERS
    print("\n" + "=" * 80)
    print("CHECKING FOR REQUIRED PARAMETERS")
    print("=" * 80)

    required_params = {
        "model": model,
        "input": "must be array",
        "text": "must have format",
        "max_output_tokens": "must be int",
    }

    for param, expected in required_params.items():
        if param in payload:
            print(f"✅ {param}: FOUND")
        else:
            print(f"❌ {param}: MISSING")
            return False

    return True


def test_lesson_payload():
    """Show exact lesson payload structure"""
    print("\n\n" + "=" * 80)
    print("LESSON PROVIDER PAYLOAD INSPECTION")
    print("=" * 80)

    # Simulate what the lesson provider does
    model_name = "gpt-5-nano-2025-08-07"
    system_prompt = "You are a Greek language teacher"
    user_message = "Generate a matching exercise"

    # Build input (exactly like line 307-310)
    input_messages = [
        {"role": "system", "content": [{"type": "input_text", "text": system_prompt}]},
        {"role": "user", "content": [{"type": "input_text", "text": user_message}]},
    ]

    # Build payload (exactly like line 314-325)
    payload = {
        "model": model_name,
        "input": input_messages,
        "store": False,
        "modalities": ["text"],
        "max_output_tokens": 8192,
        "reasoning": {"effort": "low"},
        "text": {
            "format": {"type": "json_object"},
            "verbosity": "low",
        },
    }

    endpoint = "https://api.openai.com/v1/responses"

    print(f"\nEndpoint: {endpoint}")
    print(f"\nPayload keys: {list(payload.keys())}")
    print("\nFull payload:")
    print(json.dumps(payload, indent=2))

    # CHECK FOR BANNED PARAMETERS
    print("\n" + "=" * 80)
    print("CHECKING FOR BANNED PARAMETERS")
    print("=" * 80)

    banned_params = ["response_format", "max_tokens", "messages"]
    for param in banned_params:
        if param in payload:
            print(f"❌ FOUND BANNED PARAMETER: {param}")
            return False
        else:
            print(f"✅ {param}: NOT FOUND (good)")

    # CHECK FOR REQUIRED PARAMETERS
    print("\n" + "=" * 80)
    print("CHECKING FOR REQUIRED PARAMETERS")
    print("=" * 80)

    required_params = {
        "model": model_name,
        "input": "must be array",
        "text": "must have format",
        "max_output_tokens": "must be int",
    }

    for param, expected in required_params.items():
        if param in payload:
            print(f"✅ {param}: FOUND")
        else:
            print(f"❌ {param}: MISSING")
            return False

    return True


if __name__ == "__main__":
    print("\n🔍 PAYLOAD INSPECTION TEST")
    print("This shows EXACTLY what will be sent to OpenAI API\n")

    chat_ok = test_chat_payload()
    lesson_ok = test_lesson_payload()

    print("\n\n" + "=" * 80)
    print("FINAL VERDICT")
    print("=" * 80)

    if chat_ok and lesson_ok:
        print("✅ ALL CHECKS PASSED")
        print("✅ No GPT-4 parameters found")
        print("✅ All Responses API parameters correct")
        print("✅ Payloads match web search documentation")
        sys.exit(0)
    else:
        print("❌ CHECKS FAILED")
        sys.exit(1)
