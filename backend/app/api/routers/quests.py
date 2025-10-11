"""Quests API endpoints for long-term progression goals."""

import math
from datetime import datetime, timedelta, timezone
from typing import Any, Dict, List, Optional
from uuid import uuid4

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

    quest_type: str = Field(..., description="Quest category identifier (e.g., lesson_count, daily_streak)")
    target_value: int = Field(
        ..., ge=1, le=1000, description="Progress target required to complete the quest"
    )
    duration_days: int = Field(
        default=30,
        ge=1,
        le=365,
        description="Quest duration in days before expiration",
    )
    title: Optional[str] = Field(default=None, min_length=1, max_length=255)
    description: Optional[str] = Field(default=None, max_length=1000)
    quest_id: Optional[str] = Field(
        default=None,
        description="Optional slug/identifier. Auto generated when omitted.",
    )


class QuestResponse(BaseModel):
    """Quest information."""

    id: int
    quest_type: str
    quest_id: str
    title: str
    description: Optional[str]
    current_progress: int
    target_value: int
    is_completed: bool
    is_failed: bool
    status: str  # active, completed, failed, expired
    started_at: datetime
    expires_at: Optional[datetime]
    completed_at: Optional[datetime]
    xp_reward: int
    coin_reward: int
    achievement_reward: Optional[str]
    progress_percentage: float
    difficulty_tier: Optional[str] = None


class QuestTemplateResponse(BaseModel):
    """Quest template metadata for available quest types."""

    quest_type: str
    title: str
    description: str
    xp_reward: int
    coin_reward: int
    target_value: int
    duration_days: int
    difficulty_tier: str
    achievement_reward: Optional[str] = None
    suggestions: Dict[str, Any] | None = None


class QuestPreviewResponse(BaseModel):
    """Preview of quest rewards and generated copy without persistence."""

    quest_type: str
    title: str
    description: str
    target_value: int
    duration_days: int
    xp_reward: int
    coin_reward: int
    difficulty_tier: str
    achievement_reward: Optional[str] = None
    meta: Dict[str, Any]


class QuestUpdateRequest(BaseModel):
    """Request to update quest progress."""

    increment: int = Field(default=1, ge=0, le=1000, description="Amount to increment progress")


# ---------------------------------------------------------------------
# Quest templates & helpers
# ---------------------------------------------------------------------

QUEST_TYPE_TEMPLATES: Dict[str, Dict[str, Any]] = {
    "daily_streak": {
        "title_template": "Daily Streak Defender",
        "description_template": "Maintain a {target}-day learning streak within {duration} days.",
        "xp_unit": 10,
        "type_multiplier": 1.15,
        "difficulty_scale": 0.4,
        "duration_multiplier": 0.6,
        "coin_ratio": 0.65,
        "min_xp": 120,
        "min_coins": 60,
        "achievement_reward": "streak_keeper",
    },
    "xp_milestone": {
        "title_template": "XP Milestone Hunter",
        "description_template": "Earn {target} XP before {duration} days pass.",
        "xp_unit": 12,
        "type_multiplier": 1.25,
        "difficulty_scale": 0.38,
        "duration_multiplier": 0.45,
        "coin_ratio": 0.55,
        "min_xp": 150,
        "min_coins": 70,
        "achievement_reward": "xp_hero",
    },
    "lesson_count": {
        "title_template": "Lesson Marathon",
        "description_template": "Complete {target} lessons within the next {duration} days.",
        "xp_unit": 11,
        "type_multiplier": 1.0,
        "difficulty_scale": 0.35,
        "duration_multiplier": 0.35,
        "coin_ratio": 0.5,
        "min_xp": 100,
        "min_coins": 50,
        "achievement_reward": None,
    },
    "skill_mastery": {
        "title_template": "Skill Mastery Quest",
        "description_template": "Master {target} advanced exercises in {duration} days.",
        "xp_unit": 14,
        "type_multiplier": 1.35,
        "difficulty_scale": 0.42,
        "duration_multiplier": 0.4,
        "coin_ratio": 0.6,
        "min_xp": 200,
        "min_coins": 90,
        "achievement_reward": "skill_master",
    },
}

