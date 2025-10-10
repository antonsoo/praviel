#!/usr/bin/env python3
"""Test the Ancient Languages API endpoints"""

import json

import requests

BASE_URL = "http://localhost:8001"


def test_register():
    """Test user registration"""
    print("\n=== TESTING USER REGISTRATION ===")
    data = {
        "username": "testuser123",
        "email": "testuser123@example.com",
        "password": "Test1234!",
        "confirm_password": "Test1234!",
    }

    response = requests.post(f"{BASE_URL}/api/v1/auth/register", json=data)
    print(f"Status: {response.status_code}")
    print(f"Response: {json.dumps(response.json(), indent=2)}")
    return response.json() if response.status_code == 200 else None


def test_login(username, password):
    """Test user login"""
    print("\n=== TESTING USER LOGIN ===")
    data = {"username_or_email": username, "password": password}

    response = requests.post(f"{BASE_URL}/api/v1/auth/login", json=data)
    print(f"Status: {response.status_code}")
    print(f"Response: {json.dumps(response.json(), indent=2)}")
    return response.json() if response.status_code == 200 else None


def test_get_progress(token):
    """Test getting user progress"""
    print("\n=== TESTING GET USER PROGRESS ===")
    headers = {"Authorization": f"Bearer {token}"}

    response = requests.get(f"{BASE_URL}/api/v1/progress/me", headers=headers)
    print(f"Status: {response.status_code}")
    print(f"Response: {json.dumps(response.json(), indent=2)}")
    return response.json() if response.status_code == 200 else None


def test_get_daily_challenges(token):
    """Test getting daily challenges"""
    print("\n=== TESTING GET DAILY CHALLENGES ===")
    headers = {"Authorization": f"Bearer {token}"}

    response = requests.get(f"{BASE_URL}/api/v1/challenges/daily", headers=headers)
    print(f"Status: {response.status_code}")
    print(f"Response: {json.dumps(response.json(), indent=2)}")
    return response.json() if response.status_code == 200 else None


def test_generate_lesson(token):
    """Test generating a lesson"""
    print("\n=== TESTING LESSON GENERATION ===")
    headers = {"Authorization": f"Bearer {token}"}
    data = {
        "language": "grc",
        "provider": "openai",
        "model": "gpt-5-nano-2025-08-07",
        "difficulty": 1,
        "topic": "basic vocabulary",
    }

    response = requests.post(f"{BASE_URL}/lesson/generate", json=data, headers=headers)
    print(f"Status: {response.status_code}")
    if response.status_code == 200:
        print(f"Response: {json.dumps(response.json(), indent=2)[:500]}...")  # Truncate long response
    else:
        print(f"Response: {response.text}")
    return response.json() if response.status_code == 200 else None


if __name__ == "__main__":
    # Test flow
    print("Starting API tests...")

    # 1. Register (skip if already exists)
    user_data = test_register()
    # Ignore if user already exists

    # 2. Login
    login_data = test_login("testuser123", "Test1234!")
    if not login_data or "access_token" not in login_data:
        print("[FAIL] Login failed!")
        exit(1)

    token = login_data["access_token"]
    print(f"\n[OK] Got access token: {token[:20]}...")

    # 3. Get progress
    progress = test_get_progress(token)
    if not progress:
        print("[FAIL] Get progress failed!")

    # 4. Get daily challenges
    challenges = test_get_daily_challenges(token)
    if not challenges:
        print("[FAIL] Get challenges failed!")

    # 5. Generate lesson
    lesson = test_generate_lesson(token)
    if not lesson:
        print("[FAIL] Lesson generation failed!")

    print("\n=== ALL TESTS COMPLETE ===")
