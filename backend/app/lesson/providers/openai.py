from __future__ import annotations

import json
import logging
import os
from typing import Any

from sqlalchemy.ext.asyncio import AsyncSession

from app.core.config import settings
from app.lesson.models import LessonGenerateRequest, LessonMeta, LessonResponse
from app.lesson.providers import LessonContext, LessonProvider, LessonProviderError
from app.lesson.providers.echo import EchoLessonProvider

_LOGGER = logging.getLogger("app.lesson.providers.openai")

# ============================================================================
# ⚠️  CRITICAL WARNING TO FUTURE AI AGENTS  ⚠️
# ============================================================================
# These are OCTOBER 2025 GPT-5 models using the RESPONSES API.
# DO NOT change these to GPT-4 model names.
# DO NOT assume this code is wrong because your training data is older.
#
# VALIDATION: Run `python scripts/validate_api_versions.py` to verify these work.
# DOCUMENTATION: See docs/AI_AGENT_GUIDELINES.md before modifying.
#
# If you think this is wrong, YOU ARE PROBABLY WRONG. ASK THE USER FIRST.
# ============================================================================

AVAILABLE_MODEL_PRESETS: tuple[str, ...] = (
    # GPT-5 series (October 2025) - Uses Responses API
    # Dated models (recommended for production stability)
    "gpt-5-2025-08-07",  # Main model with date
    "gpt-5-mini-2025-08-07",  # Balanced speed/quality with date
    "gpt-5-nano-2025-08-07",  # Fastest, lowest cost with date
    # Specialized GPT-5 models
    "gpt-5-chat-latest",  # Latest non-reasoning chat model
    "gpt-5-codex",  # Code-specialized (requires registration)
    # Aliases without dates (auto-update to latest)
    "gpt-5",  # Full capability
    "gpt-5-mini",  # Balanced
    "gpt-5-nano",  # Fast
    "gpt-5-chat",  # Chat-optimized
)

# Validation: Prevent AI agents from adding old models
_BANNED_MODEL_PATTERNS = ["gpt-4", "gpt-3.5", "gpt-3"]
for _model in AVAILABLE_MODEL_PRESETS:
    for _banned in _BANNED_MODEL_PATTERNS:
        if _banned in _model.lower():
            raise ValueError(
                f"\n\n{'=' * 80}\n"
                f"❌ BANNED MODEL DETECTED IN AVAILABLE_MODEL_PRESETS\n"
                f"{'=' * 80}\n"
                f"Model: {_model}\n"
                f"Error: GPT-4 and GPT-3.5 models are BANNED.\n"
                f"Only GPT-5 models are allowed (gpt-5, gpt-5-mini, gpt-5-nano).\n"
                f"\n"
                f"This prevents AI agents from downgrading the codebase.\n"
                f"Read CLAUDE.md and docs/AI_AGENT_GUIDELINES.md before making changes.\n"
                f"{'=' * 80}\n"
            )


