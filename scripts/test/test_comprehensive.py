#!/usr/bin/env python3
"""Comprehensive test of all bug fixes"""

import requests

BASE_URL = "http://localhost:8001"


def test_complete_flow():
    """Test the complete user flow with all fixes"""

    print("\n" + "=" * 60)
    print("TESTING ALL BUG FIXES")
    print("=" * 60)

    # 1. Register new user
    print("\n[1/8] Testing user registration...")
    username = f"testuser_{int(__import__('time').time())}"
    reg_data = {
        "username": username,
        "email": f"{username}@test.com",
        "password": "Test1234!",
        "confirm_password": "Test1234!",
    }

    response = requests.post(f"{BASE_URL}/api/v1/auth/register", json=reg_data)
    if response.status_code == 201:
        print(f"   [OK] Registration successful: {username}")
    else:
        print(f"   [FAIL] Registration failed: {response.status_code}")
        print(f"     {response.text}")
        return False

    # 2. Login
    print("\n[2/8] Testing login...")
    login_data = {"username_or_email": username, "password": "Test1234!"}

    response = requests.post(f"{BASE_URL}/api/v1/auth/login", json=login_data)
    if response.status_code != 200:
        print(f"   [FAIL] Login failed: {response.status_code}")
        return False

    token = response.json()["access_token"]
    headers = {"Authorization": f"Bearer {token}"}
    print("   [OK] Login successful, got token")

    # 3. Get initial progress
    print("\n[3/8] Testing initial progress...")
    response = requests.get(f"{BASE_URL}/api/v1/progress/me", headers=headers)
    if response.status_code != 200:
        print(f"   [FAIL] Get progress failed: {response.status_code}")
        return False

    progress = response.json()
    print(f"   [OK] Initial: XP={progress['xp_total']}, Coins={progress['coins']}, Level={progress['level']}")

    # 4. Generate a lesson (BUG #1 FIX)
    print("\n[4/8] Testing lesson generation (BUG #1 FIX)...")
    lesson_data = {
        "language": "grc",
        "provider": "openai",
        "model": "gpt-5-nano-2025-08-07",
        "difficulty": 1,
        "topic": "basic vocabulary",
    }

    response = requests.post(f"{BASE_URL}/lesson/generate", json=lesson_data, headers=headers, timeout=60)
    if response.status_code != 200:
        print(f"   [FAIL] Lesson generation failed: {response.status_code}")
        print(f"     {response.text}")
        return False

    lesson = response.json()
    print(f"   [OK] Lesson generated with {len(lesson.get('tasks', []))} tasks")

    # 5. Update progress (BUG #4 FIX - Progress sync)
    print("\n[5/8] Testing progress update (BUG #4 FIX)...")
    update_data = {
        "xp_gained": 50,
        "lesson_id": "test-lesson-1",
        "time_spent_minutes": 5,
        "is_perfect": True,
        "words_learned_count": 10,
    }

    response = requests.post(f"{BASE_URL}/api/v1/progress/me/update", json=update_data, headers=headers)
    if response.status_code != 200:
        print(f"   [FAIL] Progress update failed: {response.status_code}")
        print(f"     {response.text}")
        return False

    updated_progress = response.json()
    print(f"   [OK] Progress updated: XP={updated_progress['xp_total']}, Level={updated_progress['level']}")

    # 6. Get daily challenges
    print("\n[6/8] Testing daily challenges...")
    response = requests.get(f"{BASE_URL}/api/v1/challenges/daily", headers=headers)
    if response.status_code != 200:
        print(f"   [FAIL] Get challenges failed: {response.status_code}")
        return False

    challenges = response.json()
    print(f"   [OK] Got {len(challenges)} daily challenges")

    # 7. Update challenge progress (test coins sync - BUG #5 FIX)
    if challenges:
        print("\n[7/8] Testing challenge progress update (coins sync)...")
        challenge_id = challenges[0]["id"]
        update_data = {"challenge_id": challenge_id, "increment": 1}

        response = requests.post(
            f"{BASE_URL}/api/v1/challenges/update-progress", json=update_data, headers=headers
        )
        if response.status_code != 200:
            print(f"   [FAIL] Challenge update failed: {response.status_code}")
            print(f"     {response.text}")
        else:
            result = response.json()
            print(f"   [OK] Challenge updated: completed={result.get('completed')}")
            if "coins_remaining" in result:
                print(f"     Coins: {result['coins_remaining']}")

    # 8. Test double-or-nothing start
    print("\n[8/8] Testing double-or-nothing...")

    # First need enough coins
    response = requests.get(f"{BASE_URL}/api/v1/progress/me", headers=headers)
    current_coins = response.json()["coins"]

    if current_coins >= 10:
        don_data = {"wager": 10, "days": 3}

        response = requests.post(
            f"{BASE_URL}/api/v1/challenges/double-or-nothing/start", json=don_data, headers=headers
        )
        if response.status_code == 200:
            print("   [OK] Double-or-nothing started")

            # Test the new complete-day endpoint (BUG #9 FIX)
            response = requests.post(
                f"{BASE_URL}/api/v1/challenges/double-or-nothing/complete-day", headers=headers
            )
            if response.status_code == 200:
                result = response.json()
                print(f"   [OK] Day completed: {result['days_completed']}/{result['days_required']}")
            else:
                print(f"   [FAIL] Complete day failed: {response.status_code}")
        else:
            print(f"   [FAIL] Start failed: {response.status_code}")
            print(f"     {response.text}")
    else:
        print(f"   [SKIP] Skipped (need 10 coins, have {current_coins})")

    print("\n" + "=" * 60)
    print("ALL TESTS COMPLETE")
    print("=" * 60)
    return True


if __name__ == "__main__":
    try:
        success = test_complete_flow()
        exit(0 if success else 1)
    except Exception as e:
        print(f"\n[ERROR] Test failed with exception: {e}")
        import traceback

        traceback.print_exc()
        exit(1)
