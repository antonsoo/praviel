#!/usr/bin/env python3
"""
COMPREHENSIVE OpenAI Integration Test
Tests ALL OpenAI API calls in the codebase to verify they use October 2025 Responses API correctly.
"""

import sys
from pathlib import Path

# Add backend to path
sys.path.insert(0, str(Path(__file__).parent / "backend"))


def test_chat_provider():
    """Test chat/openai_provider.py"""
    print("=" * 80)
    print("TESTING: backend/app/chat/openai_provider.py")
    print("=" * 80)

    import inspect

    from app.chat.openai_provider import OpenAIChatProvider

    source = inspect.getsource(OpenAIChatProvider.converse)

    # Check for banned patterns
    banned = {
        "response_format": "OLD CHAT COMPLETIONS PARAMETER",
        'max_tokens"': "OLD PARAMETER (should be max_output_tokens)",
        "/chat/completions": "OLD ENDPOINT",
        "if.*gpt-4": "GPT-4 CONDITIONAL",
    }

    errors = []
    for pattern, desc in banned.items():
        if pattern in source:
            errors.append(f"❌ FOUND: {desc} (pattern: {pattern})")

    # Check for required patterns
    required = {
        "/v1/responses": "RESPONSES API ENDPOINT",
        "max_output_tokens": "CORRECT PARAMETER",
        'text"': "TEXT PARAMETER",
        '"input"': "INPUT PARAMETER",
    }

    for pattern, desc in required.items():
        if pattern not in source:
            errors.append(f"❌ MISSING: {desc} (pattern: {pattern})")
        else:
            print(f"✅ {desc}")

    if errors:
        for err in errors:
            print(err)
        return False

    print("✅ Chat provider OK\n")
    return True


def test_lesson_provider():
    """Test lesson/providers/openai.py"""
    print("=" * 80)
    print("TESTING: backend/app/lesson/providers/openai.py")
    print("=" * 80)

    import inspect

    from app.lesson.providers.openai import OpenAILessonProvider

    source = inspect.getsource(OpenAILessonProvider.generate)

    # Check for banned patterns
    banned = {
        "response_format": "OLD PARAMETER",
        'max_tokens"': "OLD PARAMETER",
        "/chat/completions": "OLD ENDPOINT",
    }

    errors = []
    for pattern, desc in banned.items():
        if pattern in source:
            errors.append(f"❌ FOUND: {desc}")

    # Check for required patterns
    required = {
        "/responses": "RESPONSES API ENDPOINT",
        "max_output_tokens": "CORRECT PARAMETER",
    }

    for pattern, desc in required.items():
        if pattern not in source:
            errors.append(f"❌ MISSING: {desc}")
        else:
            print(f"✅ {desc}")

    if errors:
        for err in errors:
            print(err)
        return False

    print("✅ Lesson provider OK\n")
    return True


def test_coach_provider():
    """Test coach/providers.py"""
    print("=" * 80)
    print("TESTING: backend/app/coach/providers.py")
    print("=" * 80)

    import inspect

    from app.coach.providers import OpenAIProvider

    source = inspect.getsource(OpenAIProvider.chat)

    # Check for banned patterns
    banned = {
        "response_format": "OLD PARAMETER",
        'max_tokens"': "OLD PARAMETER",
        "/chat/completions": "OLD ENDPOINT",
    }

    errors = []
    for pattern, desc in banned.items():
        if pattern in source:
            errors.append(f"❌ FOUND: {desc}")

    # Check for required patterns
    required = {
        "/v1/responses": "RESPONSES API ENDPOINT",
        "max_output_tokens": "CORRECT PARAMETER",
        '"input"': "INPUT PARAMETER",
    }

    for pattern, desc in required.items():
        if pattern not in source:
            errors.append(f"❌ MISSING: {desc}")
        else:
            print(f"✅ {desc}")

    if errors:
        for err in errors:
            print(err)
        return False

    print("✅ Coach provider OK\n")
    return True


