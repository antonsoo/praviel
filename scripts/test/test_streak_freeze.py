#!/usr/bin/env python3
"""Test streak freeze purchase and usage"""

import requests

BASE_URL = "http://localhost:8001"


def test_streak_freeze_flow():
    """Test complete streak freeze flow"""

    print("\n" + "=" * 60)
    print("TESTING STREAK FREEZE FUNCTIONALITY")
    print("=" * 60)

    # 1. Register and login
    print("\n[1/5] Setting up test user...")
    username = f"streaktest_{int(__import__('time').time())}"
    reg_data = {
        "username": username,
        "email": f"{username}@test.com",
        "password": "Test1234!",
        "confirm_password": "Test1234!",
    }

    response = requests.post(f"{BASE_URL}/api/v1/auth/register", json=reg_data)
    if response.status_code != 201:
        print(f"   [FAIL] Registration failed: {response.status_code}")
        return False

    login_data = {"username_or_email": username, "password": "Test1234!"}
    response = requests.post(f"{BASE_URL}/api/v1/auth/login", json=login_data)
    if response.status_code != 200:
        print("   [FAIL] Login failed")
        return False

    token = response.json()["access_token"]
    headers = {"Authorization": f"Bearer {token}"}
    print("   [OK] User created and logged in")

    # 2. Give user some coins (via progress update)
    print("\n[2/5] Granting coins for testing...")
    update_data = {"xp_gained": 100, "lesson_id": "test-grant-coins", "time_spent_minutes": 10}
    response = requests.post(f"{BASE_URL}/api/v1/progress/me/update", json=update_data, headers=headers)
    if response.status_code != 200:
        print("   [FAIL] Could not grant XP")
        return False

    # Complete a daily challenge to get coins
    response = requests.get(f"{BASE_URL}/api/v1/challenges/daily", headers=headers)
    challenges = response.json()

    if challenges:
        # Update the first challenge to completion
        challenge = challenges[0]
        update_data = {"challenge_id": challenge["id"], "increment": challenge["target_value"]}
        response = requests.post(
            f"{BASE_URL}/api/v1/challenges/update-progress", json=update_data, headers=headers
        )
        if response.status_code == 200:
            result = response.json()
            print(f"   [OK] Completed challenge, coins: {result.get('coins_remaining', 'N/A')}")

    # Check current coins
    response = requests.get(f"{BASE_URL}/api/v1/progress/me", headers=headers)
    progress = response.json()
    coins = progress["coins"]
    freezes = progress["streak_freezes"]
    print(f"   [OK] Current state: {coins} coins, {freezes} freezes")

    # 3. Purchase streak freeze
    print("\n[3/5] Purchasing streak freeze...")
    if coins < 200:
        print(f"   [INFO] Need more coins (need 200, have {coins})")
        print("   [INFO] Granting more coins via completing challenges...")

        # Grant more coins by completing more challenges
        for _ in range(3):
            update_data = {"xp_gained": 50, "lesson_id": f"grant-{_}"}
            requests.post(f"{BASE_URL}/api/v1/progress/me/update", json=update_data, headers=headers)

        # Try to complete more challenges
        response = requests.get(f"{BASE_URL}/api/v1/challenges/daily", headers=headers)
        challenges = response.json()
        for challenge in challenges[:2]:
            if not challenge["is_completed"]:
                update_data = {"challenge_id": challenge["id"], "increment": challenge["target_value"]}
                requests.post(
                    f"{BASE_URL}/api/v1/challenges/update-progress", json=update_data, headers=headers
                )

        # Check again
        response = requests.get(f"{BASE_URL}/api/v1/progress/me", headers=headers)
        coins = response.json()["coins"]
        print(f"   [INFO] Now have {coins} coins")

    if coins >= 200:
        response = requests.post(f"{BASE_URL}/api/v1/challenges/purchase-streak-freeze", headers=headers)
        if response.status_code == 200:
            result = response.json()
            freezes = result["streak_freezes_owned"]
            coins = result["coins_remaining"]
            print(f"   [OK] Purchased! Freezes: {freezes}, Coins: {coins}")
        else:
            print(f"   [FAIL] Purchase failed: {response.status_code} - {response.text}")
            return False
    else:
        print(f"   [SKIP] Still not enough coins ({coins}/200)")

    # 4. Check streak freeze inventory
    print("\n[4/5] Checking inventory...")
    response = requests.get(f"{BASE_URL}/api/v1/progress/me", headers=headers)
    if response.status_code == 200:
        progress = response.json()
        print(f"   [OK] Inventory: {progress['streak_freezes']} freezes, {progress['coins']} coins")
        print(f"   [INFO] Current streak: {progress['streak_days']} days")
    else:
        print("   [FAIL] Could not fetch progress")
        return False

    # 5. Test using streak freeze
    print("\n[5/5] Testing streak freeze usage...")
    if progress["streak_freezes"] > 0:
        response = requests.post(f"{BASE_URL}/api/v1/challenges/use-streak-freeze", headers=headers)
        if response.status_code == 200:
            result = response.json()
            print(f"   [OK] {result['message']}")
            print(f"   [INFO] Freezes remaining: {result['streak_freezes_remaining']}")
            print(f"   [INFO] Streak protected: {result['streak_protected']}")
        else:
            print(f"   [FAIL] Could not use freeze: {response.status_code} - {response.text}")
    else:
        print("   [SKIP] No freezes to use")

    print("\n" + "=" * 60)
    print("STREAK FREEZE TEST COMPLETE")
    print("=" * 60)
    return True


if __name__ == "__main__":
    try:
        success = test_streak_freeze_flow()
        exit(0 if success else 1)
    except Exception as e:
        print(f"\n[ERROR] Test failed: {e}")
        import traceback

        traceback.print_exc()
        exit(1)
