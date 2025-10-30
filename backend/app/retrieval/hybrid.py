from __future__ import annotations

import logging
import unicodedata
from typing import Any, Dict, Iterable, List

from sqlalchemy import text
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.config import settings
from app.db.session import SessionLocal

try:  # Prefer trigram helper used by the CLI for consistent folding
    from pipeline.search_trgm import accent_fold
except ImportError:  # pragma: no cover - fallback during isolated backend tests
    from app.ingestion.normalize import accent_fold  # type: ignore


_LOGGER = logging.getLogger(__name__)

_LANGUAGE_ALIASES = {
    "grc": "grc-cls",
}


def _normalize_language(code: str) -> str:
    normalized = (code or "").strip().lower()
    return _LANGUAGE_ALIASES.get(normalized, normalized)


# SQL snippets stay textual to match the raw LDS tables populated by ingestion.
_LEXICAL_SQL = text(
    """
    SELECT
        seg.id AS segment_id,
        seg.ref AS segment_ref,
        seg.text_nfc AS text_nfc,
        seg.text_raw AS text_raw,
        work.author AS work_author,
        work.title AS work_title,
        similarity(seg.text_fold, :query_fold) AS score
    FROM text_segment AS seg
    JOIN text_work AS work ON work.id = seg.work_id
    JOIN language AS lang ON lang.id = work.language_id
    WHERE lang.code = :language
      AND seg.text_fold % :query_fold
    ORDER BY similarity(seg.text_fold, :query_fold) DESC, seg.ref
    LIMIT :limit
    """
)

_VECTOR_SQL = text(
    """
    SELECT
        seg.id AS segment_id,
        seg.ref AS segment_ref,
        seg.text_nfc AS text_nfc,
        seg.text_raw AS text_raw,
        work.author AS work_author,
        work.title AS work_title,
        1 - (seg.emb <=> CAST(:query_vector AS vector)) AS score
    FROM text_segment AS seg
    JOIN text_work AS work ON work.id = seg.work_id
    JOIN language AS lang ON lang.id = work.language_id
    WHERE lang.code = :language
      AND seg.emb IS NOT NULL
    ORDER BY seg.emb <=> CAST(:query_vector AS vector) ASC
    LIMIT :limit
    """
)

_EXTENSION_CHECK_SQL = text("SELECT 1 FROM pg_extension WHERE extname = :name LIMIT 1")
_COLUMN_CHECK_SQL = text(
    """
    SELECT 1
    FROM information_schema.columns
    WHERE table_schema = 'public'
      AND table_name = 'text_segment'
      AND column_name = 'emb'
    LIMIT 1
    """
)
_ANY_EMBED_SQL = text("SELECT 1 FROM text_segment WHERE emb IS NOT NULL LIMIT 1")


async def hybrid_search(
    q: str,
    *,
    language: str = "grc-cls",
    k: int = 5,
    t: float = 0.05,
    use_vector: bool | None = None,
) -> List[Dict[str, Any]]:
    """Return lexical (always) + optional vector hits blended via mean-normalized score."""

    if not q or not q.strip():
        return []

    language = _normalize_language(language)
    limit = max(1, k)
    query_nfc = unicodedata.normalize("NFC", q)
    folded = accent_fold(query_nfc)

    async with SessionLocal() as session:
        lexical_hits = await _lexical_hits(
            session,
            folded,
            language=language,
            limit=limit,
            threshold=t,
        )

        vector_hits: List[Dict[str, Any]] = []
        if use_vector is not False:
            vector_hits = await _vector_hits(session, query_nfc, language=language, limit=limit)

    blended = _blend_hits(lexical_hits, vector_hits, limit)
    return blended


async def _lexical_hits(
    session: AsyncSession,
    folded_query: str,
    *,
    language: str,
    limit: int,
    threshold: float,
) -> List[Dict[str, Any]]:
    language = _normalize_language(language)
    clamped = min(max(threshold, 0.0), 1.0)
    await session.execute(text("SELECT set_limit(:threshold)"), {"threshold": clamped})

    result = await session.execute(
        _LEXICAL_SQL,
        {
            "query_fold": folded_query,
            "language": language,
            "limit": limit,
        },
    )
    rows = result.mappings().all()
    hits: List[Dict[str, Any]] = []
    for row in rows:
        hits.append(
            {
                "segment_id": row["segment_id"],
                "work_ref": _format_work_ref(row["work_author"], row["work_title"], row["segment_ref"]),
                "text_nfc": row["text_nfc"],
                "score": float(row["score"] or 0.0),
                "reasons": ["lexical"],
            }
        )
    return hits


