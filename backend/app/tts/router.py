from __future__ import annotations

import base64
import logging

from fastapi import APIRouter, Header, HTTPException, status

from app.core.config import settings
from app.tts.models import TTSAudioMeta, TTSAudioPayload, TTSSpeakRequest, TTSSpeakResponse
from app.tts.providers.base import TTSProviderError
from app.tts.service import synthesize

_LOGGER = logging.getLogger("app.tts.router")
router = APIRouter(prefix="/tts", tags=["TTS"])


@router.post("/speak", response_model=TTSSpeakResponse)
async def speak(
    request: TTSSpeakRequest,
    authorization: str | None = Header(default=None),
) -> TTSSpeakResponse:
    if not settings.TTS_ENABLED:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="TTS is disabled")

    token = authorization
    try:
        result, provider_name = await synthesize(request, token)
    except TTSProviderError as exc:
        _LOGGER.error("TTS synthesis failed: %s", exc)
        raise HTTPException(status_code=status.HTTP_502_BAD_GATEWAY, detail="TTS provider failed") from exc

    audio_b64 = base64.b64encode(result.audio).decode("ascii")
    return TTSSpeakResponse(
        audio=TTSAudioPayload(mime=result.mime, b64=audio_b64),
        meta=TTSAudioMeta(provider=provider_name, model=result.model, sample_rate=result.sample_rate),
    )
