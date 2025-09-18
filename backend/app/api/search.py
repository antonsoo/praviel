from __future__ import annotations

from typing import Any, Dict, List

from fastapi import APIRouter, HTTPException, Query

try:
    from pipeline.search_trgm import search as trigram_search
except Exception:  # pragma: no cover - fallback used when pipeline not installed

    def trigram_search(  # type: ignore[misc]
        query: str,
        *,
        language: str = "grc",
        limit: int = 5,
        threshold: float = 0.1,
        database_url: str | None = None,
    ) -> List[Dict[str, Any]]:
        return []


router = APIRouter()


@router.get("/search", response_model=List[Dict[str, Any]])
async def search_endpoint(
    q: str = Query(..., min_length=1, description="Search query"),
    lang: str = Query("grc", min_length=2, max_length=8, description="Language code", alias="l"),
    k: int = Query(5, ge=1, le=50, description="Maximum results to return"),
    t: float = Query(0.1, ge=0.0, le=1.0, description="Minimum trigram similarity"),
) -> List[Dict[str, Any]]:
    if not q.strip():
        raise HTTPException(status_code=400, detail="Query parameter 'q' cannot be empty")

    results = trigram_search(q, language=lang, limit=k, threshold=t)
    return results
