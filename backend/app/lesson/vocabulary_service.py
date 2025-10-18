"""Service layer for vocabulary interaction and review management."""

from __future__ import annotations

from datetime import datetime, timedelta
from typing import Optional

from pydantic import BaseModel, Field
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.db.models import UserVocabulary, VocabularyMastery
from app.lesson.vocabulary_engine import MasteryLevel


class VocabularyInteractionRequest(BaseModel):
    """Request to record a vocabulary interaction."""

    user_id: int = Field(..., description="User ID")
    language_code: str = Field(..., description="ISO 639-3 language code")
    word: str = Field(..., description="Word in target language")
    correct: bool = Field(..., description="Whether user answered correctly")
    response_time_ms: Optional[int] = Field(None, description="Response time in milliseconds")


class VocabularyInteractionResponse(BaseModel):
    """Response after recording interaction."""

    word: str
    mastery_level: str
    next_review: datetime
    total_encounters: int
    accuracy: float


class VocabularyReviewRequest(BaseModel):
    """Request for vocabulary items to review."""

    user_id: int = Field(..., description="User ID")
    language_code: str = Field(..., description="ISO 639-3 language code")
    count: int = Field(20, ge=1, le=100, description="Number of items to retrieve")


class VocabularyReviewItem(BaseModel):
    """A vocabulary item for review."""

    word: str
    word_normalized: str
    mastery_level: str
    times_seen: int
    accuracy: float
    last_seen: Optional[datetime]


class VocabularyReviewResponse(BaseModel):
    """Response containing review items."""

    items: list[VocabularyReviewItem]
    total_due: int
    user_id: int
    language_code: str


async def record_interaction(
    payload: VocabularyInteractionRequest,
    session: AsyncSession,
) -> VocabularyInteractionResponse:
    """Record a vocabulary interaction and update mastery level.

    Uses the SM-2 spaced repetition algorithm to calculate next review date.

    Args:
        payload: Interaction data
        session: Database session

    Returns:
        Updated vocabulary item information
    """
    # Find or create vocabulary entry
    stmt = select(UserVocabulary).where(
        UserVocabulary.user_id == payload.user_id,
        UserVocabulary.language_code == payload.language_code,
        UserVocabulary.word == payload.word,
    )
    result = await session.execute(stmt)
    vocab_item = result.scalar_one_or_none()

    now = datetime.utcnow()

    if vocab_item is None:
        # Create new vocabulary item
        import unicodedata

        vocab_item = UserVocabulary(
            user_id=payload.user_id,
            language_code=payload.language_code,
            word=payload.word,
            word_normalized=unicodedata.normalize("NFC", payload.word.lower()),
            times_seen=1,
            times_correct=1 if payload.correct else 0,
            last_seen=now,
            interval_days=1,
            ease_factor=2.5,
            mastery_level=MasteryLevel.NEW.value,
            avg_response_time_ms=payload.response_time_ms,
        )
        session.add(vocab_item)
    else:
        # Update existing item
        vocab_item.times_seen += 1
        if payload.correct:
            vocab_item.times_correct += 1
        vocab_item.last_seen = now

        # Update average response time
        if payload.response_time_ms is not None:
            if vocab_item.avg_response_time_ms is None:
                vocab_item.avg_response_time_ms = payload.response_time_ms
            else:
                # Exponential moving average
                vocab_item.avg_response_time_ms = int(
                    0.7 * vocab_item.avg_response_time_ms + 0.3 * payload.response_time_ms
                )

    # Calculate new interval using SM-2 algorithm
    current_interval = vocab_item.interval_days or 1
    ease_factor = vocab_item.ease_factor or 2.5

    if not payload.correct:
        # Reset interval on incorrect answer
        new_interval = 1
        new_ease_factor = max(1.3, ease_factor - 0.2)
    else:
        # Increase interval on correct answer
        if current_interval == 1:
            new_interval = 6
        else:
            new_interval = int(current_interval * ease_factor)
        new_ease_factor = min(2.5, ease_factor + 0.1)

    vocab_item.interval_days = new_interval
    vocab_item.ease_factor = new_ease_factor
    vocab_item.next_review = now + timedelta(days=new_interval)

    # Update mastery level
    accuracy = vocab_item.times_correct / vocab_item.times_seen
    vocab_item.mastery_level = _calculate_mastery_level(
        times_seen=vocab_item.times_seen,
        accuracy=accuracy,
        avg_response_time=vocab_item.avg_response_time_ms,
    )

    # Record mastery milestone if achieved
    old_mastery = vocab_item.mastery_level
    new_mastery = vocab_item.mastery_level
    if new_mastery == MasteryLevel.MASTERED.value and old_mastery != new_mastery:
        milestone = VocabularyMastery(
            user_id=payload.user_id,
            language_code=payload.language_code,
            word=payload.word,
            mastery_achieved=new_mastery,
            achieved_at=now,
            total_encounters=vocab_item.times_seen,
            final_accuracy=accuracy,
        )
        session.add(milestone)

    await session.commit()
    await session.refresh(vocab_item)

    return VocabularyInteractionResponse(
        word=vocab_item.word,
        mastery_level=vocab_item.mastery_level,
        next_review=vocab_item.next_review,
        total_encounters=vocab_item.times_seen,
        accuracy=accuracy,
    )


