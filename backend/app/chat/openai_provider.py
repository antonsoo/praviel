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

        # GPT-5 models use Responses API, GPT-4 uses Chat Completions API
        # IMPORTANT: This is October 2025 API - DO NOT change to older versions
        # See docs/AI_AGENT_GUIDELINES.md before modifying
        use_responses_api = model.startswith("gpt-5")

        if use_responses_api:
            # Responses API payload structure
            # Convert messages list to proper input format
            input_messages = []
            for msg in messages:
                input_messages.append({"role": msg["role"], "content": msg["content"]})

            # Use JSON object format (persona prompts already specify JSON structure)
            # October 2025 Responses API format - DO NOT change to response_format
            payload = {
                "model": model,
                "input": input_messages,
                "text": {"format": {"type": "json_object"}},  # NOT response_format!
                "max_output_tokens": 512,  # min 16 for GPT-5, NOT max_tokens!
                "reasoning": {"effort": "low"},
            }
            endpoint = "https://api.openai.com/v1/responses"
        else:
            # Chat Completions API payload (GPT-4 models)
            payload = {
                "model": model,
                "messages": messages,
                "temperature": 0.7,
                "max_tokens": 500,
                "response_format": {"type": "json_object"},  # For GPT-4 models
            }
            endpoint = "https://api.openai.com/v1/chat/completions"

        headers = {
            "Authorization": f"Bearer {token}",
            "Content-Type": "application/json",
        }

        timeout = httpx.Timeout(30.0)

        try:
            async with httpx.AsyncClient(timeout=timeout) as client:
                response = await client.post(endpoint, headers=headers, json=payload)
                response.raise_for_status()
                data = response.json()

            # Extract content based on API type
            if use_responses_api:
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
            else:
                # Chat Completions API returns message.content
                reply_text = data["choices"][0]["message"]["content"]

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
        except (KeyError, IndexError) as exc:
            _LOGGER.error("Unexpected OpenAI response format: %s", data)
            raise ChatProviderError(
                "Unexpected response format from OpenAI", note="openai_format_error"
            ) from exc

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
