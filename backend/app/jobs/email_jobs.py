"""Cron jobs for automated email campaigns.

This module provides scheduled jobs for:
- Streak reminders (daily, evening)
- SRS review reminders (daily, morning)
- Weekly progress digests (Monday morning)
- Onboarding sequences (Day 1, 3, 7)
- Re-engagement campaigns (7, 14, 30 days inactive)
- Password changed notifications

Run these jobs using a scheduler like APScheduler or system cron.
"""

from __future__ import annotations

import logging
from datetime import datetime, timedelta, timezone

from app.core.config import settings
from app.db.session import SessionLocal
from app.db.user_models import User, UserPreferences, UserProgress
from app.services.email import create_email_service
from app.services.email_marketing import (
    create_email_marketing_service,
)
from app.services.email_templates import EmailTemplates
from sqlalchemy import and_, or_, select

logger = logging.getLogger(__name__)

# Initialize services
_email_service = create_email_service(
    provider=settings.EMAIL_PROVIDER,
    resend_api_key=settings.RESEND_API_KEY,
    sendgrid_api_key=settings.SENDGRID_API_KEY,
    from_address="reminders@praviel.com",
    from_name="PRAVIEL Reminders",
    aws_region=settings.AWS_REGION,
    aws_access_key_id=settings.AWS_ACCESS_KEY_ID,
    aws_secret_access_key=settings.AWS_SECRET_ACCESS_KEY,
    mailgun_domain=settings.MAILGUN_DOMAIN,
    mailgun_api_key=settings.MAILGUN_API_KEY,
    postmark_server_token=settings.POSTMARK_SERVER_TOKEN,
)

_marketing_service = (
    create_email_marketing_service(api_key=settings.RESEND_API_KEY)
    if settings.RESEND_API_KEY and settings.EMAIL_PROVIDER == "resend"
    else None
)


# ============================================================================
# STREAK REMINDERS
# ============================================================================


async def send_streak_reminders(hour: int = 18) -> dict[str, int]:
    """Send streak reminders to users who haven't completed daily goal.

    Should run hourly during the reminder window (e.g., 6 PM - 11 PM).

    Args:
        hour: Current hour (0-23) to check against user preferences

    Returns:
        Dict with stats: {"sent": count, "skipped": count, "errors": count}
    """
    logger.info(f"Starting streak reminder job for hour {hour}")

    stats = {"sent": 0, "skipped": 0, "errors": 0}

    async with SessionLocal() as session:
        # Find users who:
        # 1. Have active streaks
        # 2. Haven't hit their daily XP goal today
        # 3. Have streak reminders enabled
        # 4. Prefer reminders at this hour
        # 5. Haven't been sent a reminder today

        now = datetime.now(timezone.utc)
        today_start = now.replace(hour=0, minute=0, second=0, microsecond=0)

        result = await session.execute(
            select(User, UserPreferences, UserProgress)
            .join(UserPreferences, User.id == UserPreferences.user_id)
            .join(UserProgress, User.id == UserProgress.user_id)
            .where(
                and_(
                    User.is_active,
                    User.email_verified,
                    UserPreferences.email_streak_reminders,
                    UserPreferences.streak_reminder_time == hour,
                    UserProgress.streak_days > 0,
                    # Haven't completed daily goal
                    or_(
                        UserProgress.last_lesson_at < today_start,
                        UserProgress.last_lesson_at.is_(None),
                    ),
                    # Haven't been sent reminder today
                    or_(
                        UserPreferences.last_streak_reminder_sent < today_start,
                        UserPreferences.last_streak_reminder_sent.is_(None),
                    ),
                )
            )
        )

        users_data = result.all()
        logger.info(f"Found {len(users_data)} users for streak reminders")

        for user, prefs, progress in users_data:
            try:
                # Calculate XP needed for daily goal
                xp_needed = max(0, prefs.daily_xp_goal - progress.xp_total)

                # Skip if they've already hit their goal
                if xp_needed == 0:
                    stats["skipped"] += 1
                    continue

                # Generate email
                quick_lesson_url = f"{settings.FRONTEND_URL}/lessons"
                settings_url = f"{settings.FRONTEND_URL}/settings/notifications"

                subject, html, text = EmailTemplates.streak_reminder(
                    username=user.username,
                    streak_days=progress.streak_days,
                    xp_needed=xp_needed,
                    quick_lesson_url=quick_lesson_url,
                    settings_url=settings_url,
                )

                # Send email
                await _email_service.send_email(
                    to_email=user.email,
                    subject=subject,
                    html_body=html,
                    text_body=text,
                )

                # Update last sent timestamp
                prefs.last_streak_reminder_sent = now
                await session.commit()

                stats["sent"] += 1
                logger.info(f"Sent streak reminder to {user.email}")

            except Exception as exc:
                logger.error(f"Failed to send streak reminder to {user.email}: {exc}")
                stats["errors"] += 1
                continue

    logger.info(f"Streak reminder job complete: {stats}")
    return stats