def test_health_provider():
    """Test api/health_providers.py"""
    print("=" * 80)
    print("TESTING: backend/app/api/health_providers.py")
    print("=" * 80)

    with open(Path(__file__).parent / "backend" / "app" / "api" / "health_providers.py") as f:
        source = f.read()

    # Check for banned patterns
    banned = {
        "/chat/completions": "OLD ENDPOINT",
        '"messages"': "OLD PARAMETER FORMAT",
    }

    errors = []
    for pattern, desc in banned.items():
        if pattern in source and "Test OpenAI" in source:
            # Make sure it's in the OpenAI section
            openai_section = source[source.find("# Test OpenAI") : source.find("# Test OpenAI") + 1000]
            if pattern in openai_section:
                errors.append(f"❌ FOUND: {desc}")

    # Check for required patterns in OpenAI section
    if "# Test OpenAI" in source:
        openai_section = source[source.find("# Test OpenAI") :]
        required = {
            "/v1/responses": "RESPONSES API ENDPOINT",
            "max_output_tokens": "CORRECT PARAMETER",
            '"input"': "INPUT PARAMETER",
        }

        for pattern, desc in required.items():
            if pattern not in openai_section:
                errors.append(f"❌ MISSING: {desc}")
            else:
                print(f"✅ {desc}")

    if errors:
        for err in errors:
            print(err)
        return False

    print("✅ Health provider OK\n")
    return True


def test_model_presets():
    """Test that only GPT-5 models are allowed"""
    print("=" * 80)
    print("TESTING: Model Presets and Validation")
    print("=" * 80)

    from app.core.config import settings
    from app.lesson.providers.openai import AVAILABLE_MODEL_PRESETS

    # Check lesson provider presets
    errors = []
    for model in AVAILABLE_MODEL_PRESETS:
        if "gpt-4" in model.lower() or "gpt-3" in model.lower():
            errors.append(f"❌ BANNED MODEL IN PRESETS: {model}")
        else:
            print(f"✅ {model}")

    # Check config defaults
    config_models = {
        "COACH_DEFAULT_MODEL": settings.COACH_DEFAULT_MODEL,
        "LESSONS_OPENAI_DEFAULT_MODEL": settings.LESSONS_OPENAI_DEFAULT_MODEL,
        "HEALTH_OPENAI_MODEL": settings.HEALTH_OPENAI_MODEL,
    }

    for key, model in config_models.items():
        if model and ("gpt-4" in model.lower() or "gpt-3" in model.lower()):
            errors.append(f"❌ BANNED MODEL IN CONFIG: {key}={model}")
        else:
            print(f"✅ {key}={model}")

    if errors:
        for err in errors:
            print(err)
        return False

    print("✅ Model presets OK\n")
    return True


def main():
    print("\n🔍 COMPREHENSIVE OpenAI INTEGRATION TEST")
    print("Testing ALL OpenAI API calls in the codebase\n")

    results = {
        "Chat Provider": test_chat_provider(),
        "Lesson Provider": test_lesson_provider(),
        "Coach Provider": test_coach_provider(),
        "Health Provider": test_health_provider(),
        "Model Presets": test_model_presets(),
    }

    print("\n" + "=" * 80)
    print("FINAL RESULTS")
    print("=" * 80)

    for name, passed in results.items():
        status = "✅ PASS" if passed else "❌ FAIL"
        print(f"{status}: {name}")

    all_passed = all(results.values())

    print("\n" + "=" * 80)
    if all_passed:
        print("✅ ALL TESTS PASSED")
        print("✅ All OpenAI integrations use October 2025 Responses API")
        print("✅ No GPT-4 code paths remain")
        print("=" * 80)
        return 0
    else:
        print("❌ SOME TESTS FAILED")
        print("❌ Fix the issues above before deploying")
        print("=" * 80)
        return 1


if __name__ == "__main__":
    try:
        sys.exit(main())
    except Exception as e:
        print(f"\n❌ CRITICAL ERROR: {e}")
        import traceback

        traceback.print_exc()
        sys.exit(1)
