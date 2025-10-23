from __future__ import annotations

import json
import unicodedata
from typing import Any, Dict, Iterable, List

from fastapi import APIRouter, Depends, HTTPException, Query
from pydantic import BaseModel, Field
from sqlalchemy import func, select, text
from sqlalchemy.ext.asyncio import AsyncSession

from app.db.models import Language, SourceDoc, TextSegment, TextWork
from app.db.session import SessionLocal, get_db
from app.ingestion.normalize import accent_fold
from app.ling.morph import analyze_tokens
from app.models.reader import (
    BookInfo,
    SegmentWithMeta,
    TextListResponse,
    TextSegmentsResponse,
    TextStructure,
    TextStructureResponse,
    TextWorkInfo,
)
from app.retrieval.hybrid import hybrid_search

router = APIRouter(prefix="/reader")


class AnalyzeRequest(BaseModel):
    text: str = Field(..., min_length=1, description="Text to analyze")
    language: str = Field(
        default="grc-cls", description="Language code (default: grc-cls for Classical Greek)"
    )


class TokenPayload(BaseModel):
    text: str
    start: int
    end: int
    lemma: str | None = None
    morph: str | None = None


class HybridHit(BaseModel):
    segment_id: int
    work_ref: str
    text_nfc: str
    score: float
    reasons: List[str]


class LexiconEntry(BaseModel):
    lemma: str
    gloss: str | None = None
    citation: str | None = None


class GrammarEntry(BaseModel):
    anchor: str
    title: str
    score: float


class AnalyzeResponse(BaseModel):
    tokens: List[TokenPayload]
    retrieval: List[HybridHit]
    lexicon: List[LexiconEntry] | None = None
    grammar: List[GrammarEntry] | None = None


@router.post("/analyze", response_model=AnalyzeResponse)
async def analyze(payload: AnalyzeRequest, include: str | None = Query(None)) -> AnalyzeResponse:
    raw = payload.text.strip()
    if not raw:
        raise HTTPException(status_code=400, detail="Text cannot be empty")

    language = payload.language
    query_nfc = unicodedata.normalize("NFC", raw)
    token_dicts = list(_tokenize(query_nfc))
    analyses = await analyze_tokens([token["text"] for token in token_dicts], language=language)
    for token, analysis in zip(token_dicts, analyses):
        token["lemma"] = analysis.get("lemma")
        token["morph"] = analysis.get("morph")

    token_models = [TokenPayload(**token) for token in token_dicts]
    hits = await hybrid_search(query_nfc, language=language)
    include_flags = _parse_include(include)

    lexicon_entries: List[LexiconEntry] | None = None
    grammar_entries: List[GrammarEntry] | None = None

    if include_flags.get("lsj"):
        lexicon_entries = await _lookup_lsj(analyses, language=language)
    if include_flags.get("smyth"):
        grammar_entries = await _lookup_smyth(query_nfc, language=language)

    return AnalyzeResponse(
        tokens=token_models,
        retrieval=[HybridHit(**hit) for hit in hits],
        lexicon=lexicon_entries,
        grammar=grammar_entries,
    )


def _tokenize(text: str) -> Iterable[dict[str, Any]]:
    tokens: list[dict[str, Any]] = []
    start: int | None = None
    for idx, ch in enumerate(text):
        if _is_token_char(ch):
            if start is None:
                start = idx
        else:
            if start is not None:
                tokens.append(
                    {
                        "text": text[start:idx],
                        "start": start,
                        "end": idx,
                        "lemma": None,
                        "morph": None,
                    }
                )
                start = None
    if start is not None:
        tokens.append(
            {
                "text": text[start:],
                "start": start,
                "end": len(text),
                "lemma": None,
                "morph": None,
            }
        )
    return tokens


def _is_token_char(ch: str) -> bool:
    if not ch:
        return False
    category = unicodedata.category(ch)
    if category.startswith("L") or category == "Mn":
        return True
    return ch in {"'", "'", "?"}


