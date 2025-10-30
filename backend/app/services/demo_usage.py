"""Demo API usage tracking and rate limiting service.

This service manages the free tier API access for users who don't have their own API keys.
It tracks usage per user per provider and enforces configurable rate limits.

Features:
- Automatic daily/weekly counter resets
- Transparent rate limit headers
- Per-user per-provider tracking
- Future-proof configurable limits
"""

from __future__ import annotations

import logging
from datetime import datetime, timedelta, timezone

from sqlalchemy import select
from sqlalchemy.exc import SQLAlchemyError
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.config import settings
from app.db.user_models import DemoAPIUsage

_LOGGER = logging.getLogger("app.services.demo_usage")


class DemoUsageExceeded(Exception):
    """Raised when user has exceeded demo API usage limits."""

    def __init__(self, message: str, daily_limit: int, weekly_limit: int, reset_at: datetime):
        super().__init__(message)
        self.daily_limit = daily_limit
        self.weekly_limit = weekly_limit
        self.reset_at = reset_at


def _get_next_daily_reset() -> datetime:
    """Get the next midnight UTC for daily reset."""
    now = datetime.now(timezone.utc)
    tomorrow = now + timedelta(days=1)
    return tomorrow.replace(hour=0, minute=0, second=0, microsecond=0)


def _get_next_weekly_reset() -> datetime:
    """Get the next Monday midnight UTC for weekly reset."""
    now = datetime.now(timezone.utc)
    # Monday is 0, Sunday is 6
    days_until_monday = (7 - now.weekday()) % 7
    if days_until_monday == 0:
        days_until_monday = 7  # If today is Monday, reset next Monday
    next_monday = now + timedelta(days=days_until_monday)
    return next_monday.replace(hour=0, minute=0, second=0, microsecond=0)


async def get_or_create_usage_record(
    session: AsyncSession,
    provider: str,
    user_id: int | None = None,
    ip_address: str | None = None,
) -> DemoAPIUsage:
    """Get or create a demo usage record for user/IP and provider.

    Supports both authenticated users (by user_id) and guest users (by IP address).

    Args:
        session: Database session
        provider: Provider name (openai, anthropic, google)
        user_id: User ID (for authenticated users)
        ip_address: IP address (for guest users)

    Returns:
        DemoAPIUsage record

    Raises:
        ValueError: If neither user_id nor ip_address is provided
    """
    if not user_id and not ip_address:
        raise ValueError("Either user_id or ip_address must be provided")

    # Query based on whether we have user_id or ip_address
    if user_id:
        result = await session.execute(
            select(DemoAPIUsage).where(
                DemoAPIUsage.user_id == user_id,
                DemoAPIUsage.provider == provider,
            )
        )
    else:
        result = await session.execute(
            select(DemoAPIUsage).where(
                DemoAPIUsage.ip_address == ip_address,
                DemoAPIUsage.provider == provider,
            )
        )

    usage = result.scalar_one_or_none()

    if not usage:
        # Create new usage record
        usage = DemoAPIUsage(
            user_id=user_id,
            ip_address=ip_address,
            provider=provider,
            requests_today=0,
            tokens_today=0,
            requests_this_week=0,
            tokens_this_week=0,
            daily_reset_at=_get_next_daily_reset(),
            weekly_reset_at=_get_next_weekly_reset(),
        )
        session.add(usage)
        await session.commit()
        await session.refresh(usage)

        identifier = f"user_id={user_id}" if user_id else f"ip={ip_address}"
        _LOGGER.info("Created demo usage record for %s provider=%s", identifier, provider)

    return usage


