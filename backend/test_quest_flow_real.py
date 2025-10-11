#!/usr/bin/env python3
"""Actually test quest system end-to-end with real user interactions."""

import asyncio
import sys

if sys.platform == "win32":
    import io

    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8")

import httpx

BASE_URL = "http://localhost:8000"


async def main():
    print("=== REAL QUEST SYSTEM TEST ===\n")

    async with httpx.AsyncClient(timeout=30.0) as client:
        # 1. Create a user
        print("1. Creating test user...")
        timestamp = int(asyncio.get_event_loop().time())
        register_data = {
            "username": f"questtest{timestamp}",
            "email": f"questtest{timestamp}@test.com",
            "password": "TestPass123!",
        }

        response = await client.post(f"{BASE_URL}/api/v1/auth/register", json=register_data)
        if response.status_code != 201:
            print(f"FAILED: Registration failed: {response.status_code}")
            print(response.text)
            return False
        print(f"✓ User created: {register_data['username']}")

        # 2. Login
        print("\n2. Logging in...")
        login_data = {
            "username_or_email": register_data["username"],
            "password": register_data["password"],
        }
        response = await client.post(f"{BASE_URL}/api/v1/auth/login", json=login_data)
        if response.status_code != 200:
            print(f"FAILED: Login failed: {response.status_code}")
            return False

        token = response.json()["access_token"]
        headers = {"Authorization": f"Bearer {token}"}
        print("✓ Logged in")

        # 3. Check available quest templates
        print("\n3. Fetching available quest templates...")
        response = await client.get(f"{BASE_URL}/api/v1/quests/available", headers=headers)
        if response.status_code != 200:
            print(f"FAILED: Cannot get templates: {response.status_code}")
            return False

        templates = response.json()
        print(f"✓ Found {len(templates)} quest templates")
        for t in templates:
            print(f"  - {t['quest_type']}: {t['title']}")

        # 4. Preview a quest
        print("\n4. Previewing daily_streak quest...")
        preview_data = {
            "quest_type": "daily_streak",
            "target_value": 7,
            "duration_days": 14,
        }
        response = await client.post(f"{BASE_URL}/api/v1/quests/preview", json=preview_data, headers=headers)
        if response.status_code != 200:
            print(f"FAILED: Preview failed: {response.status_code}")
            print(f"Response: {response.text}")
            # Try alternative endpoint
            print("Trying GET method...")
            response = await client.get(f"{BASE_URL}/api/v1/quests/preview", headers=headers)
            print(f"GET response: {response.status_code}")
            return False

        preview = response.json()
        print(f"✓ Preview: {preview['title']}")
        print(f"  XP: {preview['xp_reward']}, Coins: {preview['coin_reward']}")
        print(f"  Difficulty: {preview['difficulty_tier']}")

        # 5. Create the quest
        print("\n5. Creating quest...")
        create_data = {
            "quest_type": "lesson_count",
            "target_value": 10,
            "duration_days": 14,
            "title": "Lesson Marathon",
        }
        response = await client.post(f"{BASE_URL}/api/v1/quests/", json=create_data, headers=headers)
        if response.status_code != 200:
            print(f"FAILED: Quest creation failed: {response.status_code}")
            print(f"Response: {response.text}")
            return False

        quest = response.json()
        quest_id = quest["id"]
        print(f"✓ Created quest ID {quest_id}: {quest['title']}")
        print(f"  Target: {quest['target_value']}, Progress: {quest['current_progress']}")

        # 6. List active quests
        print("\n6. Listing active quests...")
        response = await client.get(f"{BASE_URL}/api/v1/quests/active", headers=headers)
        if response.status_code != 200:
            print(f"FAILED: Cannot list quests: {response.status_code}")
            return False

        quests = response.json()
        print(f"✓ Found {len(quests)} active quests")

        # 7. Complete a lesson to make progress
        print("\n7. Generating a lesson to make quest progress...")
        lesson_data = {
            "language": "grc",
            "profile": "beginner",
            "sources": ["daily"],
            "exercise_types": ["match", "cloze"],
            "task_count": 4,
        }
        response = await client.post(f"{BASE_URL}/lesson/generate", json=lesson_data, headers=headers)
        if response.status_code != 200:
            print(f"FAILED: Lesson generation failed: {response.status_code}")
            print(f"Response: {response.text}")
            return False

        lesson = response.json()
        print(f"✓ Generated lesson with {len(lesson['tasks'])} tasks")

        # 8. Check if quest progress updated (should auto-increment)
        print("\n8. Checking quest progress after lesson...")
        response = await client.get(f"{BASE_URL}/api/v1/quests/{quest_id}", headers=headers)
        if response.status_code != 200:
            print(f"FAILED: Cannot get quest details: {response.status_code}")
            return False

        updated_quest = response.json()
        print(f"✓ Quest progress: {updated_quest['current_progress']}/{updated_quest['target_value']}")

        if updated_quest["current_progress"] == 0:
            print("⚠ WARNING: Quest progress did NOT auto-increment after lesson!")
            print("  This means quest tracking is NOT working!")
            return False

        # 9. Try to complete the quest manually
        print("\n9. Attempting to complete quest...")
        response = await client.post(f"{BASE_URL}/api/v1/quests/{quest_id}/complete", headers=headers)
        print(f"Complete endpoint status: {response.status_code}")
        if response.status_code == 200:
            print("✓ Quest completion works")
        else:
            print(f"Note: Quest completion response: {response.text}")

        # 10. Try to abandon quest
        print("\n10. Testing quest abandonment...")
        # Create another quest first
        create_data2 = {
            "quest_type": "xp_milestone",
            "target_value": 500,
            "duration_days": 7,
        }
        response = await client.post(f"{BASE_URL}/api/v1/quests/", json=create_data2, headers=headers)
        if response.status_code == 200:
            quest2_id = response.json()["id"]
            response = await client.post(f"{BASE_URL}/api/v1/quests/{quest2_id}/abandon", headers=headers)
            print(f"Abandon endpoint status: {response.status_code}")

        print("\n=== TEST COMPLETE ===")
        return True


if __name__ == "__main__":
    result = asyncio.run(main())
    sys.exit(0 if result else 1)
