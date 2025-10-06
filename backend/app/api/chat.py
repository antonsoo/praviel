from __future__ import annotations

from fastapi import APIRouter, Depends, HTTPException, Request
from sqlalchemy.ext.asyncio import AsyncSession

from app.chat.models import ChatConverseRequest, ChatConverseResponse
from app.chat.providers import ChatProviderError, get_chat_provider, truncate_context
from app.db.session import get_session
from app.security.unified_byok import get_unified_api_key

router = APIRouter(prefix="/chat", tags=["Chat"])


@router.post("/converse", response_model=ChatConverseResponse)
async def chat_converse(
    request: Request,
    payload: ChatConverseRequest,
    session: AsyncSession = Depends(get_session),
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
    - openai: GPT-5 and GPT-4 models (requires API key)
    - anthropic: Claude Sonnet 4.5 and Claude 4 models (requires API key)
    - google: Gemini 2.5 Flash models (requires API key)
    """
    # Truncate context to prevent token limit issues
    payload.context = truncate_context(payload.context, max_messages=10)

    provider = get_chat_provider(payload.provider)

    # Get API key with unified priority: user DB > header > server default
    token = await get_unified_api_key(payload.provider, request=request, session=session)

    try:
        return await provider.converse(request=payload, token=token)
    except ChatProviderError as exc:
        raise HTTPException(status_code=502, detail=str(exc)) from exc
