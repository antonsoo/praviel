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

_LOGGER = logging.getLogger("app.lesson.providers.anthropic")

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

AVAILABLE_MODEL_PRESETS: tuple[str, ...] = (
    # Claude 4.5 Sonnet (October 2025) - Latest, most advanced reasoning
    "claude-sonnet-4-5-20250929",  # Dated model (recommended for production)
    "claude-sonnet-4-5",  # Alias (auto-updates to latest)
    # Claude 4.1 Opus (August 2025) - Improved over Opus 4
    "claude-opus-4-1-20250805",  # Dated model (recommended for production)
    "claude-opus-4-1",  # Alias (auto-updates)
    # Older Claude 4.x models (for compatibility)
    "claude-sonnet-4-20250514",
    "claude-opus-4",
    # Claude 3.x models (legacy support only)
    "claude-3-7-sonnet-20250219",
    "claude-3-5-haiku-20241022",
)


class AnthropicLessonProvider(LessonProvider):
    name = "anthropic"
    _default_base = "https://api.anthropic.com/v1"
    _default_model = settings.LESSONS_ANTHROPIC_DEFAULT_MODEL
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
            raise LessonProviderError("BYOK token required for Anthropic provider", note="anthropic_401")

        try:
            import httpx
        except ImportError as exc:  # pragma: no cover - handled through dependency docs
            raise LessonProviderError(
                "httpx is required for Anthropic provider", note="anthropic_network"
            ) from exc

        model_name = (request.model or "").strip()
        if not model_name:
            model_name = self._default_model
            _LOGGER.info("Anthropic lesson defaulted to model %s", model_name)
        elif model_name not in self._allowed_models:
            _LOGGER.warning(
                "Anthropic lesson model %s not in preset registry; using %s",
                model_name,
                self._default_model,
            )
            model_name = self._default_model

        payload = self._build_payload(request=request, context=context, model_name=model_name)
        headers = {
            "x-api-key": token,
            "anthropic-version": "2023-06-01",  # Latest stable API version
            "anthropic-beta": "max-tokens-3-5-sonnet-2024-07-15",  # Extended context support
            "Content-Type": "application/json",
        }

        base_url = self._resolve_base_url()
        endpoint = f"{base_url}/messages"
        timeout = httpx.Timeout(60.0, connect=10.0, read=60.0)

        try:
            async with httpx.AsyncClient(timeout=timeout) as client:
                response = await client.post(endpoint, headers=headers, json=payload)
                response.raise_for_status()
        except httpx.HTTPStatusError as exc:
            _LOGGER.error("Anthropic API error response: %s", exc.response.text)
            note = self._note_for_status(exc.response.status_code)
            raise LessonProviderError("Anthropic provider error", note=note) from exc
        except httpx.TimeoutException as exc:
            raise LessonProviderError("Anthropic provider timeout", note="anthropic_timeout") from exc
        except httpx.HTTPError as exc:  # pragma: no cover - transport issues
            raise LessonProviderError("Anthropic provider unavailable", note="anthropic_network") from exc

        data = response.json()
        content = self._extract_content(data)
        parsed = self._parse_json_block(content)
        tasks_payload = parsed.get("tasks")
        if not isinstance(tasks_payload, list):
            raise self._payload_error("Anthropic response missing tasks array")
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
        _LOGGER.debug("Anthropic BYOK fake adapter engaged")
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
        override = os.getenv("ANTHROPIC_API_BASE")
        base = override.strip().rstrip("/") if override and override.strip() else self._default_base
        _LOGGER.debug("Anthropic lesson base_url=%s", base)
        return base

    def _note_for_status(self, status_code: int) -> str:
        if status_code == 401:
            return "anthropic_401"
        if status_code == 403:
            return "anthropic_403"
        if status_code == 404:
            return "anthropic_404_model"
        return f"anthropic_http_{status_code}"

    def _payload_error(self, message: str) -> LessonProviderError:
        return LessonProviderError(message, note="anthropic_bad_payload")

    def _build_payload(
        self,
        *,
        request: LessonGenerateRequest,
        context: LessonContext,
        model_name: str,
    ) -> dict[str, Any]:
        from app.lesson import prompts
        from app.lesson.lang_config import get_system_prompt

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
                        daily_lines=list(context.daily_lines, language=request.language),
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
                        daily_lines=list(context.daily_lines, language=request.language),
                    )
                )

        combined_prompt = "\n\n---\n\n".join(prompt_parts)

        system_prompt = get_system_prompt(request.language)

        user_message = (
            f"{combined_prompt}\n\n"
            "Return JSON with ALL requested exercises in a single 'tasks' array. "
            'Example: {"tasks": [{"type":"match", ...}, {"type":"translate", ...}]}'
        )

        return {
            "model": model_name,
            "max_tokens": 4096,
            "temperature": 0.7,
            "system": system_prompt,
            "messages": [
                {
                    "role": "user",
                    "content": user_message,
                }
            ],
        }

    def _extract_content(self, data: dict[str, Any]) -> Any:
        content_blocks = data.get("content") or []
        if not content_blocks:
            raise self._payload_error("Anthropic response missing content")
        for block in content_blocks:
            if isinstance(block, dict) and block.get("type") == "text":
                return block.get("text")
        raise self._payload_error("Anthropic response missing text content block")

    def _parse_json_block(self, content: Any) -> dict[str, Any]:
        if isinstance(content, dict):
            return content
        if not isinstance(content, str):
            raise self._payload_error("Anthropic response is not valid JSON string")
        snippet = content.strip()
        start = snippet.find("{")
        end = snippet.rfind("}")
        if start == -1 or end == -1 or end <= start:
            raise self._payload_error("Unable to locate JSON object in Anthropic response")
        try:
            return json.loads(snippet[start : end + 1])
        except json.JSONDecodeError as exc:
            raise self._payload_error("Failed to parse JSON from Anthropic response") from exc

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
                raise self._payload_error(f"Unsupported task type '{task_type}' from Anthropic")
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
            raise self._payload_error("Anthropic response missing task types: " + ", ".join(sorted(missing)))
