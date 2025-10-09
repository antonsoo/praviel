"""Quests API endpoints for long-term progression goals."""

from datetime import datetime, timedelta, timezone
from typing import List, Optional

from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel, Field
from sqlalchemy import and_, desc, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.db.session import get_db
from app.db.user_models import User, UserProgress, UserQuest
from app.security.auth import get_current_user

router = APIRouter(prefix="/quests", tags=["Quests"])

# ---------------------------------------------------------------------
# Pydantic Models
# ---------------------------------------------------------------------


class QuestCreate(BaseModel):
    """Request to create a new quest."""

    quest_type: str = Field(..., description="Type: mastery, reading, streak")
    quest_id: str = Field(..., description="Quest slug or identifier")
    title: str = Field(..., min_length=1, max_length=255)
    description: Optional[str] = None
    progress_target: int = Field(default=1, gt=0, description="Target to reach")
    duration_days: int = Field(default=30, ge=1, le=365, description="Quest duration in days")
    xp_reward: int = Field(default=0, ge=0)
    achievement_reward: Optional[str] = None


class QuestResponse(BaseModel):
    """Quest information."""

    id: int
    quest_type: str
    quest_id: str
    title: str
    description: Optional[str]
    progress_current: int
    progress_target: int
    status: str  # active, completed, failed, expired
    started_at: datetime
    expires_at: Optional[datetime]
    completed_at: Optional[datetime]
    xp_reward: int
    achievement_reward: Optional[str]
    progress_percentage: float


class QuestUpdateRequest(BaseModel):
    """Request to update quest progress."""

    increment: int = Field(default=1, ge=0, description="Amount to increment progress")


# ---------------------------------------------------------------------
# Quest Management
# ---------------------------------------------------------------------


