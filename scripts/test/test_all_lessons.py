#!/usr/bin/env python3
"""Comprehensive test of all language×exercise type combinations."""

import requests

languages = ["grc", "lat", "hbo", "san"]
exercise_types = [
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
    "synonym",
    "contextmatch",
    "reorder",
    "dictation",
    "alphabet",
    "conjugation",
    "declension",
    "etymology",
]

baseurl = "http://localhost:8001"
total = len(languages) * len(exercise_types)
passed = 0
failed = 0
errors = []

print(f"Testing {total} combinations...\n")

for lang in languages:
    for ex_type in exercise_types:
        try:
            resp = requests.post(
                f"{baseurl}/lesson/generate",
                json={"language": lang, "exercise_type": ex_type, "count": 1},
                timeout=10,
            )
            if resp.status_code == 200:
                data = resp.json()
                if data.get("tasks"):
                    passed += 1
                    print(f"OK   {lang:4} x {ex_type:15}")
                else:
                    failed += 1
                    print(f"FAIL {lang:4} x {ex_type:15} - no tasks")
                    errors.append(f"{lang}x{ex_type}: no tasks in response")
            else:
                failed += 1
                print(f"FAIL {lang:4} x {ex_type:15} - HTTP {resp.status_code}")
                errors.append(f"{lang}x{ex_type}: HTTP {resp.status_code}")
        except Exception as e:
            failed += 1
            print(f"ERR  {lang:4} x {ex_type:15} - {e}")
            errors.append(f"{lang}×{ex_type}: {e}")

print(f"\n{'=' * 60}")
print(f"Results: {passed}/{total} passed ({100 * passed // total}%)")
print(f"         {failed}/{total} failed ({100 * failed // total}%)")
print(f"{'=' * 60}")

if errors:
    print("\nErrors:")
    for err in errors[:10]:  # Show first 10 errors
        print(f"  - {err}")
