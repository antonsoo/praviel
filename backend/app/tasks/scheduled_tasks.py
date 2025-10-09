"""Scheduled tasks for automated challenge maintenance.

This module handles:
- Daily streak freeze auto-use for users who miss challenges
- Weekly challenge expiry and regeneration
"""

import asyncio
import logging
from datetime import datetime, timedelta

from sqlalchemy import select

from app.db.session import SessionLocal
from app.db.social_models import DailyChallenge, WeeklyChallenge
from app.db.user_models import User

logger = logging.getLogger(__name__)


class ScheduledTaskRunner:
    """Background task runner for challenge-related scheduled tasks."""

    def __init__(self):
        self._tasks: list[asyncio.Task] = []
        self._running = False

    async def start(self):
        """Start all scheduled tasks."""
        if self._running:
            logger.warning("Scheduled tasks already running")
            return

        self._running = True
        logger.info("Starting scheduled tasks...")

        # Start daily streak freeze checker (runs at midnight)
        self._tasks.append(
            asyncio.create_task(self._run_daily_task(self.check_streak_freezes, hour=0, minute=0))
        )

        # Start weekly challenge cleanup (runs Monday at midnight)
        self._tasks.append(
            asyncio.create_task(self._run_weekly_task(self.cleanup_expired_challenges, weekday=0, hour=0))
        )

        logger.info(f"Started {len(self._tasks)} scheduled tasks")

    async def stop(self):
        """Stop all scheduled tasks."""
        if not self._running:
            return

        self._running = False
        logger.info("Stopping scheduled tasks...")

        for task in self._tasks:
            task.cancel()

        await asyncio.gather(*self._tasks, return_exceptions=True)
        self._tasks.clear()
        logger.info("Scheduled tasks stopped")

    async def _run_daily_task(self, task_func, hour: int, minute: int):
        """Run a task daily at the specified time."""
        while self._running:
            try:
                # Calculate time until next run
                now = datetime.now()
                next_run = now.replace(hour=hour, minute=minute, second=0, microsecond=0)
                if next_run <= now:
                    next_run += timedelta(days=1)

                wait_seconds = (next_run - now).total_seconds()
                logger.info(f"Next {task_func.__name__} run in {wait_seconds / 3600:.1f} hours")

                await asyncio.sleep(wait_seconds)
                await task_func()

            except asyncio.CancelledError:
                break
            except Exception as e:
                logger.error(f"Error in daily task {task_func.__name__}: {e}", exc_info=True)
                await asyncio.sleep(3600)  # Wait 1 hour before retry

    async def _run_weekly_task(self, task_func, weekday: int, hour: int):
        """Run a task weekly on the specified weekday (0=Monday) at the specified hour."""
        while self._running:
            try:
                # Calculate time until next run
                now = datetime.now()
                days_ahead = weekday - now.weekday()
                if days_ahead <= 0:  # Target day already happened this week
                    days_ahead += 7

                next_run = now + timedelta(days=days_ahead)
                next_run = next_run.replace(hour=hour, minute=0, second=0, microsecond=0)

                wait_seconds = (next_run - now).total_seconds()
                logger.info(f"Next {task_func.__name__} run in {wait_seconds / 3600:.1f} hours")

                await asyncio.sleep(wait_seconds)
                await task_func()

            except asyncio.CancelledError:
                break
            except Exception as e:
                logger.error(f"Error in weekly task {task_func.__name__}: {e}", exc_info=True)
                await asyncio.sleep(3600)  # Wait 1 hour before retry

    async def check_streak_freezes(self):
        """Check for broken streaks and auto-use streak freezes if available.

        Runs daily at midnight to check if users completed their challenges yesterday.
        If not, automatically uses a streak freeze if they have one, otherwise resets their streak.
        """
        logger.info("Running streak freeze auto-use check...")

        async with SessionLocal() as db:
            try:
                yesterday = datetime.now().date() - timedelta(days=1)

                # Get all users
                result = await db.execute(select(User))
                users = result.scalars().all()

                freezes_used = 0
                streaks_reset = 0

                for user in users:
                    # Check if user completed any challenges yesterday
                    challenges_result = await db.execute(
                        select(DailyChallenge).where(
                            DailyChallenge.user_id == user.id,
                            DailyChallenge.is_completed,
                            DailyChallenge.completed_at >= yesterday,
                            DailyChallenge.completed_at < yesterday + timedelta(days=1),
                        )
                    )
                    completed_yesterday = challenges_result.first() is not None

                    if not completed_yesterday:
                        # User didn't complete challenges yesterday
                        if user.streak_freezes > 0:
                            # Use a streak freeze
                            user.streak_freezes -= 1
                            freezes_used += 1
                            logger.info(f"Used streak freeze for user {user.id} ({user.email})")
                        else:
                            # Reset streak
                            if user.current_streak > 0:
                                user.current_streak = 0
                                streaks_reset += 1
                                logger.info(f"Reset streak for user {user.id} ({user.email})")

                await db.commit()
                logger.info(
                    f"Streak check complete: {freezes_used} freezes used, {streaks_reset} streaks reset"
                )

            except Exception as e:
                logger.error(f"Error checking streak freezes: {e}", exc_info=True)
                await db.rollback()

    async def cleanup_expired_challenges(self):
        """Clean up expired weekly challenges and generate new ones.

        Runs every Monday at midnight to mark expired challenges and generate new weekly challenges.
        """
        logger.info("Running weekly challenge cleanup...")

        async with SessionLocal() as db:
            try:
                now = datetime.now()

                # Mark expired weekly challenges
                result = await db.execute(
                    select(WeeklyChallenge).where(
                        WeeklyChallenge.expires_at < now, ~WeeklyChallenge.is_completed
                    )
                )
                expired_challenges = result.scalars().all()

                for challenge in expired_challenges:
                    logger.info(f"Marking weekly challenge {challenge.id} as expired")
                    # Note: Challenges are automatically filtered by expires_at in queries

                await db.commit()
                logger.info(f"Weekly cleanup complete: {len(expired_challenges)} challenges expired")

                # Note: New weekly challenges are generated on-demand when users request them
                # See daily_challenges.py router for generation logic

            except Exception as e:
                logger.error(f"Error cleaning up weekly challenges: {e}", exc_info=True)
                await db.rollback()


# Global task runner instance
task_runner = ScheduledTaskRunner()
