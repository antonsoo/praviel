"""Gamification API endpoints for progress, achievements, and challenges.

Provides REST endpoints for:
- User progress tracking (XP, level, streaks)
- Achievements and milestones
- Daily challenges/quests
- Leaderboards
- Activity tracking
"""

import logging
from datetime import datetime, timedelta, timezone
from typing import Dict, List, Optional

from fastapi import APIRouter, Depends, HTTPException, Path, Query
from pydantic import BaseModel, Field
from sqlalchemy import Integer, and_, desc, func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.db.session import get_session
from app.db.social_models import Friendship
from app.db.seed_achievements import ACHIEVEMENTS, AchievementDefinition
from app.db.user_models import (
    LearningEvent,
    User,
    UserAchievement,
    UserProfile,
    UserProgress,
    UserQuest,
)
from app.security.auth import get_current_user

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/gamification", tags=["Gamification"])

# ---------------------------------------------------------------------
# Pydantic Response Models
# ---------------------------------------------------------------------


class DailyActivityResponse(BaseModel):
    """Daily activity summary."""

    date: str  # YYYY-MM-DD
    lessons_completed: int
    xp_earned: int
    minutes_studied: int
    words_learned: int


class UserProgressResponse(BaseModel):
    """User progress and gamification stats."""

    user_id: str
    total_xp: int
    level: int
    current_streak: int
    longest_streak: int
    last_activity_date: str  # YYYY-MM-DD
    lessons_completed: int
    words_learned: int
    minutes_studied: int
    language_xp: dict[str, int]  # languageCode -> XP
    unlocked_achievements: List[str]  # achievement IDs
    weekly_activity: List[DailyActivityResponse]
    xp_for_next_level: int
    progress_to_next_level: float  # 0.0 to 1.0


class AchievementResponse(BaseModel):
    """Achievement definition and unlock status."""

    id: str
    achievement_type: str
    title: str
    description: str
    icon: str  # emoji or icon slug
    icon_name: str  # material icon identifier (for asset fallback)
    tier: int
    rarity_label: str
    rarity_percent: float | None = None
    category: str
    xp_reward: int
    coin_reward: int
    is_unlocked: bool
    unlocked_at: Optional[str] = None  # ISO datetime
    progress_current: Optional[int] = None
    progress_target: Optional[int] = None
    unlock_criteria: dict | None = None


class DailyChallengeResponse(BaseModel):
    """Daily challenge/quest."""

    id: str
    title: str
    description: str
    difficulty: str  # easy, medium, hard, expert
    type: str  # lessons, reading, vocab, grammar, streak
    xp_reward: int
    coins_reward: int
    progress_current: int
    progress_target: int
    is_completed: bool
    expires_at: str  # ISO datetime


class LeaderboardEntryResponse(BaseModel):
    """Leaderboard entry."""

    user_id: str
    username: str
    rank: int
    xp: int
    level: int
    avatar_url: Optional[str] = None
    language_code: Optional[str] = None
    is_current_user: bool = False


class LeaderboardResponse(BaseModel):
    """Leaderboard rankings."""

    scope: str  # global, friends, language
    period: str  # daily, weekly, monthly, all_time
    entries: List[LeaderboardEntryResponse]
    current_user_rank: int
    total_users: int


# ---------------------------------------------------------------------
# Pydantic Request Models
# ---------------------------------------------------------------------


class CompleteLessonRequest(BaseModel):
    """Request to record lesson completion."""

    language_code: str = Field(..., min_length=2, max_length=10)
    xp_earned: int = Field(..., ge=0, le=1000)
    words_learned: int = Field(default=0, ge=0)
    minutes_studied: int = Field(..., ge=0, le=480)
    accuracy: Optional[float] = Field(default=None, ge=0.0, le=1.0)


class UpdateProgressRequest(BaseModel):
    """Request to update user progress directly."""

    total_xp: Optional[int] = Field(default=None, ge=0)
    level: Optional[int] = Field(default=None, ge=0)
    current_streak: Optional[int] = Field(default=None, ge=0)
    lessons_completed: Optional[int] = Field(default=None, ge=0)
    words_learned: Optional[int] = Field(default=None, ge=0)
    minutes_studied: Optional[int] = Field(default=None, ge=0)
    language_xp: Optional[dict[str, int]] = None


class UpdateChallengeProgressRequest(BaseModel):
    """Request to update challenge progress."""

    progress: int = Field(..., ge=0)


# ---------------------------------------------------------------------
# Helper Functions
# ---------------------------------------------------------------------


def _calculate_xp_for_level(level: int) -> int:
    """Calculate XP required for a given level using quadratic curve.

    Formula: XP = level² × 100
    This matches UserProgressResponse.get_xp_for_level() in user_schemas.py
    """
    return level * level * 100


def _calculate_level_from_xp(total_xp: int) -> int:
    """Calculate level from total XP using square root formula.

    Formula: Level = floor(sqrt(XP / 100))
    This matches UserProgressResponse.calculate_level() in user_schemas.py
    """
    import math

    if total_xp <= 0:
        return 0
    return int(math.sqrt(total_xp / 100))


