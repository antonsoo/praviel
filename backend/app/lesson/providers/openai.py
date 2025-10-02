from __future__ import annotations

import json
import logging
import os
from typing import Any

from sqlalchemy.ext.asyncio import AsyncSession

from app.lesson.models import LessonGenerateRequest, LessonMeta, LessonResponse
from app.lesson.providers import LessonContext, LessonProvider, LessonProviderError
from app.lesson.providers.echo import EchoLessonProvider

_LOGGER = logging.getLogger("app.lesson.providers.openai")

AVAILABLE_MODEL_PRESETS: tuple[str, ...] = (
    "gpt-4o",
    "gpt-4o-mini",
    "gpt-4.1",
    "gpt-4.1-mini",
    "gpt-4.1-nano",
)


class OpenAILessonProvider(LessonProvider):
    name = "openai"
    _default_base = "https://api.openai.com/v1"
    _default_model = "gpt-4o-mini"
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

        payload = self._build_payload(request=request, context=context, model_name=model_name)
        headers = {
            "Authorization": f"Bearer {token}",
            "Content-Type": "application/json",
        }

        base_url = self._resolve_base_url()
        endpoint = f"{base_url}/chat/completions"
        timeout = httpx.Timeout(8.0, connect=5.0, read=8.0)

        # Retry logic for rate limits (429) and transient errors (503)
        from app.core.retry import with_retry

        async def attempt_request():
            async with httpx.AsyncClient(timeout=timeout) as client:
                response = await client.post(endpoint, headers=headers, json=payload)
                # Raise for status, but allow retry logic to catch it
                if response.status_code in {429, 503}:
                    _LOGGER.warning("OpenAI rate limit/unavailable (status=%d), will retry", response.status_code)
                    raise httpx.HTTPStatusError("Rate limit or unavailable", request=response.request, response=response)
                response.raise_for_status()
                return response

        try:
            response = await with_retry(attempt_request, max_attempts=3, base_delay=0.5, max_delay=4.0)
        except httpx.HTTPStatusError as exc:
            note = self._note_for_status(exc.response.status_code)
            raise LessonProviderError("OpenAI provider error", note=note) from exc
        except httpx.TimeoutException as exc:
            raise LessonProviderError("OpenAI provider timeout", note="openai_timeout") from exc
        except httpx.HTTPError as exc:  # pragma: no cover - transport issues
            raise LessonProviderError("OpenAI provider unavailable", note="openai_network") from exc

        data = response.json()
        content = self._extract_content(data)
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

    def _build_payload(
        self,
        *,
        request: LessonGenerateRequest,
        context: LessonContext,
        model_name: str,
    ) -> dict[str, Any]:
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

        system_prompt = (
            "You are an expert pedagogue designing Classical Greek lessons. "
            "Generate exercises that match the requested types. "
            "Output ONLY valid JSON with structure: {\"tasks\": [...]}\n"
            "Each task must follow the exact JSON schema specified in the prompts. "
            "Use proper polytonic Greek (NFC normalized Unicode)."
        )

        user_message = (
            f"{combined_prompt}\n\n"
            "Return JSON with ALL requested exercises in a single 'tasks' array. "
            "Example: {\"tasks\": [{\"type\":\"match\", ...}, {\"type\":\"translate\", ...}]}"
        )

        return {
            "model": model_name,
            "response_format": {"type": "json_object"},
            "temperature": 0.8,
            "messages": [
                {"role": "system", "content": system_prompt},
                {
                    "role": "user",
                    "content": user_message,
                },
            ],
        }

    def _extract_content(self, data: dict[str, Any]) -> Any:
        choices = data.get("choices") or []
        if not choices:
            raise self._payload_error("OpenAI response missing choices")
        message = choices[0].get("message") or {}
        content = message.get("content")
        if content is None:
            raise self._payload_error("OpenAI response missing content")
        return content

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
