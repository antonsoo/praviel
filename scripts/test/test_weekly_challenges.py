#!/usr/bin/env python3
"""Test weekly challenge functionality"""

import requests

BASE_URL = "http://localhost:8001"


def test_weekly_challenges():
    """Test weekly challenge flow"""

    print("\n" + "=" * 60)
    print("TESTING WEEKLY CHALLENGES")
    print("=" * 60)

    # 1. Register and login
    print("\n[1/4] Setting up test user...")
    username = f"weeklytest_{int(__import__('time').time())}"
    reg_data = {
        "username": username,
        "email": f"{username}@test.com",
        "password": "Test1234!",
        "confirm_password": "Test1234!",
    }

    response = requests.post(f"{BASE_URL}/api/v1/auth/register", json=reg_data)
    if response.status_code != 201:
        print("   [FAIL] Registration failed")
        return False

    login_data = {"username_or_email": username, "password": "Test1234!"}
    response = requests.post(f"{BASE_URL}/api/v1/auth/login", json=login_data)
    if response.status_code != 200:
        print("   [FAIL] Login failed")
        return False

    token = response.json()["access_token"]
    headers = {"Authorization": f"Bearer {token}"}
    print("   [OK] User created and logged in")

    # 2. Get weekly challenges
    print("\n[2/4] Fetching weekly challenges...")
    response = requests.get(f"{BASE_URL}/api/v1/challenges/weekly", headers=headers)
    if response.status_code != 200:
        print(f"   [FAIL] Could not fetch weekly challenges: {response.status_code}")
        print(f"   Response: {response.text}")
        return False

    challenges = response.json()
    print(f"   [OK] Got {len(challenges)} weekly challenges")

    for i, challenge in enumerate(challenges[:3], 1):
        title = challenge["title"].encode("ascii", "ignore").decode("ascii")
        print(f"   [{i}] {title}: {challenge['current_progress']}/{challenge['target_value']}")
        print(f"       Reward: {challenge['coin_reward']} coins, {challenge['xp_reward']} XP")

    if not challenges:
        print("   [INFO] No weekly challenges available")
        return True

    # 3. Update a weekly challenge
    print("\n[3/4] Updating weekly challenge progress...")
    challenge = challenges[0]
    update_data = {
        "challenge_id": challenge["id"],
        "increment": min(5, challenge["target_value"]),  # Make progress but don't complete
    }

    response = requests.post(
        f"{BASE_URL}/api/v1/challenges/weekly/update-progress", json=update_data, headers=headers
    )
    if response.status_code != 200:
        print(f"   [FAIL] Could not update progress: {response.status_code}")
        print(f"   Response: {response.text}")
        return False

    result = response.json()
    print(f"   [OK] Updated progress: {result['current_progress']}/{result['target_value']}")
    if result.get("completed"):
        print("   [OK] Challenge completed! Rewards granted.")
        print(f"   [INFO] Coins remaining: {result.get('coins_remaining')}")

    # 4. Check updated state
    print("\n[4/4] Verifying updated state...")
    response = requests.get(f"{BASE_URL}/api/v1/challenges/weekly", headers=headers)
    if response.status_code != 200:
        print("   [FAIL] Could not re-fetch challenges")
        return False

    updated_challenges = response.json()
    updated_challenge = next((c for c in updated_challenges if c["id"] == challenge["id"]), None)

    if updated_challenge:
        print("   [OK] Challenge state updated:")
        print(f"       Progress: {updated_challenge['current_progress']}/{updated_challenge['target_value']}")
        print(f"       Completed: {updated_challenge['is_completed']}")
    else:
        print("   [WARN] Challenge not found in updated list")

    print("\n" + "=" * 60)
    print("WEEKLY CHALLENGES TEST COMPLETE")
    print("=" * 60)
    return True


if __name__ == "__main__":
    try:
        success = test_weekly_challenges()
        exit(0 if success else 1)
    except Exception as e:
        print(f"\n[ERROR] Test failed: {e}")
        import traceback

        traceback.print_exc()
        exit(1)