async def reset_counters_if_needed(
    session: AsyncSession,
    usage: DemoAPIUsage,
) -> DemoAPIUsage:
    """Reset daily/weekly counters if reset time has passed.

    Args:
        session: Database session
        usage: DemoAPIUsage record

    Returns:
        Updated DemoAPIUsage record
    """
    now = datetime.now(timezone.utc)
    modified = False

    # Check daily reset
    if now >= usage.daily_reset_at:
        usage.requests_today = 0
        usage.tokens_today = 0
        usage.daily_reset_at = _get_next_daily_reset()
        modified = True
        _LOGGER.info(
            "Reset daily counters for user_id=%d provider=%s",
            usage.user_id,
            usage.provider,
        )

    # Check weekly reset
    if now >= usage.weekly_reset_at:
        usage.requests_this_week = 0
        usage.tokens_this_week = 0
        usage.weekly_reset_at = _get_next_weekly_reset()
        modified = True
        _LOGGER.info(
            "Reset weekly counters for user_id=%d provider=%s",
            usage.user_id,
            usage.provider,
        )

    if modified:
        await session.commit()
        await session.refresh(usage)

    return usage


async def check_rate_limit(
    session: AsyncSession,
    provider: str,
    user_id: int | None = None,
    ip_address: str | None = None,
) -> tuple[bool, DemoAPIUsage | None]:
    """Check if user/IP can make a demo API request.

    Supports both authenticated users (by user_id) and guest users (by IP address).

    Args:
        session: Database session
        provider: Provider name
        user_id: User ID (for authenticated users)
        ip_address: IP address (for guest users)

    Returns:
        Tuple of (allowed: bool, usage: DemoAPIUsage)

    Raises:
        DemoUsageExceeded: If user/IP has exceeded limits
        ValueError: If neither user_id nor ip_address is provided
    """
    # Get or create usage record
    try:
        usage = await get_or_create_usage_record(session, provider, user_id=user_id, ip_address=ip_address)
        usage = await reset_counters_if_needed(session, usage)
    except SQLAlchemyError as exc:
        _LOGGER.error(
            "Demo usage rate limit storage unavailable for provider=%s: %s",
            provider,
            exc,
            exc_info=True,
        )
        return True, None
    except Exception as exc:  # pragma: no cover - defensive guard
        _LOGGER.error(
            "Unexpected error while checking demo usage limits for provider=%s: %s",
            provider,
            exc,
            exc_info=True,
        )
        return True, None

    # Check limits
    daily_limit = settings.DEMO_DAILY_REQUEST_LIMIT
    weekly_limit = settings.DEMO_WEEKLY_REQUEST_LIMIT

    identifier = f"user_id={user_id}" if user_id else f"IP {ip_address}"

    if usage.requests_today >= daily_limit:
        raise DemoUsageExceeded(
            f"Daily demo API limit exceeded for {provider} ({identifier}). "
            f"Limit: {daily_limit} requests/day. "
            f"Resets at {usage.daily_reset_at.isoformat()}. "
            f"Sign up or add your own API key for unlimited usage!",
            daily_limit=daily_limit,
            weekly_limit=weekly_limit,
            reset_at=usage.daily_reset_at,
        )

    if usage.requests_this_week >= weekly_limit:
        raise DemoUsageExceeded(
            f"Weekly demo API limit exceeded for {provider} ({identifier}). "
            f"Limit: {weekly_limit} requests/week. "
            f"Resets at {usage.weekly_reset_at.isoformat()}. "
            f"Sign up or add your own API key for unlimited usage!",
            daily_limit=daily_limit,
            weekly_limit=weekly_limit,
            reset_at=usage.weekly_reset_at,
        )

    return (True, usage)