async def _vector_hits(
    session: AsyncSession,
    query: str,
    *,
    language: str,
    limit: int,
) -> List[Dict[str, Any]]:
    language = _normalize_language(language)
    if not await _vector_support_ready(session):
        return []

    query_vector = await _embed_query(query)
    if query_vector is None:
        return []

    result = await session.execute(
        _VECTOR_SQL,
        {
            "query_vector": query_vector,
            "language": language,
            "limit": limit,
        },
    )
    rows = result.mappings().all()
    hits: List[Dict[str, Any]] = []
    for row in rows:
        hits.append(
            {
                "segment_id": row["segment_id"],
                "work_ref": _format_work_ref(row["work_author"], row["work_title"], row["segment_ref"]),
                "text_nfc": row["text_nfc"],
                "score": float(row["score"] or 0.0),
                "reasons": ["vector"],
            }
        )
    return hits


async def _vector_support_ready(session: AsyncSession) -> bool:
    ext = await session.execute(_EXTENSION_CHECK_SQL, {"name": "vector"})
    if not ext.first():
        return False
    column = await session.execute(_COLUMN_CHECK_SQL)
    if not column.first():
        return False
    has_rows = await session.execute(_ANY_EMBED_SQL)
    return bool(has_rows.first())


async def _embed_query(query: str) -> List[float] | None:
    """Placeholder embedding that returns a deterministic unit vector."""

    if not query.strip():
        return None

    dim = max(1, settings.EMBED_DIM)
    coords = ["1" if i == 0 else "0" for i in range(dim)]
    return "[" + ",".join(coords) + "]"


def _blend_hits(
    lexical_hits: Iterable[Dict[str, Any]],
    vector_hits: Iterable[Dict[str, Any]],
    limit: int,
) -> List[Dict[str, Any]]:
    lexical_map = {hit["segment_id"]: dict(hit) for hit in lexical_hits}
    vector_map = {hit["segment_id"]: dict(hit) for hit in vector_hits}

    lex_norm = _normalize_scores({k: v["score"] for k, v in lexical_map.items()})
    vec_norm = _normalize_scores({k: v["score"] for k, v in vector_map.items()})

    merged: List[Dict[str, Any]] = []
    for seg_id in lexical_map.keys() | vector_map.keys():
        base = lexical_map.get(seg_id) or vector_map.get(seg_id)
        if base is None:
            continue
        reasons = set(base.get("reasons", []))
        total = 0.0
        weight = 0
        if seg_id in lexical_map:
            reasons.update(lexical_map[seg_id].get("reasons", []))
            total += lex_norm.get(seg_id, 0.0)
            weight += 1
        if seg_id in vector_map:
            reasons.update(vector_map[seg_id].get("reasons", []))
            total += vec_norm.get(seg_id, 0.0)
            weight += 1
        score = total / weight if weight else 0.0
        merged.append(
            {
                "segment_id": base["segment_id"],
                "work_ref": base["work_ref"],
                "text_nfc": base["text_nfc"],
                "score": score,
                "reasons": sorted(reasons),
            }
        )

    merged.sort(key=lambda item: item["score"], reverse=True)
    return merged[:limit]


def _normalize_scores(raw: Dict[int, float]) -> Dict[int, float]:
    if not raw:
        return {}
    values = list(raw.values())
    lo = min(values)
    hi = max(values)
    if hi == lo:
        return {k: 1.0 for k in raw}
    scale = hi - lo
    return {k: (v - lo) / scale for k, v in raw.items()}


def _format_work_ref(author: str | None, title: str | None, ref: str | None) -> str:
    label = _abbreviate(title) or _abbreviate(author) or "segment"
    return f"{label}.{ref}" if ref else label


def _abbreviate(value: str | None) -> str | None:
    if not value:
        return None
    stripped = "".join(ch for ch in value.strip() if ch.isalpha())
    if not stripped:
        return None
    if len(stripped) >= 2:
        return stripped[:2].capitalize()
    return stripped.capitalize()
