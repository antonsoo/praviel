#!/usr/bin/env python3
"""Test script for Daily Challenges API."""

import sys

import requests

# Fix Windows console encoding
if sys.platform == "win32":
    sys.stdout.reconfigure(encoding="utf-8")

BASE_URL = "http://localhost:8000/api/v1"


def test_daily_challenges():
    """Test the daily challenges API endpoints."""

    # 1. Register or login
    print("1. Creating test user...")
    register_data = {
        "email": "challengetest@test.com",
        "password": "Testpass123!",
        "username": "challengetester",
    }

    try:
        response = requests.post(f"{BASE_URL}/auth/register", json=register_data)
        if response.status_code == 200:
            data = response.json()
            token = data["access_token"]
            print(f"✓ User registered! Token: {token[:20]}...")
        else:
            # User might already exist, try login
            print("Registration failed (might exist), trying login...")
            login_data = {"username_or_email": register_data["email"], "password": register_data["password"]}
            response = requests.post(f"{BASE_URL}/auth/login", json=login_data)
            if response.status_code == 200:
                data = response.json()
                token = data["access_token"]
                print(f"✓ Logged in! Token: {token[:20]}...")
            else:
                print(f"✗ Login failed: {response.text}")
                return
    except Exception as e:
        print(f"✗ Error during auth: {e}")
        return

    headers = {"Authorization": f"Bearer {token}"}

    # 2. Get daily challenges
    print("\n2. Getting daily challenges...")
    try:
        response = requests.get(f"{BASE_URL}/challenges/daily", headers=headers)
        if response.status_code == 200:
            challenges = response.json()
            print(f"✓ Got {len(challenges)} daily challenges:")
            for ch in challenges:
                print(
                    f"  - {ch['title']}: {ch['current_progress']}/{ch['target_value']} "
                    f"(Reward: {ch['xp_reward']} XP, {ch['coin_reward']} coins)"
                )
                print(f"    Type: {ch['challenge_type']}, Difficulty: {ch['difficulty']}")
                print(f"    Expires: {ch['expires_at']}")
        else:
            print(f"✗ Failed to get challenges: {response.text}")
            return
    except Exception as e:
        print(f"✗ Error getting challenges: {e}")
        return

    # 3. Update challenge progress
    if challenges:
        print("\n3. Updating challenge progress...")
        challenge_id = challenges[0]["id"]
        try:
            update_data = {"challenge_id": challenge_id, "increment": 1}
            response = requests.post(
                f"{BASE_URL}/challenges/update-progress", headers=headers, json=update_data
            )
            if response.status_code == 200:
                result = response.json()
                print("✓ Challenge updated!")
                print(f"  Progress: {result['current_progress']}")
                print(f"  Completed: {result['is_completed']}")
                if result.get("rewards_granted"):
                    print(f"  🎉 Rewards granted: {result['xp_reward']} XP, {result['coin_reward']} coins")
            else:
                print(f"✗ Failed to update progress: {response.text}")
        except Exception as e:
            print(f"✗ Error updating progress: {e}")

    # 4. Get challenge streak
    print("\n4. Getting challenge streak...")
    try:
        response = requests.get(f"{BASE_URL}/challenges/streak", headers=headers)
        if response.status_code == 200:
            streak = response.json()
            print("✓ Challenge streak:")
            print(f"  Current: {streak['current_streak']} days")
            print(f"  Longest: {streak['longest_streak']} days")
            print(f"  Total completed: {streak['total_days_completed']} days")
            print(f"  Active today: {streak['is_active_today']}")
        else:
            print(f"✗ Failed to get streak: {response.text}")
    except Exception as e:
        print(f"✗ Error getting streak: {e}")

    # 5. Get challenge leaderboard
    print("\n5. Getting challenge leaderboard...")
    try:
        response = requests.get(f"{BASE_URL}/challenges/leaderboard", headers=headers)
        if response.status_code == 200:
            leaderboard = response.json()
            print(
                f"✓ Leaderboard (showing top {len(leaderboard['entries'])} of {leaderboard['total_users']}):"
            )
            for entry in leaderboard["entries"][:5]:
                print(
                    f"  #{entry['rank']} {entry['username']}: "
                    f"{entry['challenges_completed']} completed, "
                    f"{entry['current_streak']} day streak"
                )
            print(f"\nYour rank: #{leaderboard['user_rank']}")
        else:
            print(f"✗ Failed to get leaderboard: {response.text}")
    except Exception as e:
        print(f"✗ Error getting leaderboard: {e}")

    print("\n✅ Daily Challenges API test complete!")


if __name__ == "__main__":
    test_daily_challenges()
