from __future__ import annotations

import io
import wave

import pytest
from app.tts.models import TTSSpeakRequest
from app.tts.providers.echo import EchoTTSProvider


@pytest.mark.asyncio
async def test_echo_provider_generates_expected_wav() -> None:
    provider = EchoTTSProvider()
    request = TTSSpeakRequest(text="χαῖρε κόσμε")

    result = await provider.speak(request=request, token=None)

    assert result.mime == "audio/wav"
    assert result.sample_rate == provider.sample_rate

    buffer = io.BytesIO(result.audio)
    with wave.open(buffer) as wav_file:
        assert wav_file.getnchannels() == 1
        assert wav_file.getsampwidth() == 2
        assert wav_file.getframerate() == provider.sample_rate
        frames = wav_file.getnframes()
        duration = frames / provider.sample_rate
        assert 0.55 <= duration <= 0.65


@pytest.mark.asyncio
async def test_echo_provider_is_deterministic() -> None:
    provider = EchoTTSProvider()
    request = TTSSpeakRequest(text="salve mundi")

    first = await provider.speak(request=request, token=None)
    second = await provider.speak(request=request, token=None)

    assert first.audio == second.audio