def _parse_include(value: str | None) -> Dict[str, bool]:
    if not value:
        return {}
    try:
        payload = json.loads(value)
    except json.JSONDecodeError:
        return {}
    if not isinstance(payload, dict):
        return {}
    return {str(key).lower(): bool(val) for key, val in payload.items()}


async def _lookup_lsj(analyses: Iterable[Dict[str, Any]], language: str) -> List[LexiconEntry]:
    lemma_folds = sorted(
        {accent_fold(analysis.get("lemma", "")) for analysis in analyses if analysis.get("lemma")}
    )
    if not lemma_folds:
        return []
    async with SessionLocal() as session:
        result = await session.execute(
            _LSJ_SQL,
            {"lemmas": lemma_folds, "language": language},
        )
        entries: List[LexiconEntry] = []
        for row in result.mappings():
            data = row.get("data") or {}
            entries.append(
                LexiconEntry(
                    lemma=row.get("lemma"),
                    gloss=data.get("lsj_gloss") or data.get("gloss"),
                    citation=data.get("citation"),
                )
            )
    return entries


async def _lookup_smyth(query: str, language: str, limit: int = 5) -> List[GrammarEntry]:
    query_fold = accent_fold(query)
    async with SessionLocal() as session:
        await session.execute(text("SELECT set_limit(:threshold)"), {"threshold": 0.05})
        result = await session.execute(
            _SMYTH_SQL,
            {"query_fold": query_fold, "language": language, "limit": limit},
        )
        rows = list(result.mappings())
        if not rows:
            fallback = await session.execute(
                _SMYTH_FALLBACK_SQL,
                {"language": language, "limit": limit},
            )
            rows = list(fallback.mappings())
        return [
            GrammarEntry(
                anchor=row.get("anchor"),
                title=row.get("title"),
                score=float(row.get("score") or 0.0),
            )
            for row in rows
        ]


_LSJ_SQL = text(
    """
    SELECT lex.lemma, lex.data
    FROM lexeme AS lex
    JOIN language AS lang ON lang.id = lex.language_id
    WHERE lang.code = :language
      AND lex.lemma_fold = ANY(:lemmas)
    ORDER BY lex.lemma
    """
)


_SMYTH_SQL = text(
    """
    SELECT gt.anchor, gt.title, similarity(gt.body_fold, :query_fold) AS score
    FROM grammar_topic AS gt
    JOIN source_doc AS sd ON sd.id = gt.source_id
    WHERE gt.body_fold % :query_fold
      AND COALESCE(sd.meta->>'language', 'grc') = :language
    ORDER BY score DESC, gt.anchor
    LIMIT :limit
    """
)


_SMYTH_FALLBACK_SQL = text(
    """
    SELECT gt.anchor, gt.title, 0.0 AS score
    FROM grammar_topic AS gt
    JOIN source_doc AS sd ON sd.id = gt.source_id
    WHERE COALESCE(sd.meta->>'language', 'grc') = :language
    ORDER BY gt.anchor
    LIMIT :limit
    """
)


# =============================================================================
# NEW ENDPOINTS: Text Browsing API
# =============================================================================


