from __future__ import annotations

import logging

from fastapi import APIRouter, Depends, HTTPException, Request, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.chat.models import ChatConverseRequest, ChatConverseResponse
from app.chat.providers import ChatProviderError, get_chat_provider, truncate_context
from app.db.session import get_session
from app.security.auth import get_current_user_optional
from app.security.unified_byok import get_unified_api_key
from app.services.demo_usage import DemoUsageExceeded, check_rate_limit, record_usage
from app.utils.client_ip import get_client_ip

router = APIRouter(prefix="/chat", tags=["Chat"])
_LOGGER = logging.getLogger("app.api.chat")


@router.post("/converse", response_model=ChatConverseResponse)
async def chat_converse(
    request: Request,
    payload: ChatConverseRequest,
    session: AsyncSession = Depends(get_session),
    current_user=Depends(get_current_user_optional),
) -> ChatConverseResponse:
    """
    Engage in conversation with a historical persona.

    Personas:
    - athenian_merchant: Marketplace commerce in 400 BCE Athens
    - spartan_warrior: Military discipline and Spartan values
    - athenian_philosopher: Socratic dialogue and epistemology
    - roman_senator: Roman politics and law (Latin, MVP fallback to Greek)

    Context is automatically truncated to last 10 messages.

    Supported providers:
    - echo: Offline canned responses (no API key required)
    - openai: GPT-5 models (requires API key or uses demo key)
    - anthropic: Claude Sonnet 4.5 models (requires API key or uses demo key)
    - google: Gemini 2.5 Flash models (requires API key or uses demo key)
    """
    # Truncate context to prevent token limit issues
    payload.context = truncate_context(payload.context, max_messages=10)

    provider = get_chat_provider(payload.provider)

    # Get API key with unified priority: user DB > header > server default > demo key
    api_key, is_demo = await get_unified_api_key(payload.provider, request=request, session=session)

    # If using demo key, check and enforce rate limits (supports both authenticated and guest users)
    if is_demo:
        # Get user_id if authenticated, otherwise use IP address
        user_id = current_user.id if current_user else None
        ip_address = None if current_user else get_client_ip(request)

        try:
            await check_rate_limit(session, payload.provider, user_id=user_id, ip_address=ip_address)
        except DemoUsageExceeded as e:
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

    try:
        chat_response = await provider.converse(request=payload, token=api_key)

        # If using demo key, record the usage (supports both authenticated and guest users)
        if is_demo:
            # Get user_id if authenticated, otherwise use IP address
            user_id = current_user.id if current_user else None
            ip_address = None if current_user else get_client_ip(request)

            try:
                # Extract token count from response if available
                tokens_used = getattr(chat_response, "tokens_used", 0)

                await record_usage(
                    session=session,
                    provider=payload.provider,
                    user_id=user_id,
                    ip_address=ip_address,
                    tokens_used=tokens_used,
                )

                identifier = f"user_id={user_id}" if user_id else f"ip={ip_address}"
                _LOGGER.info(
                    "Recorded demo chat usage for %s provider=%s tokens=%d",
                    identifier,
                    payload.provider,
                    tokens_used,
                )
            except Exception as e:
                _LOGGER.error("Failed to record demo usage: %s", e, exc_info=True)

        return chat_response
    except ChatProviderError as exc:
        raise HTTPException(status_code=502, detail=str(exc)) from exc
