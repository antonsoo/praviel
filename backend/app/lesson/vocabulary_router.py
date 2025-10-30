"""Vocabulary API routes for AI-driven vocabulary generation and tracking."""

from __future__ import annotations

from pathlib import Path
from typing import Any

import yaml
from fastapi import APIRouter, Depends, HTTPException, Query, Request
from pydantic import BaseModel, Field
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.config import Settings, get_settings
from app.db.session import get_db
from app.lesson.vocabulary_engine import (
    VocabularyEngine,
    VocabularyGenerationRequest,
    VocabularyGenerationResponse,
)
from app.lesson.vocabulary_service import (
    VocabularyInteractionRequest,
    VocabularyInteractionResponse,
    VocabularyReviewRequest,
    VocabularyReviewResponse,
    get_review_items,
    record_interaction,
)
from app.security.unified_byok import get_unified_api_key
from app.utils.client_ip import get_client_ip

router = APIRouter(prefix="/vocabulary", tags=["Vocabulary"])


# ============================================================================
# Vocabulary Search Models
# ============================================================================


class VocabularyItem(BaseModel):
    """A vocabulary item from the daily seed files."""

    text: str = Field(description="Word or phrase in target language")
    translation: str = Field(description="English translation")
    language_code: str = Field(description="Language code (e.g., 'lat', 'grc-cls')")


class VocabularySearchResponse(BaseModel):
    """Response for vocabulary search."""

    items: list[VocabularyItem] = Field(description="Matching vocabulary items")
    total: int = Field(description="Total number of results")
    query: str = Field(description="Original search query")
    language_code: str | None = Field(description="Language code filter (if applied)")


# ============================================================================
# Vocabulary Search Cache
# ============================================================================

_vocabulary_cache: dict[str, list[dict[str, Any]]] = {}


def _load_daily_vocabulary(language_code: str) -> list[dict[str, Any]]:
    """Load vocabulary from daily_{lang}.yaml file.

    Args:
        language_code: Language code (e.g., 'lat', 'grc-cls')

    Returns:
        List of vocabulary items as dictionaries

    Raises:
        FileNotFoundError: If the vocabulary file doesn't exist
    """
    if language_code in _vocabulary_cache:
        return _vocabulary_cache[language_code]

    # Find the seed directory
    seed_dir = Path(__file__).parent / "seed"
    vocab_file = seed_dir / f"daily_{language_code}.yaml"

    if not vocab_file.exists():
        raise FileNotFoundError(f"Vocabulary file not found for language: {language_code}")

    with open(vocab_file, "r", encoding="utf-8") as f:
        data = yaml.safe_load(f)

    # Extract vocabulary list (structure: {daily_XXX: [{text: ..., en: ...}, ...]})
    key = f"daily_{language_code}"
    vocab_list = data.get(key, [])

    _vocabulary_cache[language_code] = vocab_list
    return vocab_list


def _search_vocabulary(query: str, language_code: str | None = None, limit: int = 50) -> list[VocabularyItem]:
    """Search vocabulary across daily seed files.

    Args:
        query: Search query (case-insensitive, matches text or translation)
        language_code: Optional language filter
        limit: Maximum number of results

    Returns:
        List of matching vocabulary items
    """
    query_lower = query.lower()
    results: list[VocabularyItem] = []

    # Determine which languages to search
    if language_code:
        languages_to_search = [language_code]
    else:
        # Search all available languages
        seed_dir = Path(__file__).parent / "seed"
        languages_to_search = []
        for file in seed_dir.glob("daily_*.yaml"):
            lang_code = file.stem.replace("daily_", "")
            languages_to_search.append(lang_code)

    # Search each language
    for lang_code in languages_to_search:
        try:
            vocab_list = _load_daily_vocabulary(lang_code)
            for item in vocab_list:
                text = item.get("text", "").lower()
                translation = item.get("en", "").lower()

                # Match if query appears in text or translation
                if query_lower in text or query_lower in translation:
                    results.append(
                        VocabularyItem(
                            text=item.get("text", ""),
                            translation=item.get("en", ""),
                            language_code=lang_code,
                        )
                    )

                    if len(results) >= limit:
                        return results
        except FileNotFoundError:
            # Skip languages without vocabulary files
            continue

    return results


# ============================================================================
# Vocabulary Search Endpoint
# ============================================================================