QUEST_TEMPLATE_RECOMMENDATIONS: Dict[str, Dict[str, int]] = {
    "daily_streak": {"target": 7, "duration": 10},
    "xp_milestone": {"target": 1500, "duration": 30},
    "lesson_count": {"target": 20, "duration": 14},
    "skill_mastery": {"target": 10, "duration": 21},
}

DEFAULT_TEMPLATE = {
    "title_template": "Epic Quest",
    "description_template": "Hit your custom goal of {target} within {duration} days.",
    "xp_unit": 10,
    "type_multiplier": 1.0,
    "difficulty_scale": 0.35,
    "duration_multiplier": 0.35,
    "coin_ratio": 0.5,
    "min_xp": 100,
    "min_coins": 50,
    "achievement_reward": None,
}


def _resolve_template(quest_type: str) -> Dict[str, Any]:
    template = QUEST_TYPE_TEMPLATES.get(quest_type)
    if template:
        return template
    fallback = DEFAULT_TEMPLATE.copy()
    fallback.update(
        {
            "title_template": f"{quest_type.replace('_', ' ').title()} Quest",
            "quest_type": quest_type,
        }
    )
    return fallback


def _difficulty_tier(target_value: int, duration_days: int) -> str:
    score = target_value + duration_days * 0.6
    if score <= 20:
        return "easy"
    if score <= 55:
        return "standard"
    if score <= 110:
        return "hard"
    return "legendary"


def _format_template(text: str, target_value: int, duration_days: int) -> str:
    try:
        return text.format(target=target_value, duration=duration_days)
    except (KeyError, IndexError, ValueError):
        return text


def _calculate_rewards(template: Dict[str, Any], target_value: int, duration_days: int) -> tuple[int, int]:
    xp_unit = template.get("xp_unit", 10)
    type_multiplier = template.get("type_multiplier", 1.0)
    difficulty_scale = template.get("difficulty_scale", 0.35)
    duration_multiplier = template.get("duration_multiplier", 0.35)

    base_xp = xp_unit * max(1, target_value)
    difficulty_factor = 1 + math.log1p(target_value) * difficulty_scale
    duration_factor = 1 + (max(1, duration_days) / 30) * duration_multiplier

    xp_reward = base_xp * type_multiplier * difficulty_factor * duration_factor
    xp_reward = int(max(template.get("min_xp", 80), round(xp_reward)))
    xp_reward = min(template.get("max_xp", 25000), xp_reward)

    coin_ratio = template.get("coin_ratio", 0.5)
    coin_reward = int(max(template.get("min_coins", 40), round(xp_reward * coin_ratio)))
    coin_reward = min(template.get("max_coins", 20000), coin_reward)

    return xp_reward, coin_reward


def _generate_quest_defaults(
    quest_type: str,
    target_value: int,
    duration_days: int,
) -> Dict[str, Any]:
    template = _resolve_template(quest_type)
    xp_reward, coin_reward = _calculate_rewards(template, target_value, duration_days)

    title = _format_template(template.get("title_template", "Quest"), target_value, duration_days)
    description = _format_template(template.get("description_template", ""), target_value, duration_days)

    return {
        "quest_id": f"{quest_type}-{uuid4().hex[:8]}",
        "title": title,
        "description": description,
        "xp_reward": xp_reward,
        "coin_reward": coin_reward,
        "achievement_reward": template.get("achievement_reward"),
        "meta": {
            "template": quest_type if quest_type in QUEST_TYPE_TEMPLATES else "custom",
            "difficulty_tier": _difficulty_tier(target_value, duration_days),
            "target_value": target_value,
            "duration_days": duration_days,
            "reward_curve": {
                "xp_unit": template.get("xp_unit", 10),
                "type_multiplier": template.get("type_multiplier", 1.0),
            },
        },
    }