# ============================================================================
# SRS REVIEW REMINDERS
# ============================================================================


async def send_srs_review_reminders(hour: int = 9) -> dict[str, int]:
    """Send SRS review reminders to users with cards due.

    Should run hourly during the morning (e.g., 8 AM - 11 AM).

    Args:
        hour: Current hour (0-23) to check against user preferences

    Returns:
        Dict with stats: {"sent": count, "skipped": count, "errors": count}
    """
    logger.info(f"Starting SRS reminder job for hour {hour}")

    stats = {"sent": 0, "skipped": 0, "errors": 0}

    async with SessionLocal() as session:
        # Find users who:
        # 1. Have SRS cards due today
        # 2. Have SRS reminders enabled
        # 3. Prefer reminders at this hour
        # 4. Haven't been sent a reminder today
        # 5. Haven't reviewed today

        now = datetime.now(timezone.utc)
        today_start = now.replace(hour=0, minute=0, second=0, microsecond=0)

        # Note: This assumes you have a UserSRSCard model with due_date
        # Adjust based on your actual SRS implementation
        result = await session.execute(
            select(User, UserPreferences)
            .join(UserPreferences, User.id == UserPreferences.user_id)
            .where(
                and_(
                    User.is_active,
                    User.email_verified,
                    UserPreferences.email_srs_reminders,
                    UserPreferences.srs_reminder_time == hour,
                    # Haven't been sent reminder today
                    or_(
                        UserPreferences.last_srs_reminder_sent < today_start,
                        UserPreferences.last_srs_reminder_sent.is_(None),
                    ),
                )
            )
        )

        users_data = result.all()

        for user, prefs in users_data:
            try:
                # Count cards due today
                # TODO: Adjust this query based on your actual SRS card model
                from app.db.user_models import UserSRSCard

                cards_result = await session.execute(
                    select(UserSRSCard).where(
                        and_(
                            UserSRSCard.user_id == user.id,
                            UserSRSCard.next_review_date <= now.date(),
                        )
                    )
                )
                cards_due = len(cards_result.all())

                # Skip if no cards due
                if cards_due == 0:
                    stats["skipped"] += 1
                    continue

                # Estimate review time (20 seconds per card)
                estimated_minutes = max(1, (cards_due * 20) // 60)

                # Generate email
                review_url = f"{settings.FRONTEND_URL}/srs/review"
                settings_url = f"{settings.FRONTEND_URL}/settings/notifications"

                subject, html, text = EmailTemplates.srs_review_reminder(
                    username=user.username,
                    cards_due=cards_due,
                    estimated_minutes=estimated_minutes,
                    review_url=review_url,
                    settings_url=settings_url,
                )

                # Send email
                await _email_service.send_email(
                    to_email=user.email,
                    subject=subject,
                    html_body=html,
                    text_body=text,
                )

                # Update last sent timestamp
                prefs.last_srs_reminder_sent = now
                await session.commit()

                stats["sent"] += 1
                logger.info(f"Sent SRS reminder to {user.email} ({cards_due} cards)")

            except Exception as exc:
                logger.error(f"Failed to send SRS reminder to {user.email}: {exc}")
                stats["errors"] += 1
                continue

    logger.info(f"SRS reminder job complete: {stats}")
    return stats


# ============================================================================
# WEEKLY DIGEST
# ============================================================================


async def send_weekly_digest() -> dict[str, int]:
    """Send weekly progress digest to all active users.

    Should run once per week (e.g., Monday 9 AM).

    Returns:
        Dict with stats: {"sent": count, "errors": count}
    """
    logger.info("Starting weekly digest job")

    if not _marketing_service:
        logger.error("Marketing service not available (RESEND_API_KEY not configured)")
        return {"sent": 0, "errors": 1}

    stats = {"sent": 0, "errors": 0}

    try:
        # Get date range for this week
        now = datetime.now(timezone.utc)
        week_start = now - timedelta(days=7)
        week_start_str = week_start.strftime("%b %d")
        week_end_str = now.strftime("%b %d, %Y")

        # Get HTML template
        html = EmailTemplates.weekly_digest_html(
            week_start=week_start_str,
            week_end=week_end_str,
        )

        # Create audience for weekly digest (or use existing)
        # Note: In production, you'd manage this audience separately
        # For now, we'll send to all users with weekly_digest enabled

        async with SessionLocal() as session:
            # Get all users who want weekly digest
            result = await session.execute(
                select(User, UserPreferences, UserProgress)
                .join(UserPreferences, User.id == UserPreferences.user_id)
                .join(UserProgress, User.id == UserProgress.user_id)
                .where(
                    and_(
                        User.is_active,
                        User.email_verified,
                        UserPreferences.email_weekly_digest,
                    )
                )
            )

            users_data = result.all()
            logger.info(f"Found {len(users_data)} users for weekly digest")

            # For Resend broadcasts, we need to use audiences
            # This is a simplified version - in production, maintain a synced audience
            for user, prefs, progress in users_data:
                try:
                    # Calculate weekly stats
                    # In production, you'd track this properly
                    xp_this_week = progress.xp_total  # Simplified
                    lessons_this_week = progress.total_lessons  # Simplified

                    # Send individual email with stats
                    # In production with proper audience management, use broadcast
                    subject = "Your Week in Review"

                    # Replace template variables
                    html_personalized = (
                        html.replace("{{{FIRST_NAME|there}}}", user.username)
                        .replace("{{{XP_THIS_WEEK|0}}}", str(xp_this_week))
                        .replace("{{{STREAK_DAYS|0}}}", str(progress.streak_days))
                        .replace("{{{LESSONS_THIS_WEEK|0}}}", str(lessons_this_week))
                        .replace("{{{SRS_REVIEWS|0}}}", "0")  # TODO: Track this
                    )

                    await _email_service.send_email(
                        to_email=user.email,
                        subject=subject,
                        html_body=html_personalized,
                        text_body=(
                            f"Your week in review: {xp_this_week} XP, "
                            f"{lessons_this_week} lessons, {progress.streak_days} day streak"
                        ),
                    )

                    stats["sent"] += 1
                    logger.info(f"Sent weekly digest to {user.email}")

                except Exception as exc:
                    logger.error(f"Failed to send weekly digest to {user.email}: {exc}")
                    stats["errors"] += 1
                    continue

    except Exception as exc:
        logger.error(f"Weekly digest job failed: {exc}")
        stats["errors"] += 1

    logger.info(f"Weekly digest job complete: {stats}")
    return stats


# ============================================================================
# ONBOARDING SEQUENCE
# ============================================================================


async def send_onboarding_emails() -> dict[str, int]:
    """Send onboarding emails based on user signup date.

    Sends:
    - Day 1: Welcome and getting started
    - Day 3: Pro learning tips
    - Day 7: First week complete

    Should run daily (e.g., 9 AM).

    Returns:
        Dict with stats: {"day1": count, "day3": count, "day7": count, "errors": count}
    """
    logger.info("Starting onboarding email job")

    stats = {"day1": 0, "day3": 0, "day7": 0, "errors": 0}

    async with SessionLocal() as session:
        now = datetime.now(timezone.utc)

        # Day 1: Send to users who signed up in the last 24 hours
        day1_cutoff = now - timedelta(hours=24)
        result_day1 = await session.execute(
            select(User, UserPreferences, UserProgress)
            .join(UserPreferences, User.id == UserPreferences.user_id)
            .join(UserProgress, User.id == UserProgress.user_id)
            .where(
                and_(
                    User.is_active,
                    User.email_verified,
                    UserPreferences.email_onboarding_series,
                    not UserPreferences.onboarding_day1_sent,
                    User.created_at >= day1_cutoff,
                )
            )
        )

        for user, prefs, progress in result_day1.all():
            try:
                first_lesson_url = f"{settings.FRONTEND_URL}/lessons"
                subject, html, text = EmailTemplates.onboarding_day1(
                    username=user.username,
                    first_lesson_url=first_lesson_url,
                )

                await _email_service.send_email(
                    to_email=user.email,
                    subject=subject,
                    html_body=html,
                    text_body=text,
                )

                prefs.onboarding_day1_sent = True
                await session.commit()
                stats["day1"] += 1
                logger.info(f"Sent Day 1 onboarding to {user.email}")

            except Exception as exc:
                logger.error(f"Failed to send Day 1 onboarding to {user.email}: {exc}")
                stats["errors"] += 1

        # Day 3: Send to users who signed up 3 days ago
        day3_start = now - timedelta(days=3, hours=2)
        day3_end = now - timedelta(days=3)

        result_day3 = await session.execute(
            select(User, UserPreferences, UserProgress)
            .join(UserPreferences, User.id == UserPreferences.user_id)
            .join(UserProgress, User.id == UserProgress.user_id)
            .where(
                and_(
                    User.is_active,
                    User.email_verified,
                    UserPreferences.email_onboarding_series,
                    not UserPreferences.onboarding_day3_sent,
                    User.created_at >= day3_start,
                    User.created_at <= day3_end,
                )
            )
        )

        for user, prefs, progress in result_day3.all():
            try:
                srs_url = f"{settings.FRONTEND_URL}/srs"
                texts_url = f"{settings.FRONTEND_URL}/texts"

                subject, html, text = EmailTemplates.onboarding_day3(
                    username=user.username,
                    srs_url=srs_url,
                    texts_url=texts_url,
                )

                await _email_service.send_email(
                    to_email=user.email,
                    subject=subject,
                    html_body=html,
                    text_body=text,
                )

                prefs.onboarding_day3_sent = True
                await session.commit()
                stats["day3"] += 1
                logger.info(f"Sent Day 3 onboarding to {user.email}")

            except Exception as exc:
                logger.error(f"Failed to send Day 3 onboarding to {user.email}: {exc}")
                stats["errors"] += 1

        # Day 7: Send to users who signed up 7 days ago
        day7_start = now - timedelta(days=7, hours=2)
        day7_end = now - timedelta(days=7)

        result_day7 = await session.execute(
            select(User, UserPreferences, UserProgress)
            .join(UserPreferences, User.id == UserPreferences.user_id)
            .join(UserProgress, User.id == UserProgress.user_id)
            .where(
                and_(
                    User.is_active,
                    User.email_verified,
                    UserPreferences.email_onboarding_series,
                    not UserPreferences.onboarding_day7_sent,
                    User.created_at >= day7_start,
                    User.created_at <= day7_end,
                )
            )
        )

        for user, prefs, progress in result_day7.all():
            try:
                community_url = "https://discord.gg/fMkF4Yza6B"  # Your Discord link

                subject, html, text = EmailTemplates.onboarding_day7(
                    username=user.username,
                    xp_earned=progress.xp_total,
                    lessons_completed=progress.total_lessons,
                    streak_days=progress.streak_days,
                    community_url=community_url,
                )

                await _email_service.send_email(
                    to_email=user.email,
                    subject=subject,
                    html_body=html,
                    text_body=text,
                )

                prefs.onboarding_day7_sent = True
                await session.commit()
                stats["day7"] += 1
                logger.info(f"Sent Day 7 onboarding to {user.email}")

            except Exception as exc:
                logger.error(f"Failed to send Day 7 onboarding to {user.email}: {exc}")
                stats["errors"] += 1

    logger.info(f"Onboarding email job complete: {stats}")
    return stats


# ============================================================================
# RE-ENGAGEMENT CAMPAIGNS
# ============================================================================


async def send_re_engagement_emails() -> dict[str, int]:
    """Send re-engagement emails to inactive users.

    Sends:
    - 7 days inactive: Gentle reminder
    - 14 days inactive: Emphasize progress made
    - 30 days inactive: What's new since they left

    Should run daily (e.g., 10 AM).

    Returns:
        Dict with stats: {"7day": count, "14day": count, "30day": count, "errors": count}
    """
    logger.info("Starting re-engagement email job")

    stats = {"7day": 0, "14day": 0, "30day": 0, "errors": 0}

    async with SessionLocal() as session:
        now = datetime.now(timezone.utc)

        # 7 days inactive
        day7_cutoff_start = now - timedelta(days=7, hours=2)
        day7_cutoff_end = now - timedelta(days=7)

        result_7day = await session.execute(
            select(User, UserPreferences, UserProgress)
            .join(UserPreferences, User.id == UserPreferences.user_id)
            .join(UserProgress, User.id == UserProgress.user_id)
            .where(
                and_(
                    User.is_active,
                    User.email_verified,
                    UserPreferences.email_re_engagement,
                    UserProgress.last_lesson_at >= day7_cutoff_start,
                    UserProgress.last_lesson_at <= day7_cutoff_end,
                )
            )
        )

        for user, prefs, progress in result_7day.all():
            try:
                quick_lesson_url = f"{settings.FRONTEND_URL}/lessons"

                # Get last language/lesson (simplified - adapt to your data model)
                last_language = prefs.language_focus or "Latin"
                last_lesson_name = "Your last lesson"

                subject, html, text = EmailTemplates.re_engagement_7days(
                    username=user.username,
                    last_language=last_language,
                    last_lesson_name=last_lesson_name,
                    quick_lesson_url=quick_lesson_url,
                )

                await _email_service.send_email(
                    to_email=user.email,
                    subject=subject,
                    html_body=html,
                    text_body=text,
                )

                stats["7day"] += 1
                logger.info(f"Sent 7-day re-engagement to {user.email}")

            except Exception as exc:
                logger.error(f"Failed to send 7-day re-engagement to {user.email}: {exc}")
                stats["errors"] += 1

        # 14 days inactive (similar pattern)
        day14_cutoff_start = now - timedelta(days=14, hours=2)
        day14_cutoff_end = now - timedelta(days=14)

        result_14day = await session.execute(
            select(User, UserPreferences, UserProgress)
            .join(UserPreferences, User.id == UserPreferences.user_id)
            .join(UserProgress, User.id == UserProgress.user_id)
            .where(
                and_(
                    User.is_active,
                    User.email_verified,
                    UserPreferences.email_re_engagement,
                    UserProgress.last_lesson_at >= day14_cutoff_start,
                    UserProgress.last_lesson_at <= day14_cutoff_end,
                )
            )
        )

        for user, prefs, progress in result_14day.all():
            try:
                welcome_back_url = f"{settings.FRONTEND_URL}/lessons?welcome_back=true"

                subject, html, text = EmailTemplates.re_engagement_14days(
                    username=user.username,
                    streak_lost=progress.max_streak,
                    lessons_completed=progress.total_lessons,
                    welcome_back_url=welcome_back_url,
                )

                await _email_service.send_email(
                    to_email=user.email,
                    subject=subject,
                    html_body=html,
                    text_body=text,
                )

                stats["14day"] += 1
                logger.info(f"Sent 14-day re-engagement to {user.email}")

            except Exception as exc:
                logger.error(f"Failed to send 14-day re-engagement to {user.email}: {exc}")
                stats["errors"] += 1

        # 30 days inactive
        day30_cutoff_start = now - timedelta(days=30, hours=2)
        day30_cutoff_end = now - timedelta(days=30)

        result_30day = await session.execute(
            select(User, UserPreferences, UserProgress)
            .join(UserPreferences, User.id == UserPreferences.user_id)
            .join(UserProgress, User.id == UserProgress.user_id)
            .where(
                and_(
                    User.is_active,
                    User.email_verified,
                    UserPreferences.email_re_engagement,
                    UserProgress.last_lesson_at >= day30_cutoff_start,
                    UserProgress.last_lesson_at <= day30_cutoff_end,
                )
            )
        )

        for user, prefs, progress in result_30day.all():
            try:
                whats_new_url = f"{settings.FRONTEND_URL}/changelog"

                subject, html, text = EmailTemplates.re_engagement_30days(
                    username=user.username,
                    whats_new_url=whats_new_url,
                )

                await _email_service.send_email(
                    to_email=user.email,
                    subject=subject,
                    html_body=html,
                    text_body=text,
                )

                stats["30day"] += 1
                logger.info(f"Sent 30-day re-engagement to {user.email}")

            except Exception as exc:
                logger.error(f"Failed to send 30-day re-engagement to {user.email}: {exc}")
                stats["errors"] += 1

    logger.info(f"Re-engagement email job complete: {stats}")
    return stats


# ============================================================================
# ACHIEVEMENT NOTIFICATIONS
# ============================================================================


async def send_achievement_notification(
    user_id: int,
    achievement_name: str,
    achievement_description: str,
    achievement_icon_url: str,
    rarity_percent: float,
) -> bool:
    """Send achievement unlocked notification to user.

    This should be called when a user unlocks a major achievement.

    Args:
        user_id: User's ID
        achievement_name: Name of achievement
        achievement_description: Description
        achievement_icon_url: URL to achievement icon
        rarity_percent: Percentage of users who have this

    Returns:
        True if sent successfully, False otherwise
    """
    async with SessionLocal() as session:
        # Get user and check if they want achievement notifications
        result = await session.execute(
            select(User, UserPreferences)
            .join(UserPreferences, User.id == UserPreferences.user_id)
            .where(
                and_(
                    User.id == user_id,
                    User.is_active,
                    User.email_verified,
                    UserPreferences.email_achievement_notifications,
                )
            )
        )

        user_data = result.first()
        if not user_data:
            logger.info(f"Skipping achievement notification for user {user_id} (disabled or not verified)")
            return False

        user, prefs = user_data

        try:
            achievements_url = f"{settings.FRONTEND_URL}/achievements"
            share_url = f"{settings.FRONTEND_URL}/share/achievement/{achievement_name}"

            subject, html, text = EmailTemplates.achievement_unlocked(
                username=user.username,
                achievement_name=achievement_name,
                achievement_description=achievement_description,
                achievement_icon_url=achievement_icon_url,
                rarity_percent=rarity_percent,
                achievements_url=achievements_url,
                share_url=share_url,
            )

            await _email_service.send_email(
                to_email=user.email,
                subject=subject,
                html_body=html,
                text_body=text,
            )

            logger.info(f"Sent achievement notification to {user.email}: {achievement_name}")
            return True

        except Exception as exc:
            logger.error(f"Failed to send achievement notification to {user.email}: {exc}")
            return False


__all__ = [
    "send_streak_reminders",
    "send_srs_review_reminders",
    "send_weekly_digest",
    "send_onboarding_emails",
    "send_re_engagement_emails",
    "send_achievement_notification",
]
