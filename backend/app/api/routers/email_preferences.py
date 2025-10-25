"""Email notification preferences management.

Allows users to control which email notifications they receive.
"""

from __future__ import annotations

import logging

from fastapi import APIRouter, Depends
from pydantic import BaseModel, Field
from sqlalchemy.ext.asyncio import AsyncSession

from app.db.session import get_session
from app.db.user_models import User, UserPreferences
from app.security.auth import get_current_user

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/user/email-preferences", tags=["email-preferences"])


class EmailPreferencesResponse(BaseModel):
    """User's email notification preferences."""

    # Engagement emails
    email_streak_reminders: bool
    email_srs_reminders: bool
    email_achievement_notifications: bool

    # Marketing emails
    email_weekly_digest: bool
    email_onboarding_series: bool
    email_new_content_alerts: bool
    email_social_notifications: bool
    email_re_engagement: bool

    # Timing preferences (hour of day, 0-23)
    srs_reminder_time: int
    streak_reminder_time: int


class EmailPreferencesUpdate(BaseModel):
    """Update email notification preferences."""

    # Engagement emails
    email_streak_reminders: bool | None = None
    email_srs_reminders: bool | None = None
    email_achievement_notifications: bool | None = None

    # Marketing emails
    email_weekly_digest: bool | None = None
    email_onboarding_series: bool | None = None
    email_new_content_alerts: bool | None = None
    email_social_notifications: bool | None = None
    email_re_engagement: bool | None = None

    # Timing preferences (hour of day, 0-23)
    srs_reminder_time: int | None = Field(None, ge=0, le=23)
    streak_reminder_time: int | None = Field(None, ge=0, le=23)


class BulkEmailPreferencesUpdate(BaseModel):
    """Bulk update all email preferences at once."""

    enable_all: bool | None = None  # Enable/disable all emails at once
    enable_reminders: bool | None = None  # Enable/disable all reminders
    enable_marketing: bool | None = None  # Enable/disable all marketing


@router.get("", response_model=EmailPreferencesResponse)
async def get_email_preferences(
    current_user: User = Depends(get_current_user),
    session: AsyncSession = Depends(get_session),
) -> EmailPreferencesResponse:
    """Get current email notification preferences."""
    # Refresh to get latest preferences
    await session.refresh(current_user, ["preferences"])

    prefs = current_user.preferences

    return EmailPreferencesResponse(
        email_streak_reminders=prefs.email_streak_reminders,
        email_srs_reminders=prefs.email_srs_reminders,
        email_achievement_notifications=prefs.email_achievement_notifications,
        email_weekly_digest=prefs.email_weekly_digest,
        email_onboarding_series=prefs.email_onboarding_series,
        email_new_content_alerts=prefs.email_new_content_alerts,
        email_social_notifications=prefs.email_social_notifications,
        email_re_engagement=prefs.email_re_engagement,
        srs_reminder_time=prefs.srs_reminder_time,
        streak_reminder_time=prefs.streak_reminder_time,
    )


@router.patch("", response_model=EmailPreferencesResponse)
async def update_email_preferences(
    updates: EmailPreferencesUpdate,
    current_user: User = Depends(get_current_user),
    session: AsyncSession = Depends(get_session),
) -> EmailPreferencesResponse:
    """Update email notification preferences.

    Only updates fields that are provided (partial update).
    """
    await session.refresh(current_user, ["preferences"])
    prefs = current_user.preferences

    # Update only provided fields
    update_data = updates.model_dump(exclude_unset=True)

    for field, value in update_data.items():
        if hasattr(prefs, field):
            setattr(prefs, field, value)
            logger.info(f"Updated {field} to {value} for user {current_user.username}")

    await session.commit()
    await session.refresh(prefs)

    return EmailPreferencesResponse(
        email_streak_reminders=prefs.email_streak_reminders,
        email_srs_reminders=prefs.email_srs_reminders,
        email_achievement_notifications=prefs.email_achievement_notifications,
        email_weekly_digest=prefs.email_weekly_digest,
        email_onboarding_series=prefs.email_onboarding_series,
        email_new_content_alerts=prefs.email_new_content_alerts,
        email_social_notifications=prefs.email_social_notifications,
        email_re_engagement=prefs.email_re_engagement,
        srs_reminder_time=prefs.srs_reminder_time,
        streak_reminder_time=prefs.streak_reminder_time,
    )