def _is_streak_active(last_activity: Optional[datetime]) -> bool:
    """Check if streak is still active (today or yesterday)."""
    if not last_activity:
        return False

    now = datetime.now(timezone.utc)
    today = now.date()
    yesterday = (now - timedelta(days=1)).date()
    last_date = last_activity.date()

    return last_date == today or last_date == yesterday


async def _get_or_create_progress(db: AsyncSession, user: User) -> UserProgress:
    """Get or create user progress record."""
    stmt = select(UserProgress).where(UserProgress.user_id == user.id)
    result = await session.execute(stmt)
    progress = result.scalar_one_or_none()

    if not progress:
        progress = UserProgress(user_id=user.id)
        session.add(progress)
        await session.commit()
        await session.refresh(progress)

    return progress


async def _get_weekly_activity(db: AsyncSession, user_id: int, days: int = 7) -> List[DailyActivityResponse]:
    """Get daily activity for the last N days."""
    cutoff = datetime.now(timezone.utc) - timedelta(days=days)

    stmt = (
        select(
            func.date(LearningEvent.event_timestamp).label("date"),
            func.count().label("lessons_completed"),
            func.coalesce(func.sum(func.cast(LearningEvent.data["xp_earned"].astext, Integer)), 0).label(
                "xp_earned"
            ),
            func.coalesce(
                func.sum(func.cast(LearningEvent.data["minutes_studied"].astext, Integer)), 0
            ).label("minutes_studied"),
            func.coalesce(func.sum(func.cast(LearningEvent.data["words_learned"].astext, Integer)), 0).label(
                "words_learned"
            ),
        )
        .where(
            and_(
                LearningEvent.user_id == user_id,
                LearningEvent.event_type == "lesson_completed",
                LearningEvent.event_timestamp >= cutoff,
            )
        )
        .group_by(func.date(LearningEvent.event_timestamp))
        .order_by(func.date(LearningEvent.event_timestamp))
    )

    result = await session.execute(stmt)
    rows = result.all()

    return [
        DailyActivityResponse(
            date=str(row.date),
            lessons_completed=row.lessons_completed,
            xp_earned=row.xp_earned,
            minutes_studied=row.minutes_studied,
            words_learned=row.words_learned,
        )
        for row in rows
    ]


# ---------------------------------------------------------------------
# Endpoints
# ---------------------------------------------------------------------


@router.get("/users/{user_id}/progress", response_model=UserProgressResponse)
async def get_user_progress(
    user_id: str = Path(..., pattern=r"^\d+$", description="User ID (numeric string)"),
    current_user: User = Depends(get_current_user),
    session: AsyncSession = Depends(get_session),
):
    """Get user progress and gamification stats.

    Returns:
    - XP, level, streaks
    - Activity stats (lessons, words, time)
    - Per-language XP breakdown
    - Unlocked achievements
    - Weekly activity chart data
    """
    try:
        target_user_id = int(user_id)
    except ValueError as exc:  # pragma: no cover - defensive guard
        raise HTTPException(status_code=404, detail="User not found") from exc

    # Resolve target user + profile visibility settings
    result = await session.execute(
        select(User, UserProfile.profile_visibility)
        .join(UserProfile, UserProfile.user_id == User.id, isouter=True)
        .where(User.id == target_user_id)
    )
    row = result.first()

    if not row:
        raise HTTPException(status_code=404, detail="User not found")

    target_user: User = row[0]
    if not target_user.is_active:
        raise HTTPException(status_code=404, detail="User not found")

    visibility = (row[1] or "friends").lower()

    if target_user.id != current_user.id and not current_user.is_superuser:
        if visibility == "private":
            raise HTTPException(status_code=403, detail="This profile is private")

        if visibility == "friends":
            friend_stmt = select(Friendship.id).where(
                and_(
                    Friendship.user_id == current_user.id,
                    Friendship.friend_id == target_user.id,
                    Friendship.status == "accepted",
                )
            )
            friend_result = await session.execute(friend_stmt)
            if friend_result.first() is None:
                raise HTTPException(status_code=403, detail="Only friends can view this profile")

    progress = await _get_or_create_progress(session, target_user)

    # Get weekly activity
    weekly_activity = await _get_weekly_activity(session, target_user.id, days=7)

    # Get unlocked achievements
    stmt = select(UserAchievement).where(UserAchievement.user_id == target_user.id)
    result = await session.execute(stmt)
    achievements = result.scalars().all()
    unlocked_achievement_ids = [f"{a.achievement_type}:{a.achievement_id}" for a in achievements]

    # Calculate level and next level progress
    level = _calculate_level_from_xp(progress.xp_total)
    xp_for_current_level = _calculate_xp_for_level(level)
    xp_for_next_level = _calculate_xp_for_level(level + 1)
    xp_progress = progress.xp_total - xp_for_current_level
    xp_required = xp_for_next_level - xp_for_current_level
    progress_to_next = xp_progress / xp_required if xp_required > 0 else 0.0

    # Parse language XP from stats JSON
    language_xp = {}
    if progress.stats and isinstance(progress.stats, dict):
        language_xp = progress.stats.get("language_xp", {})

    # Last activity date
    last_activity_date = (
        progress.last_lesson_at.date().isoformat() if progress.last_lesson_at else "1970-01-01"
    )

    return UserProgressResponse(
        user_id=user_id,
        total_xp=progress.xp_total,
        level=level,
        current_streak=progress.streak_days,
        longest_streak=progress.max_streak,
        last_activity_date=last_activity_date,
        lessons_completed=progress.total_lessons,
        words_learned=progress.stats.get("words_learned", 0) if progress.stats else 0,
        minutes_studied=progress.total_time_minutes,
        language_xp=language_xp,
        unlocked_achievements=unlocked_achievement_ids,
        weekly_activity=weekly_activity,
        xp_for_next_level=xp_for_next_level,
        progress_to_next_level=progress_to_next,
    )


