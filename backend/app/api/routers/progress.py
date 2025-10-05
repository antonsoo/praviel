"""User progress, gamification, and achievement tracking endpoints."""

from __future__ import annotations

from datetime import datetime, timezone

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.schemas.user_schemas import (
    ProgressUpdateRequest,
    UserAchievementResponse,
    UserProgressResponse,
    UserSkillResponse,
    UserTextStatsResponse,
)
from app.db.session import get_session
from app.db.user_models import (
    LearningEvent,
    User,
    UserAchievement,
    UserProgress,
    UserSkill,
    UserTextStats,
)
from app.security.auth import get_current_user

router = APIRouter(prefix="/progress", tags=["progress"])


# ---------------------------------------------------------------------
# Progress & Gamification Endpoints
# ---------------------------------------------------------------------


@router.get("/me", response_model=UserProgressResponse)
async def get_user_progress(
    current_user: User = Depends(get_current_user),
    session: AsyncSession = Depends(get_session),
) -> UserProgressResponse:
    """Get the current user's overall progress and gamification metrics."""
    result = await session.execute(select(UserProgress).where(UserProgress.user_id == current_user.id))
    progress = result.scalar_one_or_none()

    if not progress:
        # Create default progress if it doesn't exist
        progress = UserProgress(
            user_id=current_user.id,
            xp_total=0,
            level=0,
            streak_days=0,
            max_streak=0,
        )
        session.add(progress)
        await session.commit()
        await session.refresh(progress)

    # Calculate level and XP progression
    current_level = UserProgressResponse.calculate_level(progress.xp_total)
    xp_current_level = UserProgressResponse.get_xp_for_level(current_level)
    xp_next_level = UserProgressResponse.get_xp_for_level(current_level + 1)
    xp_to_next = xp_next_level - progress.xp_total
    progress_pct = (
        (progress.xp_total - xp_current_level) / (xp_next_level - xp_current_level)
        if xp_next_level > xp_current_level
        else 0.0
    )

    return UserProgressResponse(
        xp_total=progress.xp_total,
        level=current_level,
        streak_days=progress.streak_days,
        max_streak=progress.max_streak,
        total_lessons=progress.total_lessons,
        total_exercises=progress.total_exercises,
        total_time_minutes=progress.total_time_minutes,
        last_lesson_at=progress.last_lesson_at,
        last_streak_update=progress.last_streak_update,
        xp_for_current_level=xp_current_level,
        xp_for_next_level=xp_next_level,
        xp_to_next_level=xp_to_next,
        progress_to_next_level=progress_pct,
    )


@router.post("/me/update", response_model=UserProgressResponse)
async def update_user_progress(
    update: ProgressUpdateRequest,
    current_user: User = Depends(get_current_user),
    session: AsyncSession = Depends(get_session),
) -> UserProgressResponse:
    """Update user progress after completing a lesson or activity.

    This endpoint:
    1. Adds XP to the user's total
    2. Updates streak tracking
    3. Logs a learning event
    4. Recalculates level
    """
    result = await session.execute(select(UserProgress).where(UserProgress.user_id == current_user.id))
    progress = result.scalar_one_or_none()

    if not progress:
        progress = UserProgress(user_id=current_user.id, xp_total=0, level=0, streak_days=0)
        session.add(progress)
        await session.flush()

    old_level = UserProgressResponse.calculate_level(progress.xp_total)

    # Update XP
    progress.xp_total += update.xp_gained

    # Update streak logic
    now = datetime.now(timezone.utc)
    today = datetime(now.year, now.month, now.day, tzinfo=timezone.utc)

    if progress.last_streak_update:
        last_update = progress.last_streak_update
        last_update_day = datetime(last_update.year, last_update.month, last_update.day)
        days_diff = (today - last_update_day).days

        if days_diff == 0:
            # Same day - no streak change
            pass
        elif days_diff == 1:
            # Next day - increment streak
            progress.streak_days += 1
            progress.last_streak_update = now
            if progress.streak_days > progress.max_streak:
                progress.max_streak = progress.streak_days
        else:
            # Gap - reset streak
            progress.streak_days = 1
            progress.last_streak_update = now
    else:
        # First lesson ever
        progress.streak_days = 1
        progress.last_streak_update = now
        progress.max_streak = 1

    # Update activity counters
    progress.total_lessons += 1
    progress.last_lesson_at = now

    if update.time_spent_minutes:
        progress.total_time_minutes += update.time_spent_minutes

    # Calculate new level
    new_level = UserProgressResponse.calculate_level(progress.xp_total)
    progress.level = new_level

    # Log learning event
    event = LearningEvent(
        user_id=current_user.id,
        event_type="lesson_complete",
        data={
            "lesson_id": update.lesson_id,
            "xp_gained": update.xp_gained,
            "time_spent_minutes": update.time_spent_minutes,
            "old_level": old_level,
            "new_level": new_level,
            "level_up": new_level > old_level,
        },
    )
    session.add(event)

    await session.commit()
    await session.refresh(progress)

    # Return updated progress
    return await get_user_progress(current_user, session)


@router.get("/me/skills", response_model=list[UserSkillResponse])
async def get_user_skills(
    current_user: User = Depends(get_current_user),
    session: AsyncSession = Depends(get_session),
    topic_type: str | None = None,
) -> list[UserSkill]:
    """Get the current user's skill ratings for various topics.

    Optionally filter by topic_type (e.g., 'grammar', 'morph', 'vocab').
    """
    query = select(UserSkill).where(UserSkill.user_id == current_user.id)

    if topic_type:
        query = query.where(UserSkill.topic_type == topic_type)

    result = await session.execute(query.order_by(UserSkill.elo_rating.desc()))
    skills = result.scalars().all()

    return list(skills)


@router.get("/me/achievements", response_model=list[UserAchievementResponse])
async def get_user_achievements(
    current_user: User = Depends(get_current_user),
    session: AsyncSession = Depends(get_session),
) -> list[UserAchievement]:
    """Get the current user's unlocked achievements and badges."""
    result = await session.execute(
        select(UserAchievement)
        .where(UserAchievement.user_id == current_user.id)
        .order_by(UserAchievement.unlocked_at.desc())
    )
    achievements = result.scalars().all()

    return list(achievements)


@router.get("/me/texts", response_model=list[UserTextStatsResponse])
async def get_user_text_stats(
    current_user: User = Depends(get_current_user),
    session: AsyncSession = Depends(get_session),
) -> list[UserTextStats]:
    """Get the current user's reading statistics for different works."""
    result = await session.execute(
        select(UserTextStats)
        .where(UserTextStats.user_id == current_user.id)
        .order_by(UserTextStats.lemma_coverage_pct.desc().nullslast())
    )
    stats = result.scalars().all()

    return list(stats)


@router.get("/me/texts/{work_id}", response_model=UserTextStatsResponse)
async def get_user_text_stats_for_work(
    work_id: int,
    current_user: User = Depends(get_current_user),
    session: AsyncSession = Depends(get_session),
) -> UserTextStats:
    """Get the current user's reading statistics for a specific work."""
    result = await session.execute(
        select(UserTextStats).where(
            UserTextStats.user_id == current_user.id,
            UserTextStats.work_id == work_id,
        )
    )
    stats = result.scalar_one_or_none()

    if not stats:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="No statistics found for this work",
        )

    return stats


__all__ = ["router"]
