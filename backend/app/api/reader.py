from __future__ import annotations

import json
import unicodedata
from typing import Any, Dict, Iterable, List

from fastapi import APIRouter, HTTPException, Query
from pydantic import BaseModel, Field
from sqlalchemy import text

from app.db.session import SessionLocal
from app.ingestion.normalize import accent_fold
from app.ling.morph import analyze_tokens
from app.retrieval.hybrid import hybrid_search

router = APIRouter(prefix="/reader")


class AnalyzeRequest(BaseModel):
    q: str = Field(..., min_length=1, description="Greek text to analyze")


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
    raw = payload.q.strip()
    if not raw:
        raise HTTPException(status_code=400, detail="Query cannot be empty")

    query_nfc = unicodedata.normalize("NFC", raw)
    token_dicts = list(_tokenize(query_nfc))
    analyses = await analyze_tokens([token["text"] for token in token_dicts], language="grc")
    for token, analysis in zip(token_dicts, analyses):
        token["lemma"] = analysis.get("lemma")
        token["morph"] = analysis.get("morph")

    token_models = [TokenPayload(**token) for token in token_dicts]
    hits = await hybrid_search(query_nfc, language="grc")
    include_flags = _parse_include(include)

    lexicon_entries: List[LexiconEntry] | None = None
    grammar_entries: List[GrammarEntry] | None = None

    if include_flags.get("lsj"):
        lexicon_entries = await _lookup_lsj(analyses, language="grc")
    if include_flags.get("smyth"):
        grammar_entries = await _lookup_smyth(query_nfc, language="grc")

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