@router.get("/achievements", response_model=List[AchievementResponse])
async def get_achievements(
    current_user: User = Depends(get_current_user),
    session: AsyncSession = Depends(get_session),
):
    """Get all available achievements with unlock status.

    Returns all achievements (both locked and unlocked) with user's progress.
    """
    # Get user's unlocked achievements
    stmt = select(UserAchievement).where(UserAchievement.user_id == current_user.id)
    result = await session.execute(stmt)
    user_achievements = {f"{a.achievement_type}:{a.achievement_id}": a for a in result.scalars().all()}

    # Define all available achievements
    all_achievements = _get_all_achievement_definitions()
    rarity_map = await _compute_rarity_percentages(session)

    responses = []
    for achievement in all_achievements:
        achievement_key = achievement["key"]
        user_achievement = user_achievements.get(achievement_key)
        rarity_percent = rarity_map.get(achievement_key)

        responses.append(
            AchievementResponse(
                id=achievement["id"],
                achievement_type=achievement["type"],
                title=achievement["title"],
                description=achievement["description"],
                icon=achievement["icon"],
                icon_name=achievement["icon_name"],
                tier=achievement["tier"],
                rarity_label=achievement["rarity_label"],
                rarity_percent=rarity_percent,
                category=achievement["category"],
                xp_reward=achievement["xp_reward"],
                coin_reward=achievement["coin_reward"],
                is_unlocked=user_achievement is not None,
                unlocked_at=user_achievement.unlocked_at.isoformat() if user_achievement else None,
                progress_current=user_achievement.progress_current if user_achievement else None,
                progress_target=user_achievement.progress_target if user_achievement else None,
                unlock_criteria=achievement["unlock_criteria"],
            )
        )

    return responses


@router.get("/users/{user_id}/challenges", response_model=List[DailyChallengeResponse])
async def get_daily_challenges(
    user_id: str = Path(..., pattern=r"^\d+$", description="User ID (numeric string)"),
    current_user: User = Depends(get_current_user),
    session: AsyncSession = Depends(get_session),
):
    """Get active daily challenges for a user.

    Returns active and uncompleted challenges that haven't expired.
    """
    if str(current_user.id) != user_id:
        raise HTTPException(status_code=403, detail="Can only view your own challenges")

    # Get active quests that haven't expired
    now = datetime.now(timezone.utc)
    stmt = (
        select(UserQuest)
        .where(
            and_(
                UserQuest.user_id == current_user.id,
                UserQuest.status.in_(["active", "completed"]),
                UserQuest.expires_at >= now,
            )
        )
        .order_by(UserQuest.started_at.desc())
    )

    result = await session.execute(stmt)
    quests = result.scalars().all()

    # If no quests, create daily quests
    if not quests:
        quests = await _create_daily_quests(session, current_user)

    responses = []
    for quest in quests:
        # Map quest_type to difficulty
        difficulty_map = {
            "daily_lesson": "easy",
            "daily_reading": "medium",
            "daily_vocab": "medium",
            "daily_streak": "hard",
            "weekly_mastery": "expert",
        }

        responses.append(
            DailyChallengeResponse(
                id=quest.quest_id,
                title=quest.title,
                description=quest.description or "",
                difficulty=difficulty_map.get(quest.quest_type, "medium"),
                type=quest.quest_type,
                xp_reward=quest.xp_reward,
                coins_reward=quest.coin_reward,
                progress_current=quest.current_progress,
                progress_target=quest.target_value,
                is_completed=quest.status == "completed",
                expires_at=quest.expires_at.isoformat() if quest.expires_at else "",
            )
        )

    return responses


