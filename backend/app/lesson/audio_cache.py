"""Audio caching service for lesson audio generation.

Generates and caches TTS audio for lesson tasks. Uses deterministic hashing
to avoid re-generating the same audio content multiple times.
"""

from __future__ import annotations

import hashlib
import logging
from pathlib import Path
from typing import TYPE_CHECKING

if TYPE_CHECKING:
    pass

_LOGGER = logging.getLogger("app.lesson.audio_cache")

# Cache directory for generated audio files
_CACHE_DIR = Path(__file__).resolve().parent.parent.parent / "audio_cache"


def _ensure_cache_dir() -> Path:
    """Ensure audio cache directory exists"""
    _CACHE_DIR.mkdir(parents=True, exist_ok=True)
    return _CACHE_DIR


def _audio_cache_key(text: str, language: str, provider: str) -> str:
    """Generate deterministic cache key for audio"""
    content = f"{provider}:{language}:{text}"
    return hashlib.sha256(content.encode("utf-8")).hexdigest()[:16]


def _get_cached_audio_path(cache_key: str, mime: str) -> Path:
    """Get path for cached audio file"""
    extension = "wav" if "wav" in mime else "mp3" if "mp3" in mime else "audio"
    cache_dir = _ensure_cache_dir()
    return cache_dir / f"{cache_key}.{extension}"


async def get_or_generate_audio_url(
    *,
    text: str,
    language: str,
    provider: str = "echo",
    token: str | None = None,
) -> str | None:
    """Get audio URL for text, generating and caching if needed.

    Args:
        text: Text to synthesize
        language: Language code (e.g., "grc", "lat")
        provider: TTS provider name
        token: Optional API token for provider

    Returns:
        URL path to audio file, or None if generation fails
    """
    from app.tts.models import TTSSpeakRequest
    from app.tts.service import synthesize

    cache_key = _audio_cache_key(text, language, provider)

    # Check for cached file
    # Try multiple extensions since we don't know the mime type yet
    for ext in ["wav", "mp3", "audio"]:
        cached_path = _ensure_cache_dir() / f"{cache_key}.{ext}"
        if cached_path.exists():
            # Return relative URL path
            return f"/audio/{cache_key}.{ext}"

    # Generate new audio
    try:
        request = TTSSpeakRequest(
            text=text,
            provider=provider,
            format="wav",  # Use WAV for compatibility
        )
        result, actual_provider, note = await synthesize(request, token)

        # Save to cache
        cache_path = _get_cached_audio_path(cache_key, result.mime)
        cache_path.write_bytes(result.audio)

        _LOGGER.info(
            "Generated and cached audio: text_len=%d language=%s provider=%s cache_key=%s",
            len(text),
            language,
            actual_provider,
            cache_key,
        )

        # Return relative URL path
        return f"/audio/{cache_path.name}"

    except Exception as exc:
        _LOGGER.warning(
            "Failed to generate audio for text='%s' language=%s: %s",
            text[:50],
            language,
            exc,
        )
        return None


def clear_audio_cache() -> int:
    """Clear all cached audio files. Returns count of files deleted."""
    if not _CACHE_DIR.exists():
        return 0

    count = 0
    for audio_file in _CACHE_DIR.glob("*"):
        if audio_file.is_file():
            audio_file.unlink()
            count += 1

    _LOGGER.info("Cleared %d cached audio files", count)
    return count
