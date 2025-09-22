from __future__ import annotations

import hashlib
import random
import unicodedata
from functools import lru_cache
from pathlib import Path

from fastapi import HTTPException
from sqlalchemy import text
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.config import Settings
from app.lesson.models import LessonGenerateRequest, LessonResponse
from app.lesson.providers import (
    PROVIDERS,
    CanonicalLine,
    DailyLine,
    LessonContext,
    LessonProviderError,
    get_provider,
)
from app.lesson.providers.echo import EchoLessonProvider
from app.lesson.providers.openai import OpenAILessonProvider

_SEED_PATH = Path(__file__).resolve().parent / "seed" / "daily_grc.yaml"

# Register core providers
if "echo" not in PROVIDERS:
    PROVIDERS["echo"] = EchoLessonProvider()
if "openai" not in PROVIDERS:
    PROVIDERS["openai"] = OpenAILessonProvider()


async def generate_lesson(
    *,
    request: LessonGenerateRequest,
    session: AsyncSession,
    settings: Settings,
    token: str | None,
) -> LessonResponse:
    provider = get_provider(request.provider)
    if provider.name != "echo" and not token:
        raise HTTPException(status_code=400, detail="BYOK token required for provider")

    context = await _build_context(session=session, request=request)

    try:
        return await provider.generate(
            request=request,
            session=session,
            token=token,
            context=context,
        )
    except LessonProviderError as exc:
        if provider.name != "echo":
            fallback = get_provider("echo")
            try:
                return await fallback.generate(
                    request=request,
                    session=session,
                    token=None,
                    context=context,
                )
            except LessonProviderError as fallback_exc:  # pragma: no cover - defensive
                raise HTTPException(status_code=502, detail="Lesson provider unavailable") from fallback_exc
        raise HTTPException(status_code=502, detail="Lesson provider unavailable") from exc


async def _build_context(
    *,
    session: AsyncSession,
    request: LessonGenerateRequest,
) -> LessonContext:
    seed = _seed_for_request(request)

    if "daily" in request.sources:
        try:
            daily_lines = _select_daily_lines(seed=seed, sample_size=_daily_sample_size(request))
        except RuntimeError as exc:
            raise HTTPException(status_code=500, detail=str(exc)) from exc
    else:
        daily_lines = tuple()

    if request.k_canon > 0 and "canon" in request.sources:
        try:
            canonical_lines = await _fetch_canonical_lines(
                session=session,
                language=request.language,
                limit=request.k_canon,
            )
        except Exception as exc:  # pragma: no cover - DB errors
            raise HTTPException(status_code=500, detail="Failed to fetch canonical lines") from exc
    else:
        canonical_lines = tuple()

    return LessonContext(daily_lines=daily_lines, canonical_lines=canonical_lines, seed=seed)


def _seed_for_request(request: LessonGenerateRequest) -> int:
    parts = [
        request.language,
        request.profile,
        ",".join(sorted(request.sources)),
        ",".join(sorted(request.exercise_types)),
        str(request.k_canon),
        "audio" if request.include_audio else "no-audio",
    ]
    digest = hashlib.sha256("|".join(parts).encode("utf-8")).digest()
    return int.from_bytes(digest[:8], "big", signed=False)


def _daily_sample_size(request: LessonGenerateRequest) -> int:
    universe = _load_daily_seed()
    if not universe:
        return 0
    baseline = max(4, len(request.exercise_types) + (1 if "match" in request.exercise_types else 0))
    return min(baseline, len(universe))


def _select_daily_lines(*, seed: int, sample_size: int):
    lines = list(_load_daily_seed())
    if not lines or sample_size <= 0:
        return tuple()
    if sample_size >= len(lines):
        return tuple(lines)
    rng = random.Random(seed)
    indices = rng.sample(range(len(lines)), sample_size)
    return tuple(lines[idx] for idx in indices)


@lru_cache(maxsize=1)
def _load_daily_seed():
    try:
        import yaml
    except ImportError as exc:  # pragma: no cover - installation issue
        raise RuntimeError("PyYAML is required to load lesson seed data") from exc

    if not _SEED_PATH.exists():  # pragma: no cover - misconfiguration
        raise RuntimeError(f"Lesson seed file missing at {_SEED_PATH}")

    data = yaml.safe_load(_SEED_PATH.read_text(encoding="utf-8")) or []
    lines = []
    seen: set[str] = set()
    for entry in data:
        grc = _normalize(entry.get("grc", ""))
        en = (entry.get("en") or "").strip()
        if not grc or not en or grc in seen:
            continue
        variants = entry.get("variants") or []
        normalized_variants = []
        for variant in variants:
            norm_variant = _normalize(variant)
            if norm_variant and norm_variant not in normalized_variants:
                normalized_variants.append(norm_variant)
        if not normalized_variants:
            normalized_variants.append(grc)
        lines.append(
            DailyLine(
                grc=grc,
                en=en,
                variants=tuple(normalized_variants),
            )
        )
        seen.add(grc)
    return tuple(lines)


_CANONICAL_SQL = text(
    """
    SELECT ts.ref, ts.text_nfc AS text
    FROM text_segment AS ts
    JOIN text_work AS tw ON tw.id = ts.work_id
    JOIN language AS lang ON lang.id = tw.language_id
    WHERE lang.code = :language
      AND lower(tw.title) = :title
      AND lower(tw.author) = :author
      AND ts.ref LIKE '1.%'
    ORDER BY ts.ref
    LIMIT :limit
    """
)


_CANONICAL_FALLBACK_SQL = text(
    """
    SELECT ts.ref, ts.text_nfc AS text
    FROM text_segment AS ts
    JOIN text_work AS tw ON tw.id = ts.work_id
    JOIN language AS lang ON lang.id = tw.language_id
    WHERE lang.code = :language
      AND ts.ref LIKE '1.%'
    ORDER BY ts.ref
    LIMIT :limit
    """
)


async def _fetch_canonical_lines(*, session: AsyncSession, language: str, limit: int):
    limit = max(0, min(limit, 10))
    if limit == 0:
        return tuple()

    result = await session.execute(
        _CANONICAL_SQL,
        {
            "language": language,
            "title": "iliad",
            "author": "homer",
            "limit": limit,
        },
    )
    rows = result.all()
    if not rows:
        fallback = await session.execute(
            _CANONICAL_FALLBACK_SQL,
            {"language": language, "limit": limit},
        )
        rows = fallback.all()

    lines = []
    seen_refs: set[str] = set()
    for row in rows:
        ref = (row.ref or "").strip()
        text_value = _normalize(row.text or "")
        if not ref or not text_value or ref in seen_refs:
            continue
        seen_refs.add(ref)
        lines.append(
            CanonicalLine(
                ref=f"Il.{ref}",
                text=text_value,
            )
        )
        if len(lines) >= limit:
            break
    return tuple(lines)


def _normalize(value: str) -> str:
    return unicodedata.normalize("NFC", (value or "").strip())
