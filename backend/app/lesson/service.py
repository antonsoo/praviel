from __future__ import annotations

import hashlib
import logging
import random
import unicodedata
from functools import lru_cache
from pathlib import Path

from fastapi import HTTPException
from sqlalchemy import text
from sqlalchemy.exc import SQLAlchemyError
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.config import Settings
from app.lesson.models import LessonGenerateRequest, LessonResponse
from app.lesson.providers import (
    PROVIDERS,
    CanonicalLine,
    DailyLine,
    GrammarPattern,
    LessonContext,
    LessonProvider,
    LessonProviderError,
    TextRangeData,
    VocabularyItem,
    get_provider,
)
from app.lesson.providers.anthropic import AnthropicLessonProvider
from app.lesson.providers.echo import EchoLessonProvider
from app.lesson.providers.google import GoogleLessonProvider
from app.lesson.providers.openai import OpenAILessonProvider

_SEED_DIR = Path(__file__).resolve().parent / "seed"

# Register core providers
if "echo" not in PROVIDERS:
    PROVIDERS["echo"] = EchoLessonProvider()
if "openai" not in PROVIDERS:
    PROVIDERS["openai"] = OpenAILessonProvider()
if "anthropic" not in PROVIDERS:
    PROVIDERS["anthropic"] = AnthropicLessonProvider()
if "google" not in PROVIDERS:
    PROVIDERS["google"] = GoogleLessonProvider()


_LOGGER = logging.getLogger("app.lesson.service")


def _token_fingerprint(token: str | None) -> str:
    if not token:
        return "none"
    digest = hashlib.sha256(token.encode("utf-8")).hexdigest()
    return digest[:8]


def _log_byok_event(
    *,
    reason: str,
    provider: LessonProvider,
    request: LessonGenerateRequest,
    token: str | None,
    note: str | None = None,
) -> None:
    model = request.model or getattr(provider, "_default_model", "unknown")
    extra = {
        "lesson_provider": provider.name,
        "lesson_model": model,
        "byok_token_fp": _token_fingerprint(token),
    }
    if note:
        extra["lesson_note"] = note
    log_reason = note or reason
    _LOGGER.warning("Lesson BYOK fallback triggered (%s)", log_reason, extra=extra)


def _finalize_response(response: LessonResponse) -> LessonResponse:
    payload = response.model_dump()
    meta = payload.get("meta")
    if isinstance(meta, dict) and meta.get("note") is None:
        meta.pop("note", None)
    return LessonResponse.model_validate(payload)


async def _downgrade_to_echo(
    *,
    request: LessonGenerateRequest,
    session: AsyncSession,
    context: LessonContext,
    note: str,
) -> LessonResponse:
    fallback = get_provider("echo")
    try:
        response = await fallback.generate(
            request=request,
            session=session,
            token=None,
            context=context,
        )
    except LessonProviderError as fallback_exc:  # pragma: no cover - defensive
        raise HTTPException(status_code=502, detail="Lesson provider unavailable") from fallback_exc
    response.meta.provider = fallback.name
    response.meta.note = note
    return _finalize_response(response)


