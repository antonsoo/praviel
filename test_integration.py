#!/usr/bin/env python3
"""Integration test for lesson generation across all languages and exercise types"""

import sys

import requests

BASE_URL = "http://localhost:8001"
LANGUAGES = ["grc", "lat", "hbo", "san"]
EXERCISE_TYPES = [
    "alphabet",
    "match",
    "cloze",
    "translate",
    "grammar",
    "listening",
    "speaking",
    "wordbank",
    "truefalse",
    "multiplechoice",
    "dialogue",
    "conjugation",
    "declension",
    "synonym",
    "contextmatch",
    "reorder",
    "dictation",
    "etymology",
]


def test_language_exercise_combo(language: str, exercise_type: str) -> bool:
    """Test a single language/exercise combination"""
    payload = {
        "language": language,
        "profile": "beginner",
        "sources": ["daily"],
        "exercise_types": [exercise_type],
        "k_canon": 0,
        "provider": "echo",
        "task_count": 1,
    }

    try:
        response = requests.post(f"{BASE_URL}/lesson/generate", json=payload, timeout=30)

        if response.status_code != 200:
            print(f"❌ {language}/{exercise_type}: HTTP {response.status_code}")
            return False

        data = response.json()
        if not data.get("tasks"):
            print(f"❌ {language}/{exercise_type}: No tasks generated")
            return False

        if data["tasks"][0]["type"] != exercise_type:
            print(f"❌ {language}/{exercise_type}: Wrong type returned: {data['tasks'][0]['type']}")
            return False

        return True
    except Exception as e:
        print(f"❌ {language}/{exercise_type}: {e}")
        return False


def main():
    print("Testing all language/exercise combinations...")
    print(f"Languages: {', '.join(LANGUAGES)}")
    print(f"Exercise types: {len(EXERCISE_TYPES)}")
    print()

    total = len(LANGUAGES) * len(EXERCISE_TYPES)
    passed = 0
    failed = 0

    for language in LANGUAGES:
        lang_passed = 0
        lang_failed = 0

        for exercise_type in EXERCISE_TYPES:
            if test_language_exercise_combo(language, exercise_type):
                passed += 1
                lang_passed += 1
            else:
                failed += 1
                lang_failed += 1

        status = "[OK]" if lang_failed == 0 else "[FAIL]"
        print(f"{status} {language.upper()}: {lang_passed}/{len(EXERCISE_TYPES)} passed")

    print()
    print(f"{'=' * 60}")
    print(f"Total: {passed}/{total} combinations passed ({100 * passed / total:.1f}%)")
    print(f"{'=' * 60}")

    if failed > 0:
        print(f"[FAIL] {failed} combinations failed")
        sys.exit(1)
    else:
        print("[OK] All combinations passed!")
        sys.exit(0)


if __name__ == "__main__":
    main()