@router.get("/texts", response_model=TextListResponse)
async def get_texts(language: str = Query("grc-cls"), db: AsyncSession = Depends(get_db)) -> TextListResponse:
    """Get all available text works for a language.

    Args:
        language: Language code (default: "grc-cls" for Classical Greek)
        db: Database session

    Returns:
        List of text works with metadata
    """
    # Query text works with source and segment counts
    preview_subquery = (
        select(TextSegment.text_nfc)
        .where(TextSegment.work_id == TextWork.id)
        .where(func.length(func.trim(TextSegment.text_nfc)) > 0)
        .order_by(TextSegment.id)
        .limit(1)
        .scalar_subquery()
    )

    stmt = (
        select(
            TextWork.id,
            TextWork.author,
            TextWork.title,
            Language.code.label("language"),
            TextWork.ref_scheme,
            func.count(TextSegment.id).label("segment_count"),
            SourceDoc.title.label("source_title"),
            SourceDoc.license,
            preview_subquery.label("preview"),
        )
        .join(Language, Language.id == TextWork.language_id)
        .join(SourceDoc, SourceDoc.id == TextWork.source_id)
        .outerjoin(TextSegment, TextSegment.work_id == TextWork.id)
        .where(Language.code == language)
        .where(TextWork.title.notin_(["Contract Fixture Work", "Common Greek Phrases and Sentences"]))
        .group_by(TextWork.id, Language.code, SourceDoc.title, SourceDoc.license)
        .order_by(TextWork.author, TextWork.title)
    )

    result = await db.execute(stmt)
    rows = result.all()

    texts = []
    for row in rows:
        license_info = row.license or {}
        texts.append(
            TextWorkInfo(
                id=row.id,
                author=row.author,
                title=row.title,
                language=row.language,
                ref_scheme=row.ref_scheme,
                segment_count=row.segment_count,
                license_name=license_info.get("name", "Unknown"),
                license_url=license_info.get("url"),
                source_title=row.source_title,
                preview=row.preview,
            )
        )

    return TextListResponse(texts=texts)


@router.get("/texts/{text_id}/structure", response_model=TextStructureResponse)
async def get_text_structure(text_id: int, db: AsyncSession = Depends(get_db)) -> TextStructureResponse:
    """Get structural metadata for a text work (books/chapters/pages).

    Args:
        text_id: Text work ID
        db: Database session

    Returns:
        Text structure (books for Homer, pages for Plato)
    """
    # Get text work
    stmt = select(TextWork).where(TextWork.id == text_id)
    result = await db.execute(stmt)
    work = result.scalar_one_or_none()

    if not work:
        raise HTTPException(status_code=404, detail=f"Text work {text_id} not found")

    structure = TextStructure(
        text_id=work.id, title=work.title, author=work.author, ref_scheme=work.ref_scheme
    )

    if work.ref_scheme == "book.line":
        # For Homer: get book metadata
        stmt = text(
            """
            SELECT
                (meta->>'book')::int AS book,
                COUNT(*) AS line_count,
                MIN((meta->>'line')::int) AS first_line,
                MAX((meta->>'line')::int) AS last_line
            FROM text_segment
            WHERE work_id = :work_id
            GROUP BY book
            ORDER BY book
            """
        )
        result = await db.execute(stmt, {"work_id": work.id})
        rows = result.fetchall()

        structure.books = [
            BookInfo(
                book=row.book, line_count=row.line_count, first_line=row.first_line, last_line=row.last_line
            )
            for row in rows
        ]

    elif work.ref_scheme == "stephanus":
        # For Plato: get list of pages
        stmt = text(
            """
            SELECT DISTINCT meta->>'page' AS page
            FROM text_segment
            WHERE work_id = :work_id
            ORDER BY page
            """
        )
        result = await db.execute(stmt, {"work_id": work.id})
        rows = result.fetchall()

        structure.pages = [row.page for row in rows if row.page]

    return TextStructureResponse(structure=structure)


