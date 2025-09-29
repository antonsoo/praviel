from __future__ import annotations

from typing import Literal

from pydantic import BaseModel, Field, field_validator

TTSProviderName = Literal["echo", "openai"]
TTSFormat = Literal["wav"]


class TTSSpeakRequest(BaseModel):
    text: str = Field(min_length=1, max_length=4000)
    provider: TTSProviderName = Field(default="echo")
    model: str | None = None
    voice: str | None = None
    format: TTSFormat = Field(default="wav")

    @field_validator("text", mode="before")
    @classmethod
    def _normalize_text(cls, value: str) -> str:
        cleaned = value.strip()
        if not cleaned:
            raise ValueError("text must not be empty")
        return cleaned


class TTSAudioPayload(BaseModel):
    mime: str = "audio/wav"
    b64: str


class TTSAudioMeta(BaseModel):
    provider: str
    model: str
    sample_rate: int
    note: str | None = None


class TTSSpeakResponse(BaseModel):
    audio: TTSAudioPayload
    meta: TTSAudioMeta