def _quest_to_response(quest: UserQuest) -> QuestResponse:
    target_value = max(quest.target_value, 1)
    progress_pct = min(100.0, (quest.current_progress / target_value) * 100) if target_value else 0.0
    progress_pct = round(progress_pct, 1)
    return QuestResponse(
        id=quest.id,
        quest_type=quest.quest_type,
        quest_id=quest.quest_id,
        title=quest.title,
        description=quest.description,
        current_progress=quest.current_progress,
        target_value=quest.target_value,
        is_completed=quest.is_completed,
        is_failed=quest.is_failed,
        status=quest.status,
        started_at=quest.started_at,
        expires_at=quest.expires_at,
        completed_at=quest.completed_at,
        xp_reward=quest.xp_reward,
        coin_reward=getattr(quest, "coin_reward", 0),
        achievement_reward=quest.achievement_reward,
        progress_percentage=progress_pct,
        difficulty_tier=(quest.meta or {}).get("difficulty_tier") if isinstance(quest.meta, dict) else None,
    )


# ---------------------------------------------------------------------
# Quest Preview
# ---------------------------------------------------------------------


@router.post("/preview", response_model=QuestPreviewResponse)
async def preview_quest(
    quest_data: QuestCreate,
    current_user: User = Depends(get_current_user),
):
    """Preview quest rewards and generated copy without persisting."""
    defaults = _generate_quest_defaults(
        quest_type=quest_data.quest_type,
        target_value=quest_data.target_value,
        duration_days=quest_data.duration_days,
    )

    meta = defaults["meta"].copy()
    if quest_data.title:
        meta["custom_title"] = True
    if quest_data.description:
        meta["custom_description"] = True

    return QuestPreviewResponse(
        quest_type=quest_data.quest_type,
        title=quest_data.title or defaults["title"],
        description=quest_data.description or defaults["description"],
        target_value=quest_data.target_value,
        duration_days=quest_data.duration_days,
        xp_reward=defaults["xp_reward"],
        coin_reward=defaults["coin_reward"],
        difficulty_tier=meta["difficulty_tier"],
        achievement_reward=defaults["achievement_reward"],
        meta=meta,
    )


# ---------------------------------------------------------------------
# Quest Management
# ---------------------------------------------------------------------
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
    defaults = _generate_quest_defaults(
        quest_type=quest_data.quest_type,
        target_value=quest_data.target_value,
        duration_days=quest_data.duration_days,
    )

    quest_meta = defaults["meta"].copy()
    quest_meta["generated_at"] = now.isoformat()
    if quest_data.title:
        quest_meta["custom_title"] = True
    if quest_data.description:
        quest_meta["custom_description"] = True

    quest = UserQuest(
        user_id=current_user.id,
        quest_type=quest_data.quest_type,
        quest_id=quest_data.quest_id or defaults["quest_id"],
        title=quest_data.title or defaults["title"],
        description=quest_data.description or defaults["description"],
        current_progress=0,
        target_value=quest_data.target_value,
        status="active",
        started_at=now,
        expires_at=expires_at,
        xp_reward=defaults["xp_reward"],
        coin_reward=defaults["coin_reward"],
        achievement_reward=defaults["achievement_reward"],
        meta=quest_meta,
    )

    db.add(quest)
    await db.commit()
    await db.refresh(quest)

    return _quest_to_response(quest)


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
    query = select(UserQuest).where(UserQuest.user_id == current_user.id).order_by(desc(UserQuest.started_at))

    result = await db.execute(query)
    quests = list(result.scalars())

    updated = False
    responses: list[QuestResponse] = []
    for quest in quests:
        if quest.status == "active" and quest.expires_at and quest.expires_at < now:
            quest.status = "expired"
            quest_meta = dict(quest.meta or {})
            quest_meta["expired_at"] = now.isoformat()
            quest.meta = quest_meta
            updated = True
        if not include_completed and quest.status != "active":
            continue
        responses.append(_quest_to_response(quest))

    if updated:
        await db.commit()

    return responses


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