@router.get("/leaderboard", response_model=LeaderboardResponse)
async def get_leaderboard(
    scope: str = Query("global", pattern=r"^(global|friends|language)$", description="Leaderboard scope"),
    period: str = Query("weekly", pattern=r"^(daily|weekly|monthly|all_time)$", description="Time period"),
    language_code: Optional[str] = Query(None, min_length=2, max_length=20, description="Language code (required if scope=language)"),
    limit: int = Query(100, ge=1, le=500, description="Max number of entries to return"),
    current_user: User = Depends(get_current_user),
    session: AsyncSession = Depends(get_session),
):
    """Get leaderboard rankings.

    Args:
        scope: global, friends, or language
        period: daily, weekly, monthly, or all_time
        language_code: Required if scope=language
        limit: Max number of entries to return

    Returns leaderboard with rankings and current user's rank.
    """
    # Build query based on period
    cutoff_date = None
    if period == "daily":
        cutoff_date = datetime.now(timezone.utc) - timedelta(days=1)
    elif period == "weekly":
        cutoff_date = datetime.now(timezone.utc) - timedelta(days=7)
    elif period == "monthly":
        cutoff_date = datetime.now(timezone.utc) - timedelta(days=30)

    # Base query
    period_totals = None
    if cutoff_date:
        # For time-period leaderboards, aggregate XP from learning events within the window
        period_totals = (
            select(
                LearningEvent.user_id.label("user_id"),
                func.coalesce(
                    func.sum(func.cast(LearningEvent.data["xp_earned"].astext, Integer)),
                    0,
                ).label("xp"),
            )
            .join(User, User.id == LearningEvent.user_id)
            .where(
                and_(
                    User.is_active,
                    LearningEvent.event_type == "lesson_completed",
                    LearningEvent.event_timestamp >= cutoff_date,
                )
            )
            .group_by(LearningEvent.user_id)
        ).subquery()

        stmt = (
            select(
                period_totals.c.user_id,
                User.username,
                period_totals.c.xp.label("xp"),
                UserProgress.level,
            )
            .join(User, User.id == period_totals.c.user_id)
            .join(UserProgress, UserProgress.user_id == period_totals.c.user_id, isouter=True)
            .order_by(desc(period_totals.c.xp))
            .limit(limit)
        )
    else:
        # All-time leaderboard from UserProgress
        stmt = (
            select(
                User.id.label("user_id"),
                User.username,
                UserProgress.xp_total.label("xp"),
                UserProgress.level,
            )
            .join(UserProgress, UserProgress.user_id == User.id)
            .where(User.is_active)
            .order_by(desc(UserProgress.xp_total))
            .limit(limit)
        )

    result = await session.execute(stmt)
    rows = result.all()

    # Build leaderboard entries with ranks
    entries = []
    current_user_rank = -1

    for rank, row in enumerate(rows, start=1):
        is_current = row.user_id == current_user.id
        if is_current:
            current_user_rank = rank

        level = row.level if hasattr(row, "level") else _calculate_level_from_xp(row.xp)

        entries.append(
            LeaderboardEntryResponse(
                user_id=str(row.user_id),
                username=row.username,
                rank=rank,
                xp=row.xp,
                level=level,
                language_code=language_code,
                is_current_user=is_current,
            )
        )

    if cutoff_date:
        total_users_result = await session.execute(
            select(func.count()).select_from(period_totals)
        )
        total_users = total_users_result.scalar_one_or_none() or 0
    else:
        total_users_result = await session.execute(
            select(func.count())
            .select_from(UserProgress)
            .join(User, User.id == UserProgress.user_id)
            .where(User.is_active)
        )
        total_users = total_users_result.scalar_one_or_none() or 0

    # If current user not in top N, find their rank
    if current_user_rank == -1:
        if cutoff_date:
            current_xp_result = await session.execute(
                select(
                    func.coalesce(
                        func.sum(func.cast(LearningEvent.data["xp_earned"].astext, Integer)),
                        0,
                    )
                ).where(
                    and_(
                        LearningEvent.user_id == current_user.id,
                        LearningEvent.event_type == "lesson_completed",
                        LearningEvent.event_timestamp >= cutoff_date,
                    )
                )
            )
            current_xp = current_xp_result.scalar_one_or_none() or 0

            higher_count_result = await session.execute(
                select(func.count())
                .select_from(period_totals)
                .where(period_totals.c.xp > current_xp)
            )
            higher_count = higher_count_result.scalar_one_or_none() or 0
            current_user_rank = int(higher_count) + 1 if total_users else 1
        else:
            current_xp_result = await session.execute(
                select(UserProgress.xp_total)
                .join(User, User.id == UserProgress.user_id)
                .where(UserProgress.user_id == current_user.id, User.is_active)
            )
            current_xp = current_xp_result.scalar_one_or_none() or 0

            higher_count_result = await session.execute(
                select(func.count())
                .select_from(UserProgress)
                .join(User, User.id == UserProgress.user_id)
                .where(User.is_active, UserProgress.xp_total > current_xp)
            )
            higher_count = higher_count_result.scalar_one_or_none() or 0
            current_user_rank = int(higher_count) + 1

    total_users = max(total_users, current_user_rank if current_user_rank > 0 else 0)

    return LeaderboardResponse(
        scope=scope,
        period=period,
        entries=entries,
        current_user_rank=current_user_rank,
        total_users=total_users,
    )


