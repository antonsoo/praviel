from __future__ import annotations

from dataclasses import dataclass
from typing import Protocol

from app.tts.models import TTSSpeakRequest


@dataclass(slots=True)
class TTSAudioResult:
    audio: bytes
    mime: str
    model: str
    sample_rate: int


class TTSProvider(Protocol):
    name: str

    async def speak(self, *, request: TTSSpeakRequest, token: str | None) -> TTSAudioResult: ...


class TTSProviderError(RuntimeError):
    pass
