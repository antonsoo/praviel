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
from app.lesson.script_utils import enforce_script_conventions

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
        try:
            content = self._extract_responses_content(data)
        except LessonProviderError as exc:
            # If Responses API format fails, log full response for debugging
            _LOGGER.error(
                "[OpenAI Lesson] Failed to extract content from Responses API format. "
                "Full response structure: %s",
                json.dumps(data, indent=2, ensure_ascii=False)[:5000]
            )
            # Try extracting from potential Chat Completions format as absolute fallback
            if "choices" in data and data.get("choices"):
                first_choice = data["choices"][0]
                message_content = first_choice.get("message", {}).get("content")
                if message_content:
                    _LOGGER.info("[OpenAI Lesson] Extracted content from Chat Completions fallback")
                    content = message_content
                else:
                    raise
            else:
                raise

        parsed: dict[str, Any]
        try:
            parsed = self._parse_json_block(content)
            tasks_payload = parsed.get("tasks")
            if not isinstance(tasks_payload, list):
                raise self._payload_error("OpenAI response missing tasks array")
            enforce_script_conventions(tasks_payload, request.language)
            self._validate_payload(tasks_payload, request=request, context=context)
        except LessonProviderError as exc:
            snippet: str
            if isinstance(content, str):
                snippet = content
            else:
                snippet = json.dumps(content, ensure_ascii=False)[:2000]
            _LOGGER.error(
                "OpenAI payload validation failed: %s | snippet=%s",
                exc,
                snippet[:512],
            )
            raise

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
        from app.lesson.lang_config import get_system_prompt

        daily_lines = list(context.daily_lines)
        canonical_lines = list(context.canonical_lines)
        register = context.register or "literary"

        text_samples: list[str] = []
        if context.text_range_data and context.text_range_data.text_samples:
            text_samples.extend(context.text_range_data.text_samples)
        if canonical_lines:
            text_samples.extend([line.text for line in canonical_lines])
        if daily_lines:
            text_samples.extend([line.text for line in daily_lines])

        vocabulary_items = list(context.text_range_data.vocabulary) if context.text_range_data else []
        grammar_patterns = list(context.text_range_data.grammar_patterns) if context.text_range_data else []

        def _resolve_cloze_source() -> tuple[str, str, str]:
            if canonical_lines:
                canon = canonical_lines[0]
                return "canon", canon.ref, canon.text
            if text_samples:
                sample_text = text_samples[0]
                return "text_range", "sample_text", sample_text
            if daily_lines:
                daily = daily_lines[0]
                ref_label = daily.en or "daily_expression"
                return "daily", ref_label, daily.text
            # Language-specific fallbacks
            fallback_texts = {
                "grc": "Χαῖρε, φίλε.",
                "lat": "SALVE, AMICE.",
                "heb": "שלום, חבר.",
                "egy": "ḥtp dỉ",
                "akk": "šulmu",
            }
            fallback_text = fallback_texts.get(request.language, "Hello, friend.")
            return "daily", "generic_context", fallback_text

        # Build pedagogical prompts for each exercise type
        prompt_parts = []
        for ex_type in request.exercise_types:
            if ex_type == "alphabet":
                prompt_parts.append(prompts.build_alphabet_prompt(request.profile, request.language))
            elif ex_type == "match":
                # Language-specific context
                lang_contexts = {
                    "grc": "Daily conversational Greek for practical use",
                    "lat": "Daily conversational Latin for practical use",
                    "heb": "Daily conversational Hebrew for practical use",
                    "egy": "Daily Middle Egyptian hieroglyphic expressions",
                    "akk": "Daily Akkadian cuneiform expressions",
                }
                context_desc = lang_contexts.get(
                    request.language, f"Daily conversational {request.language} for practical use"
                )
                prompt_parts.append(
                    prompts.build_match_prompt(
                        profile=request.profile,
                        context=context_desc,
                        daily_lines=daily_lines,
                        language=request.language,
                    )
                )
            elif ex_type == "cloze":
                source_kind, ref_value, text_value = _resolve_cloze_source()
                prompt_parts.append(
                    prompts.build_cloze_prompt(
                        profile=request.profile,
                        source_kind=source_kind,
                        ref=ref_value,
                        canonical_text=text_value,
                    )
                )
            elif ex_type == "translate":
                # Language-specific context
                lang_contexts = {
                    "grc": "Daily conversational Greek",
                    "lat": "Daily conversational Latin",
                    "heb": "Daily conversational Hebrew",
                    "egy": "Daily Middle Egyptian",
                    "akk": "Daily Akkadian",
                }
                context_desc = lang_contexts.get(request.language, f"Daily conversational {request.language}")
                prompt_parts.append(
                    prompts.build_translate_prompt(
                        profile=request.profile,
                        context=context_desc,
                        daily_lines=daily_lines,
                        language=request.language,
                    )
                )
            elif ex_type == "grammar":
                prompt_parts.append(
                    prompts.build_grammar_prompt(
                        profile=request.profile,
                        grammar_patterns=grammar_patterns,
                        text_samples=text_samples,
                    )
                )
            elif ex_type == "listening":
                prompt_parts.append(
                    prompts.build_listening_prompt(
                        profile=request.profile,
                        daily_lines=daily_lines,
                        language=request.language,
                    )
                )
            elif ex_type == "speaking":
                prompt_parts.append(
                    prompts.build_speaking_prompt(
                        profile=request.profile,
                        register=register,
                        daily_lines=daily_lines,
                        language=request.language,
                    )
                )
            elif ex_type == "wordbank":
                prompt_parts.append(
                    prompts.build_wordbank_prompt(
                        profile=request.profile,
                        text_samples=text_samples,
                    )
                )
            elif ex_type == "truefalse":
                prompt_parts.append(
                    prompts.build_truefalse_prompt(
                        profile=request.profile,
                        grammar_patterns=grammar_patterns,
                    )
                )
            elif ex_type == "multiplechoice":
                prompt_parts.append(
                    prompts.build_multiplechoice_prompt(
                        profile=request.profile,
                        text_samples=text_samples,
                    )
                )
            elif ex_type == "dialogue":
                prompt_parts.append(
                    prompts.build_dialogue_prompt(
                        profile=request.profile,
                        daily_lines=daily_lines,
                        register=register,
                        language=request.language,
                    )
                )
            elif ex_type == "conjugation":
                prompt_parts.append(
                    prompts.build_conjugation_prompt(
                        profile=request.profile,
                        vocabulary=vocabulary_items,
                    )
                )
            elif ex_type == "declension":
                prompt_parts.append(
                    prompts.build_declension_prompt(
                        profile=request.profile,
                        vocabulary=vocabulary_items,
                    )
                )
            elif ex_type == "synonym":
                prompt_parts.append(
                    prompts.build_synonym_prompt(
                        profile=request.profile,
                        vocabulary=vocabulary_items,
                    )
                )
            elif ex_type == "contextmatch":
                prompt_parts.append(
                    prompts.build_contextmatch_prompt(
                        profile=request.profile,
                        text_samples=text_samples,
                    )
                )
            elif ex_type == "reorder":
                prompt_parts.append(
                    prompts.build_reorder_prompt(
                        profile=request.profile,
                        text_samples=text_samples,
                    )
                )
            elif ex_type == "dictation":
                prompt_parts.append(
                    prompts.build_dictation_prompt(
                        profile=request.profile,
                        daily_lines=daily_lines,
                        language=request.language,
                    )
                )
            elif ex_type == "etymology":
                prompt_parts.append(
                    prompts.build_etymology_prompt(
                        profile=request.profile,
                        vocabulary=vocabulary_items,
                    )
                )
            elif ex_type == "comprehension":
                source_kind, ref_value, text_value = _resolve_cloze_source()
                prompt_parts.append(
                    prompts.build_comprehension_prompt(
                        profile=request.profile,
                        source_kind=source_kind,
                        ref=ref_value,
                        canonical_text=text_value,
                    )
                )

        combined_prompt = "\n\n---\n\n".join(prompt_parts)

        system_prompt = get_system_prompt(request.language)

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
        - Role must be "developer" (not "system")
        - Content must be string (not array)

        See docs/AI_AGENT_GUIDELINES.md before modifying.
        """
        system_prompt, user_message = self._build_prompts(request, context)

        # Build input as array of messages with proper content structure
        # Based on working examples from OpenAI Responses API documentation (October 2025)
        # ⚠️ CRITICAL FIX: role must be "developer" (not "system") and content must be string (not array)
        input_messages = [
            {"role": "developer", "content": system_prompt},
            {"role": "user", "content": user_message},
        ]

        # ⚠️ CRITICAL: Responses API - DO NOT use "response_format" parameter
        # ⚠️ NOTE: text.format with json_object may not be supported on all GPT-5 models
        # System prompt explicitly requests JSON format instead
        # Minimal payload for Responses API (GPT-5)
        # Only required parameters per OpenAI Cookbook
        #
        # ⚠️ DO NOT ADD: response_format, modalities, store
        # ⚠️ DO NOT CHANGE: "input" to "messages" or "max_output_tokens" to "max_tokens"
        # These parameters cause 400 errors. Protected by scripts/validate_api_payload_structure.py
        payload: dict[str, Any] = {
            "model": model_name,
            "input": input_messages,  # ⚠️ Array of messages with content items
            "max_output_tokens": 16384,  # ⚠️ Increased for reasoning models (gpt-5-mini uses reasoning tokens)
            "text": {"format": {"type": "json_object"}},  # Responses API explicit JSON structure
        }

        # Only add reasoning parameter for models that support it (gpt-5, gpt-5-mini, but NOT gpt-5-nano)
        # gpt-5-nano does not support reasoning parameter
        if "nano" not in model_name.lower():
            payload["reasoning"] = {
                "effort": "low"  # Minimize reasoning tokens for lesson generation
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
                # Handle case where content is a string instead of list
                if isinstance(content_items, str):
                    _LOGGER.info("[OpenAI Lesson] Message content is string, returning directly")
                    return content_items
                if not isinstance(content_items, list):
                    content_items = [content_items]
                _LOGGER.info(f"[OpenAI Lesson] Message has {len(content_items)} content items")
                for cidx, content in enumerate(content_items):
                    # Handle string content items
                    if isinstance(content, str):
                        _LOGGER.info(f"[OpenAI Lesson] Content {cidx} is string, returning directly")
                        return content
                    if not isinstance(content, dict):
                        continue
                    content_type = content.get("type")
                    _LOGGER.info(
                        f"[OpenAI Lesson] Content {cidx}: type={content_type}, keys={list(content.keys())}"
                    )
                    if content_type == "output_text":
                        text = content.get("text")
                        if text:
                            _LOGGER.info("[OpenAI Lesson] Found output_text.text")
                            return text
                    elif content_type in {"tool_call", "tool_use"}:
                        arguments = content.get("arguments") or content.get("input")
                        if isinstance(arguments, str) and arguments.strip():
                            _LOGGER.info("[OpenAI Lesson] Found tool_call arguments")
                            return arguments
                        if isinstance(arguments, dict):
                            _LOGGER.info("[OpenAI Lesson] Found tool_call argument object")
                            return json.dumps(arguments)
                    elif content_type in {"json_object", "object", "json"}:
                        obj = content.get("object") or content.get("data")
                        if isinstance(obj, dict):
                            _LOGGER.info("[OpenAI Lesson] Found JSON object content")
                            return json.dumps(obj)
                        raw = content.get("text")
                        if isinstance(raw, str) and raw.strip():
                            _LOGGER.info("[OpenAI Lesson] Found JSON text content")
                            return raw
                    # Fallback: try 'text' field directly
                    elif "text" in content:
                        text = content.get("text")
                        if text:
                            _LOGGER.info(f"[OpenAI Lesson] Found text in content type={content_type}")
                            return text
                    # Last resort: check for any JSON-like string in common keys
                    for key in ("value", "data", "result", "content"):
                        if key in content:
                            val = content[key]
                            if isinstance(val, str) and val.strip():
                                _LOGGER.info(f"[OpenAI Lesson] Found {key} with string value")
                                return val
            else:
                # Maybe output item IS the text directly?
                _LOGGER.info(f"[OpenAI Lesson] Non-message item: {str(item)[:200]}")
                # Try to extract any usable content
                if isinstance(item, str):
                    return item
                if isinstance(item, dict):
                    for key in ("text", "content", "value", "data"):
                        if key in item and isinstance(item[key], str):
                            _LOGGER.info(f"[OpenAI Lesson] Found {key} in non-message item")
                            return item[key]

        raise self._payload_error("OpenAI Responses API: no output_text found")

    def _parse_json_block(self, content: Any) -> dict[str, Any]:
        if isinstance(content, dict):
            return content
        if not isinstance(content, str):
            raise self._payload_error("OpenAI response is not valid JSON string or dict")
        snippet = content.strip()

        # Try parsing the whole string first
        try:
            parsed = json.loads(snippet)
            if isinstance(parsed, dict):
                return parsed
        except json.JSONDecodeError:
            pass

        # Try to extract JSON block from markdown code fence or other wrapping
        # Remove common wrappers: ```json ... ```, ```...```, etc.
        if snippet.startswith("```"):
            lines = snippet.split("\n")
            # Remove first line (```json or ```)
            if len(lines) > 1:
                snippet = "\n".join(lines[1:])
            # Remove last line if it's ```
            if snippet.rstrip().endswith("```"):
                snippet = snippet.rstrip()[:-3].strip()
            try:
                parsed = json.loads(snippet)
                if isinstance(parsed, dict):
                    return parsed
            except json.JSONDecodeError:
                pass

        # Find JSON object boundaries
        start = snippet.find("{")
        end = snippet.rfind("}")
        if start == -1 or end == -1 or end <= start:
            raise self._payload_error(
                f"Unable to locate JSON object in OpenAI response. Content preview: {snippet[:500]}"
            )

        json_str = snippet[start : end + 1]
        try:
            return json.loads(json_str)
        except json.JSONDecodeError as exc:
            # Log the problematic JSON for debugging
            _LOGGER.error(
                "Failed to parse JSON from OpenAI. Excerpt: %s",
                json_str[:1000],
                exc_info=True,
            )
            raise self._payload_error(
                f"Failed to parse JSON from OpenAI response: {str(exc)}"
            ) from exc

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

        allowed_types = {
            "alphabet",
            "match",
            "cloze",
            "translate",
            "grammar",
            "listening",
            "speaking",
            "wordbank",
            "truefalse",
            "multiplechoice",
            "dialogue",
            "conjugation",
            "declension",
            "synonym",
            "contextmatch",
            "reorder",
            "dictation",
            "etymology",
            "comprehension",
        }
        requested = set(request.exercise_types)
        unsupported = requested - allowed_types
        if unsupported:
            _LOGGER.warning(
                "OpenAI provider received unsupported exercise types: %s",
                ", ".join(sorted(unsupported)),
            )
        requested &= allowed_types
        observed: set[str] = set()

        def _normalize_item(item: dict[str, Any], key: str) -> None:
            value = item.get(key)
            if isinstance(value, str):
                normalized = unicodedata.normalize("NFC", value)
                if normalized != value:
                    item[key] = normalized

        def _normalize_list(values: list[Any], *, field: str) -> list[str]:
            normalized: list[str] = []
            for entry in values:
                if entry is None:
                    raise self._payload_error(f"{field} entries must be non-null")
                if not isinstance(entry, str):
                    entry = str(entry)
                normalized.append(unicodedata.normalize("NFC", entry))
            return normalized

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
                    # Handle both "grc" (from prompt) and "native" (from model)
                    grc = pair.get("grc") or pair.get("native")
                    if grc:
                        # Ensure NFC normalization
                        normalized = unicodedata.normalize("NFC", grc)
                        # Store as "native" to match Pydantic model
                        pair["native"] = normalized
                        # Remove "grc" key if it exists
                        pair.pop("grc", None)
                    en_value = (
                        pair.get("en")
                        or pair.get("english")
                        or pair.get("english_gloss")
                        or pair.get("translation")
                    )
                    if isinstance(en_value, str) and en_value.strip():
                        pair["en"] = en_value.strip()
                    else:
                        raise self._payload_error("Match pair requires English gloss")
            elif task_type == "translate":
                # Normalize direction field: grc->en becomes native->en
                direction = item.get("direction", "native->en")
                if direction == "grc->en":
                    item["direction"] = "native->en"
                elif direction == "en->grc":
                    item["direction"] = "en->native"
                elif "direction" not in item:
                    item["direction"] = "native->en"
                _normalize_item(item, "text")
                if item.get("text") is None:
                    raise self._payload_error("Translate task requires 'text'")
                rubric = item.get("rubric")
                if rubric is not None and not isinstance(rubric, str):
                    raise self._payload_error("Translate rubric must be string")
            elif task_type == "cloze":
                _normalize_item(item, "text")
                if not item.get("text"):
                    raise self._payload_error("Cloze task requires 'text'")
                # Ensure canonical cloze has ref
                if item.get("source_kind") == "canon" and not item.get("ref"):
                    raise self._payload_error("Canonical cloze task requires 'ref' field")
                blanks = item.get("blanks") or []
                if not isinstance(blanks, list) or not blanks:
                    raise self._payload_error("Cloze task requires blanks array")
                for blank in blanks:
                    if not isinstance(blank, dict):
                        raise self._payload_error("Cloze blank must be object")
                    _normalize_item(blank, "surface")
                    if "idx" not in blank or not isinstance(blank["idx"], int):
                        raise self._payload_error("Cloze blank requires integer idx")
                options = item.get("options") or []
                if not isinstance(options, list) or len(options) < 2:
                    raise self._payload_error("Cloze task requires options array")
                item["options"] = _normalize_list(options, field="cloze options")
            elif task_type == "alphabet":
                if not isinstance(item.get("prompt"), str):
                    raise self._payload_error("Alphabet task requires prompt string")
                options = item.get("options") or []
                if not isinstance(options, list) or len(options) < 2:
                    raise self._payload_error("Alphabet task requires options array")
                item["options"] = _normalize_list(options, field="alphabet options")
                answer = item.get("answer")
                if not isinstance(answer, str):
                    raise self._payload_error("Alphabet task requires answer string")
                answer_norm = unicodedata.normalize("NFC", answer)
                if answer_norm not in item["options"]:
                    raise self._payload_error("Alphabet answer must appear in options")
                item["answer"] = answer_norm
            elif task_type == "grammar":
                _normalize_item(item, "sentence")
                sentence = item.get("sentence")
                if not isinstance(sentence, str) or not sentence.strip():
                    raise self._payload_error("Grammar task requires sentence")
                if not isinstance(item.get("is_correct"), bool):
                    raise self._payload_error("Grammar task requires boolean is_correct")
                if item["is_correct"]:
                    explanation = item.get("error_explanation")
                    if explanation not in (None, "") and not isinstance(explanation, str):
                        raise self._payload_error("Grammar explanation must be string or null")
                else:
                    explanation = item.get("error_explanation")
                    if not isinstance(explanation, str) or not explanation.strip():
                        raise self._payload_error(
                            "Grammar task requires error_explanation when is_correct is false"
                        )
            elif task_type == "listening":
                _normalize_item(item, "audio_text")
                if not item.get("audio_text"):
                    raise self._payload_error("Listening task requires audio_text")
                options = item.get("options") or []
                if not isinstance(options, list) or len(options) < 2:
                    raise self._payload_error("Listening task requires options array")
                item["options"] = _normalize_list(options, field="listening options")
                answer = item.get("answer")
                if not isinstance(answer, str):
                    raise self._payload_error("Listening task requires answer string")
                answer_norm = unicodedata.normalize("NFC", answer)
                if answer_norm not in item["options"]:
                    raise self._payload_error("Listening answer must appear in options")
                item["answer"] = answer_norm
            elif task_type == "speaking":
                if not isinstance(item.get("prompt"), str):
                    raise self._payload_error("Speaking task requires prompt")
                _normalize_item(item, "target_text")
                if not item.get("target_text"):
                    raise self._payload_error("Speaking task requires target_text")
                guide = item.get("phonetic_guide")
                if guide is not None and not isinstance(guide, str):
                    raise self._payload_error("Speaking phonetic_guide must be string")
            elif task_type == "wordbank":
                words = item.get("words") or []
                if not isinstance(words, list) or len(words) < 2:
                    raise self._payload_error("Wordbank task requires words array")
                item["words"] = _normalize_list(words, field="wordbank words")
                order = item.get("correct_order") or []
                if not isinstance(order, list) or len(order) != len(item["words"]):
                    raise self._payload_error("Wordbank correct_order must match words length")
                if not all(isinstance(idx, int) for idx in order):
                    raise self._payload_error("Wordbank correct_order must contain integers")
                if sorted(order) != list(range(len(item["words"]))):
                    raise self._payload_error("Wordbank correct_order must be permutation of indices")
                if not isinstance(item.get("translation"), str):
                    raise self._payload_error("Wordbank task requires translation string")
            elif task_type == "truefalse":
                if not isinstance(item.get("statement"), str):
                    raise self._payload_error("True/false task requires statement")
                is_true = item.get("is_true")
                if not isinstance(is_true, bool):
                    answer_val = item.get("answer")
                    if isinstance(answer_val, bool):
                        is_true = answer_val
                    elif isinstance(answer_val, str):
                        lowered = answer_val.strip().lower()
                        if lowered in {"true", "t", "1", "yes"}:
                            is_true = True
                        elif lowered in {"false", "f", "0", "no"}:
                            is_true = False
                    if isinstance(is_true, bool):
                        item["is_true"] = is_true
                    else:
                        raise self._payload_error("True/false task requires boolean is_true")
                explanation = item.get("explanation")
                if not isinstance(explanation, str) or not explanation.strip():
                    raise self._payload_error("True/false task requires explanation string")
            elif task_type == "multiplechoice":
                if not isinstance(item.get("question"), str):
                    raise self._payload_error("Multiple choice task requires question")
                context_text = item.get("context")
                if context_text is not None:
                    _normalize_item(item, "context")
                options = item.get("options") or []
                if not isinstance(options, list) or len(options) < 2:
                    raise self._payload_error("Multiple choice requires options array")
                item["options"] = _normalize_list(options, field="multiple choice options")
                answer_index = item.get("answer_index")
                if answer_index is None:
                    answer_value = item.get("answer")
                    if isinstance(answer_value, int):
                        answer_index = answer_value
                    elif isinstance(answer_value, str):
                        try:
                            answer_index = item["options"].index(answer_value)
                        except ValueError:
                            answer_index = None
                if not isinstance(answer_index, int) or not (0 <= answer_index < len(item["options"])):
                    raise self._payload_error("Multiple choice answer_index out of range")
                item["answer_index"] = answer_index
            elif task_type == "dialogue":
                lines = item.get("lines") or []
                if not isinstance(lines, list) or len(lines) < 2:
                    raise self._payload_error("Dialogue task requires at least two lines")
                for line in lines:
                    if not isinstance(line, dict):
                        raise self._payload_error("Dialogue line must be object")
                    if not isinstance(line.get("speaker"), str):
                        raise self._payload_error("Dialogue line requires speaker")
                    _normalize_item(line, "text")
                    if not line.get("text"):
                        raise self._payload_error("Dialogue line requires text")
                missing_index = item.get("missing_index")
                if not isinstance(missing_index, int) or not (0 <= missing_index < len(lines)):
                    raise self._payload_error("Dialogue missing_index out of range")
                options = item.get("options") or []
                if not isinstance(options, list) or len(options) < 2:
                    raise self._payload_error("Dialogue task requires options array")
                item["options"] = _normalize_list(options, field="dialogue options")
                answer = item.get("answer")
                if not isinstance(answer, str):
                    raise self._payload_error("Dialogue task requires answer string")
                answer_norm = unicodedata.normalize("NFC", answer)
                if answer_norm not in item["options"]:
                    raise self._payload_error("Dialogue answer must appear in options")
                item["answer"] = answer_norm
            elif task_type == "conjugation":
                for key in ("verb_infinitive", "verb_meaning", "person", "tense", "answer"):
                    if not isinstance(item.get(key), str) or not item[key].strip():
                        raise self._payload_error(f"Conjugation task requires '{key}' string")
                    _normalize_item(item, key)
            elif task_type == "declension":
                for key in ("word", "word_meaning", "case", "number", "answer"):
                    if not isinstance(item.get(key), str) or not item[key].strip():
                        raise self._payload_error(f"Declension task requires '{key}' string")
                    _normalize_item(item, key)
            elif task_type == "synonym":
                for key in ("word", "answer"):
                    if not isinstance(item.get(key), str) or not item[key].strip():
                        raise self._payload_error(f"Synonym task requires '{key}' string")
                    _normalize_item(item, key)
                task_mode = item.get("task_type")
                if task_mode not in {"synonym", "antonym"}:
                    raise self._payload_error("Synonym task requires task_type 'synonym' or 'antonym'")
                options = item.get("options") or []
                if not isinstance(options, list) or len(options) < 2:
                    raise self._payload_error("Synonym task requires options array")
                item["options"] = _normalize_list(options, field="synonym options")
                if unicodedata.normalize("NFC", item["answer"]) not in item["options"]:
                    raise self._payload_error("Synonym answer must appear in options")
            elif task_type == "contextmatch":
                _normalize_item(item, "sentence")
                if not item.get("sentence"):
                    raise self._payload_error("Context match task requires sentence")
                options = item.get("options") or []
                if not isinstance(options, list) or len(options) < 2:
                    raise self._payload_error("Context match requires options array")
                item["options"] = _normalize_list(options, field="context match options")
                answer = item.get("answer")
                if not isinstance(answer, str):
                    raise self._payload_error("Context match task requires answer string")
                answer_norm = unicodedata.normalize("NFC", answer)
                if answer_norm not in item["options"]:
                    raise self._payload_error("Context match answer must appear in options")
                item["answer"] = answer_norm
                hint = item.get("context_hint")
                if hint is not None and not isinstance(hint, str):
                    raise self._payload_error("Context match hint must be string")
            elif task_type == "reorder":
                fragments = item.get("fragments") or []
                if not isinstance(fragments, list) or len(fragments) < 2:
                    raise self._payload_error("Reorder task requires fragments array")
                item["fragments"] = _normalize_list(fragments, field="reorder fragments")
                order = item.get("correct_order") or []
                if not isinstance(order, list) or len(order) != len(item["fragments"]):
                    raise self._payload_error("Reorder correct_order must match fragments length")
                if not all(isinstance(idx, int) for idx in order):
                    raise self._payload_error("Reorder correct_order must contain integers")
                if sorted(order) != list(range(len(item["fragments"]))):
                    raise self._payload_error("Reorder correct_order must be permutation of indices")
                if not isinstance(item.get("translation"), str):
                    raise self._payload_error("Reorder task requires translation string")
            elif task_type == "dictation":
                _normalize_item(item, "target_text")
                if not item.get("target_text"):
                    raise self._payload_error("Dictation task requires target_text")
                hint = item.get("hint")
                if hint is not None and not isinstance(hint, str):
                    raise self._payload_error("Dictation hint must be string")
            elif task_type == "etymology":
                for key in ("question", "word", "explanation"):
                    if not isinstance(item.get(key), str) or not item[key].strip():
                        raise self._payload_error(f"Etymology task requires '{key}' string")
                options = item.get("options") or []
                if not isinstance(options, list) or len(options) < 2:
                    raise self._payload_error("Etymology task requires options array")
                item["options"] = _normalize_list(options, field="etymology options")
                answer_index = item.get("answer_index")
                if not isinstance(answer_index, int) or not (0 <= answer_index < len(item["options"])):
                    raise self._payload_error("Etymology answer_index out of range")
            elif task_type == "comprehension":
                _normalize_item(item, "passage")
                if not item.get("passage"):
                    raise self._payload_error("Comprehension task requires passage")
                # Ensure canonical comprehension has ref
                if item.get("source_kind") == "canon" and not item.get("ref"):
                    raise self._payload_error("Canonical comprehension task requires 'ref' field")
                translation = item.get("translation")
                if translation is not None:
                    _normalize_item(item, "translation")
                questions = item.get("questions") or []
                if not isinstance(questions, list) or not questions:
                    raise self._payload_error("Comprehension task requires questions array")
                for question in questions:
                    if not isinstance(question, dict):
                        raise self._payload_error("Comprehension question must be object")
                    if not isinstance(question.get("question"), str):
                        raise self._payload_error("Comprehension question requires question string")
                    options = question.get("options") or []
                    if not isinstance(options, list) or len(options) < 2:
                        raise self._payload_error("Comprehension question requires options array")
                    question["options"] = _normalize_list(options, field="comprehension options")
                    answer_index = question.get("answer_index")
                    if not isinstance(answer_index, int) or not (
                        0 <= answer_index < len(question["options"])
                    ):
                        raise self._payload_error("Comprehension answer_index out of range")

        missing = requested - observed
        if missing:
            raise self._payload_error("OpenAI response missing task types: " + ", ".join(sorted(missing)))
