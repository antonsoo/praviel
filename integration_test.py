#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Integration test suite for Ancient Languages API
Tests BYOK providers, chat, and reader functionality
"""
import json
import sys
import time
import requests
import io

# Fix Windows console encoding
if sys.platform == "win32":
    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')

BASE_URL = "http://127.0.0.1:8000"

class TestResult:
    def __init__(self, name: str):
        self.name = name
        self.passed = False
        self.error = None
        self.details = None

    def success(self, details=None):
        self.passed = True
        self.details = details

    def fail(self, error):
        self.passed = False
        self.error = str(error)

    def __str__(self):
        status = "[OK]" if self.passed else "[FAIL]"
        msg = f"{status} {self.name}"
        if self.details:
            msg += f"\n      Details: {self.details}"
        if self.error:
            msg += f"\n      Error: {self.error}"
        return msg


def test_health_check():
    """Test that backend is running"""
    result = TestResult("Health Check")
    try:
        response = requests.get(f"{BASE_URL}/health", timeout=5)
        if response.status_code == 200:
            data = response.json()
            if data.get("status") == "ok":
                result.success(f"Project: {data.get('project')}")
            else:
                result.fail("Health check returned unexpected status")
        else:
            result.fail(f"HTTP {response.status_code}")
    except Exception as e:
        result.fail(e)
    return result


def test_reader_analyze_basic():
    """Test Reader API with transliterated text"""
    result = TestResult("Reader API - Basic")
    try:
        payload = {"q": "menin aeide"}
        response = requests.post(
            f"{BASE_URL}/reader/analyze",
            json=payload,
            headers={"Content-Type": "application/json"},
            timeout=10
        )
        if response.status_code == 200:
            data = response.json()
            if "tokens" in data and len(data["tokens"]) > 0:
                token = data["tokens"][0]
                if "text" in token and "start" in token and "end" in token:
                    result.success(f"Returned {len(data['tokens'])} tokens")
                else:
                    result.fail("Token missing required fields")
            else:
                result.fail("No tokens returned")
        else:
            result.fail(f"HTTP {response.status_code}: {response.text}")
    except Exception as e:
        result.fail(e)
    return result


def test_reader_analyze_greek():
    """Test Reader API with actual Greek text"""
    result = TestResult("Reader API - Greek Text")
    try:
        # Using echo to pass UTF-8 properly
        payload = {"q": "μῆνις"}
        response = requests.post(
            f"{BASE_URL}/reader/analyze",
            json=payload,
            headers={"Content-Type": "application/json; charset=utf-8"},
            timeout=10
        )
        if response.status_code == 200:
            data = response.json()
            if "tokens" in data and len(data["tokens"]) > 0:
                token = data["tokens"][0]
                if "retrieval" in data and len(data["retrieval"]) > 0:
                    result.success(f"Found {len(data['retrieval'])} similar passages")
                else:
                    result.success("Parsed Greek text successfully (no corpus matches)")
            else:
                result.fail("No tokens returned")
        else:
            result.fail(f"HTTP {response.status_code}: {response.text}")
    except Exception as e:
        result.fail(e)
    return result


def test_chat_echo():
    """Test Chat API with echo provider"""
    result = TestResult("Chat API - Echo Provider")
    try:
        payload = {
            "message": "χαῖρε",
            "persona": "athenian_merchant",
            "provider": "echo",
            "context": []
        }
        response = requests.post(
            f"{BASE_URL}/chat/converse",
            json=payload,
            headers={"Content-Type": "application/json; charset=utf-8"},
            timeout=10
        )
        if response.status_code == 200:
            data = response.json()
            if "reply" in data and "meta" in data:
                if data["meta"].get("provider") == "echo":
                    reply_preview = data['reply'][:30] if len(data['reply']) > 30 else data['reply']
                    result.success(f"Reply received (echo)")
                else:
                    result.fail(f"Expected echo provider, got {data['meta'].get('provider')}")
            else:
                result.fail("Missing required response fields")
        else:
            result.fail(f"HTTP {response.status_code}: {response.text}")
    except Exception as e:
        result.fail(e)
    return result


def test_chat_context_handling():
    """Test that chat context doesn't duplicate messages"""
    result = TestResult("Chat Context - No Duplication")
    try:
        # First message
        payload1 = {
            "message": "πῶς ἔχεις",
            "persona": "athenian_merchant",
            "provider": "echo",
            "context": []
        }
        response1 = requests.post(
            f"{BASE_URL}/chat/converse",
            json=payload1,
            headers={"Content-Type": "application/json; charset=utf-8"},
            timeout=10
        )

        if response1.status_code != 200:
            result.fail(f"First request failed: HTTP {response1.status_code}")
            return result

        data1 = response1.json()

        # Second message with context
        payload2 = {
            "message": "χαίρε φίλε",
            "persona": "athenian_merchant",
            "provider": "echo",
            "context": [
                {"role": "user", "content": "πῶς ἔχεις"},
                {"role": "assistant", "content": data1["reply"]}
            ]
        }
        response2 = requests.post(
            f"{BASE_URL}/chat/converse",
            json=payload2,
            headers={"Content-Type": "application/json; charset=utf-8"},
            timeout=10
        )

        if response2.status_code == 200:
            data2 = response2.json()
            # Verify the API doesn't return the current message in the reply
            if data2["reply"] != payload2["message"]:
                result.success("Context handled correctly")
            else:
                result.fail("API echoed the current message (possible duplication)")
        else:
            result.fail(f"Second request failed: HTTP {response2.status_code}")
    except Exception as e:
        result.fail(e)
    return result


