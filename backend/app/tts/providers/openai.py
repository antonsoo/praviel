from __future__ import annotations

import logging
from dataclasses import dataclass

import httpx

from app.tts.models import TTSSpeakRequest
from app.tts.providers.base import TTSAudioResult, TTSProviderError

_LOGGER = logging.getLogger("app.tts.openai")


@dataclass(slots=True)
class OpenAITTSProvider:
    name: str = "openai"
    endpoint: str = "https://api.openai.com/v1/audio/speech"
    default_model: str = "gpt-4o-mini-tts"
    default_voice: str = "alloy"
    default_sample_rate: int = 22050

    async def speak(self, *, request: TTSSpeakRequest, token: str | None) -> TTSAudioResult:
        if not token:
            raise TTSProviderError("Authorization header required for OpenAI TTS")

        payload = {
            "model": request.model or self.default_model,
            "voice": request.voice or self.default_voice,
            "input": request.text,
            "format": request.format,
        }
        headers = {
            "Authorization": token,
            "Content-Type": "application/json",
        }
        timeout = httpx.Timeout(connect=5.0, read=15.0, write=5.0, pool=5.0)

        try:
            async with httpx.AsyncClient(timeout=timeout) as client:
                response = await client.post(self.endpoint, json=payload, headers=headers)
        except httpx.HTTPError as exc:  # pragma: no cover - network failure depends on environment
            raise TTSProviderError(f"OpenAI TTS request failed: {exc}") from exc

        if response.status_code != 200:
            truncated = response.text[:200]
            _LOGGER.warning("OpenAI TTS error status=%s body=%s", response.status_code, truncated)
            raise TTSProviderError(f"OpenAI TTS returned {response.status_code}")

        mime = response.headers.get("content-type", "audio/wav").split(";")[0]
        sample_rate_header = response.headers.get("x-openai-sampling-rate")
        try:
            sample_rate = int(sample_rate_header) if sample_rate_header else self.default_sample_rate
        except ValueError:
            sample_rate = self.default_sample_rate

        return TTSAudioResult(
            audio=response.content,
            mime=mime,
            model=payload["model"],
            sample_rate=sample_rate,
        )
