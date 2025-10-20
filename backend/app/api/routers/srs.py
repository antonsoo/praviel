"""SRS (Spaced Repetition System) API endpoints for flashcard management."""

from datetime import datetime, timedelta, timezone
from typing import List, Optional

from fastapi import APIRouter, Depends, HTTPException, Query
from pydantic import BaseModel, Field
from sqlalchemy import and_, case, func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.db.session import get_db
from app.db.user_models import User, UserProgress, UserSRSCard
from app.security.auth import get_current_user

router = APIRouter(prefix="/srs", tags=["SRS"])

# ---------------------------------------------------------------------
# Pydantic Models
# ---------------------------------------------------------------------


class SRSCardCreate(BaseModel):
    """Request to create a new SRS card for language learning content."""

    card_type: str = Field(..., description="Type: lemma, grammar, morph")
    content_id: str = Field(
        ...,
        min_length=1,
        max_length=200,
        description="Content identifier (lexeme.id, grammar_topic.slug, etc.)",
    )


class SRSCardResponse(BaseModel):
    """SRS card data."""

    id: int
    card_type: str
    content_id: str
    state: str  # new, learning, review, relearning
    due_at: datetime
    stability: float
    difficulty: float
    elapsed_days: int
    scheduled_days: int
    reps: int
    lapses: int
    p_recall: Optional[float]
    last_review_at: Optional[datetime]
    created_at: datetime
    updated_at: datetime


class SRSReviewRequest(BaseModel):
    """Request to review an SRS card."""

    card_id: int
    quality: int = Field(..., ge=1, le=4, description="Review quality: 1=Again, 2=Hard, 3=Good, 4=Easy")


class SRSReviewResponse(BaseModel):
    """Response after reviewing an SRS card."""

    card_id: int
    next_due_at: datetime
    new_stability: float
    new_difficulty: float
    new_state: str
    days_until_next_review: int


class SRSStats(BaseModel):
    """Overall SRS statistics."""

    total_cards: int
    new_cards: int
    learning_cards: int
    review_cards: int
    relearning_cards: int
    due_today: int


# ---------------------------------------------------------------------
# SRS Card Management
# ---------------------------------------------------------------------


