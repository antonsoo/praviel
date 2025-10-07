#!/usr/bin/env python3
"""Test the chat endpoint to verify OpenAI integration works"""

import json
import os

import requests

# Test with echo provider first (no API key needed)
print("=" * 80)
print("TEST 1: Echo Provider (baseline)")
print("=" * 80)

response = requests.post(
    "http://127.0.0.1:8000/chat/converse",
    json={"provider": "echo", "persona": "spartan_warrior", "message": "Hello warrior"},
)

print(f"Status: {response.status_code}")
print(f"Response: {json.dumps(response.json(), indent=2)}")

# Test with OpenAI provider (requires API key)
print("\n" + "=" * 80)
print("TEST 2: OpenAI Provider (testing the fix)")
print("=" * 80)

# Get API key from environment
api_key = os.environ.get("OPENAI_API_KEY")
if not api_key:
    print("❌ OPENAI_API_KEY not set in environment")
    print("Set it with: $env:OPENAI_API_KEY='your-key-here'")
    exit(1)

response = requests.post(
    "http://127.0.0.1:8000/chat/converse",
    headers={"Authorization": f"Bearer {api_key}"},
    json={"provider": "openai", "persona": "spartan_warrior", "message": "Hello"},
)

print(f"Status: {response.status_code}")

if response.status_code == 200:
    print("✅ SUCCESS!")
    print(f"Response: {json.dumps(response.json(), indent=2)}")
else:
    print("❌ FAILED!")
    print(f"Error: {response.text}")

print("\n" + "=" * 80)
print("Check backend logs for detailed error messages:")
log_path = (
    "C:\\Dev\\AI_Projects\\AncientLanguagesAppDirs\\"
    "Current-working-dirs\\AncientLanguages\\artifacts\\uvicorn_20251007_115157.log"
)
print(f"Get-Content {log_path} -Tail 50")
print("=" * 80)