@router.get("/search", response_model=VocabularySearchResponse)
async def search_vocabulary(
    q: str = Query(..., min_length=1, description="Search query"),
    language_code: str | None = Query(None, description="Language code filter (e.g., 'lat', 'grc-cls')"),
    limit: int = Query(50, ge=1, le=200, description="Maximum number of results"),
) -> VocabularySearchResponse:
    """Search vocabulary from daily seed files.

    This endpoint searches through the vocabulary in daily_{lang}.yaml files
    and returns matching items based on the query. The search is case-insensitive
    and matches both the target language text and English translations.

    Args:
        q: Search query
        language_code: Optional language filter
        limit: Maximum number of results (1-200)

    Returns:
        Matching vocabulary items

    Examples:
        - GET /vocabulary/search?q=hello
        - GET /vocabulary/search?q=salve&language_code=lat
        - GET /vocabulary/search?q=χρυσός&language_code=grc-cls&limit=10
    """
    try:
        results = _search_vocabulary(query=q, language_code=language_code, limit=limit)
        return VocabularySearchResponse(
            items=results, total=len(results), query=q, language_code=language_code
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Vocabulary search failed: {str(e)}") from e


@router.post("/generate", response_model=VocabularyGenerationResponse)
async def generate_vocabulary(
    payload: VocabularyGenerationRequest,
    request: Request,
    settings: Settings = Depends(get_settings),
    session: AsyncSession = Depends(get_db),
) -> VocabularyGenerationResponse:
    """Generate personalized vocabulary using AI.

    This endpoint uses LLM (GPT-5, Claude, or Gemini) to generate
    vocabulary items tailored to the user's proficiency level,
    excluding words they already know.

    NOTE: This endpoint accepts both authenticated and unauthenticated requests.
    - Authenticated: Uses user's ID for personalization
    - Unauthenticated: user_id must be provided in payload OR uses -1 for anonymous

    Args:
        payload: Vocabulary generation request
        request: FastAPI request for header inspection
        settings: Application settings
        session: Database session

    Returns:
        Generated vocabulary items with metadata

    Raises:
        HTTPException: If vocabulary generation is disabled or fails
    """
    if not getattr(settings, "LESSONS_ENABLED", False):
        raise HTTPException(status_code=404, detail="Vocabulary endpoint is disabled (LESSONS_ENABLED=false)")

    # Try to get authenticated user (optional)
    from app.db.user_models import User

    current_user: User | None = None
    try:
        # Try to get user from auth token
        from app.security.deps import get_token_from_request

        token = get_token_from_request(request)
        if token:
            from app.security.auth import verify_access_token

            token_data = verify_access_token(token)
            if token_data:
                from sqlalchemy import select

                result = await session.execute(select(User).where(User.id == token_data.user_id))
                current_user = result.scalar_one_or_none()
    except Exception:
        pass  # Anonymous access is allowed

    # If authenticated, use authenticated user's ID; otherwise use payload user_id or -1
    if current_user:
        payload.user_id = current_user.id

    # If no user_id provided and not authenticated, use -1 for anonymous
    if not hasattr(payload, "user_id") or payload.user_id is None:
        payload.user_id = -1

    # Get API key with unified priority: user DB > header > server default > demo key
    # Use same provider as lesson generation (openai, anthropic, google)
    provider = payload.provider or getattr(settings, "LESSONS_DEFAULT_PROVIDER", "openai")
    token, is_demo = await get_unified_api_key(provider, request=request, session=session)

    # If using demo key, check and enforce rate limits (supports both authenticated and guest users)
    if is_demo:
        # Get user_id if authenticated, otherwise use IP address
        user_id = current_user.id if current_user else None
        ip_address = None if current_user else get_client_ip(request)

        from app.services.demo_usage import DemoUsageExceeded, check_rate_limit, record_usage

        try:
            await check_rate_limit(session, provider, user_id=user_id, ip_address=ip_address)
        except DemoUsageExceeded as e:
            raise HTTPException(
                status_code=429,
                detail=str(e),
                headers={
                    "X-RateLimit-Limit-Daily": str(e.daily_limit),
                    "X-RateLimit-Limit-Weekly": str(e.weekly_limit),
                    "X-RateLimit-Reset": e.reset_at.isoformat(),
                },
            )

    # Import provider and create vocabulary engine
    from app.lesson.providers.base import get_provider

    llm_provider = get_provider(provider)

    engine = VocabularyEngine(db=session, llm_provider=llm_provider, token=token)

    try:
        response = await engine.generate_vocabulary(payload)

        # If using demo key, record the usage (supports both authenticated and guest users)
        if is_demo:
            # Get user_id if authenticated, otherwise use IP address
            user_id = current_user.id if current_user else None
            ip_address = None if current_user else get_client_ip(request)

            import logging

            from app.services.demo_usage import record_usage

            logger = logging.getLogger("app.lesson.vocabulary_router")
            try:
                await record_usage(
                    session=session,
                    provider=provider,
                    user_id=user_id,
                    ip_address=ip_address,
                    tokens_used=0,  # Token tracking not available in vocabulary response
                )

                identifier = f"user_id={user_id}" if user_id else f"ip={ip_address}"
                logger.info(
                    "Recorded demo vocabulary usage for %s provider=%s",
                    identifier,
                    provider,
                )
            except Exception as e:
                logger.error("Failed to record demo usage: %s", e, exc_info=True)

        return response
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Vocabulary generation failed: {str(e)}") from e


@router.post("/interaction", response_model=VocabularyInteractionResponse)
async def record_vocabulary_interaction(
    payload: VocabularyInteractionRequest,
    session: AsyncSession = Depends(get_db),
) -> VocabularyInteractionResponse:
    """Record a vocabulary interaction for spaced repetition tracking.

    This endpoint updates the user's vocabulary mastery based on their
    performance using the SM-2 spaced repetition algorithm.

    Args:
        payload: Vocabulary interaction data
        session: Database session

    Returns:
        Updated vocabulary item with next review date

    Raises:
        HTTPException: If interaction recording fails
    """
    try:
        return await record_interaction(payload, session)
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to record interaction: {str(e)}") from e


@router.post("/review", response_model=VocabularyReviewResponse)
async def get_review_vocabulary(
    payload: VocabularyReviewRequest,
    session: AsyncSession = Depends(get_db),
) -> VocabularyReviewResponse:
    """Get vocabulary items due for review.

    This endpoint returns vocabulary that needs to be reviewed based on
    the spaced repetition schedule.

    Args:
        payload: Review request parameters
        session: Database session

    Returns:
        Vocabulary items due for review

    Raises:
        HTTPException: If review retrieval fails
    """
    try:
        return await get_review_items(payload, session)
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to get review items: {str(e)}") from e
