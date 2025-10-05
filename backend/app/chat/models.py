from __future__ import annotations

from typing import Literal

from pydantic import BaseModel, Field

# Chat providers: echo (offline canned responses), openai (GPT-5 and GPT-4)
# Note: anthropic and google providers are not yet implemented for chat
ChatProviderName = Literal["echo", "openai"]


class ChatMessage(BaseModel):
    """Single message in conversation history"""

    role: Literal["user", "assistant"]
    content: str


class ChatConverseRequest(BaseModel):
    """Request to converse with a historical persona"""

    message: str = Field(min_length=1)
    persona: str = Field(default="athenian_merchant")
    provider: ChatProviderName = Field(default="echo")
    model: str | None = None
    context: list[ChatMessage] = Field(default_factory=list)


class ChatMeta(BaseModel):
    """Metadata about the chat response"""

    provider: str
    model: str
    persona: str
    context_length: int
    note: str | None = None


class ChatConverseResponse(BaseModel):
    """Response from chatbot conversation"""

    reply: str
    translation_help: str | None = None
    grammar_notes: list[str] = Field(default_factory=list)
    meta: ChatMeta
