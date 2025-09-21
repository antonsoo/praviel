from __future__ import annotations

from typing import Protocol

from fastapi import HTTPException


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
    _endpoint = "https://api.openai.com/v1/chat/completions"

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

        headers = {"Authorization": f"Bearer {token}", "Content-Type": "application/json"}
        payload = {"model": model or "gpt-4o-mini", "messages": messages}
        try:
            async with httpx.AsyncClient(timeout=15.0) as client:
                response = await client.post(self._endpoint, headers=headers, json=payload)
                response.raise_for_status()
        except httpx.HTTPStatusError as exc:
            raise HTTPException(status_code=502, detail="OpenAI provider error") from exc
        except httpx.HTTPError as exc:  # pragma: no cover - network/transport issues
            raise HTTPException(status_code=502, detail="OpenAI provider unavailable") from exc

        data = response.json()
        choices = data.get("choices") or []
        answer = ""
        if choices:
            message = choices[0].get("message") or {}
            answer = message.get("content", "") or ""
        usage = data.get("usage")
        return answer, usage


PROVIDERS: dict[str, Provider] = {
    "echo": EchoProvider(),
    "openai": OpenAIProvider(),
}