@router.post("/", response_model=QuestResponse)
async def create_quest(
    quest_data: QuestCreate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Create a new quest for the user.

    Quest types:
    - mastery: Master a specific grammar concept or skill
    - reading: Complete a reading challenge
    - streak: Maintain a learning streak
    """
    now = datetime.now(timezone.utc)
    expires_at = now + timedelta(days=quest_data.duration_days) if quest_data.duration_days > 0 else None

    # Create quest
    quest = UserQuest(
        user_id=current_user.id,
        quest_type=quest_data.quest_type,
        quest_id=quest_data.quest_id,
        title=quest_data.title,
        description=quest_data.description,
        progress_current=0,
        progress_target=quest_data.progress_target,
        status="active",
        started_at=now,
        expires_at=expires_at,
        xp_reward=quest_data.xp_reward,
        achievement_reward=quest_data.achievement_reward,
    )

    db.add(quest)
    await db.commit()
    await db.refresh(quest)

    return QuestResponse(
        id=quest.id,
        quest_type=quest.quest_type,
        quest_id=quest.quest_id,
        title=quest.title,
        description=quest.description,
        progress_current=quest.progress_current,
        progress_target=quest.progress_target,
        status=quest.status,
        started_at=quest.started_at,
        expires_at=quest.expires_at,
        completed_at=quest.completed_at,
        xp_reward=quest.xp_reward,
        achievement_reward=quest.achievement_reward,
        progress_percentage=0.0,
    )


@router.get("/", response_model=List[QuestResponse])
async def list_quests(
    include_completed: bool = False,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Get user's quests.

    By default returns only active quests.
    """
    now = datetime.now(timezone.utc)

    # Build query
    query = select(UserQuest).where(UserQuest.user_id == current_user.id)

    if not include_completed:
        query = query.where(UserQuest.status == "active")

    query = query.order_by(desc(UserQuest.started_at))

    result = await db.execute(query)
    quests = result.scalars().all()

    # Mark expired quests as expired
    for quest in quests:
        if quest.status == "active" and quest.expires_at and quest.expires_at < now:
            quest.status = "expired"
            await db.commit()

    return [
        QuestResponse(
            id=q.id,
            quest_type=q.quest_type,
            quest_id=q.quest_id,
            title=q.title,
            description=q.description,
            progress_current=q.progress_current,
            progress_target=q.progress_target,
            status=q.status,
            started_at=q.started_at,
            expires_at=q.expires_at,
            completed_at=q.completed_at,
            xp_reward=q.xp_reward,
            achievement_reward=q.achievement_reward,
            progress_percentage=min(100.0, (q.progress_current / q.progress_target) * 100)
            if q.progress_target > 0
            else 0.0,
        )
        for q in quests
    ]


# ---------------------------------------------------------------------
# Convenience Endpoints (must be before /{quest_id} to avoid path conflicts)
# ---------------------------------------------------------------------


@router.get("/active", response_model=List[QuestResponse])
async def get_active_quests(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Get active quests (convenience endpoint, same as /?include_completed=false)."""
    return await list_quests(include_completed=False, current_user=current_user, db=db)


@router.get("/completed", response_model=List[QuestResponse])
async def get_completed_quests(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Get completed quests (convenience endpoint, same as /?include_completed=true filtering completed)."""
    quests = await list_quests(include_completed=True, current_user=current_user, db=db)
    return [q for q in quests if q.status == "completed"]


@router.get("/available", response_model=List[dict])
async def get_available_quest_types(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Get available quest types that can be started."""
    # Return list of quest types with metadata
    return [
        {
            "quest_type": "beginner_journey",
            "title": "Beginner's Journey",
            "description": "Complete your first 5 lessons",
            "xp_reward": 100,
            "coin_reward": 50,
            "target_value": 5,
        },
        {
            "quest_type": "daily_dedication",
            "title": "Daily Dedication",
            "description": "Maintain a 7-day streak",
            "xp_reward": 200,
            "coin_reward": 100,
            "target_value": 7,
        },
        {
            "quest_type": "vocab_master",
            "title": "Vocabulary Master",
            "description": "Learn 50 new words",
            "xp_reward": 300,
            "coin_reward": 150,
            "target_value": 50,
        },
    ]


@router.get("/{quest_id}", response_model=QuestResponse)
async def get_quest(
    quest_id: int,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Get a specific quest by ID."""
    query = select(UserQuest).where(
        and_(
            UserQuest.id == quest_id,
            UserQuest.user_id == current_user.id,
        )
    )

    result = await db.execute(query)
    quest = result.scalar_one_or_none()

    if not quest:
        raise HTTPException(status_code=404, detail="Quest not found")

    return QuestResponse(
        id=quest.id,
        quest_type=quest.quest_type,
        quest_id=quest.quest_id,
        title=quest.title,
        description=quest.description,
        progress_current=quest.progress_current,
        progress_target=quest.progress_target,
        status=quest.status,
        started_at=quest.started_at,
        expires_at=quest.expires_at,
        completed_at=quest.completed_at,
        xp_reward=quest.xp_reward,
        achievement_reward=quest.achievement_reward,
        progress_percentage=min(100.0, (quest.progress_current / quest.progress_target) * 100)
        if quest.progress_target > 0
        else 0.0,
    )


@router.put("/{quest_id}", response_model=QuestResponse)
async def update_quest_progress(
    quest_id: int,
    update: QuestUpdateRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Update progress on a quest."""
    query = select(UserQuest).where(
        and_(
            UserQuest.id == quest_id,
            UserQuest.user_id == current_user.id,
        )
    )

    result = await db.execute(query)
    quest = result.scalar_one_or_none()

    if not quest:
        raise HTTPException(status_code=404, detail="Quest not found")

    if quest.status == "completed":
        raise HTTPException(status_code=400, detail="Quest already completed")

    if quest.status in ["failed", "expired"]:
        raise HTTPException(status_code=400, detail=f"Quest has {quest.status}")

    # Check if expired
    now = datetime.now(timezone.utc)
    if quest.expires_at and quest.expires_at < now:
        quest.status = "expired"
        await db.commit()
        raise HTTPException(status_code=400, detail="Quest has expired")

    # Update progress
    quest.progress_current = min(quest.progress_current + update.increment, quest.progress_target)

    await db.commit()
    await db.refresh(quest)

    return QuestResponse(
        id=quest.id,
        quest_type=quest.quest_type,
        quest_id=quest.quest_id,
        title=quest.title,
        description=quest.description,
        progress_current=quest.progress_current,
        progress_target=quest.progress_target,
        status=quest.status,
        started_at=quest.started_at,
        expires_at=quest.expires_at,
        completed_at=quest.completed_at,
        xp_reward=quest.xp_reward,
        achievement_reward=quest.achievement_reward,
        progress_percentage=min(100.0, (quest.progress_current / quest.progress_target) * 100)
        if quest.progress_target > 0
        else 0.0,
    )


@router.post("/{quest_id}/complete", response_model=dict)
async def complete_quest(
    quest_id: int,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Mark a quest as completed and grant rewards."""
    query = select(UserQuest).where(
        and_(
            UserQuest.id == quest_id,
            UserQuest.user_id == current_user.id,
        )
    )

    result = await db.execute(query)
    quest = result.scalar_one_or_none()

    if not quest:
        raise HTTPException(status_code=404, detail="Quest not found")

    if quest.status == "completed":
        return {"message": "Quest already completed", "rewards_granted": False}

    if quest.status in ["failed", "expired"]:
        raise HTTPException(status_code=400, detail=f"Cannot complete a {quest.status} quest")

    # Verify progress requirement met
    if quest.progress_current < quest.progress_target:
        raise HTTPException(
            status_code=400,
            detail=f"Quest not complete. Progress: {quest.progress_current}/{quest.progress_target}",
        )

    # Mark as completed
    now = datetime.now(timezone.utc)
    quest.status = "completed"
    quest.completed_at = now

    # Grant rewards
    progress_query = select(UserProgress).where(UserProgress.user_id == current_user.id)
    progress_result = await db.execute(progress_query)
    progress = progress_result.scalar_one_or_none()

    if progress and quest.xp_reward > 0:
        progress.xp_total += quest.xp_reward

    await db.commit()

    # Get updated balances
    if progress:
        await db.refresh(progress)

    return {
        "message": "Quest completed!",
        "rewards_granted": True,
        "xp_earned": quest.xp_reward,
        "achievement_earned": quest.achievement_reward,
        "total_xp": progress.xp_total if progress else 0,
    }


@router.delete("/{quest_id}", response_model=dict)
async def abandon_quest(
    quest_id: int,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Abandon a quest (mark as failed, no rewards)."""
    query = select(UserQuest).where(
        and_(
            UserQuest.id == quest_id,
            UserQuest.user_id == current_user.id,
        )
    )

    result = await db.execute(query)
    quest = result.scalar_one_or_none()

    if not quest:
        raise HTTPException(status_code=404, detail="Quest not found")

    if quest.status == "completed":
        raise HTTPException(status_code=400, detail="Cannot abandon a completed quest")

    quest.status = "failed"
    await db.commit()

    return {"message": "Quest abandoned", "quest_id": quest_id}