@router.post("/bulk-update", response_model=EmailPreferencesResponse)
async def bulk_update_email_preferences(
    bulk_updates: BulkEmailPreferencesUpdate,
    current_user: User = Depends(get_current_user),
    session: AsyncSession = Depends(get_session),
) -> EmailPreferencesResponse:
    """Bulk update email preferences.

    Allows users to quickly enable/disable categories of emails.
    """
    await session.refresh(current_user, ["preferences"])
    prefs = current_user.preferences

    if bulk_updates.enable_all is not None:
        # Enable/disable ALL emails
        value = bulk_updates.enable_all
        prefs.email_streak_reminders = value
        prefs.email_srs_reminders = value
        prefs.email_achievement_notifications = value
        prefs.email_weekly_digest = value
        prefs.email_onboarding_series = value
        prefs.email_new_content_alerts = value
        prefs.email_social_notifications = value
        prefs.email_re_engagement = value
        logger.info(f"Bulk updated ALL emails to {value} for user {current_user.username}")

    if bulk_updates.enable_reminders is not None:
        # Enable/disable reminder emails only
        value = bulk_updates.enable_reminders
        prefs.email_streak_reminders = value
        prefs.email_srs_reminders = value
        logger.info(f"Bulk updated REMINDERS to {value} for user {current_user.username}")

    if bulk_updates.enable_marketing is not None:
        # Enable/disable marketing emails only
        value = bulk_updates.enable_marketing
        prefs.email_weekly_digest = value
        prefs.email_onboarding_series = value
        prefs.email_new_content_alerts = value
        prefs.email_social_notifications = value
        prefs.email_re_engagement = value
        logger.info(f"Bulk updated MARKETING to {value} for user {current_user.username}")

    await session.commit()
    await session.refresh(prefs)

    return EmailPreferencesResponse(
        email_streak_reminders=prefs.email_streak_reminders,
        email_srs_reminders=prefs.email_srs_reminders,
        email_achievement_notifications=prefs.email_achievement_notifications,
        email_weekly_digest=prefs.email_weekly_digest,
        email_onboarding_series=prefs.email_onboarding_series,
        email_new_content_alerts=prefs.email_new_content_alerts,
        email_social_notifications=prefs.email_social_notifications,
        email_re_engagement=prefs.email_re_engagement,
        srs_reminder_time=prefs.srs_reminder_time,
        streak_reminder_time=prefs.streak_reminder_time,
    )


@router.post("/disable-all", response_model=EmailPreferencesResponse)
async def disable_all_emails(
    current_user: User = Depends(get_current_user),
    session: AsyncSession = Depends(get_session),
) -> EmailPreferencesResponse:
    """Disable all non-essential email notifications.

    Security and transactional emails (password reset, etc.) cannot be disabled.
    """
    await session.refresh(current_user, ["preferences"])
    prefs = current_user.preferences

    # Disable all optional emails
    prefs.email_streak_reminders = False
    prefs.email_srs_reminders = False
    prefs.email_achievement_notifications = False
    prefs.email_weekly_digest = False
    prefs.email_onboarding_series = False
    prefs.email_new_content_alerts = False
    prefs.email_social_notifications = False
    prefs.email_re_engagement = False

    await session.commit()
    await session.refresh(prefs)

    logger.info(f"Disabled all emails for user {current_user.username}")

    return EmailPreferencesResponse(
        email_streak_reminders=prefs.email_streak_reminders,
        email_srs_reminders=prefs.email_srs_reminders,
        email_achievement_notifications=prefs.email_achievement_notifications,
        email_weekly_digest=prefs.email_weekly_digest,
        email_onboarding_series=prefs.email_onboarding_series,
        email_new_content_alerts=prefs.email_new_content_alerts,
        email_social_notifications=prefs.email_social_notifications,
        email_re_engagement=prefs.email_re_engagement,
        srs_reminder_time=prefs.srs_reminder_time,
        streak_reminder_time=prefs.streak_reminder_time,
    )


__all__ = ["router"]
