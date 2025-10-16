"""OpenAI chat provider for conversational immersion"""

from __future__ import annotations

import json
import logging

from app.chat.models import ChatConverseRequest, ChatConverseResponse, ChatMeta
from app.chat.personas import get_persona_prompt
from app.chat.providers import ChatProviderError

_LOGGER = logging.getLogger("app.chat.openai_provider")

# ============================================================================
# ⚠️  CRITICAL WARNING TO FUTURE AI AGENTS  ⚠️
# ============================================================================
# This chat provider uses OCTOBER 2025 GPT-5 RESPONSES API.
# DO NOT change to GPT-4 models or old Chat Completions API.
# DO NOT assume this code is wrong because your training data is older.
#
# VALIDATION: Run `python scripts/validate_october_2025_apis.py`
# DOCUMENTATION: See docs/AI_AGENT_GUIDELINES.md before modifying.
#
# If you think this is wrong, YOU ARE PROBABLY WRONG. ASK THE USER FIRST.
# ============================================================================


class OpenAIChatProvider:
    """OpenAI provider for chat conversations"""

    name = "openai"
    _default_model = "gpt-5-nano-2025-08-07"  # Dated model for production stability

    async def converse(
        self,
        *,
        request: ChatConverseRequest,
        token: str | None,
    ) -> ChatConverseResponse:
        """Converse with historical persona using OpenAI"""
        if not token:
            raise ChatProviderError("API key required for OpenAI chat provider", note="openai_no_key")

        try:
            import httpx
        except ImportError as exc:
            raise ChatProviderError(
                "httpx is required for OpenAI provider", note="openai_missing_httpx"
            ) from exc

        model = request.model or self._default_model
        system_prompt = get_persona_prompt(request.persona)

        # Build messages: system prompt + context + user message
        messages = [{"role": "system", "content": system_prompt}]

        # Add conversation context
        for msg in request.context:
            messages.append({"role": msg.role, "content": msg.content})

        # Add current user message
        messages.append({"role": "user", "content": request.message})

        # GPT-5 RESPONSES API ONLY (October 2025)
        # IMPORTANT: This is October 2025 API - DO NOT change to older versions
        # See docs/AI_AGENT_GUIDELINES.md before modifying
        # ⚠️ GPT-4 MODELS ARE NOT SUPPORTED - GPT-5 ONLY

        _LOGGER.info(f"[OpenAI Chat] Using GPT-5 Responses API with model: {model}")

        # Responses API payload structure
        # Convert messages list to proper input format with content array
        # Based on working examples from OpenAI Cookbook and Microsoft Azure docs
        input_messages = []
        for msg in messages:
            # Each message needs content as array of content items
            input_messages.append(
                {"role": msg["role"], "content": [{"type": "input_text", "text": msg["content"]}]}
            )

        # October 2025 Responses API format
        # ⚠️ NOTE: text.format with json_object may not be supported on all GPT-5 models
        # Relying on system prompt to request JSON format instead
        # Minimal payload - only required parameters + max_output_tokens
        # Based on OpenAI Cookbook examples for gpt-5-nano/mini
        #
        # ⚠️ DO NOT ADD: response_format, modalities, reasoning, store, text.verbosity
        # ⚠️ DO NOT CHANGE: endpoint to /v1/chat/completions
        # ⚠️ DO NOT CHANGE: "input" to "messages" or "max_output_tokens" to "max_tokens"
        # These will cause 400 errors. See docs/AI_AGENT_PROTECTION.md
        max_output_tokens = 4096

        def build_payload(token_budget: int) -> dict[str, object]:
            message_payload: dict[str, object] = {
                "model": model,
                "input": input_messages,
                "max_output_tokens": token_budget,
                "text": {"format": {"type": "json_object"}},
            }
            if "nano" not in model.lower():
                message_payload["reasoning"] = {"effort": "low"}
            return message_payload

        endpoint = "https://api.openai.com/v1/responses"

        headers = {
            "Authorization": f"Bearer {token}",
            "Content-Type": "application/json",
        }

        timeout = httpx.Timeout(60.0)

        attempt = 0
        data: dict[str, object] | None = None

        while True:
            payload = build_payload(max_output_tokens)
            _LOGGER.info(
                "[OpenAI Chat] Sending request to %s (max_output_tokens=%s, attempt=%d)",
                endpoint,
                max_output_tokens,
                attempt + 1,
            )
            _LOGGER.info(f"[OpenAI Chat] Payload keys: {list(payload.keys())}")

            try:
                async with httpx.AsyncClient(timeout=timeout) as client:
                    response = await client.post(endpoint, headers=headers, json=payload)
                    response.raise_for_status()
                    data = response.json()
            except httpx.HTTPStatusError as exc:
                _LOGGER.error("OpenAI API error: %s", exc.response.text)
                try:
                    error_data = exc.response.json()
                    error_msg = error_data.get("error", {}).get("message", str(exc))
                except Exception:
                    error_msg = str(exc)
                raise ChatProviderError(f"OpenAI API error: {error_msg}", note="openai_api_error") from exc
            except httpx.RequestError as exc:
                _LOGGER.error("OpenAI network error: %s", exc)
                raise ChatProviderError(f"Network error: {exc}", note="openai_network_error") from exc

            # Check for incomplete response (reasoning consumed all tokens)
            if isinstance(data, dict) and data.get("status") == "incomplete":
                reason = data.get("incomplete_details", {}).get("reason")
                _LOGGER.warning(
                    "[OpenAI Chat] Response incomplete (reason=%s, attempt=%d, budget=%s)",
                    reason,
                    attempt + 1,
                    max_output_tokens,
                )
                if reason == "max_output_tokens" and max_output_tokens < 8192:
                    max_output_tokens = min(max_output_tokens * 2, 8192)
                    attempt += 1
                    continue
                raise ChatProviderError(
                    f"Response incomplete: {reason}",
                    note="openai_incomplete",
                )
            break

        if not isinstance(data, dict):
            raise ChatProviderError("Unexpected response structure from OpenAI", note="openai_format_error")

        # Responses API returns output array with message items
        # Format: {"output": [{"type": "message"|"reasoning", "content": [...]}]}
        output_items = data.get("output", [])
        reply_text = ""
        for item in output_items:
            if item.get("type") == "message":
                content_items = item.get("content", [])
                for content in content_items:
                    if content.get("type") == "output_text":
                        reply_text = content.get("text", "")
                        break
                if reply_text:
                    break
        if not reply_text:
            raise ChatProviderError(
                "No output_text found in Responses API response", note="openai_format_error"
            )

        # Parse JSON response
        try:
            response_data = json.loads(reply_text)
            greek_text = response_data.get("reply", "")
            translation_help = response_data.get("translation_help")
            grammar_notes = response_data.get("grammar_notes", [])
        except json.JSONDecodeError:
            # Fallback to parsing plain text if JSON fails
            _LOGGER.warning("Failed to parse JSON response, using fallback parser")
            translation_help, grammar_notes = self._parse_response(reply_text)
            greek_text = reply_text.split("\n")[0].strip()

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

    def _parse_response(self, text: str) -> tuple[str | None, list[str]]:
        """
        Parse LLM response to extract translation and grammar notes.

        Expected format (from persona prompts):
        Greek text
        Translation: English translation
        Grammar: Note 1
        Grammar: Note 2
        """
        lines = text.strip().split("\n")
        translation = None
        grammar_notes = []

        for line in lines[1:]:  # Skip first line (Greek text)
            line = line.strip()
            if line.startswith("Translation:"):
                translation = line.replace("Translation:", "").strip()
            elif line.startswith("Grammar:"):
                grammar_notes.append(line.replace("Grammar:", "").strip())

        return translation, grammar_notes
