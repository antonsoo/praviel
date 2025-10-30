from __future__ import annotations

import logging

from fastapi import APIRouter, Depends, HTTPException, Request, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.config import Settings, get_settings
from app.db.session import get_db
from app.lesson.models import LessonGenerateRequest, LessonResponse
from app.lesson.service import generate_lesson as generate_lesson_service
from app.security.auth import get_current_user_optional
from app.security.unified_byok import PROVIDER_MAP, get_unified_api_key
from app.services.demo_usage import (
    DemoUsageExceeded,
    check_rate_limit,
    get_demo_key,
    is_demo_key_available,
    record_usage,
)
from app.utils.client_ip import get_client_ip

router = APIRouter(prefix="/lesson", tags=["Lesson"])
_LOGGER = logging.getLogger("app.lesson.router")


@router.post("/generate", response_model=LessonResponse, response_model_exclude_none=True)
async def generate_lesson(
    payload: LessonGenerateRequest,
    request: Request,
    settings: Settings = Depends(get_settings),
    session: AsyncSession = Depends(get_db),
    current_user=Depends(get_current_user_optional),
) -> LessonResponse:
    if not getattr(settings, "LESSONS_ENABLED", False):
        raise HTTPException(status_code=404, detail="Lesson endpoint is disabled")

    # Get API key with unified priority: user DB > header > server default > demo key
    provider = payload.provider
    provider_normalized = provider.lower()
    api_key: str | None = None
    is_demo: bool = False

    if payload.use_demo_key:
        provider_key = PROVIDER_MAP.get(provider.lower(), provider.lower())
        if not await is_demo_key_available(provider_key):
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Demo key is not available for this provider. Add your own API key in settings.",
            )
        api_key = get_demo_key(provider_key)
        if not api_key:
            raise HTTPException(
                status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
                detail="Demo key temporarily unavailable. Try again shortly or add your own API key.",
            )
        is_demo = True
        _LOGGER.info("Using demo API key for provider=%s (client requested)", provider_key)
    else:
        api_key, is_demo = await get_unified_api_key(provider, request=request, session=session)

    if is_demo and session is None:
        _LOGGER.warning(
            "Demo key available for provider=%s but database session unavailable; falling back to echo flow",
            provider_normalized,
        )
        api_key = None
        is_demo = False

    if provider_normalized != "echo" and not api_key:
        if not getattr(settings, "ECHO_FALLBACK_ENABLED", True):
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="No API key available. Add an API key in settings or enable the free demo key option.",
            )

    # If using demo key, check and enforce rate limits (supports both authenticated and guest users)
    if is_demo:
        # Get user_id if authenticated, otherwise use IP address
        user_id = current_user.id if current_user else None
        ip_address = None if current_user else get_client_ip(request)

        if session is None:
            _LOGGER.warning(
                "Demo key for provider=%s but no database session; skipping rate limit checks",
                provider_normalized,
            )
        else:
            try:
                # Check if user/IP has exceeded rate limits
                await check_rate_limit(session, provider, user_id=user_id, ip_address=ip_address)
            except DemoUsageExceeded as e:
                # Return 429 with detailed rate limit information
                raise HTTPException(
                    status_code=status.HTTP_429_TOO_MANY_REQUESTS,
                    detail=str(e),
                    headers={
                        "X-RateLimit-Limit-Daily": str(e.daily_limit),
                        "X-RateLimit-Limit-Weekly": str(e.weekly_limit),
                        "X-RateLimit-Reset": e.reset_at.isoformat(),
                        "Retry-After": str(int((e.reset_at.timestamp() - __import__("time").time()))),
                    },
                )

    # Generate the lesson
    lesson_response = await generate_lesson_service(
        request=payload,
        session=session,
        settings=settings,
        token=api_key,
    )

    # If using demo key, record the usage (supports both authenticated and guest users)
    if is_demo:
        # Get user_id if authenticated, otherwise use IP address
        user_id = current_user.id if current_user else None
        ip_address = None if current_user else get_client_ip(request)

        if session is None:
            _LOGGER.warning(
                "Demo usage recording skipped for provider=%s due to missing database session",
                provider_normalized,
            )
        else:
            try:
                # Extract token count from response metadata if available
                tokens_used = 0
                if hasattr(lesson_response, "meta") and lesson_response.meta:
                    tokens_used = getattr(lesson_response.meta, "tokens_used", 0)

                await record_usage(
                    session=session,
                    provider=provider,
                    user_id=user_id,
                    ip_address=ip_address,
                    tokens_used=tokens_used,
                )

                identifier = f"user_id={user_id}" if user_id else f"ip={ip_address}"
                _LOGGER.info(
                    "Recorded demo usage for %s provider=%s tokens=%d",
                    identifier,
                    payload.provider,
                    tokens_used,
                )
            except Exception as e:
                # Log error but don't fail the request if usage recording fails
                _LOGGER.error("Failed to record demo usage: %s", e, exc_info=True)

    return lesson_response
