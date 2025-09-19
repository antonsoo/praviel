from __future__ import annotations

import unicodedata
from typing import Any, Iterable, List

from fastapi import APIRouter, HTTPException
from pydantic import BaseModel, Field

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


class AnalyzeResponse(BaseModel):
    tokens: List[TokenPayload]
    retrieval: List[HybridHit]


@router.post("/analyze", response_model=AnalyzeResponse)
async def analyze(payload: AnalyzeRequest) -> AnalyzeResponse:
    raw = payload.q.strip()
    if not raw:
        raise HTTPException(status_code=400, detail="Query cannot be empty")

    query_nfc = unicodedata.normalize("NFC", raw)
    tokens = [TokenPayload(**token) for token in _tokenize(query_nfc)]
    hits = await hybrid_search(query_nfc, language="grc")
    return AnalyzeResponse(tokens=tokens, retrieval=[HybridHit(**hit) for hit in hits])


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
    return ch in {"'", "’", "᾽"}