async def record_usage(
    session: AsyncSession,
    provider: str,
    user_id: int | None = None,
    ip_address: str | None = None,
    tokens_used: int = 0,
) -> DemoAPIUsage | None:
    """Record a demo API usage event.

    Supports both authenticated users (by user_id) and guest users (by IP address).

    Args:
        session: Database session
        provider: Provider name
        user_id: User ID (for authenticated users)
        ip_address: IP address (for guest users)
        tokens_used: Number of tokens used (optional)

    Returns:
        Updated DemoAPIUsage record

    Raises:
        ValueError: If neither user_id nor ip_address is provided
    """
    try:
        usage = await get_or_create_usage_record(session, provider, user_id=user_id, ip_address=ip_address)
        usage = await reset_counters_if_needed(session, usage)
    except SQLAlchemyError as exc:
        _LOGGER.error(
            "Demo usage tracking unavailable for provider=%s: %s",
            provider,
            exc,
            exc_info=True,
        )
        return None
    except Exception as exc:  # pragma: no cover - defensive guard
        _LOGGER.error(
            "Unexpected error while recording demo usage for provider=%s: %s",
            provider,
            exc,
            exc_info=True,
        )
        return None

    # Increment counters
    usage.requests_today += 1
    usage.requests_this_week += 1
    usage.tokens_today += tokens_used
    usage.tokens_this_week += tokens_used
    usage.last_request_at = datetime.now(timezone.utc)

    await session.commit()
    await session.refresh(usage)

    identifier = f"user_id={user_id}" if user_id else f"ip={ip_address}"
    _LOGGER.info(
        "Recorded demo usage: %s provider=%s requests_today=%d/%d requests_week=%d/%d",
        identifier,
        provider,
        usage.requests_today,
        settings.DEMO_DAILY_REQUEST_LIMIT,
        usage.requests_this_week,
        settings.DEMO_WEEKLY_REQUEST_LIMIT,
    )

    return usage


async def get_usage_stats(
    session: AsyncSession,
    user_id: int,
    provider: str | None = None,
) -> list[dict]:
    """Get usage statistics for a user.

    Args:
        session: Database session
        user_id: User ID
        provider: Optional provider filter (if None, returns all providers)

    Returns:
        List of usage stat dictionaries
    """
    query = select(DemoAPIUsage).where(DemoAPIUsage.user_id == user_id)

    if provider:
        query = query.where(DemoAPIUsage.provider == provider)

    result = await session.execute(query)
    usage_records = result.scalars().all()

    stats = []
    for usage in usage_records:
        # Reset counters if needed (read-only check)
        now = datetime.now(timezone.utc)
        requests_today = 0 if now >= usage.daily_reset_at else usage.requests_today
        requests_week = 0 if now >= usage.weekly_reset_at else usage.requests_this_week
        tokens_today = 0 if now >= usage.daily_reset_at else usage.tokens_today
        tokens_week = 0 if now >= usage.weekly_reset_at else usage.tokens_this_week

        stats.append(
            {
                "provider": usage.provider,
                "requests_today": requests_today,
                "requests_today_limit": settings.DEMO_DAILY_REQUEST_LIMIT,
                "requests_remaining_today": max(0, settings.DEMO_DAILY_REQUEST_LIMIT - requests_today),
                "requests_this_week": requests_week,
                "requests_week_limit": settings.DEMO_WEEKLY_REQUEST_LIMIT,
                "requests_remaining_week": max(0, settings.DEMO_WEEKLY_REQUEST_LIMIT - requests_week),
                "tokens_today": tokens_today,
                "tokens_this_week": tokens_week,
                "daily_reset_at": usage.daily_reset_at.isoformat(),
                "weekly_reset_at": usage.weekly_reset_at.isoformat(),
                "last_request_at": usage.last_request_at.isoformat() if usage.last_request_at else None,
            }
        )

    return stats


async def is_demo_key_available(provider: str) -> bool:
    """Check if a demo key is configured and enabled for a provider.

    Args:
        provider: Provider name (openai, anthropic, google)

    Returns:
        True if demo key is available for this provider
    """
    if not settings.DEMO_ENABLED:
        return False

    provider_lower = provider.lower()

    if provider_lower == "openai":
        return settings.DEMO_OPENAI_API_KEY is not None
    elif provider_lower == "anthropic":
        return settings.DEMO_ANTHROPIC_API_KEY is not None
    elif provider_lower == "google":
        return settings.DEMO_GOOGLE_API_KEY is not None

    return False


def get_demo_key(provider: str) -> str | None:
    """Get the demo API key for a provider.

    Args:
        provider: Provider name (openai, anthropic, google)

    Returns:
        Demo API key or None if not configured
    """
    if not settings.DEMO_ENABLED:
        return None

    provider_lower = provider.lower()

    if provider_lower == "openai":
        return settings.DEMO_OPENAI_API_KEY
    elif provider_lower == "anthropic":
        return settings.DEMO_ANTHROPIC_API_KEY
    elif provider_lower == "google":
        return settings.DEMO_GOOGLE_API_KEY

    return None
