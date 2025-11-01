from __future__ import annotations

import re
from typing import Any, List, Sequence

from fastapi import APIRouter, Depends, HTTPException, Query, status
from pydantic import BaseModel, Field
from sqlalchemy import select, text
from sqlalchemy.ext.asyncio import AsyncSession

from app.db.models import Language, TextWork
from app.db.session import get_session
from app.ingestion.normalize import accent_fold

router = APIRouter()

DEFAULT_TYPES: Sequence[str] = ("lexicon", "grammar", "text")


class LexiconResult(BaseModel):
    id: int
    lemma: str
    language: str
    part_of_speech: str | None = Field(default=None)
    short_definition: str | None = Field(default=None)
    full_definition: str | None = Field(default=None)
    forms: List[str] = Field(default_factory=list)
    relevance_score: float


class GrammarResult(BaseModel):
    id: int
    title: str
    category: str
    language: str
    summary: str | None = Field(default=None)
    content: str | None = Field(default=None)
    tags: List[str] = Field(default_factory=list)
    relevance_score: float


class TextResult(BaseModel):
    id: int
    work_id: int
    work_title: str
    author: str
    passage: str
    translation: str | None = Field(default=None)
    line_number: int = Field(default=0)
    book: str | None = Field(default=None)
    chapter: str | None = Field(default=None)
    relevance_score: float


class SearchResponse(BaseModel):
    query: str
    total_results: int
    lexicon_results: List[LexiconResult] = Field(default_factory=list)
    grammar_results: List[GrammarResult] = Field(default_factory=list)
    text_results: List[TextResult] = Field(default_factory=list)


class WorkResult(BaseModel):
    id: int
    title: str
    author: str
    language: str


_LEXICON_SQL = text(
    """
    SELECT
        lex.id,
        lex.lemma,
        lang.code AS language,
        lex.pos,
        lex.data,
        similarity(lex.lemma_fold, :query_fold) AS score
    FROM lexeme AS lex
    JOIN language AS lang ON lang.id = lex.language_id
    WHERE (CAST(:language AS TEXT) IS NULL OR lang.code = CAST(:language AS TEXT))
      AND lex.lemma_fold % :query_fold
    ORDER BY score DESC, lex.lemma
    LIMIT :limit
    """
)

_GRAMMAR_SQL = text(
    """
    SELECT
        topic.id,
        topic.title,
        topic.body,
        topic.body_fold,
        source.meta AS source_meta,
        similarity(topic.body_fold, :query_fold) AS body_score,
        similarity(lower(topic.title), lower(:query_plain)) AS title_score
    FROM grammar_topic AS topic
    JOIN source_doc AS source ON source.id = topic.source_id
    WHERE (CAST(:language AS TEXT) IS NULL OR source.meta ->> 'language' = CAST(:language AS TEXT))
      AND (
          topic.body_fold % :query_fold OR similarity(lower(topic.title), lower(:query_plain)) >= :threshold
      )
    ORDER BY GREATEST(body_score, title_score) DESC, topic.title
    LIMIT :limit
    """
)

_TEXT_SQL = text(
    """
    SELECT
        seg.id,
        seg.work_id,
        seg.ref,
        seg.text_nfc,
        work.title AS work_title,
        work.author AS author,
        lang.code AS language,
        seg.meta ->> 'translation' AS translation,
        seg.meta ->> 'book' AS book_meta,
        seg.meta ->> 'chapter' AS chapter_meta,
        seg.meta ->> 'line' AS line_meta,
        similarity(seg.text_fold, :query_fold) AS score
    FROM text_segment AS seg
    JOIN text_work AS work ON work.id = seg.work_id
    JOIN language AS lang ON lang.id = work.language_id
    WHERE (CAST(:language AS TEXT) IS NULL OR lang.code = CAST(:language AS TEXT))
      AND seg.text_fold % :query_fold
      AND (CAST(:work_id AS INTEGER) IS NULL OR seg.work_id = CAST(:work_id AS INTEGER))
    ORDER BY score DESC, seg.ref
    LIMIT :limit
    """
)