async def generate_lesson(
    *,
    request: LessonGenerateRequest,
    session: AsyncSession,
    settings: Settings,
    token: str | None,
) -> LessonResponse:
    provider = get_provider(request.provider)
    context = await _build_context(session=session, request=request)

    if provider.name == "echo":
        try:
            generated = await provider.generate(
                request=request,
                session=session,
                token=None,
                context=context,
            )
            return _finalize_response(generated)
        except LessonProviderError as exc:
            raise HTTPException(status_code=502, detail="Lesson provider unavailable") from exc

    # Check if server-side API key is available
    server_api_key = None
    if provider.name == "openai":
        server_api_key = settings.OPENAI_API_KEY
    elif provider.name == "anthropic":
        server_api_key = settings.ANTHROPIC_API_KEY
    elif provider.name == "google":
        server_api_key = settings.GOOGLE_API_KEY

    # Use server-side key if available, otherwise require BYOK token
    if session is None and token is None:
        effective_token = None
    else:
        effective_token = server_api_key or token

    use_fake_adapter = False
    probe_fake = getattr(provider, "use_fake_adapter", None)
    if callable(probe_fake):
        try:
            use_fake_adapter = bool(probe_fake())
        except Exception:  # pragma: no cover - defensive
            use_fake_adapter = False

    if not effective_token and not use_fake_adapter:
        fallback_allowed = settings.ECHO_FALLBACK_ENABLED or session is None
        if not fallback_allowed:
            _LOGGER.error(
                "Provider %s requires API key (server-side or BYOK token)",
                provider.name,
                extra={"lesson_provider": provider.name},
            )
            raise HTTPException(
                status_code=503,
                detail=(
                    f"{provider.name} provider requires API key. "
                    f"Set {provider.name.upper()}_API_KEY in server "
                    "environment or provide BYOK token."
                ),
            )
        _log_byok_event(
            reason="missing_token",
            provider=provider,
            request=request,
            token=token,
            note="byok_missing_fell_back_to_echo",
        )
        return await _downgrade_to_echo(
            request=request,
            session=session,
            context=context,
            note="byok_missing_fell_back_to_echo",
        )

    try:
        generated = await provider.generate(
            request=request,
            session=session,
            token=effective_token,
            context=context,
        )
        return _finalize_response(generated)
    except LessonProviderError as exc:
        # Fallback disabled by default - raise error instead
        if not settings.ECHO_FALLBACK_ENABLED:
            _LOGGER.error(
                "Provider %s failed: %s",
                provider.name,
                exc.note or str(exc),
                extra={"lesson_provider": provider.name, "lesson_note": exc.note},
            )
            raise HTTPException(
                status_code=503,
                detail=(f"{provider.name} provider failed: {exc.note or 'unknown_error'} | {str(exc)}"),
            ) from exc
        fallback_note = exc.note or "byok_failed_fell_back_to_echo"
        _log_byok_event(
            reason="provider_error",
            provider=provider,
            request=request,
            token=effective_token,
            note=fallback_note,
        )
        return await _downgrade_to_echo(
            request=request,
            session=session,
            context=context,
            note=fallback_note,
        )


async def _build_context(
    *,
    session: AsyncSession,
    request: LessonGenerateRequest,
) -> LessonContext:
    seed = _seed_for_request(request)

    daily_lines: tuple[DailyLine, ...] = tuple()
    if "daily" in request.sources:
        try:
            daily_lines = _select_daily_lines(
                language=request.language,
                seed=seed,
                sample_size=_daily_sample_size(request),
                register=request.language_register,
            )
        except RuntimeError as exc:
            _LOGGER.warning(
                "Daily seed lookup failed; continuing without daily lines (lang=%s): %s",
                request.language,
                exc,
            )
            daily_lines = tuple()

    canonical_lines: tuple[CanonicalLine, ...] = tuple()
    if request.k_canon > 0 and "canon" in request.sources:
        try:
            canonical_lines = await _fetch_canonical_lines(
                session=session,
                language=request.language,
                limit=request.k_canon,
            )
        except SQLAlchemyError as exc:
            _LOGGER.warning(
                "Canonical line lookup failed; continuing without canon (lang=%s): %s",
                request.language,
                exc,
            )
            canonical_lines = tuple()
        except (ConnectionError, OSError) as exc:  # pragma: no cover - network/db unavailable
            _LOGGER.warning(
                "Canonical line lookup connection error; continuing without canon (lang=%s): %s",
                request.language,
                exc,
            )
            canonical_lines = tuple()
        except Exception as exc:  # pragma: no cover - unexpected errors
            _LOGGER.error(
                "Unexpected canonical line error; continuing without canon (lang=%s): %s",
                request.language,
                exc,
                exc_info=True,
            )
            canonical_lines = tuple()

    # Extract text range data if specified
    text_range_data = None
    if request.text_range:
        try:
            text_range_data = await _extract_text_range_data(
                session=session,
                language=request.language,
                ref_start=request.text_range.ref_start,
                ref_end=request.text_range.ref_end,
            )
        except SQLAlchemyError as exc:
            _LOGGER.warning(
                "Text range extraction failed; continuing without text_range (lang=%s): %s",
                request.language,
                exc,
            )
            text_range_data = None
        except Exception as exc:
            _LOGGER.warning(
                "Text range extraction failed; continuing without text_range (lang=%s): %s",
                request.language,
                exc,
            )
            text_range_data = None

    return LessonContext(
        daily_lines=daily_lines,
        canonical_lines=canonical_lines,
        seed=seed,
        text_range_data=text_range_data,
        register=request.language_register,
    )


def _seed_for_request(request: LessonGenerateRequest) -> int:
    parts = [
        request.language,
        request.profile,
        request.language_register,
        ",".join(sorted(request.sources)),
        ",".join(sorted(request.exercise_types)),
        str(request.k_canon),
        "audio" if request.include_audio else "no-audio",
    ]
    digest = hashlib.sha256("|".join(parts).encode("utf-8")).digest()
    return int.from_bytes(digest[:8], "big", signed=False)


