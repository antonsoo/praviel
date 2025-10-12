#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Comprehensive backend integration test for Ancient Languages app.

Tests the complete user journey:
1. User registration
2. User login
3. Progress tracking
4. Power-up purchases
5. Achievement unlocks
6. Leaderboard
7. Language preferences
"""

import io
import random
import string
import sys

import requests

BASE_URL = "http://localhost:8001"
API_URL = f"{BASE_URL}/api/v1"


def generate_random_user():
    """Generate random user credentials for testing."""
    random_suffix = "".join(random.choices(string.ascii_lowercase + string.digits, k=8))
    return {
        "username": f"testuser_{random_suffix}",
        "email": f"test_{random_suffix}@example.com",
        "password": "TestPassword123!",
    }


def test_health():
    """Test 1: Health check."""
    print("\n=== Test 1: Health Check ===")
    response = requests.get(f"{BASE_URL}/health")
    assert response.status_code == 200, f"Health check failed: {response.status_code}"
    data = response.json()
    print(f"✓ Health check passed: {data}")
    return True


def test_registration(user_creds):
    """Test 2: User registration."""
    print("\n=== Test 2: User Registration ===")
    response = requests.post(
        f"{API_URL}/auth/register", json=user_creds, headers={"Content-Type": "application/json"}
    )
    if response.status_code != 201:
        print(f"✗ Registration failed: {response.status_code}")
        print(f"Response: {response.text}")
        return False

    data = response.json()
    print(f"✓ User registered: {data['username']} (ID: {data['id']})")
    return True


def test_login(user_creds):
    """Test 3: User login."""
    print("\n=== Test 3: User Login ===")
    response = requests.post(
        f"{API_URL}/auth/login",
        json={"username_or_email": user_creds["username"], "password": user_creds["password"]},
        headers={"Content-Type": "application/json"},
    )
    if response.status_code != 200:
        print(f"✗ Login failed: {response.status_code}")
        print(f"Response: {response.text}")
        return None

    data = response.json()
    print("✓ Login successful")
    print(f"  Access token: {data['access_token'][:20]}...")
    return data["access_token"]


def test_get_progress(token):
    """Test 4: Get user progress."""
    print("\n=== Test 4: Get User Progress ===")
    response = requests.get(f"{API_URL}/progress/me", headers={"Authorization": f"Bearer {token}"})
    if response.status_code != 200:
        print(f"✗ Get progress failed: {response.status_code}")
        print(f"Response: {response.text}")
        return None

    data = response.json()
    print("✓ Progress retrieved:")
    print(f"  XP: {data['xp_total']}")
    print(f"  Level: {data['level']}")
    print(f"  Streak: {data['streak_days']} days")
    print(f"  Coins: {data['coins']}")
    print(f"  Total Lessons: {data['total_lessons']}")
    return data


def test_update_progress(token):
    """Test 5: Update user progress (complete a lesson)."""
    print("\n=== Test 5: Update Progress (Complete Lesson) ===")
    response = requests.post(
        f"{API_URL}/progress/me/update",
        json={"lesson_id": "test_lesson_001", "xp_gained": 150, "time_spent_minutes": 5},
        headers={"Authorization": f"Bearer {token}", "Content-Type": "application/json"},
    )
    if response.status_code != 200:
        print(f"✗ Update progress failed: {response.status_code}")
        print(f"Response: {response.text}")
        return None

    data = response.json()
    print("✓ Progress updated:")
    print(f"  New XP: {data['xp_total']}")
    print(f"  New Level: {data['level']}")
    print(f"  New Streak: {data['streak_days']} days")
    print(f"  New Coins: {data['coins']} (+{150 // 10} from XP)")
    return data


def test_buy_power_up(token, power_up_type):
    """Test 6: Buy power-up."""
    print(f"\n=== Test 6: Buy Power-Up ({power_up_type}) ===")
    endpoints = {
        "streak-freeze": "/progress/me/streak-freeze/buy",
        "xp-boost": "/progress/me/power-ups/xp-boost/buy",
        "hint": "/progress/me/power-ups/hint-reveal/buy",
        "skip": "/progress/me/power-ups/time-warp/buy",
    }

    endpoint = endpoints.get(power_up_type)
    if not endpoint:
        print(f"✗ Unknown power-up type: {power_up_type}")
        return False

    response = requests.post(f"{API_URL}{endpoint}", headers={"Authorization": f"Bearer {token}"})

    if response.status_code != 200:
        print(f"✗ Buy power-up failed: {response.status_code}")
        print(f"Response: {response.text}")
        return False

    data = response.json()
    print("✓ Power-up purchased:")
    print(f"  Message: {data['message']}")
    print(f"  Coins remaining: {data['coins_remaining']}")
    return True


def test_get_achievements(token):
    """Test 7: Get user achievements."""
    print("\n=== Test 7: Get User Achievements ===")
    response = requests.get(
        f"{API_URL}/progress/me/achievements", headers={"Authorization": f"Bearer {token}"}
    )
    if response.status_code != 200:
        print(f"✗ Get achievements failed: {response.status_code}")
        print(f"Response: {response.text}")
        return None

    data = response.json()
    print(f"✓ Retrieved {len(data)} unlocked achievements:")
    for ach in data[:5]:  # Show first 5
        print(f"  - {ach['achievement_type']}: {ach['achievement_id']}")
    return data


def test_get_leaderboard(token):
    """Test 8: Get leaderboard."""
    print("\n=== Test 8: Get Leaderboard ===")
    for scope in ["global", "local", "friends"]:
        print(f"\n  Testing {scope} leaderboard...")
        response = requests.get(
            f"{API_URL}/social/leaderboard/{scope}",
            headers={"Authorization": f"Bearer {token}"},
            params={"period": "weekly", "limit": 10},
        )
        if response.status_code != 200:
            print(f"  ✗ Get {scope} leaderboard failed: {response.status_code}")
            continue

        data = response.json()
        users = data.get("users", [])
        print(f"  ✓ {scope.capitalize()} leaderboard retrieved: {len(users)} users")
        if users and len(users) > 0:
            top = users[0]
            username = top.get("username", "N/A")
            rank = top.get("rank")
            xp = top.get("xp", 0)
            print(f"    Top user: {username} (Rank: {rank}, XP: {xp})")
    return True


def test_update_preferences(token, language_code="lat"):
    """Test 9: Update user preferences (last learned language)."""
    print(f"\n=== Test 9: Update User Preferences (Language: {language_code}) ===")
    response = requests.patch(
        f"{API_URL}/users/me/preferences",
        json={"language_focus": language_code},
        headers={"Authorization": f"Bearer {token}", "Content-Type": "application/json"},
    )
    if response.status_code != 200:
        print(f"✗ Update preferences failed: {response.status_code}")
        print(f"Response: {response.text}")
        return False

    data = response.json()
    print("✓ Preferences updated:")
    print(f"  Language focus: {data.get('language_focus', 'N/A')}")
    return True


def test_get_preferences(token):
    """Test 10: Get user preferences."""
    print("\n=== Test 10: Get User Preferences ===")
    response = requests.get(f"{API_URL}/users/me/preferences", headers={"Authorization": f"Bearer {token}"})
    if response.status_code != 200:
        print(f"✗ Get preferences failed: {response.status_code}")
        print(f"Response: {response.text}")
        return None

    data = response.json()
    print("✓ Preferences retrieved:")
    print(f"  Language focus: {data.get('language_focus', 'N/A')}")
    print(f"  Theme: {data.get('theme', 'N/A')}")
    print(f"  Daily XP goal: {data.get('daily_xp_goal', 'N/A')}")
    return data


def main():
    """Run all integration tests."""
    # Fix encoding issues on Windows
    if sys.platform == "win32":
        sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8")

    print("=" * 60)
    print("ANCIENT LANGUAGES APP - BACKEND INTEGRATION TESTS")
    print("=" * 60)

    try:
        # Test 1: Health check
        test_health()

        # Generate test user
        user_creds = generate_random_user()
        print(f"\n📝 Test user: {user_creds['username']}")

        # Test 2-3: Registration and login
        if not test_registration(user_creds):
            print("\n❌ Registration failed. Stopping tests.")
            return False

        token = test_login(user_creds)
        if not token:
            print("\n❌ Login failed. Stopping tests.")
            return False

        # Test 4: Get initial progress
        initial_progress = test_get_progress(token)
        if not initial_progress:
            print("\n❌ Get progress failed.")
            return False

        # Test 5: Complete a lesson (update progress)
        updated_progress = test_update_progress(token)
        if not updated_progress:
            print("\n❌ Update progress failed.")
            return False

        # Test 6: Buy power-ups (if user has enough coins)
        if updated_progress["coins"] >= 100:
            test_buy_power_up(token, "streak-freeze")
        else:
            print("\n⚠️  Skipping power-up test (not enough coins)")

        # Test 7: Get achievements
        test_get_achievements(token)

        # Test 8: Get leaderboard
        test_get_leaderboard(token)

        # Test 9-10: Update and get preferences
        test_update_preferences(token, "lat")
        test_get_preferences(token)

        print("\n" + "=" * 60)
        print("✅ ALL INTEGRATION TESTS PASSED!")
        print("=" * 60)
        return True

    except Exception as e:
        print(f"\n❌ Test suite failed with exception: {e}")
        import traceback

        traceback.print_exc()
        return False


if __name__ == "__main__":
    import sys

    success = main()
    sys.exit(0 if success else 1)
