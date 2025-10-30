"""Demo API usage statistics endpoints.

Provides users with visibility into their demo API usage limits and consumption.
"""

from __future__ import annotations

from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.config import settings
from app.db.session import get_session
from app.db.user_models import User
from app.security.auth import get_current_user
from app.services.demo_usage import get_usage_stats

router = APIRouter(prefix="/demo-usage", tags=["demo-usage"])


class DemoUsageStatsResponse(BaseModel):
    """Demo usage statistics for a provider."""

    provider: str
    requests_today: int
    requests_today_limit: int
    requests_remaining_today: int
    requests_this_week: int
    requests_week_limit: int
    requests_remaining_week: int
    tokens_today: int
    tokens_this_week: int
    daily_reset_at: str
    weekly_reset_at: str
    last_request_at: str | None


class DemoUsageOverviewResponse(BaseModel):
    """Overall demo usage information."""

    demo_enabled: bool
    daily_limit: int
    weekly_limit: int
    providers: list[DemoUsageStatsResponse]


@router.get("/", response_model=DemoUsageOverviewResponse)
async def get_demo_usage_overview(
    current_user: User = Depends(get_current_user),
    session: AsyncSession = Depends(get_session),
) -> DemoUsageOverviewResponse:
    """Get demo API usage statistics for the current user across all providers.

    Returns:
        Demo usage overview with stats for all providers
    """
    if not settings.DEMO_ENABLED:
        return DemoUsageOverviewResponse(
            demo_enabled=False,
            daily_limit=0,
            weekly_limit=0,
            providers=[],
        )

    # Get stats for all providers
    stats = await get_usage_stats(session, current_user.id)

    return DemoUsageOverviewResponse(
        demo_enabled=True,
        daily_limit=settings.DEMO_DAILY_REQUEST_LIMIT,
        weekly_limit=settings.DEMO_WEEKLY_REQUEST_LIMIT,
        providers=[DemoUsageStatsResponse(**stat) for stat in stats],
    )


@router.get("/{provider}", response_model=DemoUsageStatsResponse)
async def get_demo_usage_for_provider(
    provider: str,
    current_user: User = Depends(get_current_user),
    session: AsyncSession = Depends(get_session),
) -> DemoUsageStatsResponse:
    """Get demo API usage statistics for a specific provider.

    Args:
        provider: Provider name (openai, anthropic, google)

    Returns:
        Demo usage stats for the specified provider
    """
    if not settings.DEMO_ENABLED:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Demo API keys are not enabled",
        )

    # Validate provider
    if provider.lower() not in ["openai", "anthropic", "google"]:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Invalid provider: {provider}. Must be one of: openai, anthropic, google",
        )

    # Get stats for specific provider
    stats = await get_usage_stats(session, current_user.id, provider=provider.lower())

    if not stats:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"No usage data found for provider: {provider}",
        )

    return DemoUsageStatsResponse(**stats[0])


__all__ = ["router"]
