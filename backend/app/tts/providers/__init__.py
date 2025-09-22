from __future__ import annotations

from app.tts.providers.base import TTSAudioResult, TTSProvider, TTSProviderError
from app.tts.providers.echo import EchoTTSProvider
from app.tts.providers.openai import OpenAITTSProvider

__all__ = [
    "TTSAudioResult",
    "TTSProvider",
    "TTSProviderError",
    "PROVIDERS",
]

PROVIDERS: dict[str, TTSProvider] = {
    "echo": EchoTTSProvider(),
    "openai": OpenAITTSProvider(),
}


def get_provider(name: str) -> TTSProvider:
    provider = PROVIDERS.get(name)
    if provider is None:
        raise TTSProviderError(f"Unknown TTS provider '{name}'")
    return provider
