from __future__ import annotations

import logging

from app.tts.models import TTSSpeakRequest
from app.tts.providers import TTSProviderError, get_provider
from app.tts.providers.base import TTSAudioResult

_LOGGER = logging.getLogger("app.tts.service")


async def synthesize(request: TTSSpeakRequest, token: str | None) -> tuple[TTSAudioResult, str]:
    provider = get_provider(request.provider)
    try:
        result = await provider.speak(request=request, token=token)
        return result, provider.name
    except TTSProviderError as exc:
        if provider.name != "echo":
            _LOGGER.warning("TTS provider %s failed: %s; falling back to echo", provider.name, exc)
            echo = get_provider("echo")
            fallback = await echo.speak(request=request.model_copy(update={"provider": "echo"}), token=None)
            return fallback, "echo"
        raise
