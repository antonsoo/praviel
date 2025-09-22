from __future__ import annotations

import json
from typing import Any

from sqlalchemy.ext.asyncio import AsyncSession

from app.lesson.models import LessonGenerateRequest, LessonMeta, LessonResponse
from app.lesson.providers import LessonContext, LessonProvider, LessonProviderError


class OpenAILessonProvider(LessonProvider):
    name = "openai"
    _endpoint = "https://api.openai.com/v1/chat/completions"
    _default_model = "gpt-4o-mini"

    async def generate(
        self,
        *,
        request: LessonGenerateRequest,
        session: AsyncSession,
        token: str | None,
        context: LessonContext,
    ) -> LessonResponse:
        if not token:
            raise LessonProviderError("BYOK token required for OpenAI provider")

        try:
            import httpx
        except ImportError as exc:  # pragma: no cover - handled through dependency docs
            raise LessonProviderError("httpx is required for OpenAI provider") from exc

        payload = self._build_payload(request=request, context=context)
        headers = {"Authorization": f"Bearer {token}", "Content-Type": "application/json"}

        try:
            async with httpx.AsyncClient(timeout=20.0) as client:
                response = await client.post(self._endpoint, headers=headers, json=payload)
                response.raise_for_status()
        except httpx.HTTPStatusError as exc:
            raise LessonProviderError("OpenAI provider error") from exc
        except httpx.HTTPError as exc:  # pragma: no cover - transport issues
            raise LessonProviderError("OpenAI provider unavailable") from exc

        data = response.json()
        content = self._extract_content(data)
        parsed = self._parse_json_block(content)
        tasks_payload = parsed.get("tasks")
        if not isinstance(tasks_payload, list):
            raise LessonProviderError("OpenAI response missing tasks array")
        self._validate_payload(tasks_payload, request=request, context=context)

        meta = LessonMeta(
            language=request.language,
            profile=request.profile,
            provider=self.name,
            model=request.model or self._default_model,
        )
        response_payload = {"meta": meta.model_dump(), "tasks": tasks_payload}
        return LessonResponse.model_validate(response_payload)

    def _build_payload(self, *, request: LessonGenerateRequest, context: LessonContext) -> dict[str, Any]:
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
        request_model = request.model or self._default_model
        return {
            "model": request_model,
            "response_format": {"type": "json_object"},
            "temperature": 0.4,
            "messages": [
                {"role": "system", "content": system_prompt},
                {
                    "role": "user",
                    "content": json.dumps(user_instructions, ensure_ascii=False),
                },
            ],
        }

    def _extract_content(self, data: dict[str, Any]) -> Any:
        choices = data.get("choices") or []
        if not choices:
            raise LessonProviderError("OpenAI response missing choices")
        message = choices[0].get("message") or {}
        content = message.get("content")
        if content is None:
            raise LessonProviderError("OpenAI response missing content")
        return content

    def _parse_json_block(self, content: Any) -> dict[str, Any]:
        if isinstance(content, dict):
            return content
        if not isinstance(content, str):
            raise LessonProviderError("OpenAI response is not valid JSON string")
        snippet = content.strip()
        start = snippet.find("{")
        end = snippet.rfind("}")
        if start == -1 or end == -1 or end <= start:
            raise LessonProviderError("Unable to locate JSON object in OpenAI response")
        try:
            return json.loads(snippet[start : end + 1])
        except json.JSONDecodeError as exc:
            raise LessonProviderError("Failed to parse JSON from OpenAI response") from exc

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
                raise LessonProviderError("Task payload must be object")
            task_type = item.get("type")
            if task_type not in allowed_types:
                raise LessonProviderError(f"Unsupported task type '{task_type}' from OpenAI")
            observed.add(task_type)
            if task_type == "match":
                pairs = item.get("pairs") or []
                for pair in pairs:
                    grc = pair.get("grc") if isinstance(pair, dict) else None
                    if grc and grc not in allowed_daily:
                        raise LessonProviderError("Match task uses unauthorized text")
            elif task_type == "translate":
                text_value = item.get("text")
                if text_value and text_value not in allowed_daily and text_value not in allowed_canon:
                    raise LessonProviderError("Translate task uses unauthorized text")
            elif task_type == "cloze":
                blanks = item.get("blanks") or []
                for blank in blanks:
                    surface = blank.get("surface") if isinstance(blank, dict) else None
                    if surface and surface not in allowed_daily and surface not in allowed_canon:
                        raise LessonProviderError("Cloze task uses unauthorized text")
        missing = requested - observed
        if missing:
            raise LessonProviderError("OpenAI response missing task types: " + ", ".join(sorted(missing)))
