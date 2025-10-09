#!/usr/bin/env python3
"""Seed the database with test users and leaderboard data.

This script creates 20 test users with varying XP levels to populate
the leaderboard for testing purposes, along with social features:
- Friendships
- Leaderboard entries (global and regional)
- Power-up inventories
- Friend challenges
- Achievements and quests

Usage:
    python backend/scripts/seed_leaderboard.py

Or from project root with correct Python:
    C:/ProgramData/anaconda3/envs/ancient-languages-py312/python.exe backend/scripts/seed_leaderboard.py
"""

import asyncio
import random
import sys
from datetime import datetime, timedelta, timezone
from pathlib import Path

# Add backend to path
backend_dir = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(backend_dir))

from app.db.session import SessionLocal  # noqa: E402
from app.db.social_models import (  # noqa: E402
    FriendChallenge,
    Friendship,
    LeaderboardEntry,
    PowerUpInventory,
)
from app.db.user_models import (  # noqa: E402
    User,
    UserAchievement,
    UserPreferences,
    UserProfile,
    UserProgress,
    UserQuest,
)
from app.security.auth import hash_password  # noqa: E402
from sqlalchemy import delete, select  # noqa: E402


async def seed_leaderboard_data():
    """Create test users with varying XP for leaderboard testing."""

    # Test users with region data for regional leaderboards
    test_users = [
        ("sophia_chen", "sophia@example.com", 15000, "Sophia Chen", "USA"),
        ("marcus_johnson", "marcus@example.com", 13500, "Marcus Johnson", "USA"),
        ("elena_rodriguez", "elena@example.com", 12800, "Elena Rodriguez", "Spain"),
        ("james_wilson", "james@example.com", 11200, "James Wilson", "UK"),
        ("amara_okonkwo", "amara@example.com", 10500, "Amara Okonkwo", "Nigeria"),
        ("lucas_martin", "lucas@example.com", 9800, "Lucas Martin", "France"),
        ("yuki_tanaka", "yuki@example.com", 8900, "Yuki Tanaka", "Japan"),
        ("isabella_garcia", "isabella@example.com", 8200, "Isabella Garcia", "Spain"),
        ("noah_thompson", "noah@example.com", 7600, "Noah Thompson", "USA"),
        ("priya_patel", "priya@example.com", 6800, "Priya Patel", "India"),
        ("liam_obrien", "liam@example.com", 6200, "Liam O'Brien", "Ireland"),
        ("maya_singh", "maya@example.com", 5500, "Maya Singh", "India"),
        ("ethan_kim", "ethan@example.com", 4900, "Ethan Kim", "South Korea"),
        ("zara_hassan", "zara@example.com", 4200, "Zara Hassan", "Pakistan"),
        ("oliver_brown", "oliver@example.com", 3800, "Oliver Brown", "UK"),
        ("aria_nguyen", "aria@example.com", 3200, "Aria Nguyen", "Vietnam"),
        ("felix_mueller", "felix@example.com", 2700, "Felix Mueller", "Germany"),
        ("leila_abbasi", "leila@example.com", 2100, "Leila Abbasi", "Iran"),
        ("diego_silva", "diego@example.com", 1600, "Diego Silva", "Brazil"),
        ("nora_kowalski", "nora@example.com", 1200, "Nora Kowalski", "Poland"),
    ]

    # Friendships to create (username pairs)
    friendships = [
        ("sophia_chen", "marcus_johnson"),
        ("sophia_chen", "noah_thompson"),
        ("marcus_johnson", "james_wilson"),
        ("elena_rodriguez", "isabella_garcia"),
        ("james_wilson", "oliver_brown"),
        ("lucas_martin", "felix_mueller"),
        ("yuki_tanaka", "ethan_kim"),
        ("priya_patel", "maya_singh"),
        ("liam_obrien", "james_wilson"),
    ]

    # Power-ups to give
    power_ups = {
        "streak_freeze": ["sophia_chen", "marcus_johnson", "elena_rodriguez", "james_wilson"],
        "xp_boost": ["lucas_martin", "yuki_tanaka", "priya_patel"],
        "hint_reveal": ["isabella_garcia", "noah_thompson"],
    }

    async with SessionLocal() as db:
        # Clear existing test data
        print("[*] Clearing existing test data...")
        await db.execute(delete(PowerUpInventory))
        await db.execute(delete(FriendChallenge))
        await db.execute(delete(Friendship))
        await db.execute(delete(LeaderboardEntry))
        await db.execute(delete(UserQuest))
        await db.execute(delete(UserAchievement))
        await db.commit()
        print("[OK] Cleared existing social data\n")

        # Track created users
        user_map = {}
        created_count = 0
        skipped_count = 0
        now = datetime.now(timezone.utc)

        print("[*] Creating users...")
        for username, email, xp, display_name, region in test_users:
            # Check if user already exists
            existing_query = select(User).where((User.username == username) | (User.email == email))
            existing_result = await db.execute(existing_query)
            existing_user = existing_result.scalar_one_or_none()

            if existing_user:
                print(f"  Using existing: {username}")
                user_map[username] = existing_user
                skipped_count += 1
                continue

            # Create user
            user = User(
                username=username,
                email=email,
                hashed_password=hash_password("password123"),
                is_active=True,
            )
            db.add(user)
            await db.flush()  # Get user ID

            # Create user profile
            profile = UserProfile(
                user_id=user.id,
                real_name=display_name,
            )
            db.add(profile)

            # Create preferences
            prefs = UserPreferences(
                user_id=user.id,
                daily_xp_goal=50,
            )
            db.add(prefs)

            # Create user progress with XP
            level = xp // 100  # 100 XP per level
            streak = min(xp // 200, 30)
            progress = UserProgress(
                user_id=user.id,
                xp_total=xp,
                level=level,
                streak_days=streak,
                max_streak=streak + random.randint(0, 10),
                total_lessons=xp // 50,
                total_exercises=xp // 10,
                total_time_minutes=(xp // 50) * random.randint(15, 45),
                last_lesson_at=now - timedelta(hours=random.randint(1, 48)),
                last_streak_update=now - timedelta(hours=random.randint(1, 24)),
            )
            db.add(progress)

            # Add achievements
            if xp >= 1000:
                ach = UserAchievement(
                    user_id=user.id,
                    achievement_type="milestone",
                    achievement_id="xp_1000",
                    unlocked_at=now - timedelta(days=random.randint(1, 60)),
                )
                db.add(ach)
            if xp >= 5000:
                ach = UserAchievement(
                    user_id=user.id,
                    achievement_type="milestone",
                    achievement_id="xp_5000",
                    unlocked_at=now - timedelta(days=random.randint(1, 30)),
                )
                db.add(ach)
            if xp >= 10000:
                ach = UserAchievement(
                    user_id=user.id,
                    achievement_type="milestone",
                    achievement_id="xp_10000",
                    unlocked_at=now - timedelta(days=random.randint(1, 15)),
                )
                db.add(ach)

            user_map[username] = user
            created_count += 1
            print(f"  Created: {username} (Level {level}, {xp:,} XP, {region})")

        await db.commit()

        # Create leaderboard entries
        print("\n[*] Creating leaderboard entries...")
        sorted_users = sorted(test_users, key=lambda u: u[2], reverse=True)

        # Global leaderboard
        for rank, (username, _, xp, _, region) in enumerate(sorted_users, start=1):
            user = user_map.get(username)
            if not user:
                continue
            entry = LeaderboardEntry(
                user_id=user.id,
                board_type="global",
                rank=rank,
                xp_total=xp,
                level=xp // 100,
                calculated_at=now,
            )
            db.add(entry)

        # Regional leaderboards
        regions = {}
        for username, _, xp, _, region in test_users:
            if region not in regions:
                regions[region] = []
            regions[region].append((username, xp))

        for region, region_users in regions.items():
            sorted_region = sorted(region_users, key=lambda u: u[1], reverse=True)
            for rank, (username, xp) in enumerate(sorted_region, start=1):
                user = user_map.get(username)
                if not user:
                    continue
                entry = LeaderboardEntry(
                    user_id=user.id,
                    board_type="local",
                    region=region,
                    rank=rank,
                    xp_total=xp,
                    level=xp // 100,
                    calculated_at=now,
                )
                db.add(entry)

        await db.commit()
        print(f"[OK] Created leaderboard entries for {len(sorted_users)} users")

        # Create friendships
        print("\n[*] Creating friendships...")
        friendship_count = 0
        for user1_name, user2_name in friendships:
            user1 = user_map.get(user1_name)
            user2 = user_map.get(user2_name)
            if not user1 or not user2:
                continue

            # Bidirectional friendship
            f1 = Friendship(
                user_id=user1.id,
                friend_id=user2.id,
                status="accepted",
                initiated_by_user_id=user1.id,
                accepted_at=now - timedelta(days=random.randint(1, 90)),
            )
            f2 = Friendship(
                user_id=user2.id,
                friend_id=user1.id,
                status="accepted",
                initiated_by_user_id=user1.id,
                accepted_at=f1.accepted_at,
            )
            db.add(f1)
            db.add(f2)
            friendship_count += 1

        await db.commit()
        print(f"[OK] Created {friendship_count} friendships")

        # Create power-ups
        print("\n[*] Creating power-ups...")
        powerup_count = 0
        for power_up_type, usernames in power_ups.items():
            for username in usernames:
                user = user_map.get(username)
                if not user:
                    continue
                inv = PowerUpInventory(
                    user_id=user.id,
                    power_up_type=power_up_type,
                    quantity=random.randint(1, 5),
                    active_count=0,
                )
                db.add(inv)
                powerup_count += 1

        await db.commit()
        print(f"[OK] Created {powerup_count} power-up entries")

        # Create challenges
        print("\n[*] Creating challenges...")
        challenge_pairs = [
            ("sophia_chen", "marcus_johnson", "xp_race", 1000),
            ("elena_rodriguez", "isabella_garcia", "lesson_count", 10),
        ]
        challenge_count = 0
        for user1_name, user2_name, challenge_type, target in challenge_pairs:
            user1 = user_map.get(user1_name)
            user2 = user_map.get(user2_name)
            if not user1 or not user2:
                continue

            challenge = FriendChallenge(
                initiator_user_id=user1.id,
                opponent_user_id=user2.id,
                challenge_type=challenge_type,
                target_value=target,
                initiator_progress=random.randint(0, target),
                opponent_progress=random.randint(0, target),
                status="active",
                starts_at=now - timedelta(days=random.randint(1, 7)),
                expires_at=now + timedelta(days=random.randint(7, 30)),
            )
            db.add(challenge)
            challenge_count += 1

        await db.commit()
        print(f"[OK] Created {challenge_count} challenges")

        print(f"\n{'=' * 60}")
        print("[SUMMARY]")
        print(f"  Users: {created_count} created, {skipped_count} existing")
        print(f"  Friendships: {friendship_count}")
        print(f"  Power-ups: {powerup_count}")
        print(f"  Challenges: {challenge_count}")
        print("  Password: password123")
        print(f"{'=' * 60}")


async def main():
    """Main entry point."""
    print("Seeding leaderboard data...")
    print("=" * 60)

    try:
        await seed_leaderboard_data()
        print("\n" + "=" * 60)
        print("SUCCESS: Leaderboard data seeded!")
        return 0
    except Exception as e:
        print("\n" + "=" * 60)
        print(f"ERROR: Failed to seed data: {e}")
        import traceback

        traceback.print_exc()
        return 1


if __name__ == "__main__":
    sys.exit(asyncio.run(main()))
