"""Email job scheduler using APScheduler.

Schedules automated email campaigns:
- Streak reminders (daily at multiple hours)
- SRS review reminders (daily at multiple hours)
- Weekly progress digests (Mondays at 9:00 AM)
- Onboarding emails (daily check for new users)
- Re-engagement emails (daily check for inactive users)

Usage:
    from app.jobs.scheduler import email_scheduler

    # Start scheduler when app starts
    await email_scheduler.start()

    # Stop scheduler when app shuts down
    await email_scheduler.stop()
"""

from __future__ import annotations

import asyncio
import logging
from datetime import datetime

logger = logging.getLogger(__name__)


class EmailScheduler:
    """Scheduler for email cron jobs using APScheduler.

    Manages scheduled tasks for automated email campaigns.
    All jobs run asynchronously without blocking the main application.
    """

    def __init__(self):
        """Initialize scheduler (without starting)."""
        self.scheduler = None
        self._started = False
        self._lock = asyncio.Lock()

    async def start(self) -> None:
        """Start the scheduler and register all email jobs.

        Should be called during application startup.
        """
        async with self._lock:
            if self._started:
                logger.warning("Email scheduler already started")
                return

            try:
                from apscheduler.schedulers.asyncio import AsyncIOScheduler
                from apscheduler.triggers.cron import CronTrigger
            except ImportError as exc:
                logger.error(
                    "APScheduler not installed. Email jobs will not run. "
                    "Install with: pip install apscheduler"
                )
                raise ImportError("APScheduler library required for email jobs") from exc

            self.scheduler = AsyncIOScheduler()

            # Import email job functions
            from app.jobs.email_jobs import (
                send_onboarding_emails,
                send_re_engagement_emails,
                send_srs_review_reminders,
                send_streak_reminders,
                send_weekly_digest,
            )

            # Register jobs
            self._register_streak_reminder_jobs(CronTrigger, send_streak_reminders)
            self._register_srs_reminder_jobs(CronTrigger, send_srs_review_reminders)
            self._register_weekly_digest_job(CronTrigger, send_weekly_digest)
            self._register_onboarding_job(CronTrigger, send_onboarding_emails)
            self._register_re_engagement_job(CronTrigger, send_re_engagement_emails)

            # Start scheduler
            self.scheduler.start()
            self._started = True
            logger.info("Email scheduler started successfully")

    async def stop(self) -> None:
        """Stop the scheduler.

        Should be called during application shutdown.
        """
        async with self._lock:
            if not self._started:
                return

            if self.scheduler:
                self.scheduler.shutdown(wait=True)
                logger.info("Email scheduler stopped")

            self._started = False

    def _register_streak_reminder_jobs(self, CronTrigger, send_streak_reminders) -> None:
        """Register streak reminder jobs for multiple hours throughout the day.

        Runs at hours: 16, 17, 18, 19, 20, 21 (4 PM to 9 PM)
        Users can customize their preferred reminder hour.
        """
        # Run streak reminders every hour from 4 PM to 9 PM (user's local time is handled by preference)
        for hour in range(16, 22):
            self.scheduler.add_job(
                send_streak_reminders,
                trigger=CronTrigger(hour=hour, minute=0),
                args=[hour],
                id=f"streak_reminder_hour_{hour}",
                name=f"Streak Reminder - Hour {hour}",
                replace_existing=True,
                max_instances=1,
            )
        logger.info("Registered streak reminder jobs (16:00-21:00)")

    def _register_srs_reminder_jobs(self, CronTrigger, send_srs_review_reminders) -> None:
        """Register SRS review reminder jobs for multiple hours.

        Runs at hours: 7, 8, 9, 10, 11 (7 AM to 11 AM)
        Users can customize their preferred reminder hour.
        """
        # Run SRS reminders every hour from 7 AM to 11 AM
        for hour in range(7, 12):
            self.scheduler.add_job(
                send_srs_review_reminders,
                trigger=CronTrigger(hour=hour, minute=0),
                args=[hour],
                id=f"srs_reminder_hour_{hour}",
                name=f"SRS Review Reminder - Hour {hour}",
                replace_existing=True,
                max_instances=1,
            )
        logger.info("Registered SRS reminder jobs (07:00-11:00)")

    def _register_weekly_digest_job(self, CronTrigger, send_weekly_digest) -> None:
        """Register weekly progress digest job.

        Runs every Monday at 9:00 AM UTC.
        """
        self.scheduler.add_job(
            send_weekly_digest,
            trigger=CronTrigger(day_of_week="mon", hour=9, minute=0),
            id="weekly_digest",
            name="Weekly Progress Digest",
            replace_existing=True,
            max_instances=1,
        )
        logger.info("Registered weekly digest job (Mondays 09:00)")

    def _register_onboarding_job(self, CronTrigger, send_onboarding_emails) -> None:
        """Register onboarding email job.

        Runs daily at 10:00 AM UTC to send Day 1, 3, 7 emails.
        """
        self.scheduler.add_job(
            send_onboarding_emails,
            trigger=CronTrigger(hour=10, minute=0),
            id="onboarding_emails",
            name="Onboarding Email Sequence",
            replace_existing=True,
            max_instances=1,
        )
        logger.info("Registered onboarding job (daily 10:00)")

    def _register_re_engagement_job(self, CronTrigger, send_re_engagement_emails) -> None:
        """Register re-engagement email job.

        Runs daily at 11:00 AM UTC to send 7, 14, 30 day re-engagement emails.
        """
        self.scheduler.add_job(
            send_re_engagement_emails,
            trigger=CronTrigger(hour=11, minute=0),
            id="re_engagement_emails",
            name="Re-engagement Campaign",
            replace_existing=True,
            max_instances=1,
        )
        logger.info("Registered re-engagement job (daily 11:00)")

    def get_jobs(self) -> list[dict]:
        """Get list of scheduled jobs with their next run times.

        Returns:
            List of job details (id, name, next_run_time)

        Example:
            jobs = scheduler.get_jobs()
            for job in jobs:
                print(f"{job['name']}: {job['next_run_time']}")
        """
        if not self.scheduler:
            return []

        jobs = []
        for job in self.scheduler.get_jobs():
            jobs.append(
                {
                    "id": job.id,
                    "name": job.name,
                    "next_run_time": job.next_run_time.isoformat() if job.next_run_time else None,
                }
            )
        return jobs


# Global scheduler instance
email_scheduler = EmailScheduler()


async def start_email_scheduler() -> None:
    """Start the email scheduler.

    Call this during application startup (in lifespan context).
    """
    await email_scheduler.start()


async def stop_email_scheduler() -> None:
    """Stop the email scheduler.

    Call this during application shutdown (in lifespan context).
    """
    await email_scheduler.stop()


__all__ = [
    "EmailScheduler",
    "email_scheduler",
    "start_email_scheduler",
    "stop_email_scheduler",
]
