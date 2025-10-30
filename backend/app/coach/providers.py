from __future__ import annotations

from typing import Protocol

from fastapi import HTTPException

from app.core.config import settings


class Provider(Protocol):
    async def chat(
        self,
        *,
        messages: list[dict[str, str]],
        model: str | None,
        token: str,
    ) -> tuple[str, dict | None]: ...


class EchoProvider:
    async def chat(
        self,
        *,
        messages: list[dict[str, str]],
        model: str | None,
        token: str,
    ) -> tuple[str, dict | None]:
        last_user = next((m.get("content", "") for m in reversed(messages) if m.get("role") == "user"), "")
        cleaned = last_user.strip()
        reply = f"[echo] {cleaned}" if cleaned else "[echo]"
        return reply, None


class OpenAIProvider:
    """
    October 2025 GPT-5 Responses API provider for Coach feature.
    GPT-4 models are NOT supported - GPT-5 only.
    """

    async def chat(
        self,
        *,
        messages: list[dict[str, str]],
        model: str | None,
        token: str,
    ) -> tuple[str, dict | None]:
        try:
            import httpx
        except ImportError as exc:  # pragma: no cover - handled via dependency extras
            raise HTTPException(status_code=500, detail="httpx is required for OpenAI provider") from exc

        # Defensive: trim model and handle empty strings
        model_name = (model or "").strip() or settings.COACH_DEFAULT_MODEL

        # GPT-5 ONLY - Responses API (October 2025)
        # Convert messages to Responses API format with content arrays
        input_messages = []
        for msg in messages:
            input_messages.append(
                {"role": msg["role"], "content": [{"type": "input_text", "text": msg["content"]}]}
            )

        endpoint = "https://api.openai.com/v1/responses"
        # Minimal payload per OpenAI Cookbook
        # ⚠️ DO NOT ADD: response_format, modalities, reasoning, store
        # ⚠️ DO NOT CHANGE: endpoint to /v1/chat/completions
        # Protected by scripts/validate_api_payload_structure.py
        payload = {
            "model": model_name,
            "input": input_messages,
            "max_output_tokens": 3072,
        }

        headers = {"Authorization": f"Bearer {token}", "Content-Type": "application/json"}
        try:
            async with httpx.AsyncClient(timeout=30.0) as client:  # Longer timeout for coaching
                response = await client.post(endpoint, headers=headers, json=payload)
                response.raise_for_status()
        except httpx.HTTPStatusError as exc:
            raise HTTPException(status_code=502, detail="OpenAI provider error") from exc
        except httpx.HTTPError as exc:  # pragma: no cover - network/transport issues
            raise HTTPException(status_code=502, detail="OpenAI provider unavailable") from exc

        data = response.json()

        # Responses API format: extract from output array
        output_items = data.get("output", [])
        answer = ""
        for item in output_items:
            if item.get("type") == "message":
                content_items = item.get("content", [])
                for content in content_items:
                    if content.get("type") == "output_text":
                        answer = content.get("text", "")
                        break
                if answer:
                    break
        usage = data.get("usage")

        return answer, usage


PROVIDERS: dict[str, Provider] = {
    "echo": EchoProvider(),
    "openai": OpenAIProvider(),
}