@router.post("/users/{user_id}/lessons/complete")
async def complete_lesson(
    user_id: str = Path(..., pattern=r"^\d+$", description="User ID (numeric string)"),
    request: CompleteLessonRequest = ...,
    current_user: User = Depends(get_current_user),
    session: AsyncSession = Depends(get_session),
):
    """Record lesson completion and update progress.

    Updates:
    - XP and level
    - Streak tracking
    - Activity stats
    - Creates learning event
    - Checks for achievement unlocks
    """
    if str(current_user.id) != user_id:
        raise HTTPException(status_code=403, detail="Can only update your own progress")

    progress = await _get_or_create_progress(session, current_user)

    # Update XP
    progress.xp_total += request.xp_earned
    progress.level = _calculate_level_from_xp(progress.xp_total)

    # Update streak
    now = datetime.now(timezone.utc)
    if _is_streak_active(progress.last_lesson_at):
        # Check if this is a new day
        if progress.last_lesson_at and progress.last_lesson_at.date() < now.date():
            progress.streak_days += 1
    else:
        # Streak broken, restart at 1
        progress.streak_days = 1

    if progress.streak_days > progress.max_streak:
        progress.max_streak = progress.streak_days

    # Update activity stats
    progress.total_lessons += 1
    progress.total_time_minutes += request.minutes_studied
    progress.last_lesson_at = now

    # Update language XP in stats JSON
    if not progress.stats:
        progress.stats = {}
    if "language_xp" not in progress.stats:
        progress.stats["language_xp"] = {}

    lang_xp = progress.stats["language_xp"].get(request.language_code, 0)
    progress.stats["language_xp"][request.language_code] = lang_xp + request.xp_earned

    if "words_learned" not in progress.stats:
        progress.stats["words_learned"] = 0
    progress.stats["words_learned"] += request.words_learned

    # Create learning event
    event = LearningEvent(
        user_id=current_user.id,
        event_type="lesson_completed",
        event_timestamp=now,
        data={
            "language_code": request.language_code,
            "xp_earned": request.xp_earned,
            "words_learned": request.words_learned,
            "minutes_studied": request.minutes_studied,
            "accuracy": request.accuracy,
        },
    )
    session.add(event)

    # Update quest progress
    await _update_quest_progress(session, current_user.id, "lesson_completed", 1)

    await session.commit()
    await session.refresh(progress)

    return {"status": "success", "xp_total": progress.xp_total, "level": progress.level}


# ---------------------------------------------------------------------
# Helper Functions for Achievements and Quests
# ---------------------------------------------------------------------


def _get_all_achievement_definitions() -> List[dict]:
    """Hydrate achievement definitions from the canonical seed module."""
    payloads: List[dict] = []
    for definition in ACHIEVEMENTS:
        payloads.append(_serialize_achievement_definition(definition))
    return payloads


def _serialize_achievement_definition(definition: AchievementDefinition) -> dict:
    criteria = dict(definition.unlock_criteria or {})
    category = _categorize_achievement(definition, criteria)
    icon_name = _icon_for_category(category)
    rarity_label = _tier_to_rarity(definition.tier)
    return {
        "key": f"{definition.achievement_type}:{definition.achievement_id}",
        "type": definition.achievement_type,
        "id": definition.achievement_id,
        "title": definition.title,
        "description": definition.description,
        "icon": definition.icon,
        "icon_name": icon_name,
        "tier": definition.tier,
        "rarity_label": rarity_label,
        "rarity": rarity_label,
        "category": category,
        "xp_reward": definition.xp_reward,
        "coin_reward": definition.coin_reward,
        "unlock_criteria": criteria,
    }


def _categorize_achievement(definition: AchievementDefinition, criteria: dict) -> str:
    if criteria.get("streak_days") is not None or definition.achievement_id.startswith("streak"):
        return "streaks"
    if criteria.get("perfect_lessons") is not None:
        return "mastery"
    if criteria.get("lessons_completed") is not None or "lessons" in criteria:
        return "lessons"
    if criteria.get("language") is not None or criteria.get("languages_count") is not None:
        return "polyglot"
    if criteria.get("xp_total") is not None or criteria.get("level") is not None:
        return "xp"
    if criteria.get("coins") is not None:
        return "economy"
    if criteria.get("special") is not None:
        return "special"
    if definition.achievement_type == "collection":
        return "collections"
    return "general"


def _icon_for_category(category: str) -> str:
    mapping = {
        "lessons": "school",
        "mastery": "military_tech",
        "streaks": "local_fire_department",
        "polyglot": "translate",
        "xp": "workspace_premium",
        "economy": "paid",
        "special": "auto_awesome",
        "collections": "inventory",
        "general": "emoji_events",
    }
    return mapping.get(category, "emoji_events")


def _tier_to_rarity(tier: int) -> str:
    return {
        1: "common",
        2: "rare",
        3: "epic",
        4: "legendary",
    }.get(tier, "common")


