"""Chat providers for conversational immersion"""

from __future__ import annotations

import json
from typing import Protocol

from app.chat.models import ChatConverseRequest, ChatConverseResponse, ChatMessage, ChatMeta
from app.chat.personas import get_persona_prompt


class ChatProvider(Protocol):
    """Protocol for chat providers"""
    name: str

    async def converse(
        self,
        *,
        request: ChatConverseRequest,
        token: str | None,
    ) -> ChatConverseResponse: ...


class ChatProviderError(RuntimeError):
    """Chat provider error"""
    def __init__(self, message: str, *, note: str | None = None):
        super().__init__(message)
        self.note = note


# Registry
CHAT_PROVIDERS: dict[str, ChatProvider] = {}


def get_chat_provider(name: str) -> ChatProvider:
    """Get chat provider by name"""
    provider = CHAT_PROVIDERS.get(name)
    if provider is None:
        raise ChatProviderError(f"Unknown chat provider '{name}'")
    return provider


class EchoChatProvider:
    """Offline echo provider with canned responses"""
    name = "echo"

    async def converse(
        self,
        *,
        request: ChatConverseRequest,
        token: str | None,
    ) -> ChatConverseResponse:
        """Return canned response based on persona"""
        canned_responses = {
            "athenian_merchant": {
                "reply": "χαῖρε, ὦ φίλε! τί δέῃ;",
                "translation_help": "Greetings, friend! What do you need?",
                "grammar_notes": [
                    "χαῖρε - imperative of χαίρω (to rejoice, greet)",
                    "τί δέῃ - present subjunctive in indirect question (what you need)",
                ],
            },
            "spartan_warrior": {
                "reply": "λάκωνες ἀεὶ ἕτοιμοι.",
                "translation_help": "Spartans always ready.",
                "grammar_notes": [
                    "ἕτοιμοι - nominative plural adjective agreeing with Λάκωνες",
                    "ἀεί - adverb (always) modifying the predicate",
                ],
            },
            "athenian_philosopher": {
                "reply": "τί ἐστιν ἀρετή; οἶδας;",
                "translation_help": "What is virtue? Do you know?",
                "grammar_notes": [
                    "τί ἐστιν - interrogative + copula (what is)",
                    "οἶδας - perfect with present meaning (you know)",
                ],
            },
            "roman_senator": {
                "reply": "σύγγνωθι, φίλε· τὰ Ῥωμαϊκὰ οὐ πάρεστιν.",
                "translation_help": "Forgive me, friend; the Roman (corpus) is not available yet.",
                "grammar_notes": [
                    "σύγγνωθι - aorist imperative (forgive)",
                    "πάρεστιν - present of πάρειμι (to be present)",
                ],
            },
        }

        persona_response = canned_responses.get(
            request.persona,
            canned_responses["athenian_merchant"],
        )

        return ChatConverseResponse(
            reply=persona_response["reply"],
            translation_help=persona_response["translation_help"],
            grammar_notes=persona_response["grammar_notes"],
            meta=ChatMeta(
                provider=self.name,
                model="echo-v1",
                persona=request.persona,
                context_length=len(request.context),
            ),
        )


# Register echo provider
CHAT_PROVIDERS["echo"] = EchoChatProvider()


def truncate_context(context: list[ChatMessage], max_messages: int = 10) -> list[ChatMessage]:
    """Truncate context to last N messages"""
    if len(context) <= max_messages:
        return context
    return context[-max_messages:]