@router.get("/search", response_model=SearchResponse)
async def search_endpoint(
    q: str = Query(..., min_length=1, description="Search query"),
    language: str | None = Query(None, min_length=2, max_length=8, description="Language code"),
    types: str | None = Query(None, description="Comma-separated list of result types"),
    limit: int = Query(20, ge=1, le=50, description="Maximum results to return per type"),
    threshold: float = Query(0.1, ge=0.0, le=1.0, description="Minimum trigram similarity"),
    legacy_lang: str | None = Query(None, alias="l", description="Legacy language parameter"),
    legacy_limit: int | None = Query(None, alias="k", description="Legacy limit parameter"),
    legacy_threshold: float | None = Query(None, alias="t", description="Legacy threshold parameter"),
    work_id: int | None = Query(None, ge=1, description="Filter text results to a specific work ID"),
    session: AsyncSession = Depends(get_session),
) -> SearchResponse:
    query = q.strip()
    if not query:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST, detail="Query parameter 'q' cannot be empty"
        )

    resolved_language = _resolve_language_param(language, legacy_lang)
    resolved_limit = legacy_limit or limit
    resolved_threshold = legacy_threshold if legacy_threshold is not None else threshold
    result_types = _parse_types(types)

    folded_query = accent_fold(query)
    await session.execute(
        text("SELECT set_limit(:threshold)"), {"threshold": _clamp_threshold(resolved_threshold)}
    )

    lexicon_results: list[LexiconResult] = []
    grammar_results: list[GrammarResult] = []
    text_results: list[TextResult] = []

    if "lexicon" in result_types:
        lexicon_results = await _search_lexicon(
            session,
            query_fold=folded_query,
            language=resolved_language,
            limit=resolved_limit,
        )

    if "grammar" in result_types:
        grammar_results = await _search_grammar(
            session,
            query=query,
            query_fold=folded_query,
            language=resolved_language,
            limit=resolved_limit,
            threshold=_clamp_threshold(resolved_threshold),
        )

    if "text" in result_types:
        text_results = await _search_text_segments(
            session,
            query_fold=folded_query,
            language=resolved_language,
            limit=resolved_limit,
            work_id=work_id,
        )

    total = len(lexicon_results) + len(grammar_results) + len(text_results)
    return SearchResponse(
        query=query,
        total_results=total,
        lexicon_results=lexicon_results,
        grammar_results=grammar_results,
        text_results=text_results,
    )


def _resolve_language_param(language: str | None, legacy: str | None) -> str | None:
    candidate = language or legacy
    if not candidate:
        return None
    trimmed = candidate.strip().lower()
    return trimmed or None


def _parse_types(raw: str | None) -> Sequence[str]:
    if not raw:
        return DEFAULT_TYPES
    requested = [part.strip().lower() for part in raw.split(",") if part.strip()]
    if not requested:
        return DEFAULT_TYPES
    invalid = [item for item in requested if item not in DEFAULT_TYPES]
    if invalid:
        allowed = ", ".join(DEFAULT_TYPES)
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Invalid search type(s): {', '.join(invalid)}. Allowed: {allowed}",
        )
    # Preserve requested ordering while removing duplicates
    deduped: list[str] = []
    seen: set[str] = set()
    for item in requested:
        if item not in seen:
            seen.add(item)
            deduped.append(item)
    return tuple(deduped)


def _clamp_threshold(value: float) -> float:
    return max(0.0, min(1.0, value))


async def _search_lexicon(
    session: AsyncSession,
    *,
    query_fold: str,
    language: str | None,
    limit: int,
) -> list[LexiconResult]:
    params: dict[str, Any] = {
        "query_fold": query_fold,
        "language": language,
        "limit": limit,
    }
    result = await session.execute(_LEXICON_SQL, params)
    rows = result.mappings().all()
    entries: list[LexiconResult] = []
    for row in rows:
        data = row.get("data") or {}
        entries.append(
            LexiconResult(
                id=row["id"],
                lemma=row["lemma"],
                language=row["language"],
                part_of_speech=row.get("pos"),
                short_definition=_extract_short_definition(data),
                full_definition=_extract_full_definition(data),
                forms=_coerce_str_list(data.get("forms")),
                relevance_score=float(row.get("score") or 0.0),
            )
        )
    return entries


async def _search_grammar(
    session: AsyncSession,
    *,
    query: str,
    query_fold: str,
    language: str | None,
    limit: int,
    threshold: float,
) -> list[GrammarResult]:
    params: dict[str, Any] = {
        "query_plain": query,
        "query_fold": query_fold,
        "language": language,
        "limit": limit,
        "threshold": threshold,
    }
    result = await session.execute(_GRAMMAR_SQL, params)
    rows = result.mappings().all()
    entries: list[GrammarResult] = []
    for row in rows:
        meta = row.get("source_meta") or {}
        body = row.get("body") or ""
        score_body = float(row.get("body_score") or 0.0)
        score_title = float(row.get("title_score") or 0.0)
        entries.append(
            GrammarResult(
                id=row["id"],
                title=row["title"],
                category=_resolve_grammar_category(meta),
                language=_resolve_grammar_language(meta, fallback=language),
                summary=_summarize(body),
                content=body,
                tags=_coerce_str_list(meta.get("tags")),
                relevance_score=max(score_body, score_title),
            )
        )
    return entries


