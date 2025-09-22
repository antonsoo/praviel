from __future__ import annotations

import hashlib
import io
import math
import struct
import wave
from dataclasses import dataclass

from app.tts.models import TTSSpeakRequest
from app.tts.providers.base import TTSAudioResult, TTSProviderError


@dataclass(slots=True)
class EchoTTSProvider:
    name: str = "echo"
    sample_rate: int = 22050
    duration_seconds: float = 0.6

    async def speak(self, *, request: TTSSpeakRequest, token: str | None) -> TTSAudioResult:
        # Deterministic tone derived from text hash; ignores BYOK token
        digest = hashlib.sha256(request.text.encode("utf-8")).digest()
        base_freq = 220 + digest[0] % 220  # 220–439 Hz
        overtone = base_freq * 2
        amplitude = 0.35
        total_frames = max(int(self.sample_rate * self.duration_seconds), 1)

        buffer = io.BytesIO()
        try:
            with wave.open(buffer, "wb") as wav_file:
                wav_file.setnchannels(1)
                wav_file.setsampwidth(2)
                wav_file.setframerate(self.sample_rate)

                frames = bytearray()
                for idx in range(total_frames):
                    t = idx / self.sample_rate
                    envelope = min(1.0, idx / 200.0) * (1.0 - min(1.0, idx / total_frames))
                    sample = (
                        math.sin(2 * math.pi * base_freq * t)
                        + 0.5 * math.sin(2 * math.pi * overtone * t)
                    )
                    value = int(max(-1.0, min(1.0, amplitude * envelope * sample)) * 32767)
                    frames.extend(struct.pack("<h", value))
                wav_file.writeframes(frames)
        except wave.Error as exc:  # pragma: no cover - extremely unlikely
            raise TTSProviderError(f"Failed to synthesize echo audio: {exc}") from exc

        return TTSAudioResult(
            audio=buffer.getvalue(),
            mime="audio/wav",
            model="echo:v0",
            sample_rate=self.sample_rate,
        )
