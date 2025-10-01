from __future__ import annotations

from fastapi import APIRouter, Depends, HTTPException

from app.chat.models import ChatConverseRequest, ChatConverseResponse
from app.chat.providers import ChatProviderError, get_chat_provider, truncate_context
from app.core.config import Settings, get_settings
from app.security.byok import get_byok_token

router = APIRouter(prefix="/chat", tags=["Chat"])


@router.post("/converse", response_model=ChatConverseResponse)
async def chat_converse(
    payload: ChatConverseRequest,
    settings: Settings = Depends(get_settings),
    token: str | None = Depends(get_byok_token),
) -> ChatConverseResponse:
    """
    Engage in conversation with a historical persona.

    Personas:
    - athenian_merchant: Marketplace commerce in 400 BCE Athens
    - spartan_warrior: Military discipline and Spartan values
    - athenian_philosopher: Socratic dialogue and epistemology
    - roman_senator: Roman politics and law (Latin, MVP fallback to Greek)

    Context is automatically truncated to last 10 messages.
    BYOK keys are request-scoped and never persisted.
    """
    # Truncate context to prevent token limit issues
    payload.context = truncate_context(payload.context, max_messages=10)

    provider = get_chat_provider(payload.provider)

    # Echo provider doesn't need BYOK token
    if provider.name == "echo":
        try:
            return await provider.converse(request=payload, token=None)
        except ChatProviderError as exc:
            raise HTTPException(status_code=502, detail="Chat provider unavailable") from exc

    # BYOK providers require token (or degrade to echo)
    if not token:
        # Degrade to echo
        echo_provider = get_chat_provider("echo")
        try:
            response = await echo_provider.converse(request=payload, token=None)
            response.meta.note = "byok_missing_fell_back_to_echo"
            return response
        except ChatProviderError as exc:
            raise HTTPException(status_code=502, detail="Chat provider unavailable") from exc

    # Try BYOK provider
    try:
        return await provider.converse(request=payload, token=token)
    except ChatProviderError as exc:
        # Fallback to echo
        fallback_note = exc.note or "byok_failed_fell_back_to_echo"
        echo_provider = get_chat_provider("echo")
        try:
            response = await echo_provider.converse(request=payload, token=None)
            response.meta.note = fallback_note
            return response
        except ChatProviderError as fallback_exc:
            raise HTTPException(status_code=502, detail="Chat provider unavailable") from fallback_exc
