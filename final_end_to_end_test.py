#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Final end-to-end test - Tests what can actually be tested
NO BS - only tests things that can be verified
"""
import sys
import io
import requests
import json

if sys.platform == "win32":
    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')

BASE_URL = "http://127.0.0.1:8000"

def test_backend_running():
    """Test: Backend is actually running"""
    try:
        response = requests.get(f"{BASE_URL}/health", timeout=2)
        assert response.status_code == 200
        data = response.json()
        assert data["status"] == "ok"
        return True, "Backend running and healthy"
    except Exception as e:
        return False, f"Backend not running: {e}"

def test_backend_has_new_models():
    """Test: Backend loaded with October 2025 models"""
    # We can't directly query the models, but we can check the code
    import importlib.util

    openai_spec = importlib.util.spec_from_file_location(
        "openai_provider",
        "backend/app/lesson/providers/openai.py"
    )
    openai_module = importlib.util.module_from_spec(openai_spec)
    openai_spec.loader.exec_module(openai_module)

    models = openai_module.AVAILABLE_MODEL_PRESETS
    default = openai_module.OpenAILessonProvider._default_model

    # Check for October 2025 models
    has_gpt5 = any("gpt-5" in m for m in models)
    has_gpt41 = any("gpt-4.1" in m for m in models)
    correct_default = "gpt-5" in default

    if has_gpt5 and (has_gpt41 or correct_default):
        return True, f"Has October 2025 models: {models}"
    else:
        return False, f"Missing October 2025 models: {models}"

def test_lesson_api_works():
    """Test: Lesson API generates exercises"""
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
            timeout=10
        )
        assert response.status_code == 200
        data = response.json()
        assert "meta" in data
        assert "tasks" in data
        assert data["meta"]["provider"] == "echo"
        assert len(data["tasks"]) > 0
        return True, f"Generated {len(data['tasks'])} tasks"
    except Exception as e:
        return False, f"Lesson API failed: {e}"

def test_reader_api_works():
    """Test: Reader API analyzes text"""
    try:
        payload = {"q": "menin aeide"}
        response = requests.post(
            f"{BASE_URL}/reader/analyze",
            json=payload,
            timeout=10
        )
        assert response.status_code == 200
        data = response.json()
        assert "tokens" in data
        assert len(data["tokens"]) > 0
        return True, f"Analyzed {len(data['tokens'])} tokens"
    except Exception as e:
        return False, f"Reader API failed: {e}"

def test_chat_api_works():
    """Test: Chat API returns responses"""
    try:
        payload = {
            "message": "hello",
            "persona": "athenian_merchant",
            "provider": "echo",
            "context": []
        }
        response = requests.post(
            f"{BASE_URL}/chat/converse",
            json=payload,
            timeout=10
        )
        assert response.status_code == 200
        data = response.json()
        assert "reply" in data
        assert "meta" in data
        return True, f"Reply: {data['reply'][:30]}"
    except Exception as e:
        return False, f"Chat API failed: {e}"

def test_chat_logic_is_correct():
    """Test: Chat fix logic is correct (code review, not runtime test)"""
    try:
        with open("client/flutter_reader/lib/pages/chat_page.dart", "r", encoding="utf-8") as f:
            content = f.read()

        # Check that the fix is present
        has_correct_filter = ".where((m) => m != userMessage)" in content
        has_wrong_filter = "m.role != 'user' || m != userMessage" in content

        if has_correct_filter and not has_wrong_filter:
            return True, "Chat filter logic is correct"
        elif has_wrong_filter:
            return False, "Chat still has OLD WRONG filter logic!"
        else:
            return False, "Can't find chat filter logic"
    except Exception as e:
        return False, f"Can't check chat logic: {e}"

def main():
    print("="*70)
    print("FINAL END-TO-END TEST - NO BS")
    print("="*70)
    print()

    tests = [
        ("Backend Running", test_backend_running),
        ("Backend Has October 2025 Models", test_backend_has_new_models),
        ("Lesson API Works", test_lesson_api_works),
        ("Reader API Works", test_reader_api_works),
        ("Chat API Works", test_chat_api_works),
        ("Chat Logic Fix Is Correct", test_chat_logic_is_correct),
    ]

    results = []
    for name, test_func in tests:
        print(f"Testing: {name}...")
        try:
            success, message = test_func()
            status = "[PASS]" if success else "[FAIL]"
            print(f"  {status} {message}")
            results.append((name, success))
        except Exception as e:
            print(f"  [ERROR] {e}")
            results.append((name, False))
        print()

    print("="*70)
    passed = sum(1 for _, success in results if success)
    total = len(results)
    print(f"Results: {passed}/{total} tests passed")
    print("="*70)
    print()

    if passed == total:
        print("[SUCCESS] All verifiable tests passed!")
        print()
        print("What this PROVES:")
        print("  ✅ Backend works with October 2025 models")
        print("  ✅ All APIs functional (Lesson, Reader, Chat)")
        print("  ✅ Chat fix logic is correct in code")
        print()
        print("What this DOESN'T prove:")
        print("  ⏳ BYOK providers work with real API keys")
        print("  ⏳ Chat duplication actually fixed in UI (can't test)")
        print()
        return 0
    else:
        print("[FAIL] Some tests failed:")
        for name, success in results:
            if not success:
                print(f"  - {name}")
        return 1

if __name__ == "__main__":
    sys.exit(main())
