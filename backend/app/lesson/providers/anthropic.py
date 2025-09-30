from __future__ import annotations

import json
import logging
import os
from typing import Any

from sqlalchemy.ext.asyncio import AsyncSession

from app.lesson.models import LessonGenerateRequest, LessonMeta, LessonResponse
from app.lesson.providers import LessonContext, LessonProvider, LessonProviderError
from app.lesson.providers.echo import EchoLessonProvider

_LOGGER = logging.getLogger("app.lesson.providers.anthropic")

AVAILABLE_MODEL_PRESETS: tuple[str, ...] = (
    "claude-sonnet-4-5",
    "claude-opus-4-1-20250805",
    "claude-sonnet-4",
    "claude-opus-4",
)


class AnthropicLessonProvider(LessonProvider):
    name = "anthropic"
    _default_base = "https://api.anthropic.com/v1"
    _default_model = "claude-sonnet-4-5"
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
            raise LessonProviderError("httpx is required for Anthropic provider", note="anthropic_network") from exc

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
            "anthropic-version": "2023-06-01",
            "Content-Type": "application/json",
        }

        base_url = self._resolve_base_url()
        endpoint = f"{base_url}/messages"
        timeout = httpx.Timeout(8.0, connect=5.0, read=8.0)

        try:
            async with httpx.AsyncClient(timeout=timeout) as client:
                response = await client.post(endpoint, headers=headers, json=payload)
                response.raise_for_status()
        except httpx.HTTPStatusError as exc:
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
        daily_lines = [
            {"grc": line.grc, "variants": list(line.variants), "en": line.en} for line in context.daily_lines
        ]
        canonical_lines = [{"ref": line.ref, "text": line.text} for line in context.canonical_lines]
        user_instructions = {
            "exercise_types": request.exercise_types,
            "sources": request.sources,
            "daily_lines": daily_lines,
            "canonical_lines": canonical_lines,
            "constraints": {
                "language": request.language,
                "profile": request.profile,
                "include_audio": request.include_audio,
            },
        }
        system_prompt = (
            "You design compact lesson exercises for Classical Greek. "
            "Use only the provided daily lines and canonical excerpts. "
            "Produce JSON with a single key 'tasks' whose value is a list of tasks. "
            "Each task must match the requested types exactly and stay within the provided text."
        )
        return {
            "model": model_name,
            "max_tokens": 4096,
            "temperature": 0.4,
            "system": system_prompt,
            "messages": [
                {
                    "role": "user",
                    "content": json.dumps(user_instructions, ensure_ascii=False),
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
        allowed_types = {"alphabet", "match", "cloze", "translate"}
        requested = set(request.exercise_types)
        observed: set[str] = set()

        allowed_daily = {line.grc for line in context.daily_lines}
        for line in context.daily_lines:
            allowed_daily.update(line.variants or ())
        allowed_canon = {line.text for line in context.canonical_lines}

        for item in tasks:
            if not isinstance(item, dict):
                raise self._payload_error("Task payload must be object")
            task_type = item.get("type")
            if task_type not in allowed_types:
                raise self._payload_error(f"Unsupported task type '{task_type}' from Anthropic")
            observed.add(task_type)
            if task_type == "match":
                pairs = item.get("pairs") or []
                for pair in pairs:
                    grc = pair.get("grc") if isinstance(pair, dict) else None
                    if grc and grc not in allowed_daily:
                        raise self._payload_error("Match task uses unauthorized text")
            elif task_type == "translate":
                text_value = item.get("text")
                if text_value and text_value not in allowed_daily and text_value not in allowed_canon:
                    raise self._payload_error("Translate task uses unauthorized text")
            elif task_type == "cloze":
                blanks = item.get("blanks") or []
                for blank in blanks:
                    surface = blank.get("surface") if isinstance(blank, dict) else None
                    if surface and surface not in allowed_daily and surface not in allowed_canon:
                        raise self._payload_error("Cloze task uses unauthorized text")
        missing = requested - observed
        if missing:
            raise self._payload_error("Anthropic response missing task types: " + ", ".join(sorted(missing)))