@router.get("/texts/{text_id}/segments", response_model=TextSegmentsResponse)
async def get_text_segments(
    text_id: int, ref_start: str = Query(...), ref_end: str = Query(...), db: AsyncSession = Depends(get_db)
) -> TextSegmentsResponse:
    """Get text segments within a reference range.

    Args:
        text_id: Text work ID
        ref_start: Starting reference (e.g., "Il.1.1", "Apol.17a")
        ref_end: Ending reference (e.g., "Il.1.50", "Apol.20e")
        db: Database session

    Returns:
        List of text segments with metadata
    """
    # Get text work and source info
    stmt = (
        select(TextWork, SourceDoc)
        .join(SourceDoc, SourceDoc.id == TextWork.source_id)
        .where(TextWork.id == text_id)
    )

    result = await db.execute(stmt)
    row = result.first()

    if not row:
        raise HTTPException(status_code=404, detail=f"Text work {text_id} not found")

    work, source = row

    # Query segments within range - parse refs and filter by meta fields
    if work.ref_scheme == "book.line":
        # For Homer: parse "Il.1.1" -> book=1, line=1
        # ref_start = "Il.1.1", ref_end = "Il.1.50"
        start_parts = ref_start.split(".")
        end_parts = ref_end.split(".")
        if len(start_parts) >= 3 and len(end_parts) >= 3:
            start_book = int(start_parts[1])
            start_line = int(start_parts[2])
            end_book = int(end_parts[1])
            end_line = int(end_parts[2])

            # Query with proper book/line filtering
            if start_book == end_book:
                # Same book - filter by line range
                stmt = text(
                    """
                    SELECT id, ref, text_raw, meta
                    FROM text_segment
                    WHERE work_id = :work_id
                      AND (meta->>'book')::int = :book
                      AND (meta->>'line')::int >= :start_line
                      AND (meta->>'line')::int <= :end_line
                    ORDER BY (meta->>'line')::int
                    LIMIT 1000
                    """
                )
                result = await db.execute(
                    stmt,
                    {"work_id": text_id, "book": start_book, "start_line": start_line, "end_line": end_line},
                )
            else:
                # Multiple books
                stmt = text(
                    """
                    SELECT id, ref, text_raw, meta
                    FROM text_segment
                    WHERE work_id = :work_id
                      AND (
                        ((meta->>'book')::int = :start_book AND (meta->>'line')::int >= :start_line)
                        OR ((meta->>'book')::int > :start_book AND (meta->>'book')::int < :end_book)
                        OR ((meta->>'book')::int = :end_book AND (meta->>'line')::int <= :end_line)
                      )
                    ORDER BY (meta->>'book')::int, (meta->>'line')::int
                    LIMIT 1000
                    """
                )
                result = await db.execute(
                    stmt,
                    {
                        "work_id": text_id,
                        "start_book": start_book,
                        "start_line": start_line,
                        "end_book": end_book,
                        "end_line": end_line,
                    },
                )
            rows = result.fetchall()
            segments_db = [
                type("Segment", (), {"ref": r.ref, "text_raw": r.text_raw, "meta": r.meta})() for r in rows
            ]
        else:
            # Malformed refs - return empty
            segments_db = []
    elif work.ref_scheme == "stephanus":
        # For Plato: alphabetic page ordering works
        stmt = text(
            """
            SELECT id, ref, text_raw, meta
            FROM text_segment
            WHERE work_id = :work_id
              AND ref >= :ref_start
              AND ref <= :ref_end
            ORDER BY meta->>'page'
            LIMIT 1000
            """
        )
        result = await db.execute(stmt, {"work_id": text_id, "ref_start": ref_start, "ref_end": ref_end})
        rows = result.fetchall()
        segments_db = [
            type("Segment", (), {"ref": r.ref, "text_raw": r.text_raw, "meta": r.meta})() for r in rows
        ]
    else:
        # Fallback: alphabetic ordering
        stmt = (
            select(TextSegment)
            .where(TextSegment.work_id == text_id)
            .where(TextSegment.ref >= ref_start)
            .where(TextSegment.ref <= ref_end)
            .order_by(TextSegment.ref)
            .limit(1000)
        )
        result = await db.execute(stmt)
        segments_db = result.scalars().all()

    segments = [SegmentWithMeta(ref=seg.ref, text=seg.text_raw, meta=seg.meta or {}) for seg in segments_db]

    license_info = source.license or {}
    text_info = {
        "author": work.author,
        "title": work.title,
        "source": source.title,
        "license": license_info.get("name", "Unknown"),
        "license_url": license_info.get("url"),
    }

    return TextSegmentsResponse(segments=segments, text_info=text_info)
