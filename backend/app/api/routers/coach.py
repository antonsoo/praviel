from __future__ import annotations

from typing import Literal

from fastapi import APIRouter, Depends, HTTPException, Request
from pydantic import BaseModel, Field

from app.coach.prompts import COACH_SYSTEM_PROMPT
from app.coach.providers import PROVIDERS, Provider
from app.core.config import Settings, get_settings
from app.retrieval.context import build_context
from app.security.byok import get_byok_token

router = APIRouter(prefix="/coach", tags=["Coach"])


class ChatTurn(BaseModel):
    role: Literal["system", "user", "assistant"]
    content: str


class CoachRequest(BaseModel):
    q: str | None = None
    history: list[ChatTurn] = Field(default_factory=list)
    provider: Literal["echo", "openai"] = "echo"
    model: str | None = None


class CoachResponse(BaseModel):
    answer: str
    citations: list[str] = Field(default_factory=list)
    usage: dict | None = None


@router.post("/chat", response_model=CoachResponse)
async def coach_chat(
    payload: CoachRequest,
    request: Request,
    settings: Settings = Depends(get_settings),
    byok_token: str | None = Depends(get_byok_token),
) -> CoachResponse:
    if not settings.COACH_ENABLED:
        raise HTTPException(status_code=404, detail="Coach endpoint is disabled")

    provider = _resolve_provider(payload.provider)
    if provider is not PROVIDERS["echo"] and not byok_token:
        raise HTTPException(status_code=400, detail="BYOK token required")

    question = (payload.q or _latest_user_question(payload.history)).strip()
    if not question:
        raise HTTPException(status_code=400, detail="Question required")

    citations, context = await build_context(question)
    messages = _build_messages(context=context, history=payload.history, question=question)
    default_model = payload.model or settings.COACH_DEFAULT_MODEL
    answer, usage = await provider.chat(messages=messages, model=default_model, token=byok_token or "")

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
