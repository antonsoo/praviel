#!/usr/bin/env python3
"""Test weekly challenges endpoints."""

import sys

import requests

# Fix Windows console encoding
if sys.platform == "win32":
    sys.stdout.reconfigure(encoding="utf-8")

BASE_URL = "http://localhost:8000/api/v1"
TOKEN = None  # Will be filled after login


def login():
    """Login and get token."""
    global TOKEN
    response = requests.post(
        f"{BASE_URL}/auth/login",
        json={"username_or_email": "challengetester", "password": "Weekly123!"},
    )
    if response.status_code == 200:
        TOKEN = response.json()["access_token"]
        print("✓ Logged in successfully")
        return True
    else:
        print(f"✗ Login failed: {response.status_code} - {response.text}")
        return False


def get_headers():
    """Get auth headers."""
    return {"Authorization": f"Bearer {TOKEN}"}


def test_get_weekly_challenges():
    """Test GET /challenges/weekly."""
    print("\n=== Testing GET /challenges/weekly ===")
    response = requests.get(f"{BASE_URL}/challenges/weekly", headers=get_headers())

    if response.status_code == 200:
        challenges = response.json()
        print(f"✓ Got {len(challenges)} weekly challenges")
        for i, challenge in enumerate(challenges, 1):
            print(f"\n  Challenge {i}:")
            print(f"    Type: {challenge['challenge_type']}")
            print(f"    Title: {challenge['title']}")
            print(f"    Difficulty: {challenge['difficulty']}")
            print(f"    Progress: {challenge['current_progress']}/{challenge['target_value']}")
            print(f"    Rewards: {challenge['coin_reward']} coins, {challenge['xp_reward']} XP")
            print(f"    Multiplier: {challenge['reward_multiplier']}x")
            print(f"    Days remaining: {challenge['days_remaining']}")
            print(f"    Completed: {challenge['is_completed']}")
        return challenges
    else:
        print(f"✗ Failed: {response.status_code} - {response.text}")
        return None


def test_update_weekly_progress(challenge_id, increment=1):
    """Test POST /challenges/weekly/update-progress."""
    print(f"\n=== Testing POST /challenges/weekly/update-progress (challenge_id={challenge_id}) ===")
    response = requests.post(
        f"{BASE_URL}/challenges/weekly/update-progress",
        headers=get_headers(),
        json={"challenge_id": challenge_id, "increment": increment},
    )

    if response.status_code == 200:
        result = response.json()
        print("✓ Progress updated successfully")
        print(f"  Success: {result['success']}")
        print(f"  Completed: {result['completed']}")
        print(f"  Progress: {result['current_progress']}/{result['target_value']}")
        if result.get("rewards_granted"):
            print(
                f"  Rewards: {result['rewards_granted']['coins']} coins, {result['rewards_granted']['xp']} XP"
            )
        return result
    else:
        print(f"✗ Failed: {response.status_code} - {response.text}")
        return None


def main():
    """Run all tests."""
    print("=== Weekly Challenges API Test ===\n")

    if not login():
        return

    # Test 1: Get weekly challenges (auto-generates if none exist)
    challenges = test_get_weekly_challenges()

    if challenges and len(challenges) > 0:
        # Test 2: Update progress on first challenge
        first_challenge = challenges[0]
        test_update_weekly_progress(first_challenge["id"], increment=1)

        # Test 3: Get challenges again to see updated progress
        test_get_weekly_challenges()

    print("\n✅ All tests completed!")


if __name__ == "__main__":
    main()