async def get_review_items(
    payload: VocabularyReviewRequest,
    session: AsyncSession,
) -> VocabularyReviewResponse:
    """Get vocabulary items due for review.

    Args:
        payload: Review request
        session: Database session

    Returns:
        Vocabulary items due for review
    """
    now = datetime.utcnow()

    # Query items due for review
    stmt = (
        select(UserVocabulary)
        .where(
            UserVocabulary.user_id == payload.user_id,
            UserVocabulary.language_code == payload.language_code,
            UserVocabulary.next_review <= now,
        )
        .order_by(UserVocabulary.next_review.asc())
        .limit(payload.count)
    )

    result = await session.execute(stmt)
    vocab_items = result.scalars().all()

    # Count total items due
    count_stmt = select(UserVocabulary).where(
        UserVocabulary.user_id == payload.user_id,
        UserVocabulary.language_code == payload.language_code,
        UserVocabulary.next_review <= now,
    )
    count_result = await session.execute(count_stmt)
    total_due = len(count_result.scalars().all())

    items = [
        VocabularyReviewItem(
            word=item.word,
            word_normalized=item.word_normalized,
            mastery_level=item.mastery_level,
            times_seen=item.times_seen,
            accuracy=item.times_correct / item.times_seen if item.times_seen > 0 else 0.0,
            last_seen=item.last_seen,
        )
        for item in vocab_items
    ]

    return VocabularyReviewResponse(
        items=items,
        total_due=total_due,
        user_id=payload.user_id,
        language_code=payload.language_code,
    )


def _calculate_mastery_level(
    times_seen: int,
    accuracy: float,
    avg_response_time: Optional[int],
) -> str:
    """Calculate mastery level based on performance metrics.

    Args:
        times_seen: Total number of encounters
        accuracy: Accuracy rate (0.0-1.0)
        avg_response_time: Average response time in ms

    Returns:
        Mastery level string
    """
    if times_seen == 0:
        return MasteryLevel.NEW.value

    # Determine mastery based on encounters, accuracy, and speed
    if times_seen >= 10 and accuracy >= 0.95:
        # Check response time for mastered status
        if avg_response_time is not None and avg_response_time < 2000:
            return MasteryLevel.MASTERED.value
        return MasteryLevel.KNOWN.value
    elif times_seen >= 4 and accuracy >= 0.5:
        if accuracy >= 0.8:
            return MasteryLevel.KNOWN.value
        return MasteryLevel.FAMILIAR.value
    elif times_seen >= 1:
        return MasteryLevel.LEARNING.value

    return MasteryLevel.NEW.value
