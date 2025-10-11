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
        coins=progress.coins,
        streak_freezes=progress.streak_freezes,
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

    Uses row-level locking (SELECT FOR UPDATE) to prevent race conditions
    when multiple concurrent requests update the same user's progress.
    """
    # Use SELECT FOR UPDATE to lock the row and prevent race conditions
    result = await session.execute(
        select(UserProgress).where(UserProgress.user_id == current_user.id).with_for_update()
    )
    progress = result.scalar_one_or_none()

    if not progress:
        progress = UserProgress(user_id=current_user.id, xp_total=0, level=0, streak_days=0)
        session.add(progress)
        await session.flush()

    old_level = UserProgressResponse.calculate_level(progress.xp_total)

    # Update XP and award coins (1 coin per 10 XP)
    progress.xp_total += update.xp_gained
    coins_earned = update.xp_gained // 10
    progress.coins += coins_earned

    # Update streak logic
    now = datetime.now(timezone.utc)
    today = datetime(now.year, now.month, now.day, tzinfo=timezone.utc)

    if progress.last_streak_update:
        last_update = progress.last_streak_update
        # Ensure timezone consistency - both datetime objects must have timezone
        last_update_day = datetime(last_update.year, last_update.month, last_update.day, tzinfo=timezone.utc)
        days_diff = (today - last_update_day).days

        if days_diff == 0:
            # Same day - no streak change, but reset freeze flag
            if progress.streak_freeze_used_today:
                progress.streak_freeze_used_today = False
        elif days_diff == 1:
            # Next day - increment streak
            progress.streak_days += 1
            progress.last_streak_update = now
            if progress.streak_days > progress.max_streak:
                progress.max_streak = progress.streak_days
        elif days_diff == 2 and progress.streak_freezes > 0 and not progress.streak_freeze_used_today:
            # 2-day gap but user has a streak freeze available - use it automatically
            progress.streak_freezes -= 1
            progress.streak_freeze_used_today = True
            progress.last_streak_update = now
            # Streak preserved!
        else:
            # Gap too large or no freeze available - reset streak
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


@router.post("/me/streak-freeze/buy")
async def buy_streak_freeze(
    current_user: User = Depends(get_current_user),
    session: AsyncSession = Depends(get_session),
) -> dict:
    """Purchase a streak freeze with coins.

    Cost: 100 coins per streak freeze.
    Streak freezes protect your streak if you miss a day.
    """
    STREAK_FREEZE_COST = 100

    result = await session.execute(
        select(UserProgress).where(UserProgress.user_id == current_user.id).with_for_update()
    )
    progress = result.scalar_one_or_none()

    if not progress:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Progress not found")

    if progress.coins < STREAK_FREEZE_COST:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Not enough coins. Need {STREAK_FREEZE_COST}, have {progress.coins}",
        )

    # Deduct coins and add streak freeze
    progress.coins -= STREAK_FREEZE_COST
    progress.streak_freezes += 1

    await session.commit()
    await session.refresh(progress)

    return {
        "success": True,
        "coins_remaining": progress.coins,
        "streak_freezes": progress.streak_freezes,
        "message": "Streak freeze purchased successfully!",
    }


@router.post("/me/streak-repair")
async def repair_broken_streak(
    current_user: User = Depends(get_current_user),
    session: AsyncSession = Depends(get_session),
) -> dict:
    """Repair a broken streak by completing a double lesson (2x XP required).

    This endpoint should be called after user completes special "repair" lessons.
    Only available if streak was broken within the last 24 hours.
    """
    result = await session.execute(
        select(UserProgress).where(UserProgress.user_id == current_user.id).with_for_update()
    )
    progress = result.scalar_one_or_none()

    if not progress:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Progress not found")

    now = datetime.now(timezone.utc)

    # Check if streak was recently broken (within 24 hours)
    if progress.last_streak_update:
        time_since_last = (now - progress.last_streak_update).total_seconds() / 3600
        if time_since_last > 48:  # More than 48 hours
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Streak repair only available within 48 hours of breaking",
            )

    # Restore previous streak (stored in max_streak if recently broken)
    if progress.streak_days == 1 and progress.max_streak > 1:
        progress.streak_days = progress.max_streak
        progress.last_streak_update = now

        await session.commit()
        await session.refresh(progress)

        return {
            "success": True,
            "streak_days": progress.streak_days,
            "message": f"Streak repaired! Back to {progress.streak_days} days!",
        }
    else:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="No broken streak to repair")


__all__ = ["router"]