@router.get("/available", response_model=List[QuestTemplateResponse])
async def get_available_quest_types(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Get available quest types that can be started."""
    recommendations: list[dict[str, Any]] = []
    seen: set[str] = set()

    for quest_type, template in QUEST_TYPE_TEMPLATES.items():
        seen.add(quest_type)
        rec = QUEST_TEMPLATE_RECOMMENDATIONS.get(quest_type, {"target": 10, "duration": 30})
        defaults = _generate_quest_defaults(
            quest_type=quest_type,
            target_value=rec["target"],
            duration_days=rec["duration"],
        )
        recommendations.append(
            QuestTemplateResponse(
                quest_type=quest_type,
                title=defaults["title"],
                description=defaults["description"],
                xp_reward=defaults["xp_reward"],
                coin_reward=defaults["coin_reward"],
                target_value=rec["target"],
                duration_days=rec["duration"],
                difficulty_tier=defaults["meta"]["difficulty_tier"],
                achievement_reward=defaults["achievement_reward"],
                suggestions={
                    "recommended_register": "daily" if quest_type == "daily_streak" else "standard",
                    "difficulty_curve": defaults["meta"]["reward_curve"],
                },
            )
        )

    if "custom" not in seen:
        rec = {"target": 12, "duration": 21}
        defaults = _generate_quest_defaults("custom", rec["target"], rec["duration"])
        recommendations.append(
            QuestTemplateResponse(
                quest_type="custom",
                title=defaults["title"],
                description=defaults["description"],
                xp_reward=defaults["xp_reward"],
                coin_reward=defaults["coin_reward"],
                target_value=rec["target"],
                duration_days=rec["duration"],
                difficulty_tier=defaults["meta"]["difficulty_tier"],
                achievement_reward=defaults["achievement_reward"],
                suggestions={
                    "recommended_register": "custom",
                    "difficulty_curve": defaults["meta"]["reward_curve"],
                },
            )
        )

    return recommendations


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

    return _quest_to_response(quest)


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
    quest.current_progress = min(
        quest.current_progress + update.increment,
        quest.target_value,
    )

    await db.commit()
    await db.refresh(quest)

    return _quest_to_response(quest)


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

    # Load current progress snapshot
    progress_query = select(UserProgress).where(UserProgress.user_id == current_user.id)
    progress_result = await db.execute(progress_query)
    progress = progress_result.scalar_one_or_none()

    if quest.status == "completed":
        total_xp = progress.xp_total if progress else 0
        total_coins = progress.coins if progress else 0
        return {
            "message": "Quest already completed",
            "rewards_granted": False,
            "xp_earned": 0,
            "coins_earned": 0,
            "total_xp": total_xp,
            "total_coins": total_coins,
            "achievement_earned": quest.achievement_reward,
        }

    if quest.status in {"failed", "expired"}:
        raise HTTPException(status_code=400, detail=f"Cannot complete a {quest.status} quest")

    # Verify progress requirement met
    if quest.current_progress < quest.target_value:
        raise HTTPException(
            status_code=400,
            detail=f"Quest not complete. Progress: {quest.current_progress}/{quest.target_value}",
        )

    # Mark as completed
    now = datetime.now(timezone.utc)
    quest.is_completed = True
    quest.completed_at = now
    quest_meta = dict(quest.meta or {})
    quest_meta["completed_at"] = now.isoformat()
    quest_meta["reward_claimed"] = True
    quest.meta = quest_meta

    # Grant rewards
    if progress and quest.xp_reward > 0:
        progress.xp_total += quest.xp_reward
    if progress and quest.coin_reward > 0:
        progress.coins += quest.coin_reward

    if not progress:
        # Create baseline progress record so totals are not lost; minimal fields only
        progress = UserProgress(
            user_id=current_user.id,
            xp_total=quest.xp_reward,
            coins=quest.coin_reward,
            last_lesson_at=now,
            last_streak_update=now,
        )
        db.add(progress)

    await db.commit()

    # Get updated balances
    if progress:
        await db.refresh(progress)

    return {
        "message": "Quest completed!",
        "rewards_granted": True,
        "xp_earned": quest.xp_reward,
        "coins_earned": quest.coin_reward,
        "achievement_earned": quest.achievement_reward,
        "total_xp": progress.xp_total if progress else 0,
        "total_coins": progress.coins if progress else 0,
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

    quest.is_failed = True
    await db.commit()

    return {"message": "Quest abandoned", "quest_id": quest_id}