def _daily_sample_size(request: LessonGenerateRequest) -> int:
    universe = _load_daily_seed(language=request.language, register=request.language_register)
    if not universe:
        return 0
    baseline = max(4, len(request.exercise_types) + (1 if "match" in request.exercise_types else 0))
    return min(baseline, len(universe))


def _select_daily_lines(*, language: str, seed: int, sample_size: int, register: str = "literary"):
    lines = list(_load_daily_seed(language=language, register=register))
    if not lines or sample_size <= 0:
        return tuple()
    if sample_size >= len(lines):
        return tuple(lines)
    rng = random.Random(seed)
    indices = rng.sample(range(len(lines)), sample_size)
    return tuple(lines[idx] for idx in indices)


@lru_cache(maxsize=16)
def _load_daily_seed(language: str = "grc", register: str = "literary"):
    try:
        import yaml
    except ImportError as exc:  # pragma: no cover - installation issue
        raise RuntimeError("PyYAML is required to load lesson seed data") from exc

    prefix = "colloquial" if register == "colloquial" else "daily"
    base_language = language.split("-", 1)[0]

    search_candidates: list[tuple[str, str]] = [
        (f"{prefix}_{language}.yaml", f"{prefix}_{language}"),
    ]

    if "-" in language:
        search_candidates.append((f"{prefix}_{base_language}.yaml", f"{prefix}_{base_language}"))

    if register == "colloquial":
        search_candidates.append((f"daily_{language}.yaml", f"daily_{language}"))
        if "-" in language:
            search_candidates.append((f"daily_{base_language}.yaml", f"daily_{base_language}"))

    seed_path = None
    yaml_key = None
    for filename, candidate_key in search_candidates:
        candidate_path = _SEED_DIR / filename
        if candidate_path.exists():
            seed_path = candidate_path
            yaml_key = candidate_key
            break

    if seed_path is None or yaml_key is None:  # pragma: no cover - misconfiguration
        _LOGGER.warning(
            "Lesson seed file missing at %s for language '%s' (register=%s)",
            _SEED_DIR / search_candidates[0][0],
            language,
            register,
        )
        return tuple()

    yaml_data = yaml.safe_load(seed_path.read_text(encoding="utf-8")) or {}
    data = yaml_data.get(yaml_key, [])
    if not data and "-" in yaml_key:
        fallback_key = yaml_key.split("-", 1)[0]
        data = yaml_data.get(fallback_key, [])
    lines = []
    seen: set[str] = set()
    for entry in data:
        text = _normalize(entry.get("text", ""))
        # Defensive: handle booleans that YAML parsed from "yes"→True, "no"→False
        en_raw = entry.get("en")
        if en_raw is None:
            en = ""
        elif isinstance(en_raw, bool):
            # Convert bool back to lowercase yes/no for consistency
            en = "yes" if en_raw else "no"
        else:
            en = str(en_raw).strip()
        if not text or not en or text in seen:
            continue
        variants = entry.get("variants") or []
        normalized_variants = []
        for variant in variants:
            norm_variant = _normalize(variant)
            if norm_variant and norm_variant not in normalized_variants:
                normalized_variants.append(norm_variant)
        if not normalized_variants:
            normalized_variants.append(text)
        lines.append(
            DailyLine(
                text=text,
                en=en,
                language=language,
                variants=tuple(normalized_variants),
            )
        )
        seen.add(text)
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
    import asyncio

    limit = max(0, min(limit, 10))
    if limit == 0:
        return tuple()

    try:
        # Add 5 second timeout to prevent hanging on empty database
        result = await asyncio.wait_for(
            session.execute(
                _CANONICAL_SQL,
                {
                    "language": language,
                    "title": "iliad",
                    "author": "homer",
                    "limit": limit,
                },
            ),
            timeout=5.0,
        )
        rows = result.all()
        if not rows:
            fallback = await asyncio.wait_for(
                session.execute(
                    _CANONICAL_FALLBACK_SQL,
                    {"language": language, "limit": limit},
                ),
                timeout=5.0,
            )
            rows = fallback.all()
    except asyncio.TimeoutError:
        _LOGGER.warning(
            "Database query for canonical lines timed out after 5s (database may be empty or slow)"
        )
        return tuple()

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
    # Handle booleans that YAML parsed from keywords like "on"→True, "yes"→True, "no"→False
    if isinstance(value, bool):
        # Convert bool back to the likely original keyword
        return "on" if value else "off"
    return unicodedata.normalize("NFC", (value or "").strip())