@router.post("/cards", response_model=SRSCardResponse)
async def create_srs_card(
    card_data: SRSCardCreate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Create a new SRS card for language learning content.

    Uses FSRS (Free Spaced Repetition Scheduler) algorithm for optimal learning.
    Card links to language content (lemmas, grammar topics, morphology).
    """
    now = datetime.now(timezone.utc)

    # Check if card already exists for this user and content
    existing_query = select(UserSRSCard).where(
        and_(
            UserSRSCard.user_id == current_user.id,
            UserSRSCard.card_type == card_data.card_type,
            UserSRSCard.content_id == card_data.content_id,
        )
    )
    result = await db.execute(existing_query)
    existing_card = result.scalar_one_or_none()

    if existing_card:
        raise HTTPException(status_code=400, detail="SRS card already exists for this content")

    # Create new card with FSRS defaults
    card = UserSRSCard(
        user_id=current_user.id,
        card_type=card_data.card_type,
        content_id=card_data.content_id,
        state="new",
        due_at=now,  # New cards are immediately available
        stability=1.0,  # FSRS initial stability
        difficulty=5.0,  # FSRS initial difficulty (1-10 scale)
        elapsed_days=0,
        scheduled_days=0,
        reps=0,
        lapses=0,
        last_review_at=None,
        p_recall=None,
    )

    db.add(card)
    await db.commit()
    await db.refresh(card)

    return SRSCardResponse(
        id=card.id,
        card_type=card.card_type,
        content_id=card.content_id,
        state=card.state,
        due_at=card.due_at,
        stability=card.stability,
        difficulty=card.difficulty,
        elapsed_days=card.elapsed_days,
        scheduled_days=card.scheduled_days,
        reps=card.reps,
        lapses=card.lapses,
        p_recall=card.p_recall,
        last_review_at=card.last_review_at,
        created_at=card.created_at,
        updated_at=card.updated_at,
    )


@router.get("/cards/due", response_model=List[SRSCardResponse])
async def get_due_cards(
    card_type: Optional[str] = Query(default=None, description="Filter by card type: lemma, grammar, morph"),
    limit: int = Query(default=20, ge=1, le=100),
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Get SRS cards that are due for review.

    Returns cards in optimal order: new → learning → review → relearning.
    """
    now = datetime.now(timezone.utc)

    # Build query for due cards
    query = select(UserSRSCard).where(
        and_(
            UserSRSCard.user_id == current_user.id,
            UserSRSCard.due_at <= now,
        )
    )

    if card_type:
        query = query.where(UserSRSCard.card_type == card_type)

    # Order by state priority (new first, then learning, then relearning, then review)
    query = query.order_by(
        case(
            (UserSRSCard.state == "new", 1),
            (UserSRSCard.state == "learning", 2),
            (UserSRSCard.state == "relearning", 3),
            (UserSRSCard.state == "review", 4),
            else_=5,
        ),
        UserSRSCard.due_at,  # Then by due date
    ).limit(limit)

    result = await db.execute(query)
    cards = result.scalars().all()

    return [
        SRSCardResponse(
            id=c.id,
            card_type=c.card_type,
            content_id=c.content_id,
            state=c.state,
            due_at=c.due_at,
            stability=c.stability,
            difficulty=c.difficulty,
            elapsed_days=c.elapsed_days,
            scheduled_days=c.scheduled_days,
            reps=c.reps,
            lapses=c.lapses,
            p_recall=c.p_recall,
            last_review_at=c.last_review_at,
            created_at=c.created_at,
            updated_at=c.updated_at,
        )
        for c in cards
    ]


@router.post("/cards/{card_id}/review", response_model=SRSReviewResponse)
async def review_srs_card(
    card_id: int,
    review: SRSReviewRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Submit a review for an SRS card and update scheduling using FSRS algorithm.

    Quality ratings:
    - 1 (Again): Complete failure, card will reappear soon
    - 2 (Hard): Recalled with serious difficulty
    - 3 (Good): Recalled correctly with some effort
    - 4 (Easy): Perfect recall, no hesitation
    """
    # Get the card
    query = select(UserSRSCard).where(
        and_(
            UserSRSCard.id == card_id,
            UserSRSCard.user_id == current_user.id,
        )
    )

    result = await db.execute(query)
    card = result.scalar_one_or_none()

    if not card:
        raise HTTPException(status_code=404, detail="Card not found")

    now = datetime.now(timezone.utc)

    # Calculate time since last review
    if card.last_review_at:
        elapsed_days = (now - card.last_review_at).days
    else:
        elapsed_days = 0

    # Apply FSRS algorithm
    new_stability, new_difficulty, new_state, scheduled_days = _calculate_fsrs_schedule(
        quality=review.quality,
        current_stability=card.stability,
        current_difficulty=card.difficulty,
        current_state=card.state,
        elapsed_days=elapsed_days,
    )

    # Update card
    card.stability = new_stability
    card.difficulty = new_difficulty
    card.state = new_state
    card.elapsed_days = elapsed_days
    card.scheduled_days = scheduled_days
    card.reps += 1
    card.last_review_at = now
    card.due_at = now + timedelta(days=scheduled_days)

    # Track lapses (failures)
    if review.quality == 1:
        card.lapses += 1

    await db.commit()

    # Grant XP for completing review
    progress_query = select(UserProgress).where(UserProgress.user_id == current_user.id)
    progress_result = await db.execute(progress_query)
    progress = progress_result.scalar_one_or_none()

    if progress:
        # Grant 5-15 XP based on quality
        xp_rewards = {1: 5, 2: 8, 3: 12, 4: 15}
        xp_earned = xp_rewards.get(review.quality, 10)
        progress.xp_total += xp_earned
        await db.commit()

    return SRSReviewResponse(
        card_id=card.id,
        next_due_at=card.due_at,
        new_stability=new_stability,
        new_difficulty=new_difficulty,
        new_state=new_state,
        days_until_next_review=scheduled_days,
    )


@router.get("/stats", response_model=SRSStats)
async def get_srs_stats(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Get overall SRS statistics for the user."""
    now = datetime.now(timezone.utc)

    # Get all cards stats
    query = select(
        func.count(UserSRSCard.id).label("total_cards"),
        func.sum(case((UserSRSCard.state == "new", 1), else_=0)).label("new_cards"),
        func.sum(case((UserSRSCard.state == "learning", 1), else_=0)).label("learning_cards"),
        func.sum(case((UserSRSCard.state == "review", 1), else_=0)).label("review_cards"),
        func.sum(case((UserSRSCard.state == "relearning", 1), else_=0)).label("relearning_cards"),
        func.sum(case((UserSRSCard.due_at <= now, 1), else_=0)).label("due_today"),
    ).where(UserSRSCard.user_id == current_user.id)

    result = await db.execute(query)
    row = result.fetchone()

    if not row:
        return SRSStats(
            total_cards=0,
            new_cards=0,
            learning_cards=0,
            review_cards=0,
            relearning_cards=0,
            due_today=0,
        )

    total, new, learning, review, relearning, due = row

    return SRSStats(
        total_cards=total or 0,
        new_cards=new or 0,
        learning_cards=learning or 0,
        review_cards=review or 0,
        relearning_cards=relearning or 0,
        due_today=due or 0,
    )


@router.delete("/cards/{card_id}", response_model=dict)
async def delete_srs_card(
    card_id: int,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Delete an SRS card."""
    query = select(UserSRSCard).where(
        and_(
            UserSRSCard.id == card_id,
            UserSRSCard.user_id == current_user.id,
        )
    )

    result = await db.execute(query)
    card = result.scalar_one_or_none()

    if not card:
        raise HTTPException(status_code=404, detail="Card not found")

    await db.delete(card)
    await db.commit()

    return {"message": "Card deleted successfully", "card_id": card_id}


# ---------------------------------------------------------------------
# FSRS Algorithm Implementation
# ---------------------------------------------------------------------


def _calculate_fsrs_schedule(
    quality: int,
    current_stability: float,
    current_difficulty: float,
    current_state: str,
    elapsed_days: int,
) -> tuple[float, float, str, int]:
    """Calculate next review schedule using FSRS algorithm.

    FSRS (Free Spaced Repetition Scheduler) is a modern alternative to SM-2/Anki.
    Research shows it improves retention by 15-20% over traditional algorithms.

    Returns: (new_stability, new_difficulty, new_state, scheduled_days)
    """
    # FSRS parameters (optimized defaults from research)
    w = [0.4, 0.6, 2.4, 5.8, 4.93, 0.94, 0.86, 0.01, 1.49, 0.14, 0.94, 2.18, 0.05, 0.34, 1.26, 0.29, 2.61]

    # Convert quality (1-4) to FSRS rating (1-4)
    rating = quality

    # Handle new cards
    if current_state == "new":
        if rating == 1:  # Again
            new_state = "learning"
            new_stability = w[0]
            new_difficulty = w[4]
            scheduled_days = 0  # Review again in minutes/hours (backend rounds to 1 day minimum)
        elif rating == 2:  # Hard
            new_state = "learning"
            new_stability = w[1]
            new_difficulty = w[4]
            scheduled_days = 1
        elif rating == 3:  # Good
            new_state = "learning"
            new_stability = w[2]
            new_difficulty = w[4]
            scheduled_days = 1
        else:  # Easy
            new_state = "review"
            new_stability = w[3]
            new_difficulty = w[4] - 1
            scheduled_days = 4
    # Handle learning/relearning cards
    elif current_state in ["learning", "relearning"]:
        if rating == 1:  # Again
            new_state = "relearning"
            new_stability = max(1, current_stability * w[11])
            new_difficulty = min(10, current_difficulty + w[6])
            scheduled_days = 0
        elif rating == 2:  # Hard
            new_state = "learning"
            new_stability = current_stability * w[12]
            new_difficulty = current_difficulty + w[7]
            scheduled_days = max(1, int(current_stability))
        elif rating == 3:  # Good
            new_state = "review"
            new_stability = current_stability * w[13]
            new_difficulty = current_difficulty - w[8]
            scheduled_days = max(1, int(current_stability * 2))
        else:  # Easy
            new_state = "review"
            new_stability = current_stability * w[14]
            new_difficulty = max(1, current_difficulty - w[9])
            scheduled_days = max(2, int(current_stability * 3))
    # Handle review cards
    else:  # state == "review"
        if rating == 1:  # Again (lapse)
            new_state = "relearning"
            new_stability = max(1, current_stability * w[11])
            new_difficulty = min(10, current_difficulty + w[6])
            scheduled_days = 0
        elif rating == 2:  # Hard
            new_state = "review"
            new_stability = current_stability * w[15]
            new_difficulty = current_difficulty + w[7]
            scheduled_days = max(1, int(current_stability * 0.75))
        elif rating == 3:  # Good
            new_state = "review"
            # Apply forgetting curve
            retrievability = (1 + elapsed_days / (9 * current_stability)) ** -1
            new_stability = current_stability * (1 + w[10] * (rating - 3) * retrievability)
            new_difficulty = current_difficulty - w[8]
            scheduled_days = max(1, int(new_stability))
        else:  # Easy
            new_state = "review"
            retrievability = (1 + elapsed_days / (9 * current_stability)) ** -1
            new_stability = current_stability * (1 + w[10] * 1.5 * retrievability)
            new_difficulty = max(1, current_difficulty - w[9])
            scheduled_days = max(2, int(new_stability * 1.3))

    # Clamp values
    new_stability = max(0.1, min(365, new_stability))
    new_difficulty = max(1, min(10, new_difficulty))
    scheduled_days = max(1, min(365, scheduled_days))  # 1 day to 1 year

    return new_stability, new_difficulty, new_state, scheduled_days