def test_lesson_echo():
    """Test Lesson API with echo provider"""
    result = TestResult("Lesson API - Echo Provider")
    try:
        payload = {
            "language": "grc",
            "profile": "beginner",
            "sources": ["daily"],
            "exercise_types": ["match"],
            "provider": "echo"
        }
        response = requests.post(
            f"{BASE_URL}/lesson/generate",
            json=payload,
            headers={"Content-Type": "application/json"},
            timeout=15
        )
        if response.status_code == 200:
            data = response.json()
            if "meta" in data and "tasks" in data:
                if data["meta"].get("provider") == "echo":
                    result.success(f"Generated {len(data['tasks'])} tasks")
                else:
                    result.fail(f"Expected echo provider, got {data['meta'].get('provider')}")
            else:
                result.fail("Missing required response fields")
        else:
            result.fail(f"HTTP {response.status_code}: {response.text}")
    except Exception as e:
        result.fail(e)
    return result


def main():
    print("=" * 70)
    print("Ancient Languages API - Integration Test Suite")
    print("=" * 70)
    print()

    # Check if backend is running
    print("Checking backend availability...")
    try:
        requests.get(f"{BASE_URL}/health", timeout=2)
        print("[OK] Backend is running\n")
    except:
        print("[FAIL] Backend not running at", BASE_URL)
        print("       Start backend: py -m uvicorn app.main:app --reload\n")
        return 1

    # Run all tests
    tests = [
        test_health_check,
        test_reader_analyze_basic,
        test_reader_analyze_greek,
        test_chat_echo,
        test_chat_context_handling,
        test_lesson_echo,
    ]

    results = []
    for test_func in tests:
        print(f"Running: {test_func.__doc__}")
        result = test_func()
        results.append(result)
        print(f"  {result}")
        print()
        time.sleep(0.5)  # Rate limit

    # Summary
    print("=" * 70)
    passed = sum(1 for r in results if r.passed)
    total = len(results)
    print(f"Results: {passed}/{total} tests passed")
    print("=" * 70)

    if passed == total:
        print("[SUCCESS] All integration tests passed!")
        return 0
    else:
        print("[FAIL] Some tests failed")
        for r in results:
            if not r.passed:
                print(f"  - {r.name}: {r.error}")
        return 1


if __name__ == "__main__":
    sys.exit(main())
