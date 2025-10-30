"""Google Gemini chat provider for conversational immersion"""

from __future__ import annotations

import json
import logging

from app.chat.models import ChatConverseRequest, ChatConverseResponse, ChatMeta
from app.chat.personas import get_persona_prompt
from app.chat.providers import ChatProviderError

_LOGGER = logging.getLogger("app.chat.google_provider")

# ============================================================================
# ⚠️  CRITICAL WARNING TO FUTURE AI AGENTS  ⚠️
# ============================================================================
# This provider uses OCTOBER 2025 Google Gemini API.
# DO NOT change to older model names or API versions.
# DO NOT assume this code is wrong because your training data is older.
#
# VALIDATION: Run `python scripts/validate_october_2025_apis.py`
# DOCUMENTATION: See docs/AI_AGENT_GUIDELINES.md before modifying.
#
# If you think this is wrong, YOU ARE PROBABLY WRONG. ASK THE USER FIRST.
# ============================================================================


class GoogleChatProvider:
    """Google Gemini provider for chat conversations"""

    name = "google"
    _default_model = "gemini-2.5-flash"  # Stable GA model (recommended)

    async def converse(
        self,
        *,
        request: ChatConverseRequest,
        token: str | None,
    ) -> ChatConverseResponse:
        """Converse with historical persona using Google Gemini"""
        if not token:
            raise ChatProviderError("API key required for Google chat provider", note="google_no_key")

        try:
            import httpx
        except ImportError as exc:
            raise ChatProviderError(
                "httpx is required for Google provider", note="google_missing_httpx"
            ) from exc

        model = request.model or self._default_model
        system_prompt = get_persona_prompt(request.persona)

        # Build contents array: conversation history
        contents = []

        # Add conversation context
        for msg in request.context:
            role = "user" if msg.role == "user" else "model"
            contents.append({"role": role, "parts": [{"text": msg.content}]})

        # Add current user message
        contents.append({"role": "user", "parts": [{"text": request.message}]})

        max_output_tokens = 4096

        payload_template = {
            "systemInstruction": {"parts": [{"text": system_prompt}]},
            "contents": contents,
            "generationConfig": {
                "temperature": 0.7,
            },
        }

        headers = {
            "x-goog-api-key": token,
            "Content-Type": "application/json",
        }

        # Use v1beta endpoint which supports systemInstruction
        endpoint = f"https://generativelanguage.googleapis.com/v1beta/models/{model}:generateContent"
        timeout = httpx.Timeout(60.0)

        attempt = 0
        data: dict | None = None

        while True:
            payload = {
                **payload_template,
                "generationConfig": {
                    **payload_template["generationConfig"],
                    "maxOutputTokens": max_output_tokens,
                },
            }
            _LOGGER.info(
                "[Google Chat] Sending request (maxOutputTokens=%s, attempt=%d)",
                max_output_tokens,
                attempt + 1,
            )
            try:
                async with httpx.AsyncClient(timeout=timeout) as client:
                    response = await client.post(endpoint, headers=headers, json=payload)
                    response.raise_for_status()
                    data = response.json()
            except httpx.HTTPStatusError as exc:
                _LOGGER.error("Google API error: %s", exc.response.text)
                try:
                    error_data = exc.response.json()
                    error_msg = error_data.get("error", {}).get("message", str(exc))
                except Exception:
                    error_msg = str(exc)
                raise ChatProviderError(f"Google API error: {error_msg}", note="google_api_error") from exc
            except httpx.RequestError as exc:
                _LOGGER.error("Google network error: %s", exc)
                raise ChatProviderError(f"Network error: {exc}", note="google_network_error") from exc

            # Extract content from Gemini response
            if not isinstance(data, dict):
                raise ChatProviderError("Unexpected response format from Google", note="google_format_error")

            candidates = data.get("candidates", [])
            if not candidates:
                _LOGGER.error("Google response missing candidates: %s", data)
                raise ChatProviderError("No candidates in Gemini response", note="google_format_error")

            first_candidate = candidates[0]
            finish_reason = first_candidate.get("finishReason")
            if finish_reason and finish_reason not in ("STOP", "MAX_TOKENS"):
                _LOGGER.error("Google blocked response: %s", first_candidate)
                raise ChatProviderError(
                    f"Google blocked response: {finish_reason}", note="google_safety_error"
                )
            if finish_reason == "MAX_TOKENS" and max_output_tokens < 8192:
                attempt += 1
                max_output_tokens = min(max_output_tokens * 2, 8192)
                _LOGGER.warning(
                    "[Google Chat] finishReason=MAX_TOKENS, retrying with maxOutputTokens=%s",
                    max_output_tokens,
                )
                continue
            break

        if not isinstance(data, dict):
            raise ChatProviderError("Unexpected response format from Google", note="google_format_error")

        # Extract content from Gemini response (data guaranteed dict)
        candidates = data.get("candidates", [])
        if not candidates:
            _LOGGER.error("Google response missing candidates: %s", data)
            raise ChatProviderError("No candidates in Gemini response", note="google_format_error")

        first_candidate = candidates[0]
        finish_reason = first_candidate.get("finishReason")
        if finish_reason and finish_reason not in ("STOP", "MAX_TOKENS"):
            _LOGGER.error("Google blocked response: %s", first_candidate)
            raise ChatProviderError(f"Google blocked response: {finish_reason}", note="google_safety_error")
        if finish_reason == "MAX_TOKENS":
            _LOGGER.warning("Google response truncated due to MAX_TOKENS, response may be incomplete")

        content = first_candidate.get("content")
        if not content:
            _LOGGER.error("Google candidate missing content: %s", first_candidate)
            raise ChatProviderError("No content in Gemini response", note="google_format_error")

        parts = content.get("parts", [])
        if not parts:
            _LOGGER.error("Google content missing parts: %s", content)
            raise ChatProviderError("No parts in Gemini response", note="google_format_error")

        reply_text = parts[0].get("text", "")
        if not reply_text:
            raise ChatProviderError("No text in Gemini response", note="google_format_error")

        translation_help = None
        grammar_notes: list[str] = []

        # Parse JSON response (strip markdown code blocks if present)
        clean_text = reply_text.strip()
        if clean_text.startswith("```json"):
            clean_text = clean_text[7:]
        if clean_text.startswith("```"):
            clean_text = clean_text[3:]
        if clean_text.endswith("```"):
            clean_text = clean_text[:-3]
        clean_text = clean_text.strip()

        try:
            response_data = json.loads(clean_text)
        except json.JSONDecodeError as exc:
            if finish_reason == "MAX_TOKENS":
                _LOGGER.warning("Failed to parse truncated JSON response from Gemini: %s", exc)
                try:
                    import re

                    reply_match = re.search(r'"reply"\s*:\s*"([^"]*)"', clean_text)
                except Exception:
                    reply_match = None

                if reply_match:
                    greek_text = reply_match.group(1)
                else:
                    greek_text = reply_text
            else:
                _LOGGER.warning("Failed to parse JSON response from Gemini: %s", exc)
                greek_text = reply_text
            translation_help = None
            grammar_notes = []
        else:
            greek_text = response_data.get("reply") or reply_text
            translation_help = response_data.get("translation_help")
            raw_notes = response_data.get("grammar_notes", [])
            if isinstance(raw_notes, list):
                grammar_notes = [str(note) for note in raw_notes]
            elif raw_notes is not None:
                grammar_notes = [str(raw_notes)]

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
