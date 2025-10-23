"""Gamification API endpoints for progress, achievements, and challenges.

Provides REST endpoints for:
- User progress tracking (XP, level, streaks)
- Achievements and milestones
- Daily challenges/quests
- Leaderboards
- Activity tracking
"""

from datetime import datetime, timedelta, timezone
from typing import List, Optional

from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel, Field
from sqlalchemy import Integer, and_, desc, func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.db.session import get_db
from app.db.user_models import LearningEvent, User, UserAchievement, UserProgress, UserQuest
from app.security.auth import get_current_user

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
    title: str
    description: str
    icon_name: str
    rarity: str  # common, uncommon, rare, epic, legendary, mythic
    category: str  # lessons, reading, streaks, mastery, social, exploration
    xp_reward: int
    is_unlocked: bool
    unlocked_at: Optional[str] = None  # ISO datetime
    progress_current: Optional[int] = None
    progress_target: Optional[int] = None


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


# ---------------------------------------------------------------------
# Helper Functions
# ---------------------------------------------------------------------


def _calculate_xp_for_level(level: int) -> int:
    """Calculate XP required for a given level using exponential curve."""
    return int(100 * (level**1.5))


def _calculate_level_from_xp(total_xp: int) -> int:
    """Calculate level from total XP."""
    level = 0
    while _calculate_xp_for_level(level + 1) <= total_xp:
        level += 1
    return level


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
    result = await db.execute(stmt)
    progress = result.scalar_one_or_none()

    if not progress:
        progress = UserProgress(user_id=user.id)
        db.add(progress)
        await db.commit()
        await db.refresh(progress)

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

    result = await db.execute(stmt)
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
    user_id: str,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Get user progress and gamification stats.

    Returns:
    - XP, level, streaks
    - Activity stats (lessons, words, time)
    - Per-language XP breakdown
    - Unlocked achievements
    - Weekly activity chart data
    """
    # For now, only allow users to view their own progress
    # TODO: Add friend visibility logic
    if str(current_user.id) != user_id:
        raise HTTPException(status_code=403, detail="Can only view your own progress")

    progress = await _get_or_create_progress(db, current_user)

    # Get weekly activity
    weekly_activity = await _get_weekly_activity(db, current_user.id, days=7)

    # Get unlocked achievements
    stmt = select(UserAchievement).where(UserAchievement.user_id == current_user.id)
    result = await db.execute(stmt)
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
    db: AsyncSession = Depends(get_db),
):
    """Get all available achievements with unlock status.

    Returns all achievements (both locked and unlocked) with user's progress.
    """
    # Get user's unlocked achievements
    stmt = select(UserAchievement).where(UserAchievement.user_id == current_user.id)
    result = await db.execute(stmt)
    user_achievements = {f"{a.achievement_type}:{a.achievement_id}": a for a in result.scalars().all()}

    # Define all available achievements
    # In production, this would come from a database table or config file
    all_achievements = _get_all_achievement_definitions()

    responses = []
    for achievement in all_achievements:
        achievement_key = f"{achievement['type']}:{achievement['id']}"
        user_achievement = user_achievements.get(achievement_key)

        responses.append(
            AchievementResponse(
                id=achievement["id"],
                title=achievement["title"],
                description=achievement["description"],
                icon_name=achievement["icon_name"],
                rarity=achievement["rarity"],
                category=achievement["category"],
                xp_reward=achievement["xp_reward"],
                is_unlocked=user_achievement is not None,
                unlocked_at=user_achievement.unlocked_at.isoformat() if user_achievement else None,
                progress_current=user_achievement.progress_current if user_achievement else None,
                progress_target=user_achievement.progress_target if user_achievement else None,
            )
        )

    return responses


@router.get("/users/{user_id}/challenges", response_model=List[DailyChallengeResponse])
async def get_daily_challenges(
    user_id: str,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
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

    result = await db.execute(stmt)
    quests = result.scalars().all()

    # If no quests, create daily quests
    if not quests:
        quests = await _create_daily_quests(db, current_user)

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
    scope: str = "global",  # global, friends, language
    period: str = "weekly",  # daily, weekly, monthly, all_time
    language_code: Optional[str] = None,
    limit: int = 100,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
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
    if cutoff_date:
        # For time-period leaderboards, sum XP from events
        stmt = (
            select(
                User.id.label("user_id"),
                User.username,
                func.coalesce(func.sum(func.cast(LearningEvent.data["xp_earned"].astext, Integer)), 0).label(
                    "xp"
                ),
            )
            .join(LearningEvent, LearningEvent.user_id == User.id)
            .where(
                and_(
                    User.is_active,
                    LearningEvent.event_type == "lesson_completed",
                    LearningEvent.event_timestamp >= cutoff_date,
                )
            )
            .group_by(User.id, User.username)
            .order_by(desc("xp"))
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

    result = await db.execute(stmt)
    rows = result.all()

    # Build leaderboard entries with ranks
    entries = []
    current_user_rank = -1

    for rank, row in enumerate(rows, start=1):
        is_current = row.user_id == current_user.id
        if is_current:
            current_user_rank = rank

        level = _calculate_level_from_xp(row.xp) if hasattr(row, "level") else row.level

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

    # If current user not in top N, find their rank
    if current_user_rank == -1:
        # TODO: Calculate actual rank with efficient query
        current_user_rank = limit + 1

    return LeaderboardResponse(
        scope=scope,
        period=period,
        entries=entries,
        current_user_rank=current_user_rank,
        total_users=len(entries),
    )


@router.post("/users/{user_id}/lessons/complete")
async def complete_lesson(
    user_id: str,
    request: CompleteLessonRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
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

    progress = await _get_or_create_progress(db, current_user)

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
    db.add(event)

    # Update quest progress
    await _update_quest_progress(db, current_user.id, "lesson_completed", 1)

    await db.commit()
    await db.refresh(progress)

    return {"status": "success", "xp_total": progress.xp_total, "level": progress.level}


# ---------------------------------------------------------------------
# Helper Functions for Achievements and Quests
# ---------------------------------------------------------------------


def _get_all_achievement_definitions() -> List[dict]:
    """Get all achievement definitions.

    In production, this would come from a database or config file.
    """
    return [
        {
            "type": "lessons",
            "id": "first_lesson",
            "title": "First Steps",
            "description": "Complete your first lesson",
            "icon_name": "school",
            "rarity": "common",
            "category": "lessons",
            "xp_reward": 50,
        },
        {
            "type": "lessons",
            "id": "lesson_10",
            "title": "Dedicated Learner",
            "description": "Complete 10 lessons",
            "icon_name": "school",
            "rarity": "uncommon",
            "category": "lessons",
            "xp_reward": 100,
        },
        {
            "type": "streaks",
            "id": "streak_7",
            "title": "Week Warrior",
            "description": "Maintain a 7-day streak",
            "icon_name": "local_fire_department",
            "rarity": "rare",
            "category": "streaks",
            "xp_reward": 200,
        },
        {
            "type": "streaks",
            "id": "streak_30",
            "title": "Monthly Master",
            "description": "Maintain a 30-day streak",
            "icon_name": "local_fire_department",
            "rarity": "epic",
            "category": "streaks",
            "xp_reward": 500,
        },
        {
            "type": "reading",
            "id": "words_100",
            "title": "Vocabulary Builder",
            "description": "Learn 100 new words",
            "icon_name": "translate",
            "rarity": "uncommon",
            "category": "reading",
            "xp_reward": 150,
        },
        {
            "type": "reading",
            "id": "words_1000",
            "title": "Polyglot",
            "description": "Learn 1000 new words",
            "icon_name": "translate",
            "rarity": "legendary",
            "category": "reading",
            "xp_reward": 1000,
        },
    ]


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
        db.add(quest)

    await db.commit()

    for quest in quests:
        await db.refresh(quest)

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

    result = await db.execute(stmt)
    quests = result.scalars().all()

    for quest in quests:
        quest.current_progress += increment
        if quest.current_progress >= quest.target_value:
            quest.status = "completed"
            quest.completed_at = datetime.now(timezone.utc)


# Export router
__all__ = ["router"]
