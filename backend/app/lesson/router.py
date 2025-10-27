from __future__ import annotations

import logging

from fastapi import APIRouter, Depends, HTTPException, Request, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.config import Settings, get_settings
from app.db.session import get_db
from app.lesson.models import LessonGenerateRequest, LessonResponse
from app.lesson.service import generate_lesson as generate_lesson_service
from app.security.auth import get_current_user_optional
from app.security.unified_byok import get_unified_api_key
from app.services.demo_usage import DemoUsageExceeded, check_rate_limit, record_usage
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
    api_key, is_demo = await get_unified_api_key(payload.provider, request=request, session=session)

    # If using demo key, check and enforce rate limits (supports both authenticated and guest users)
    if is_demo:
        # Get user_id if authenticated, otherwise use IP address
        user_id = current_user.id if current_user else None
        ip_address = None if current_user else get_client_ip(request)

        try:
            # Check if user/IP has exceeded rate limits
            await check_rate_limit(session, payload.provider, user_id=user_id, ip_address=ip_address)
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

        try:
            # Extract token count from response metadata if available
            tokens_used = 0
            if hasattr(lesson_response, "meta") and lesson_response.meta:
                tokens_used = getattr(lesson_response.meta, "tokens_used", 0)

            await record_usage(
                session=session,
                provider=payload.provider,
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
