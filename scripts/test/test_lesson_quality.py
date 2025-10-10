#!/usr/bin/env python3
"""Test lesson quality and variety"""

import requests

BASE_URL = "http://localhost:8001"


def test_lesson_quality():
    """Generate multiple lessons and check quality"""

    print("\n" + "=" * 60)
    print("TESTING LESSON QUALITY & VARIETY")
    print("=" * 60)

    # Register and login
    username = f"quality_test_{int(__import__('time').time())}"
    reg_data = {
        "username": username,
        "email": f"{username}@test.com",
        "password": "Test1234!",
        "confirm_password": "Test1234!",
    }

    requests.post(f"{BASE_URL}/api/v1/auth/register", json=reg_data)

    login_data = {"username_or_email": username, "password": "Test1234!"}
    response = requests.post(f"{BASE_URL}/api/v1/auth/login", json=login_data)
    token = response.json()["access_token"]
    headers = {"Authorization": f"Bearer {token}"}

    # Test different lesson configurations
    test_configs = [
        {
            "name": "Beginner Greek",
            "language": "grc",
            "provider": "openai",
            "model": "gpt-5-nano-2025-08-07",
            "difficulty": 1,
            "topic": "basic greetings and introductions",
        },
        {
            "name": "Intermediate Greek",
            "language": "grc",
            "provider": "openai",
            "model": "gpt-5-nano-2025-08-07",
            "difficulty": 3,
            "topic": "Homeric vocabulary and syntax",
        },
    ]

    all_phrases_seen = set()
    all_tasks_seen = []

    for config in test_configs:
        print(f"\n{'=' * 60}")
        print(f"Testing: {config['name']}")
        print(f"Topic: {config['topic']}")
        print(f"{'=' * 60}")

        response = requests.post(f"{BASE_URL}/lesson/generate", json=config, headers=headers, timeout=90)

        if response.status_code != 200:
            print(f"[FAIL] Generation failed: {response.status_code}")
            print(response.text)
            continue

        lesson = response.json()
        tasks = lesson.get("tasks", [])

        print(f"\n[OK] Generated {len(tasks)} tasks:")

        for i, task in enumerate(tasks, 1):
            task_type = task.get("type")
            all_tasks_seen.append(task_type)

            print(f"\n  Task {i}: {task_type.upper()}")

            if task_type == "alphabet":
                prompt = task.get("prompt", "").encode("ascii", "ignore").decode("ascii")
                print(f"    Prompt: {prompt}")
                print(f"    Options: {len(task.get('options', []))} choices")

            elif task_type == "match":
                pairs = task.get("pairs", [])
                print(f"    Pairs: {len(pairs)}")
                for j, pair in enumerate(pairs[:3], 1):  # Show first 3
                    grc = pair.get("grc", "").encode("ascii", "ignore").decode("ascii")
                    en = pair.get("en", "")
                    print(f"      {j}. {grc} = {en}")
                    all_phrases_seen.add(grc)
                if len(pairs) > 3:
                    print(f"      ... and {len(pairs) - 3} more")

            elif task_type == "translate":
                text = task.get("text", "").encode("ascii", "ignore").decode("ascii")
                print(f"    Text: {text}")
                all_phrases_seen.add(text)

            elif task_type == "cloze":
                text = task.get("text", "").encode("ascii", "ignore").decode("ascii")
                blanks = task.get("blanks", [])
                print(f"    Text: {text}")
                print(f"    Blanks: {len(blanks)}")

    # Analysis
    print(f"\n{'=' * 60}")
    print("QUALITY ANALYSIS")
    print(f"{'=' * 60}")

    print("\nTask Type Distribution:")
    from collections import Counter

    type_counts = Counter(all_tasks_seen)
    for task_type, count in type_counts.most_common():
        print(f"  {task_type}: {count}")

    print(f"\nUnique Phrases Generated: {len(all_phrases_seen)}")
    print(f"Total Tasks Generated: {len(all_tasks_seen)}")

    variety_score = len(all_phrases_seen) / max(len(all_tasks_seen), 1)
    print(f"Variety Score: {variety_score:.2f} (1.0 = all unique)")

    if variety_score > 0.7:
        print("[GOOD] High variety in generated content")
    elif variety_score > 0.4:
        print("[OK] Moderate variety")
    else:
        print("[WARN] Low variety - may be repetitive")

    print(f"\n{'=' * 60}")
    print("LESSON QUALITY TEST COMPLETE")
    print(f"{'=' * 60}")


if __name__ == "__main__":
    try:
        test_lesson_quality()
    except Exception as e:
        print(f"\n[ERROR] {e}")
        import traceback

        traceback.print_exc()