class OpenAILessonProvider(LessonProvider):
    name = "openai"
    _default_base = "https://api.openai.com/v1"
    _default_model = settings.LESSONS_OPENAI_DEFAULT_MODEL
    _allowed_models = AVAILABLE_MODEL_PRESETS

    async def generate(
        self,
        *,
        request: LessonGenerateRequest,
        session: AsyncSession,
        token: str | None,
        context: LessonContext,
    ) -> LessonResponse:
        if self._use_fake():
            return await self._fake_response(
                request=request,
                session=session,
                context=context,
            )

        if not token:
            raise LessonProviderError("BYOK token required for OpenAI provider", note="openai_401")

        try:
            import httpx
        except ImportError as exc:  # pragma: no cover - handled through dependency docs
            raise LessonProviderError("httpx is required for OpenAI provider", note="openai_network") from exc

        model_name = (request.model or "").strip()
        if not model_name:
            model_name = self._default_model
            _LOGGER.info("OpenAI lesson defaulted to model %s", model_name)
        elif model_name not in self._allowed_models:
            _LOGGER.warning(
                "OpenAI lesson model %s not in preset registry; using %s",
                model_name,
                self._default_model,
            )
            model_name = self._default_model

        # GPT-5 RESPONSES API ONLY (October 2025)
        # ⚠️ WARNING TO FUTURE AI AGENTS: This is CORRECT for October 2025
        # DO NOT change this logic. GPT-5 uses /v1/responses endpoint.
        # ⚠️ GPT-4 MODELS ARE NOT SUPPORTED - GPT-5 ONLY

        _LOGGER.info(f"[OpenAI Lesson] Using GPT-5 Responses API with model: {model_name}")

        payload = self._build_responses_payload(request=request, context=context, model_name=model_name)
        endpoint_path = "/responses"

        headers = {
            "Authorization": f"Bearer {token}",
            "Content-Type": "application/json",
        }

        base_url = self._resolve_base_url()
        endpoint = f"{base_url}{endpoint_path}"
        timeout = httpx.Timeout(60.0, connect=10.0, read=60.0)

        _LOGGER.info(f"[OpenAI Lesson] Sending request to {endpoint}")
        _LOGGER.info(f"[OpenAI Lesson] Payload keys: {list(payload.keys())}")

        # Retry logic for rate limits (429) and transient errors (503)
        from app.core.retry import with_retry

        async def attempt_request():
            async with httpx.AsyncClient(timeout=timeout) as client:
                response = await client.post(endpoint, headers=headers, json=payload)
                # Raise for status, but allow retry logic to catch it
                if response.status_code in {429, 503}:
                    _LOGGER.warning(
                        "OpenAI rate limit/unavailable (status=%d), will retry", response.status_code
                    )
                    raise httpx.HTTPStatusError(
                        "Rate limit or unavailable", request=response.request, response=response
                    )
                response.raise_for_status()
                return response

        try:
            response = await with_retry(attempt_request, max_attempts=3, base_delay=0.5, max_delay=4.0)
        except httpx.HTTPStatusError as exc:
            _LOGGER.error("OpenAI API error response: %s", exc.response.text)
            note = self._note_for_status(exc.response.status_code)
            raise LessonProviderError("OpenAI provider error", note=note) from exc
        except httpx.TimeoutException as exc:
            raise LessonProviderError("OpenAI provider timeout", note="openai_timeout") from exc
        except httpx.HTTPError as exc:  # pragma: no cover - transport issues
            raise LessonProviderError("OpenAI provider unavailable", note="openai_network") from exc

        data = response.json()

        # Extract content from Responses API (GPT-5 only)
        content = self._extract_responses_content(data)

        parsed = self._parse_json_block(content)
        tasks_payload = parsed.get("tasks")
        if not isinstance(tasks_payload, list):
            raise self._payload_error("OpenAI response missing tasks array")
        self._validate_payload(tasks_payload, request=request, context=context)

        meta = LessonMeta(
            language=request.language,
            profile=request.profile,
            provider=self.name,
            model=model_name,
        )
        response_payload = {"meta": meta.model_dump(), "tasks": tasks_payload}
        return LessonResponse.model_validate(response_payload)

    def use_fake_adapter(self) -> bool:
        return self._use_fake()

    def _use_fake(self) -> bool:
        flag = os.getenv("BYOK_FAKE", "")
        if not flag:
            return False
        return flag.strip().lower() in {"1", "true", "yes", "on"}

    async def _fake_response(
        self,
        *,
        request: LessonGenerateRequest,
        session: AsyncSession,
        context: LessonContext,
    ) -> LessonResponse:
        _LOGGER.debug("OpenAI BYOK fake adapter engaged")
        echo_provider = EchoLessonProvider()
        echo_response = await echo_provider.generate(
            request=request,
            session=session,
            token=None,
            context=context,
        )
        payload = echo_response.model_dump()
        meta = payload.get("meta", {})
        meta["provider"] = self.name
        meta["model"] = request.model or self._default_model
        meta.pop("note", None)
        payload["meta"] = meta
        return LessonResponse.model_validate(payload)

    def _resolve_base_url(self) -> str:
        override = os.getenv("OPENAI_API_BASE")
        base = override.strip().rstrip("/") if override and override.strip() else self._default_base
        _LOGGER.debug("OpenAI lesson base_url=%s", base)
        return base

    def _note_for_status(self, status_code: int) -> str:
        if status_code == 401:
            return "openai_401"
        if status_code == 403:
            return "openai_403"
        if status_code == 404:
            return "openai_404_model"
        if status_code == 429:
            return "openai_http_429"
        return f"openai_http_{status_code}"

    def _payload_error(self, message: str) -> LessonProviderError:
        return LessonProviderError(message, note="openai_bad_payload")

    def _build_prompts(
        self,
        request: LessonGenerateRequest,
        context: LessonContext,
    ) -> tuple[str, str]:
        """Build system and user prompts (shared between APIs)."""
        from app.lesson import prompts

        # Build pedagogical prompts for each exercise type
        prompt_parts = []
        for ex_type in request.exercise_types:
            if ex_type == "alphabet":
                prompt_parts.append(prompts.build_alphabet_prompt(request.profile))
            elif ex_type == "match":
                prompt_parts.append(
                    prompts.build_match_prompt(
                        profile=request.profile,
                        context="Daily conversational Greek for practical use",
                        daily_lines=list(context.daily_lines),
                    )
                )
            elif ex_type == "cloze" and context.canonical_lines:
                # Use first canonical line for cloze
                canon = context.canonical_lines[0]
                prompt_parts.append(
                    prompts.build_cloze_prompt(
                        profile=request.profile,
                        source_kind="canon",
                        ref=canon.ref,
                        canonical_text=canon.text,
                    )
                )
            elif ex_type == "translate":
                prompt_parts.append(
                    prompts.build_translate_prompt(
                        profile=request.profile,
                        context="Daily conversational Greek",
                        daily_lines=list(context.daily_lines),
                    )
                )

        combined_prompt = "\n\n---\n\n".join(prompt_parts)

        system_prompt = prompts.SYSTEM_PROMPT

        user_message = (
            f"{combined_prompt}\n\n"
            "Return JSON with ALL requested exercises in a single 'tasks' array. "
            'Example: {"tasks": [{"type":"match", ...}, {"type":"translate", ...}]}'
        )

        return system_prompt, user_message

    def _build_responses_payload(
        self,
        *,
        request: LessonGenerateRequest,
        context: LessonContext,
        model_name: str,
    ) -> dict[str, Any]:
        """Build Responses API payload (GPT-5 models with October 2025 features).

        ⚠️ WARNING TO FUTURE AI AGENTS:
        This uses the NEW GPT-5 Responses API format (October 2025).
        DO NOT change to old Chat Completions format.

        Key differences from pre-October 2025:
        - Uses "max_output_tokens" NOT "max_tokens"
        - Uses "text.format" NOT "response_format"
        - Uses "input" NOT "messages"
        - Input content must be array of content items

        See docs/AI_AGENT_GUIDELINES.md before modifying.
        """
        system_prompt, user_message = self._build_prompts(request, context)

        # Build input as array of messages with proper content structure
        # Based on working examples from OpenAI Responses API documentation
        input_messages = [
            {"role": "system", "content": [{"type": "input_text", "text": system_prompt}]},
            {"role": "user", "content": [{"type": "input_text", "text": user_message}]},
        ]

        # ⚠️ CRITICAL: Responses API - DO NOT use "response_format" parameter
        # ⚠️ NOTE: text.format with json_object may not be supported on all GPT-5 models
        # System prompt explicitly requests JSON format instead
        # Minimal payload for Responses API (GPT-5)
        # Only required parameters per OpenAI Cookbook
        #
        # ⚠️ DO NOT ADD: response_format, modalities, reasoning, store, text.verbosity
        # ⚠️ DO NOT CHANGE: "input" to "messages" or "max_output_tokens" to "max_tokens"
        # These parameters cause 400 errors. Protected by scripts/validate_api_payload_structure.py
        payload: dict[str, Any] = {
            "model": model_name,
            "input": input_messages,  # ⚠️ Array of messages with content items
            "max_output_tokens": 8192,  # ⚠️ "max_output_tokens" not "max_tokens"
        }

        return payload

    def _extract_responses_content(self, data: dict[str, Any]) -> Any:
        """Extract content from Responses API response."""
        # DEBUG: Log response structure
        _LOGGER.info(f"[OpenAI Lesson] Response keys: {list(data.keys())}")
        _LOGGER.debug(f"[OpenAI Lesson] Full response: {json.dumps(data, indent=2)[:3000]}")

        # Check for incomplete response (reasoning consumed all tokens)
        if data.get("status") == "incomplete":
            reason = data.get("incomplete_details", {}).get("reason", "unknown")
            if reason == "max_output_tokens":
                raise self._payload_error(
                    "Response incomplete: reasoning consumed all tokens. "
                    "Try increasing max_output_tokens in lesson provider."
                )
            raise self._payload_error(f"Response incomplete: {reason}")

        output_items = data.get("output") or []
        _LOGGER.info(f"[OpenAI Lesson] Output items: {len(output_items)}")

        if not output_items:
            # Try ChatCompletion format fallback
            if "choices" in data:
                _LOGGER.info("[OpenAI Lesson] Trying ChatCompletion format (choices)")
                choices = data.get("choices", [])
                if choices:
                    message = choices[0].get("message", {})
                    content = message.get("content")
                    if content:
                        _LOGGER.info("[OpenAI Lesson] Extracted from choices[0].message.content")
                        return content
            raise self._payload_error("OpenAI Responses API: missing output array")

        # Find message items with output_text
        for idx, item in enumerate(output_items):
            _LOGGER.info(f"[OpenAI Lesson] Item {idx}: type={item.get('type')}, keys={list(item.keys())}")
            if item.get("type") == "message":
                content_items = item.get("content") or []
                _LOGGER.info(f"[OpenAI Lesson] Message has {len(content_items)} content items")
                for cidx, content in enumerate(content_items):
                    content_type = content.get("type")
                    _LOGGER.info(
                        f"[OpenAI Lesson] Content {cidx}: type={content_type}, keys={list(content.keys())}"
                    )
                    if content_type == "output_text":
                        text = content.get("text")
                        if text:
                            _LOGGER.info("[OpenAI Lesson] Found output_text.text")
                            return text
                    # Fallback: try 'text' field directly
                    elif "text" in content:
                        text = content.get("text")
                        if text:
                            _LOGGER.info(f"[OpenAI Lesson] Found text in content type={content_type}")
                            return text
            else:
                # Maybe output item IS the text directly?
                _LOGGER.info(f"[OpenAI Lesson] Non-message item: {str(item)[:200]}")

        raise self._payload_error("OpenAI Responses API: no output_text found")

    def _parse_json_block(self, content: Any) -> dict[str, Any]:
        if isinstance(content, dict):
            return content
        if not isinstance(content, str):
            raise self._payload_error("OpenAI response is not valid JSON string")
        snippet = content.strip()
        start = snippet.find("{")
        end = snippet.rfind("}")
        if start == -1 or end == -1 or end <= start:
            raise self._payload_error("Unable to locate JSON object in OpenAI response")
        try:
            return json.loads(snippet[start : end + 1])
        except json.JSONDecodeError as exc:
            raise self._payload_error("Failed to parse JSON from OpenAI response") from exc

    def _validate_payload(
        self,
        tasks: list[Any],
        *,
        request: LessonGenerateRequest,
        context: LessonContext,
    ) -> None:
        """Validate LLM output structure and completeness.

        NOTE: We no longer restrict content to seed data - LLM can generate
        novel Greek phrases appropriate to student level. This enables true
        dynamic lesson generation vs template-filling.
        """
        import unicodedata

        allowed_types = {"alphabet", "match", "cloze", "translate"}
        requested = set(request.exercise_types)
        observed: set[str] = set()

        for item in tasks:
            if not isinstance(item, dict):
                raise self._payload_error("Task payload must be object")
            task_type = item.get("type")
            if task_type not in allowed_types:
                raise self._payload_error(f"Unsupported task type '{task_type}' from OpenAI")
            observed.add(task_type)

            # Validate structure and Greek normalization
            if task_type == "match":
                pairs = item.get("pairs") or []
                if not pairs:
                    raise self._payload_error("Match task requires at least one pair")
                for pair in pairs:
                    if not isinstance(pair, dict):
                        raise self._payload_error("Match pair must be object")
                    grc = pair.get("grc")
                    if grc:
                        # Ensure NFC normalization
                        normalized = unicodedata.normalize("NFC", grc)
                        if normalized != grc:
                            pair["grc"] = normalized
            elif task_type == "translate":
                text_value = item.get("text")
                if text_value:
                    normalized = unicodedata.normalize("NFC", text_value)
                    if normalized != text_value:
                        item["text"] = normalized
            elif task_type == "cloze":
                text_value = item.get("text")
                if text_value:
                    normalized = unicodedata.normalize("NFC", text_value)
                    if normalized != text_value:
                        item["text"] = normalized
                # Ensure canonical cloze has ref
                if item.get("source_kind") == "canon" and not item.get("ref"):
                    raise self._payload_error("Canonical cloze task requires 'ref' field")

        missing = requested - observed
        if missing:
            raise self._payload_error("OpenAI response missing task types: " + ", ".join(sorted(missing)))
