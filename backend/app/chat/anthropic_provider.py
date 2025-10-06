"""Anthropic chat provider for conversational immersion"""

from __future__ import annotations

import json
import logging

from app.chat.models import ChatConverseRequest, ChatConverseResponse, ChatMeta
from app.chat.personas import get_persona_prompt
from app.chat.providers import ChatProviderError

_LOGGER = logging.getLogger("app.chat.anthropic_provider")

# ============================================================================
# ⚠️  CRITICAL WARNING TO FUTURE AI AGENTS  ⚠️
# ============================================================================
# This provider uses OCTOBER 2025 Anthropic Claude API.
# DO NOT change to older model names or API versions.
# DO NOT assume this code is wrong because your training data is older.
#
# VALIDATION: Run `python scripts/validate_october_2025_apis.py`
# DOCUMENTATION: See docs/AI_AGENT_GUIDELINES.md before modifying.
#
# If you think this is wrong, YOU ARE PROBABLY WRONG. ASK THE USER FIRST.
# ============================================================================


class AnthropicChatProvider:
    """Anthropic Claude provider for chat conversations"""

    name = "anthropic"
    _default_model = "claude-sonnet-4-5-20250929"  # Dated model (recommended for production)

    async def converse(
        self,
        *,
        request: ChatConverseRequest,
        token: str | None,
    ) -> ChatConverseResponse:
        """Converse with historical persona using Anthropic Claude"""
        if not token:
            raise ChatProviderError("API key required for Anthropic chat provider", note="anthropic_no_key")

        try:
            import httpx
        except ImportError as exc:
            raise ChatProviderError(
                "httpx is required for Anthropic provider", note="anthropic_missing_httpx"
            ) from exc

        model = request.model or self._default_model
        system_prompt = get_persona_prompt(request.persona)

        # Build messages: context + user message
        messages = []

        # Add conversation context
        for msg in request.context:
            messages.append({"role": msg.role, "content": msg.content})

        # Add current user message
        messages.append({"role": "user", "content": request.message})

        payload = {
            "model": model,
            "system": system_prompt,
            "messages": messages,
            "max_tokens": 500,
        }

        headers = {
            "x-api-key": token,
            "anthropic-version": "2023-06-01",
            "Content-Type": "application/json",
        }

        endpoint = "https://api.anthropic.com/v1/messages"
        timeout = httpx.Timeout(30.0)

        try:
            async with httpx.AsyncClient(timeout=timeout) as client:
                response = await client.post(endpoint, headers=headers, json=payload)
                response.raise_for_status()
                data = response.json()

            # Extract content from Anthropic response
            content_blocks = data.get("content", [])
            reply_text = ""
            for block in content_blocks:
                if block.get("type") == "text":
                    reply_text = block.get("text", "")
                    break

            if not reply_text:
                raise ChatProviderError("No text in Anthropic response", note="anthropic_format_error")

            # Parse JSON response (strip markdown code blocks if present)
            try:
                # Remove markdown code block formatting if present
                clean_text = reply_text.strip()
                if clean_text.startswith("```json"):
                    clean_text = clean_text[7:]  # Remove ```json
                if clean_text.startswith("```"):
                    clean_text = clean_text[3:]  # Remove ```
                if clean_text.endswith("```"):
                    clean_text = clean_text[:-3]  # Remove trailing ```
                clean_text = clean_text.strip()

                response_data = json.loads(clean_text)
                greek_text = response_data.get("reply", "")
                translation_help = response_data.get("translation_help")
                grammar_notes = response_data.get("grammar_notes", [])
            except json.JSONDecodeError:
                # Fallback if not JSON
                _LOGGER.warning("Failed to parse JSON response from Anthropic")
                greek_text = reply_text
                translation_help = None
                grammar_notes = []

            return ChatConverseResponse(
                reply=greek_text,
                translation_help=translation_help,
                grammar_notes=grammar_notes,
                meta=ChatMeta(
                    provider=self.name,
                    model=model,
                    persona=request.persona,
                    context_length=len(request.context),
                ),
            )

        except httpx.HTTPStatusError as exc:
            _LOGGER.error("Anthropic API error: %s", exc.response.text)
            try:
                error_data = exc.response.json()
                error_msg = error_data.get("error", {}).get("message", str(exc))
            except Exception:
                error_msg = str(exc)
            raise ChatProviderError(f"Anthropic API error: {error_msg}", note="anthropic_api_error") from exc
        except httpx.RequestError as exc:
            _LOGGER.error("Anthropic network error: %s", exc)
            raise ChatProviderError(f"Network error: {exc}", note="anthropic_network_error") from exc
        except (KeyError, IndexError) as exc:
            _LOGGER.error("Unexpected Anthropic response format: %s", data)
            raise ChatProviderError(
                "Unexpected response format from Anthropic", note="anthropic_format_error"
            ) from exc