async def _compute_rarity_percentages(session: AsyncSession) -> Dict[str, float]:
    total_users = await session.scalar(select(func.count(User.id)).where(User.is_active == True))
    if not total_users or total_users <= 0:
        return {}

    result = await session.execute(
        select(
            UserAchievement.achievement_type,
            UserAchievement.achievement_id,
            func.count(UserAchievement.id),
        ).group_by(UserAchievement.achievement_type, UserAchievement.achievement_id)
    )
    data: Dict[str, float] = {}
    for achievement_type, achievement_id, count in result:
        key = f"{achievement_type}:{achievement_id}"
        data[key] = (count / total_users) * 100.0
    return data


async def _compute_rarity_for(
    session: AsyncSession, achievement_type: str, achievement_id: str
) -> float | None:
    total_users = await session.scalar(select(func.count(User.id)).where(User.is_active == True))
    if not total_users or total_users <= 0:
        return None
    unlocked = await session.scalar(
        select(func.count(UserAchievement.id)).where(
            and_(
                UserAchievement.achievement_type == achievement_type,
                UserAchievement.achievement_id == achievement_id,
            )
        )
    )
    unlocked = unlocked or 0
    return (unlocked / total_users) * 100.0


async def _create_daily_quests(db: AsyncSession, user: User) -> List[UserQuest]:
    """Create daily quests for a user."""
    now = datetime.now(timezone.utc)
    tomorrow = now + timedelta(days=1)
    tomorrow_midnight = datetime.combine(tomorrow.date(), datetime.min.time(), tzinfo=timezone.utc)

    quests = [
        UserQuest(
            user_id=user.id,
            quest_type="daily_lesson",
            quest_id="daily_lesson",
            title="Complete 3 Lessons",
            description="Finish 3 lessons today to earn bonus XP",
            current_progress=0,
            target_value=3,
            status="active",
            xp_reward=150,
            coin_reward=10,
            expires_at=tomorrow_midnight,
        ),
        UserQuest(
            user_id=user.id,
            quest_type="daily_vocab",
            quest_id="daily_vocab",
            title="Learn 20 New Words",
            description="Expand your vocabulary with 20 new words",
            current_progress=0,
            target_value=20,
            status="active",
            xp_reward=100,
            coin_reward=5,
            expires_at=tomorrow_midnight,
        ),
        UserQuest(
            user_id=user.id,
            quest_type="daily_reading",
            quest_id="daily_reading",
            title="Read for 15 Minutes",
            description="Spend 15 minutes reading ancient texts",
            current_progress=0,
            target_value=15,
            status="active",
            xp_reward=120,
            coin_reward=8,
            expires_at=tomorrow_midnight,
        ),
    ]

    for quest in quests:
        session.add(quest)

    await session.commit()

    for quest in quests:
        await session.refresh(quest)

    return quests


async def _update_quest_progress(db: AsyncSession, user_id: int, event_type: str, increment: int) -> None:
    """Update quest progress based on events."""
    # Map event types to quest types
    quest_type_map = {
        "lesson_completed": "daily_lesson",
        "vocab_learned": "daily_vocab",
        "reading_time": "daily_reading",
    }

    quest_type = quest_type_map.get(event_type)
    if not quest_type:
        return

    # Find active quests of this type
    stmt = select(UserQuest).where(
        and_(
            UserQuest.user_id == user_id,
            UserQuest.quest_type == quest_type,
            UserQuest.status == "active",
        )
    )

    result = await session.execute(stmt)
    quests = result.scalars().all()

    for quest in quests:
        quest.current_progress += increment
        if quest.current_progress >= quest.target_value:
            quest.status = "completed"
            quest.completed_at = datetime.now(timezone.utc)


# ---------------------------------------------------------------------
# Additional Endpoints for Flutter Client Compatibility
# ---------------------------------------------------------------------


@router.put("/users/{user_id}/progress", response_model=UserProgressResponse)
async def update_user_progress(
    user_id: str = Path(..., pattern=r"^\d+$", description="User ID (numeric string)"),
    request: UpdateProgressRequest = ...,
    current_user: User = Depends(get_current_user),
    session: AsyncSession = Depends(get_session),
):
    """Update user progress directly (for Flutter client compatibility).

    This endpoint allows direct updates to user progress fields.
    Primarily used by the Flutter client for bulk progress updates.
    """
    if str(current_user.id) != user_id:
        raise HTTPException(status_code=403, detail="Can only update your own progress")

    progress = await _get_or_create_progress(session, current_user)

    # Update provided fields
    if request.total_xp is not None:
        progress.xp_total = request.total_xp
        progress.level = _calculate_level_from_xp(request.total_xp)
    elif request.level is not None:
        progress.level = request.level

    if request.current_streak is not None:
        progress.streak_days = request.current_streak

    if request.lessons_completed is not None:
        progress.total_lessons = request.lessons_completed

    if request.minutes_studied is not None:
        progress.total_time_minutes = request.minutes_studied

    if request.language_xp is not None:
        if not progress.stats:
            progress.stats = {}
        progress.stats["language_xp"] = request.language_xp

    if request.words_learned is not None:
        if not progress.stats:
            progress.stats = {}
        progress.stats["words_learned"] = request.words_learned

    await session.commit()
    await session.refresh(progress)

    # Return full progress response
    return await get_user_progress(user_id, current_user, session)


