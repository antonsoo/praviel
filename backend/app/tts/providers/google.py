"""Google Gemini TTS provider for text-to-speech synthesis

Google Gemini 2.5 provides native TTS with controllable output.
Supports 24 languages with natural prosody and expressiveness.

Note: Gemini TTS API (v1beta) only outputs PCM audio format (audio/L16).
The format parameter in requests is ignored. Output is always 24kHz PCM.
"""

from __future__ import annotations

import logging
from dataclasses import dataclass

import httpx

from app.tts.models import TTSSpeakRequest
from app.tts.providers.base import TTSAudioResult, TTSProviderError

_LOGGER = logging.getLogger("app.tts.google")


@dataclass(slots=True)
class GoogleTTSProvider:
    """Google Gemini 2.5 TTS provider

    Uses Gemini 2.5 Flash TTS or Pro TTS models for high-quality speech synthesis.
    Supports 24 languages with natural prosody control.

    Available models:
    - gemini-2.5-flash-preview-tts: Fast, cost-efficient (recommended for most use cases)
    - gemini-2.5-pro-preview-tts: Highest quality, more expressive
    """

    name: str = "google"
    endpoint_base: str = "https://generativelanguage.googleapis.com/v1beta"
    default_model: str = "gemini-2.5-flash-preview-tts"
    default_language_code: str = "en-US"
    default_sample_rate: int = 24000  # Gemini TTS uses 24kHz

    async def speak(self, *, request: TTSSpeakRequest, token: str | None) -> TTSAudioResult:
        """Generate speech audio from text using Google Gemini TTS

        Args:
            request: TTS request with text, model, voice options
            token: Google API key (x-goog-api-key header)

        Returns:
            TTSAudioResult with audio bytes and metadata

        Raises:
            TTSProviderError: If request fails or API returns error
        """
        if not token:
            raise TTSProviderError("API key required for Google TTS provider")

        model = request.model or self.default_model

        # Validate model is a TTS model (must end with -preview-tts for v1beta API)
        if not model.endswith("-preview-tts"):
            raise TTSProviderError(
                f"Model {model} is not a valid TTS model. "
                "Use gemini-2.5-flash-preview-tts or gemini-2.5-pro-preview-tts"
            )

        # Build endpoint for the specific model
        endpoint = f"{self.endpoint_base}/models/{model}:generateContent"

        # Gemini TTS uses generateContent with responseModalities and speechConfig
        # Voice parameter maps to prebuilt voice name (e.g., "Kore", "Puck", etc.)
        voice_name = request.voice or "Kore"  # Default to Kore voice

        payload = {
            "contents": [{"parts": [{"text": request.text}]}],
            "generationConfig": {
                "responseModalities": ["AUDIO"],
                "speechConfig": {"voiceConfig": {"prebuiltVoiceConfig": {"voiceName": voice_name}}},
            },
        }

        headers = {
            "x-goog-api-key": token,
            "Content-Type": "application/json",
        }

        timeout = httpx.Timeout(connect=5.0, read=30.0, write=5.0, pool=5.0)

        try:
            async with httpx.AsyncClient(timeout=timeout) as client:
                response = await client.post(endpoint, json=payload, headers=headers)
        except httpx.HTTPError as exc:  # pragma: no cover
            raise TTSProviderError(f"Google TTS request failed: {exc}") from exc

        if response.status_code != 200:
            truncated = response.text[:500]
            _LOGGER.warning("Google TTS error status=%s body=%s", response.status_code, truncated)
            raise TTSProviderError(f"Google TTS returned {response.status_code}: {truncated}")

        # Parse response - Gemini returns audio in base64 within JSON response
        try:
            data = response.json()
            candidates = data.get("candidates", [])
            if not candidates:
                raise TTSProviderError("Google TTS response missing candidates")

            first_candidate = candidates[0]
            content = first_candidate.get("content", {})
            parts = content.get("parts", [])
            if not parts:
                raise TTSProviderError("Google TTS response missing parts")

            # Extract audio data (base64 encoded)
            audio_part = parts[0]
            audio_data = audio_part.get("inlineData", {})
            audio_base64 = audio_data.get("data")
            audio_mime = audio_data.get("mimeType", "audio/wav")

            if not audio_base64:
                raise TTSProviderError("Google TTS response missing audio data")

            # Decode base64 audio
            import base64

            audio_bytes = base64.b64decode(audio_base64)

        except (KeyError, IndexError, ValueError) as exc:
            _LOGGER.error("Failed to parse Google TTS response: %s", response.text[:500])
            raise TTSProviderError(f"Failed to parse Google TTS response: {exc}") from exc

        return TTSAudioResult(
            audio=audio_bytes,
            mime=audio_mime,
            model=model,
            sample_rate=self.default_sample_rate,
        )
