from __future__ import annotations

import asyncio
import logging
from typing import Any, Dict, Iterable, List

from sqlalchemy import text
from sqlalchemy.ext.asyncio import AsyncSession

from app.db.session import SessionLocal
from app.ingestion.normalize import accent_fold, nfc

_LOGGER = logging.getLogger(__name__)

_PERSEUS_SQL = text(
    """
    SELECT surface_fold, lemma, lemma_fold, msd, freq, total
    FROM (
        SELECT
            tk.surface_fold AS surface_fold,
            tk.lemma AS lemma,
            tk.lemma_fold AS lemma_fold,
            tk.msd AS msd,
            COUNT(*) AS freq,
            SUM(COUNT(*)) OVER (PARTITION BY tk.surface_fold) AS total
        FROM token AS tk
        JOIN text_segment AS seg ON seg.id = tk.segment_id
        JOIN text_work AS work ON work.id = seg.work_id
        JOIN language AS lang ON lang.id = work.language_id
        WHERE lang.code = :language
          AND tk.surface_fold = ANY(:folds)
          AND tk.lemma IS NOT NULL
        GROUP BY tk.surface_fold, tk.lemma, tk.lemma_fold, tk.msd
    ) AS grouped
    ORDER BY surface_fold, freq DESC, lemma
    """
)

_CLTK_LEMMATIZERS: dict[str, Any] = {}
_CLTK_INIT_ERRORS: dict[str, Exception] = {}


def _get_cltk_lemmatizer(language: str) -> Any | None:
    lang = (language or "").lower()
    if lang in _CLTK_LEMMATIZERS or lang in _CLTK_INIT_ERRORS:
        return _CLTK_LEMMATIZERS.get(lang)
    try:
        if lang.startswith("grc"):
            from cltk.lemmatize.grc import GreekBackoffLemmatizer

            lemmatizer = GreekBackoffLemmatizer()
        elif lang.startswith("lat"):
            from cltk.lemmatize.lat import LatinBackoffLemmatizer

            lemmatizer = LatinBackoffLemmatizer()
        else:
            _CLTK_INIT_ERRORS[lang] = RuntimeError(
                f"Unsupported CLTK language: {language}",
            )
            return None
        _CLTK_LEMMATIZERS[lang] = lemmatizer
        return lemmatizer
    except Exception as exc:  # pragma: no cover - optional dependency
        _CLTK_INIT_ERRORS[lang] = exc
        _LOGGER.warning("CLTK lemmatizer unavailable for %s: %s", language, exc)
        return None


async def analyze_tokens(tokens: List[str], language: str = "grc") -> List[Dict[str, Any]]:
    """Return lemma/morph/confidence for each token. Prefer Perseus data with CLTK fallback."""

    if not tokens:
        return []

    normalized = [nfc(token or "") for token in tokens]
    folds = [accent_fold(token) if token else "" for token in normalized]
    unique_folds = sorted({fold for fold in folds if fold})

    perseus_map: Dict[str, Dict[str, Any]] = {}
    if unique_folds:
        async with SessionLocal() as session:
            perseus_map = await _perseus_lookup(session, unique_folds, language)

    missing_folds = [fold for fold in folds if fold and fold not in perseus_map]
    fallback_map: Dict[str, Dict[str, Any]] = {}
    if missing_folds:
        fallback_map = await _cltk_lookup(
            {fold: normalized[index] for index, fold in enumerate(folds) if fold in missing_folds},
            language,
        )

    analyses: List[Dict[str, Any]] = []
    for fold in folds:
        entry = perseus_map.get(fold) or fallback_map.get(fold)
        if entry is None:
            entry = {"lemma": None, "morph": None, "confidence": 0.0}
        analyses.append(entry)
    return analyses


async def _perseus_lookup(
    session: AsyncSession, folds: Iterable[str], language: str
) -> Dict[str, Dict[str, Any]]:
    folds_list = list(folds)
    if not folds_list:
        return {}

    try:
        result = await session.execute(_PERSEUS_SQL, {"folds": folds_list, "language": language})
    except Exception as exc:  # pragma: no cover - defensive
        _LOGGER.warning(
            "Perseus lookup failed for language=%s, folds_count=%d: %s",
            language,
            len(folds_list),
            exc,
            exc_info=True,
        )
        return {}

    mapping: Dict[str, Dict[str, Any]] = {}
    row_count = 0
    for row in result.mappings():
        row_count += 1
        fold = row.get("surface_fold")
        if not fold or fold in mapping:
            continue
        lemma = row.get("lemma")
        msd = row.get("msd") or {}
        morph = None
        if isinstance(msd, dict):
            morph = msd.get("perseus_tag") or msd.get("ana")
        freq = float(row.get("freq") or 0.0)
        total = float(row.get("total") or 0.0)
        confidence = freq / total if total else 0.0
        mapping[fold] = {
            "lemma": lemma,
            "morph": morph,
            "confidence": confidence,
        }

    _LOGGER.info(
        "Perseus lookup: requested=%d, rows=%d, mapped=%d (language=%s)",
        len(folds_list),
        row_count,
        len(mapping),
        language,
    )
    return mapping


async def _cltk_lookup(samples: Dict[str, str], language: str) -> Dict[str, Dict[str, Any]]:
    if not samples:
        return {}
    lemmatizer = _get_cltk_lemmatizer(language)
    if lemmatizer is None:
        return {}

    lang = (language or "").lower()

    loop = asyncio.get_running_loop()

    def _lemmatize(values: List[str]) -> List[tuple[str, str]]:
        return lemmatizer.lemmatize(values)

    folds = list(samples.keys())
    values = [samples[fold] for fold in folds]
    pairs = await loop.run_in_executor(None, _lemmatize, values)

    result: Dict[str, Dict[str, Any]] = {}
    for fold, (_, lemma) in zip(folds, pairs):
        result[fold] = {
            "lemma": lemma or None,
            "morph": None,
            "confidence": 0.2 if lang.startswith("grc") else 0.15,
        }
    return result