@router.get("/users/{user_id}/achievements", response_model=List[AchievementResponse])
async def get_user_achievements_only(
    user_id: str = Path(..., pattern=r"^\d+$", description="User ID (numeric string)"),
    current_user: User = Depends(get_current_user),
    session: AsyncSession = Depends(get_session),
):
    """Get only the user's unlocked achievements (for Flutter client).

    Returns only achievements that the user has unlocked, not all available achievements.
    """
    if str(current_user.id) != user_id:
        raise HTTPException(status_code=403, detail="Can only view your own achievements")

    # Get user's unlocked achievements
    stmt = select(UserAchievement).where(UserAchievement.user_id == current_user.id)
    result = await session.execute(stmt)
    user_achievements = result.scalars().all()

    # Get all achievement definitions
    all_achievements = _get_all_achievement_definitions()
    achievement_map = {a["key"]: a for a in all_achievements}
    rarity_map = await _compute_rarity_percentages(session)

    # Return only unlocked achievements with full details
    responses = []
    for user_achievement in user_achievements:
        achievement_key = f"{user_achievement.achievement_type}:{user_achievement.achievement_id}"
        achievement_def = achievement_map.get(achievement_key)

        if achievement_def:
            responses.append(
                AchievementResponse(
                    id=achievement_def["id"],
                    achievement_type=achievement_def["type"],
                    title=achievement_def["title"],
                    description=achievement_def["description"],
                    icon=achievement_def["icon"],
                    icon_name=achievement_def["icon_name"],
                    tier=achievement_def["tier"],
                    rarity_label=achievement_def["rarity_label"],
                    rarity_percent=rarity_map.get(achievement_key),
                    category=achievement_def["category"],
                    xp_reward=achievement_def["xp_reward"],
                    coin_reward=achievement_def["coin_reward"],
                    is_unlocked=True,
                    unlocked_at=user_achievement.unlocked_at.isoformat(),
                    progress_current=user_achievement.progress_current,
                    progress_target=user_achievement.progress_target,
                    unlock_criteria=achievement_def["unlock_criteria"],
                )
            )

    return responses