async def _search_text_segments(
    session: AsyncSession,
    *,
    query_fold: str,
    language: str | None,
    limit: int,
    work_id: int | None,
) -> list[TextResult]:
    params: dict[str, Any] = {
        "query_fold": query_fold,
        "language": language,
        "limit": limit,
        "work_id": work_id,
    }
    result = await session.execute(_TEXT_SQL, params)
    rows = result.mappings().all()
    entries: list[TextResult] = []
    for row in rows:
        book, chapter, line_no = _parse_text_reference(
            row.get("ref"),
            fallback_line=row.get("line_meta"),
        )
        entries.append(
            TextResult(
                id=row["id"],
                work_id=row["work_id"],
                work_title=row["work_title"],
                author=row["author"],
                passage=row["text_nfc"],
                translation=row.get("translation"),
                line_number=line_no,
                book=book or _normalize_meta_str(row.get("book_meta")),
                chapter=chapter or _normalize_meta_str(row.get("chapter_meta")),
                relevance_score=float(row.get("score") or 0.0),
            )
        )
    return entries


@router.get("/search/works", response_model=List[WorkResult])
async def search_works(
    language: str | None = Query(None, min_length=2, max_length=8, description="Language code to filter by"),
    limit: int = Query(50, ge=1, le=500, description="Maximum works to return"),
    session: AsyncSession = Depends(get_session),
) -> List[WorkResult]:
    results = await _fetch_works(session=session, language=language, limit=limit)
    return results


async def _fetch_works(session: AsyncSession, *, language: str | None, limit: int) -> List[WorkResult]:
    stmt = (
        select(
            TextWork.id.label("id"),
            TextWork.title.label("title"),
            TextWork.author.label("author"),
            Language.code.label("language"),
        )
        .join(Language, Language.id == TextWork.language_id)
        .order_by(TextWork.author, TextWork.title)
        .limit(max(1, limit))
    )
    if language:
        stmt = stmt.where(Language.code == language.strip().lower())
    result = await session.execute(stmt)
    rows = result.mappings().all()
    return [
        WorkResult(
            id=row["id"],
            title=row["title"],
            author=row["author"],
            language=row["language"],
        )
        for row in rows
    ]


def _extract_short_definition(data: dict[str, Any]) -> str | None:
    return data.get("short_definition") or data.get("short_def") or data.get("gloss") or data.get("lsj_gloss")


def _extract_full_definition(data: dict[str, Any]) -> str | None:
    return data.get("full_definition") or data.get("definition") or data.get("detailed_gloss")


def _coerce_str_list(value: Any) -> list[str]:
    if isinstance(value, list):
        return [str(item) for item in value if isinstance(item, str) or isinstance(item, (int, float))]
    if isinstance(value, (str, int, float)):
        return [str(value)]
    return []


def _resolve_grammar_category(meta: dict[str, Any]) -> str:
    category = meta.get("category")
    if isinstance(category, str) and category.strip():
        return category.strip()
    return "general"


def _resolve_grammar_language(meta: dict[str, Any], *, fallback: str | None) -> str:
    language = meta.get("language")
    if isinstance(language, str) and language.strip():
        return language.strip()
    if fallback:
        return fallback
    return "grc-cls"


def _summarize(body: str, *, max_length: int = 200) -> str | None:
    trimmed = body.strip()
    if not trimmed:
        return None
    if len(trimmed) <= max_length:
        return trimmed
    if max_length <= 3:
        return trimmed[:max_length]
    return trimmed[: max_length - 3].rstrip() + "..."


def _parse_text_reference(ref: Any, *, fallback_line: Any = None) -> tuple[str | None, str | None, int]:
    if not isinstance(ref, str) or not ref.strip():
        line_number = _extract_int(_normalize_meta_str(fallback_line))
        return None, None, line_number
    cleaned = ref.strip()
    parts = cleaned.split(".")
    book: str | None = None
    chapter: str | None = None
    line_raw: str | None = None

    if len(parts) == 1:
        line_raw = parts[0]
    elif len(parts) == 2:
        book, line_raw = parts
    else:
        book = parts[0]
        chapter = parts[1]
        line_raw = parts[-1]

    line_number = _extract_int(line_raw)
    if line_number == 0:
        line_number = _extract_int(_normalize_meta_str(fallback_line))
    return book, chapter, line_number


def _extract_int(value: str | None) -> int:
    if not value:
        return 0
    digits = re.findall(r"\d+", value)
    if not digits:
        return 0
    try:
        return int(digits[-1])
    except ValueError:
        return 0


def _normalize_meta_str(value: Any) -> str | None:
    if isinstance(value, str):
        stripped = value.strip()
        return stripped or None
    if isinstance(value, (int, float)):
        return str(value)
    return None
