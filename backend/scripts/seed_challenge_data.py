#!/usr/bin/env python3
"""Seed challenge data for testing leaderboard and streaks."""

import asyncio
import sys
from pathlib import Path

# Fix Windows console encoding
if sys.platform == "win32":
    sys.stdout.reconfigure(encoding="utf-8")

# Add backend to path
backend_dir = Path(__file__).parent.parent
sys.path.insert(0, str(backend_dir))

from datetime import datetime, timedelta, timezone  # noqa: E402

from app.db.session import SessionLocal  # noqa: E402
from app.db.social_models import ChallengeStreak, DailyChallenge  # noqa: E402
from app.db.user_models import User  # noqa: E402
from sqlalchemy import select  # noqa: E402


async def seed_challenge_data():
    """Seed challenge completion data for multiple users."""

    async with SessionLocal() as db:
        # Get all users
        result = await db.execute(select(User))
        users = result.scalars().all()

        if not users:
            print("No users found. Please create users first.")
            return

        print(f"Found {len(users)} users")

        # Create some completed challenges and streaks for testing
        for i, user in enumerate(users[:5]):  # Top 5 users
            streak_days = 5 - i  # Descending streaks
            completed_count = (5 - i) * 3  # Descending completion counts

            # Create or update streak
            streak_query = select(ChallengeStreak).where(ChallengeStreak.user_id == user.id)
            result = await db.execute(streak_query)
            streak = result.scalar_one_or_none()

            if not streak:
                streak = ChallengeStreak(
                    user_id=user.id,
                    current_streak=streak_days,
                    longest_streak=streak_days + 2,
                    total_days_completed=streak_days + 10,
                    last_completion_date=datetime.now(timezone.utc),
                    is_active_today=True,
                )
                db.add(streak)
            else:
                streak.current_streak = streak_days
                streak.longest_streak = streak_days + 2
                streak.total_days_completed = streak_days + 10
                streak.is_active_today = True

            # Create some completed challenges
            for day_offset in range(streak_days):
                date = datetime.now(timezone.utc) - timedelta(days=day_offset)
                expires_at = datetime(date.year, date.month, date.day, 23, 59, 59)

                for challenge_num in range(3):  # 3 challenges per day
                    challenge_types = ["lessons_completed", "xp_earned", "streak_maintain"]
                    challenge = DailyChallenge(
                        user_id=user.id,
                        challenge_type=challenge_types[challenge_num],
                        difficulty="medium",
                        title=f"Test Challenge {challenge_num + 1}",
                        description="Auto-generated test challenge",
                        target_value=3,
                        current_progress=3,
                        coin_reward=100,
                        xp_reward=50,
                        is_completed=True,
                        is_weekend_bonus=False,
                        completed_at=date,
                        expires_at=expires_at,
                    )
                    db.add(challenge)

            print(
                f"✓ Seeded data for user {user.username}: "
                f"{streak_days} day streak, {completed_count} challenges"
            )

        await db.commit()
        print("\n✅ Challenge data seeded successfully!")


if __name__ == "__main__":
    asyncio.run(seed_challenge_data())
