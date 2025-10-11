#!/usr/bin/env python3
"""Comprehensive API test to verify all endpoints work correctly."""

import asyncio
import sys
from typing import Any

import httpx

# Fix Windows encoding
if sys.platform == "win32":
    import io

    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8")
    sys.stderr = io.TextIOWrapper(sys.stderr.buffer, encoding="utf-8")

BASE_URL = "http://localhost:8000"


async def test_endpoint(
    client: httpx.AsyncClient,
    method: str,
    path: str,
    expected_status: int = 200,
    json_data: dict[str, Any] | None = None,
    headers: dict[str, str] | None = None,
) -> bool:
    """Test a single endpoint and return success status."""
    try:
        if method == "GET":
            response = await client.get(f"{BASE_URL}{path}", headers=headers)
        elif method == "POST":
            response = await client.post(f"{BASE_URL}{path}", json=json_data, headers=headers)
        else:
            print(f"  ❌ Unsupported method: {method}")
            return False

        if response.status_code == expected_status:
            print(f"  ✅ {method} {path} → {response.status_code}")
            return True
        else:
            print(f"  ❌ {method} {path} → {response.status_code} (expected {expected_status})")
            print(f"     Response: {response.text[:200]}")
            return False
    except Exception as e:
        print(f"  ❌ {method} {path} → Error: {e}")
        return False


async def main():
    """Run comprehensive API tests."""
    print("🚀 Starting comprehensive API tests...\n")

    async with httpx.AsyncClient(timeout=30.0) as client:
        results = []

        # Test 1: Health endpoint
        print("1️⃣ Testing health endpoint...")
        results.append(await test_endpoint(client, "GET", "/health"))

        # Test 2: Register a new user
        print("\n2️⃣ Testing user registration...")
        timestamp = int(asyncio.get_event_loop().time())
        register_data = {
            "username": f"testuser{timestamp}",
            "email": f"test{timestamp}@example.com",
            "password": "TestPass123!",
        }
        results.append(
            await test_endpoint(
                client, "POST", "/api/v1/auth/register", expected_status=201, json_data=register_data
            )
        )

        # Test 3: Login with the new user
        print("\n3️⃣ Testing user login...")
        login_data = {
            "username_or_email": register_data["username"],
            "password": register_data["password"],
        }
        login_response = await client.post(f"{BASE_URL}/api/v1/auth/login", json=login_data)
        if login_response.status_code == 200:
            print(f"  ✅ POST /api/v1/auth/login → {login_response.status_code}")
            token = login_response.json()["access_token"]
            auth_headers = {"Authorization": f"Bearer {token}"}
            results.append(True)
        else:
            print(f"  ❌ POST /api/v1/auth/login → {login_response.status_code}")
            print(f"     Response: {login_response.text}")
            auth_headers = {}
            results.append(False)

        # Test 4: Get user profile
        print("\n4️⃣ Testing user profile...")
        results.append(await test_endpoint(client, "GET", "/api/v1/users/me", headers=auth_headers))

        # Test 5: Generate lesson
        print("\n5️⃣ Testing lesson generation...")
        lesson_data = {
            "language": "grc",
            "profile": "beginner",
            "sources": ["daily"],
            "exercise_types": ["match", "cloze", "translate"],
            "task_count": 6,
        }
        results.append(
            await test_endpoint(
                client, "POST", "/lesson/generate", json_data=lesson_data, headers=auth_headers
            )
        )

        # Test 6: Quest templates
        print("\n6️⃣ Testing quest templates...")
        results.append(await test_endpoint(client, "GET", "/api/v1/quests/available", headers=auth_headers))

        # Test 7: Preview quest
        print("\n7️⃣ Testing quest preview...")
        quest_preview_data = {
            "quest_type": "daily_streak",
            "target_value": 7,
            "duration_days": 7,
            "title": "Week Warrior",
        }
        results.append(
            await test_endpoint(
                client,
                "POST",
                "/api/v1/quests/preview",
                json_data=quest_preview_data,
                headers=auth_headers,
            )
        )

        # Test 8: Create quest
        print("\n8️⃣ Testing quest creation...")
        quest_create_data = {
            "quest_type": "lesson_count",
            "target_value": 5,
            "duration_days": 7,
            "title": "Lesson Master",
        }
        create_response = await client.post(
            f"{BASE_URL}/api/v1/quests/", json=quest_create_data, headers=auth_headers
        )
        if create_response.status_code == 200:
            print(f"  ✅ POST /api/v1/quests/ → {create_response.status_code}")
            quest_id = create_response.json()["id"]
            results.append(True)
        else:
            print(f"  ❌ POST /api/v1/quests/ → {create_response.status_code}")
            print(f"     Response: {create_response.text}")
            quest_id = None
            results.append(False)

        # Test 9: List active quests
        print("\n9️⃣ Testing active quests list...")
        results.append(await test_endpoint(client, "GET", "/api/v1/quests/active", headers=auth_headers))

        # Test 10: Get specific quest
        if quest_id:
            print("\n🔟 Testing quest detail...")
            results.append(
                await test_endpoint(client, "GET", f"/api/v1/quests/{quest_id}", headers=auth_headers)
            )

        # Print summary
        print("\n" + "=" * 60)
        passed = sum(results)
        total = len(results)
        print(f"📊 Test Results: {passed}/{total} passed ({passed * 100 // total}%)")

        if passed == total:
            print("✅ All tests passed!")
            return 0
        else:
            print(f"❌ {total - passed} test(s) failed")
            return 1


if __name__ == "__main__":
    sys.exit(asyncio.run(main()))
