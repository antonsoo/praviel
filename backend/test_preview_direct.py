#!/usr/bin/env python3
"""Test preview endpoint directly via test client."""

import asyncio
import sys

if sys.platform == "win32":
    import io

    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8")

from app.main import app
from httpx import ASGITransport, AsyncClient


async def main():
    print("Testing preview endpoint with test client...\n")

    # Create test user
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        # Register
        timestamp = int(asyncio.get_event_loop().time())
        register_data = {
            "username": f"preview{timestamp}",
            "email": f"preview{timestamp}@test.com",
            "password": "TestPass123!",
        }

        response = await client.post("/api/v1/auth/register", json=register_data)
        if response.status_code != 201:
            print(f"Registration failed: {response.status_code}")
            return False

        # Login
        login_data = {
            "username_or_email": register_data["username"],
            "password": register_data["password"],
        }
        response = await client.post("/api/v1/auth/login", json=login_data)
        if response.status_code != 200:
            print(f"Login failed: {response.status_code}")
            return False

        token = response.json()["access_token"]
        headers = {"Authorization": f"Bearer {token}"}

        # Test preview
        print("Testing POST /api/v1/quests/preview...")
        preview_data = {
            "quest_type": "daily_streak",
            "target_value": 7,
            "duration_days": 14,
        }
        response = await client.post("/api/v1/quests/preview", json=preview_data, headers=headers)

        print(f"Status: {response.status_code}")
        if response.status_code == 200:
            data = response.json()
            print("✅ SUCCESS!")
            print(f"Title: {data['title']}")
            print(f"XP: {data['xp_reward']}, Coins: {data['coin_reward']}")
            print(f"Difficulty: {data['difficulty_tier']}")
            return True
        else:
            print(f"❌ FAILED: {response.text}")
            return False


if __name__ == "__main__":
    result = asyncio.run(main())
    sys.exit(0 if result else 1)
