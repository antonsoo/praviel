#!/usr/bin/env python3
"""
Comprehensive integration test to check ALL backend/frontend connections.
Tests authentication, progress tracking, streaks, achievements, lessons, etc.
"""

import asyncio
import sys
from datetime import datetime
from pathlib import Path

import httpx

# Add backend to path
backend_path = Path(__file__).parent.parent.parent / "backend"
sys.path.insert(0, str(backend_path))

BASE_URL = "http://localhost:8001"
TEST_EMAIL = f"test_user_{datetime.now().timestamp()}@example.com"
TEST_PASSWORD = "TestPassword123!"
TEST_USERNAME = f"testuser_{int(datetime.now().timestamp())}"


class IntegrationTester:
    def __init__(self):
        self.client = httpx.AsyncClient(base_url=BASE_URL, timeout=30.0)
        self.token = None
        self.user_id = None
        self.results = {}

    async def close(self):
        await self.client.aclose()

    def log(self, test_name: str, passed: bool, message: str = ""):
        status = "[PASS]" if passed else "[FAIL]"
        self.results[test_name] = passed
        print(f"{status} | {test_name:<40} | {message}")

    async def test_health(self):
        """Test health endpoint"""
        try:
            response = await self.client.get("/health")
            passed = response.status_code == 200
            self.log("Backend Health Check", passed, f"Status: {response.status_code}")
            return passed
        except Exception as e:
            self.log("Backend Health Check", False, f"Error: {e}")
            return False

    async def test_registration(self):
        """Test user registration"""
        try:
            response = await self.client.post(
                "/api/v1/auth/register",
                json={
                    "email": TEST_EMAIL,
                    "password": TEST_PASSWORD,
                    "username": TEST_USERNAME,
                },
            )
            passed = response.status_code in (200, 201)
            if passed:
                data = response.json()
                self.token = data.get("access_token")
                self.user_id = data.get("user_id")
                self.log(
                    "User Registration", passed, f"Token: {self.token[:20] if self.token else 'None'}..."
                )
            else:
                self.log(
                    "User Registration",
                    passed,
                    f"Status: {response.status_code}, Body: {response.text[:100]}",
                )
            return passed
        except Exception as e:
            self.log("User Registration", False, f"Error: {e}")
            return False

    async def test_login(self):
        """Test user login"""
        try:
            response = await self.client.post(
                "/api/v1/auth/login",
                json={
                    "username_or_email": TEST_EMAIL,
                    "password": TEST_PASSWORD,
                },
            )
            passed = response.status_code == 200
            if passed:
                data = response.json()
                self.token = data.get("access_token")
                self.log("User Login", passed, f"Token: {self.token[:20] if self.token else 'None'}...")
            else:
                self.log("User Login", passed, f"Status: {response.status_code}, Body: {response.text[:200]}")
            return passed
        except Exception as e:
            self.log("User Login", False, f"Error: {e}")
            return False

    def get_headers(self):
        return {"Authorization": f"Bearer {self.token}"} if self.token else {}

    async def test_get_progress(self):
        """Test getting user progress"""
        try:
            response = await self.client.get("/api/v1/progress/me", headers=self.get_headers())
            passed = response.status_code == 200
            if passed:
                data = response.json()
                self.log(
                    "Get User Progress",
                    passed,
                    f"XP: {data.get('xp_total')}, Streak: {data.get('streak_days')}",
                )
            else:
                self.log("Get User Progress", passed, f"Status: {response.status_code}")
            return passed
        except Exception as e:
            self.log("Get User Progress", False, f"Error: {e}")
            return False

    async def test_update_progress(self):
        """Test updating user progress (earning XP)"""
        try:
            response = await self.client.post(
                "/api/v1/progress/me/update",
                json={
                    "xp_gained": 50,
                    "lesson_id": "test_lesson_001",
                    "time_spent_minutes": 5,
                },
                headers=self.get_headers(),
            )
            passed = response.status_code == 200
            if passed:
                data = response.json()
                self.log(
                    "Update Progress (Earn XP)",
                    passed,
                    f"XP: {data.get('xp_total')}, Streak: {data.get('streak_days')}",
                )
            else:
                self.log("Update Progress (Earn XP)", passed, f"Status: {response.status_code}")
            return passed
        except Exception as e:
            self.log("Update Progress (Earn XP)", False, f"Error: {e}")
            return False

    async def test_leaderboard_global(self):
        """Test global leaderboard"""
        try:
            response = await self.client.get("/api/v1/social/leaderboard/global", headers=self.get_headers())
            passed = response.status_code == 200
            if passed:
                data = response.json()
                self.log(
                    "Global Leaderboard",
                    passed,
                    f"Users: {len(data.get('users', []))}, Rank: {data.get('current_user_rank')}",
                )
            else:
                self.log("Global Leaderboard", passed, f"Status: {response.status_code}")
            return passed
        except Exception as e:
            self.log("Global Leaderboard", False, f"Error: {e}")
            return False

    async def test_achievements(self):
        """Test achievements endpoint"""
        try:
            response = await self.client.get("/api/v1/progress/me/achievements", headers=self.get_headers())
            passed = response.status_code == 200
            if passed:
                data = response.json()
                self.log("Get Achievements", passed, f"Achievements: {len(data)}")
            else:
                self.log("Get Achievements", passed, f"Status: {response.status_code}")
            return passed
        except Exception as e:
            self.log("Get Achievements", False, f"Error: {e}")
            return False

    async def test_daily_challenges(self):
        """Test daily challenges endpoint"""
        try:
            response = await self.client.get("/api/v1/challenges/daily", headers=self.get_headers())
            passed = response.status_code == 200
            if passed:
                data = response.json()
                self.log("Daily Challenges", passed, f"Challenges: {len(data)}")
            else:
                self.log("Daily Challenges", passed, f"Status: {response.status_code}")
            return passed
        except Exception as e:
            self.log("Daily Challenges", False, f"Error: {e}")
            return False

    async def test_streak_freeze_purchase(self):
        """Test buying streak freeze"""
        try:
            # First earn enough coins
            await self.client.post(
                "/api/v1/progress/me/update",
                json={
                    "xp_gained": 1000,
                    "lesson_id": "earn_coins_test",
                },
                headers=self.get_headers(),
            )

            # Try to buy streak freeze
            response = await self.client.post(
                "/api/v1/progress/me/streak-freeze/buy", headers=self.get_headers()
            )
            passed = response.status_code == 200
            if passed:
                data = response.json()
                self.log(
                    "Buy Streak Freeze",
                    passed,
                    f"Shields: {data.get('streak_freezes')}, Coins: {data.get('coins_remaining')}",
                )
            else:
                self.log("Buy Streak Freeze", passed, f"Status: {response.status_code}")
            return passed
        except Exception as e:
            self.log("Buy Streak Freeze", False, f"Error: {e}")
            return False

    async def test_lesson_generation(self):
        """Test lesson generation (echo provider)"""
        try:
            response = await self.client.post(
                "/lesson/generate",  # No /api/v1 prefix for lesson router
                json={
                    "language": "grc",
                    "profile": "beginner",
                    "sources": ["daily"],
                    "exercise_types": ["match", "cloze"],
                    "k_canon": 2,
                    "provider": "echo",
                },
                headers=self.get_headers(),
            )
            passed = response.status_code == 200
            if passed:
                data = response.json()
                tasks = data.get("tasks", [])
                self.log("Lesson Generation (Echo)", passed, f"Tasks generated: {len(tasks)}")
            else:
                self.log(
                    "Lesson Generation (Echo)",
                    passed,
                    f"Status: {response.status_code}, Body: {response.text[:100]}",
                )
            return passed
        except Exception as e:
            self.log("Lesson Generation (Echo)", False, f"Error: {e}")
            return False

    async def run_all_tests(self):
        """Run all integration tests"""
        print("\n" + "=" * 80)
        print("COMPREHENSIVE INTEGRATION TEST - Backend/Frontend Connections")
        print("=" * 80 + "\n")

        # Core backend tests
        await self.test_health()

        # Authentication tests
        await self.test_registration()
        await self.test_login()

        # Progress & gamification tests
        await self.test_get_progress()
        await self.test_update_progress()
        await self.test_leaderboard_global()
        await self.test_achievements()

        # Feature tests
        await self.test_daily_challenges()
        await self.test_streak_freeze_purchase()
        await self.test_lesson_generation()

        # Summary
        print("\n" + "=" * 80)
        passed_count = sum(1 for v in self.results.values() if v)
        total_count = len(self.results)
        pass_rate = (passed_count / total_count * 100) if total_count > 0 else 0

        print(f"RESULTS: {passed_count}/{total_count} tests passed ({pass_rate:.1f}%)")

        if passed_count == total_count:
            print("SUCCESS: ALL TESTS PASSED! Backend integration is working.")
        elif pass_rate >= 80:
            print("WARNING: Most tests passed, but some issues found.")
        else:
            print("FAILURE: Multiple test failures - Backend integration has issues.")

        print("=" * 80 + "\n")

        return passed_count == total_count


async def main():
    tester = IntegrationTester()
    try:
        success = await tester.run_all_tests()
        sys.exit(0 if success else 1)
    finally:
        await tester.close()


if __name__ == "__main__":
    asyncio.run(main())
