from __future__ import annotations

import logging
from typing import Literal

from fastapi import APIRouter, Depends, HTTPException, Request, status
from pydantic import BaseModel, Field
from sqlalchemy.ext.asyncio import AsyncSession

from app.coach.prompts import COACH_SYSTEM_PROMPT
from app.coach.providers import PROVIDERS, Provider
from app.core.config import Settings, get_settings
from app.db.session import get_session
from app.retrieval.context import build_context
from app.security.auth import get_current_user_optional
from app.security.unified_byok import get_unified_api_key
from app.services.demo_usage import DemoUsageExceeded, check_rate_limit, record_usage
from app.utils.client_ip import get_client_ip

router = APIRouter(prefix="/coach", tags=["Coach"])
_LOGGER = logging.getLogger("app.api.routers.coach")


class ChatTurn(BaseModel):
    role: Literal["system", "user", "assistant"]
    content: str = Field(..., min_length=1, max_length=10000, description="Chat message content")


class CoachRequest(BaseModel):
    q: str | None = Field(None, min_length=1, max_length=2000, description="Question to ask the coach")
    history: list[ChatTurn] = Field(default_factory=list, max_length=50, description="Chat history")
    provider: Literal["echo", "openai"] = "echo"
    model: str | None = Field(None, max_length=100, description="Model name")


class CoachResponse(BaseModel):
    answer: str
    citations: list[str] = Field(default_factory=list)
    usage: dict | None = None


@router.post("/chat", response_model=CoachResponse)
async def coach_chat(
    payload: CoachRequest,
    request: Request,
    settings: Settings = Depends(get_settings),
    session: AsyncSession = Depends(get_session),
    current_user=Depends(get_current_user_optional),
) -> CoachResponse:
    if not settings.COACH_ENABLED:
        raise HTTPException(status_code=404, detail="Coach endpoint is disabled")

    provider = _resolve_provider(payload.provider)

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
                    "Retry-After": str(int((e.reset_at.timestamp() - __import__('time').time()))),
                },
            )

    if provider is not PROVIDERS["echo"] and not api_key:
        raise HTTPException(status_code=400, detail="API key required for this provider")

    question = (payload.q or _latest_user_question(payload.history)).strip()
    if not question:
        raise HTTPException(status_code=400, detail="Question required")

    citations, context = await build_context(question)
    messages = _build_messages(context=context, history=payload.history, question=question)
    default_model = payload.model or settings.COACH_DEFAULT_MODEL
    answer, usage = await provider.chat(messages=messages, model=default_model, token=api_key or "")

    # If using demo key, record the usage (supports both authenticated and guest users)
    if is_demo:
        # Get user_id if authenticated, otherwise use IP address
        user_id = current_user.id if current_user else None
        ip_address = None if current_user else get_client_ip(request)

        try:
            # Extract token count from usage if available
            tokens_used = usage.get("total_tokens", 0) if usage else 0

            await record_usage(
                session=session,
                provider=payload.provider,
                user_id=user_id,
                ip_address=ip_address,
                tokens_used=tokens_used,
            )

            identifier = f"user_id={user_id}" if user_id else f"ip={ip_address}"
            _LOGGER.info(
                "Recorded demo coach usage for %s provider=%s tokens=%d",
                identifier,
                payload.provider,
                tokens_used,
            )
        except Exception as e:
            _LOGGER.error("Failed to record demo usage: %s", e, exc_info=True)

    return CoachResponse(answer=answer, citations=citations, usage=usage)


def _latest_user_question(history: list[ChatTurn]) -> str:
    for turn in reversed(history):
        if turn.role == "user" and turn.content.strip():
            return turn.content
    return ""


def _build_messages(*, context: str, history: list[ChatTurn], question: str) -> list[dict[str, str]]:
    system_content = COACH_SYSTEM_PROMPT
    if context:
        system_content += f"\nUse the following context when helpful:\n{context}"
    messages: list[dict[str, str]] = [{"role": "system", "content": system_content}]
    messages.extend(turn.model_dump() for turn in history)
    messages.append({"role": "user", "content": question})
    return messages


def _resolve_provider(name: str) -> Provider:
    provider = PROVIDERS.get(name)
    if provider is None:
        raise HTTPException(status_code=400, detail=f"Unknown provider '{name}'")
    return provider