@router.post("/users/{user_id}/achievements/{achievement_id}/unlock", response_model=AchievementResponse)
async def unlock_achievement(
    user_id: str = Path(..., pattern=r"^\d+$", description="User ID (numeric string)"),
    achievement_id: str = Path(..., min_length=1, max_length=100, description="Achievement ID"),
    current_user: User = Depends(get_current_user),
    session: AsyncSession = Depends(get_session),
):
    """Manually unlock an achievement for a user (for Flutter client).

    This endpoint allows the client to trigger achievement unlocks explicitly.
    """
    if str(current_user.id) != user_id:
        raise HTTPException(status_code=403, detail="Can only unlock your own achievements")

    # Parse achievement_id (format: "type:id" or just "id")
    if ":" in achievement_id:
        achievement_type, achievement_key = achievement_id.split(":", 1)
    else:
        # Try to find in definitions
        all_achievements = _get_all_achievement_definitions()
        matching = [a for a in all_achievements if a["id"] == achievement_id]
        if not matching:
            raise HTTPException(status_code=404, detail="Achievement not found")
        achievement_type = matching[0]["type"]
        achievement_key = achievement_id

    # Check if already unlocked
    stmt = select(UserAchievement).where(
        and_(
            UserAchievement.user_id == current_user.id,
            UserAchievement.achievement_type == achievement_type,
            UserAchievement.achievement_id == achievement_key,
        )
    )
    result = await session.execute(stmt)
    existing = result.scalar_one_or_none()

    if existing:
        # Already unlocked, return existing
        all_achievements = _get_all_achievement_definitions()
        achievement_def = next(
            (a for a in all_achievements if a["type"] == achievement_type and a["id"] == achievement_key),
            None,
        )
        if not achievement_def:
            raise HTTPException(status_code=404, detail="Achievement definition not found")

        rarity_percent = await _compute_rarity_for(session, achievement_type, achievement_key)

        return AchievementResponse(
            id=achievement_def["id"],
            achievement_type=achievement_def["type"],
            title=achievement_def["title"],
            description=achievement_def["description"],
            icon=achievement_def["icon"],
            icon_name=achievement_def["icon_name"],
            tier=achievement_def["tier"],
            rarity_label=achievement_def["rarity_label"],
            rarity_percent=rarity_percent,
            category=achievement_def["category"],
            xp_reward=achievement_def["xp_reward"],
            coin_reward=achievement_def["coin_reward"],
            is_unlocked=True,
            unlocked_at=existing.unlocked_at.isoformat(),
            progress_current=existing.progress_current,
            progress_target=existing.progress_target,
            unlock_criteria=achievement_def["unlock_criteria"],
        )

    # Create new achievement unlock
    all_achievements = _get_all_achievement_definitions()
    achievement_def = next(
        (a for a in all_achievements if a["type"] == achievement_type and a["id"] == achievement_key),
        None,
    )
    if not achievement_def:
        raise HTTPException(status_code=404, detail="Achievement definition not found")

    now = datetime.now(timezone.utc)
    user_achievement = UserAchievement(
        user_id=current_user.id,
        achievement_type=achievement_type,
        achievement_id=achievement_key,
        unlocked_at=now,
    )
    session.add(user_achievement)

    # Award XP
    progress = await _get_or_create_progress(session, current_user)
    progress.xp_total += achievement_def["xp_reward"]
    progress.level = _calculate_level_from_xp(progress.xp_total)

    await session.commit()
    await session.refresh(user_achievement)

    rarity_percent = await _compute_rarity_for(session, achievement_type, achievement_key)

    # Send achievement notification email (async, don't block response)
    try:
        from app.core.config import settings
        from app.jobs.email_jobs import send_achievement_notification

        # Build icon URL
        icon_url = f"{settings.FRONTEND_URL}/assets/achievements/{achievement_def['icon_name']}.png"

        # Send notification (fire and forget)
        import asyncio

        asyncio.create_task(
            send_achievement_notification(
                user_id=current_user.id,
                achievement_name=achievement_def["title"],
                achievement_description=achievement_def["description"],
                achievement_icon_url=icon_url,
                rarity_percent=rarity_percent,
            )
        )
    except Exception as exc:
        logger.error(f"Failed to send achievement notification: {exc}")

    return AchievementResponse(
        id=achievement_def["id"],
        achievement_type=achievement_def["type"],
        title=achievement_def["title"],
        description=achievement_def["description"],
        icon=achievement_def["icon"],
        icon_name=achievement_def["icon_name"],
        tier=achievement_def["tier"],
        rarity_label=achievement_def["rarity_label"],
        rarity_percent=rarity_percent,
        category=achievement_def["category"],
        xp_reward=achievement_def["xp_reward"],
        coin_reward=achievement_def["coin_reward"],
        is_unlocked=True,
        unlocked_at=user_achievement.unlocked_at.isoformat(),
        progress_current=user_achievement.progress_current,
        progress_target=user_achievement.progress_target,
        unlock_criteria=achievement_def["unlock_criteria"],
    )


@router.put("/users/{user_id}/challenges/{challenge_id}/progress", response_model=DailyChallengeResponse)
async def update_challenge_progress_endpoint(
    user_id: str = Path(..., pattern=r"^\d+$", description="User ID (numeric string)"),
    challenge_id: str = Path(..., min_length=1, max_length=100, description="Challenge/quest ID"),
    request: UpdateChallengeProgressRequest = ...,
    current_user: User = Depends(get_current_user),
    session: AsyncSession = Depends(get_session),
):
    """Update progress on a specific daily challenge (for Flutter client).

    Args:
        request: Contains progress value (absolute, not increment)
    """
    if str(current_user.id) != user_id:
        raise HTTPException(status_code=403, detail="Can only update your own challenges")

    # Find the quest
    stmt = select(UserQuest).where(
        and_(
            UserQuest.user_id == current_user.id,
            UserQuest.quest_id == challenge_id,
            UserQuest.status.in_(["active", "completed"]),
        )
    )
    result = await session.execute(stmt)
    quest = result.scalar_one_or_none()

    if not quest:
        raise HTTPException(status_code=404, detail="Challenge not found")

    # Update progress
    quest.current_progress = request.progress

    # Check if completed
    if quest.current_progress >= quest.target_value and quest.status == "active":
        quest.status = "completed"
        quest.completed_at = datetime.now(timezone.utc)

        # Award rewards
        user_progress = await _get_or_create_progress(session, current_user)
        user_progress.xp_total += quest.xp_reward
        user_progress.level = _calculate_level_from_xp(user_progress.xp_total)

    await session.commit()
    await session.refresh(quest)

    # Map difficulty
    difficulty_map = {
        "daily_lesson": "easy",
        "daily_reading": "medium",
        "daily_vocab": "medium",
        "daily_streak": "hard",
        "weekly_mastery": "expert",
    }

    return DailyChallengeResponse(
        id=quest.quest_id,
        title=quest.title,
        description=quest.description or "",
        difficulty=difficulty_map.get(quest.quest_type, "medium"),
        type=quest.quest_type,
        xp_reward=quest.xp_reward,
        coins_reward=quest.coin_reward,
        progress_current=quest.current_progress,
        progress_target=quest.target_value,
        is_completed=quest.status == "completed",
        expires_at=quest.expires_at.isoformat() if quest.expires_at else "",
    )


# Export router
__all__ = ["router"]
