"""Vocabulary API routes for AI-driven vocabulary generation and tracking."""

from __future__ import annotations

from fastapi import APIRouter, Depends, HTTPException, Request
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

router = APIRouter(prefix="/vocabulary", tags=["Vocabulary"])


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

    # Get API key with unified priority: user DB > header > server default
    # Use same provider as lesson generation (openai, anthropic, google)
    provider = payload.provider or getattr(settings, "LESSONS_DEFAULT_PROVIDER", "openai")
    token = await get_unified_api_key(provider, request=request, session=session)

    # Import provider and create vocabulary engine
    from app.lesson.providers.base import get_provider

    llm_provider = get_provider(provider)

    engine = VocabularyEngine(db=session, llm_provider=llm_provider, token=token)

    try:
        return await engine.generate_vocabulary(payload)
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