async def _extract_text_range_data(
    *,
    session: AsyncSession,
    language: str,
    ref_start: str,
    ref_end: str,
) -> TextRangeData:
    """Extract vocabulary and grammar patterns from a text range"""

    # Parse ref format (e.g., "Il.1.20" -> "1.20")
    def parse_ref(ref: str) -> str:
        parts = ref.split(".")
        if len(parts) == 3 and parts[0].lower() in ("il", "iliad"):
            return f"{parts[1]}.{parts[2]}"
        elif len(parts) == 2:
            return ref
        return ref

    start_ref = parse_ref(ref_start)
    end_ref = parse_ref(ref_end)

    # Fetch text segments in range
    query = text(
        """
        SELECT ts.ref, ts.text_nfc, ts.id
        FROM text_segment AS ts
        JOIN text_work AS tw ON tw.id = ts.work_id
        JOIN language AS lang ON lang.id = tw.language_id
        WHERE lang.code = :language
          AND ts.ref >= :start_ref
          AND ts.ref <= :end_ref
        ORDER BY ts.ref
        LIMIT 50
        """
    )
    result = await session.execute(
        query,
        {"language": language, "start_ref": start_ref, "end_ref": end_ref},
    )
    segments = result.all()

    if not segments:
        return TextRangeData(
            ref_start=ref_start,
            ref_end=ref_end,
            vocabulary=tuple(),
            grammar_patterns=tuple(),
            text_samples=tuple(),
        )

    segment_ids = [seg.id for seg in segments]
    text_samples = [_normalize(seg.text_nfc) for seg in segments if seg.text_nfc][:5]

    # Fetch tokens for these segments
    token_query = text(
        """
        SELECT t.lemma, t.surface_nfc, t.msd
        FROM token AS t
        WHERE t.segment_id = ANY(:segment_ids)
          AND t.lemma IS NOT NULL
        ORDER BY t.segment_id, t.idx
        """
    )
    token_result = await session.execute(
        token_query,
        {"segment_ids": segment_ids},
    )
    tokens = token_result.all()

    # Count lemma frequencies
    lemma_freq: dict[str, list[str]] = {}
    msd_patterns: dict[str, list[str]] = {}

    for token in tokens:
        lemma = _normalize(token.lemma or "")
        surface = _normalize(token.surface_nfc or "")
        if not lemma or not surface:
            continue

        if lemma not in lemma_freq:
            lemma_freq[lemma] = []
        if surface not in lemma_freq[lemma]:
            lemma_freq[lemma].append(surface)

        # Extract grammar patterns from msd
        if token.msd and isinstance(token.msd, dict):
            msd_dict = token.msd
            # Identify notable patterns
            if msd_dict.get("tense") == "aorist" and msd_dict.get("voice") == "passive":
                pattern_key = "aorist_passive"
                if pattern_key not in msd_patterns:
                    msd_patterns[pattern_key] = []
                if surface not in msd_patterns[pattern_key]:
                    msd_patterns[pattern_key].append(surface)
            elif msd_dict.get("case") == "genitive" and msd_dict.get("pos") == "noun":
                pattern_key = "genitive_noun"
                if pattern_key not in msd_patterns:
                    msd_patterns[pattern_key] = []
                if surface not in msd_patterns[pattern_key]:
                    msd_patterns[pattern_key].append(surface)
            elif msd_dict.get("mood") == "subjunctive":
                pattern_key = "subjunctive"
                if pattern_key not in msd_patterns:
                    msd_patterns[pattern_key] = []
                if surface not in msd_patterns[pattern_key]:
                    msd_patterns[pattern_key].append(surface)

    # Build vocabulary items (top 30 by frequency)
    vocab_items = [
        VocabularyItem(
            lemma=lemma,
            surface_forms=tuple(surfaces[:5]),  # Limit surface forms
            frequency=len(surfaces),
        )
        for lemma, surfaces in sorted(lemma_freq.items(), key=lambda x: len(x[1]), reverse=True)[:30]
    ]

    # Build grammar patterns
    grammar_patterns_list = []
    pattern_descriptions = {
        "aorist_passive": "Aorist passive (verbs expressing completed action in passive voice)",
        "genitive_noun": "Genitive case nouns (possession, origin, or partitive)",
        "subjunctive": "Subjunctive mood (expressing possibility, purpose, or condition)",
    }
    for pattern_key, examples in msd_patterns.items():
        if len(examples) >= 2:  # Only include patterns with multiple examples
            grammar_patterns_list.append(
                GrammarPattern(
                    pattern=pattern_key,
                    description=pattern_descriptions.get(pattern_key, pattern_key),
                    examples=tuple(examples[:5]),
                )
            )

    return TextRangeData(
        ref_start=ref_start,
        ref_end=ref_end,
        vocabulary=tuple(vocab_items),
        grammar_patterns=tuple(grammar_patterns_list),
        text_samples=tuple(text_samples),
    )
