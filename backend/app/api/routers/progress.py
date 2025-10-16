"""User progress, gamification, and achievement tracking endpoints."""

from __future__ import annotations

from datetime import datetime, timedelta, timezone

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
from app.db.seed_achievements import check_and_unlock_achievements
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
        xp_boost_2x=progress.xp_boost_2x,
        xp_boost_5x=progress.xp_boost_5x,
        time_warp=progress.time_warp,
        coin_doubler=progress.coin_doubler,
        perfect_protection=progress.perfect_protection,
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
            # Same day - no streak change, but reset shield flag
            if progress.streak_freeze_used_today:
                progress.streak_freeze_used_today = False
        elif days_diff == 1:
            # Next day - increment streak
            progress.streak_days += 1
            progress.last_streak_update = now
            if progress.streak_days > progress.max_streak:
                progress.max_streak = progress.streak_days
        elif days_diff == 2 and progress.streak_freezes > 0 and not progress.streak_freeze_used_today:
            # 2-day gap but user has a streak shield available - use it automatically
            progress.streak_freezes -= 1
            progress.streak_freeze_used_today = True
            progress.last_streak_update = now
            # Streak preserved!
        else:
            # Gap too large or no shield available - reset streak
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

    # Check for achievement unlocks BEFORE committing
    # (so achievements are added to the same transaction)
    progress_data = {
        "total_lessons": progress.total_lessons,
        "streak_days": progress.streak_days,
        "xp_total": progress.xp_total,
        "level": new_level,
        "coins": progress.coins,
        # TODO: Add perfect_lessons tracking
    }

    newly_unlocked: list[UserAchievement] = []
    try:
        newly_unlocked = await check_and_unlock_achievements(session, current_user.id, progress_data)
        if newly_unlocked:
            print(f"[SUCCESS] {len(newly_unlocked)} achievements unlocked for user {current_user.id}")
    except Exception as e:
        print(f"[ERROR] Error checking achievements for user {current_user.id}: {e}")
        import traceback

        traceback.print_exc()

    # Commit everything: progress update, learning event, AND newly unlocked achievements
    await session.commit()
    await session.refresh(progress)

    # Get updated progress and add newly unlocked achievements
    progress_response = await get_user_progress(current_user, session)

    # Populate newly unlocked achievements if any
    if newly_unlocked:
        progress_response.newly_unlocked_achievements = [
            UserAchievementResponse.model_validate(ach) for ach in newly_unlocked
        ]

    return progress_response


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
    """Purchase a streak shield with coins.

    Cost: 100 coins per streak shield.
    Streak shields protect your streak if you miss a day.
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

    # Deduct coins and add streak shield
    progress.coins -= STREAK_FREEZE_COST
    progress.streak_freezes += 1

    await session.commit()
    await session.refresh(progress)

    return {
        "success": True,
        "coins_remaining": progress.coins,
        "streak_freezes": progress.streak_freezes,
        "message": "Streak shield purchased successfully!",
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


@router.post("/me/power-ups/xp-boost/buy")
async def buy_xp_boost(
    current_user: User = Depends(get_current_user),
    session: AsyncSession = Depends(get_session),
) -> dict:
    """Purchase a 2x XP Boost power-up with coins.

    Cost: 150 coins
    Effect: Double XP for 30 minutes (tracked client-side or via active_boosts table)
    """
    XP_BOOST_COST = 150

    result = await session.execute(
        select(UserProgress).where(UserProgress.user_id == current_user.id).with_for_update()
    )
    progress = result.scalar_one_or_none()

    if not progress:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Progress not found")

    if progress.coins < XP_BOOST_COST:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Not enough coins. Need {XP_BOOST_COST}, have {progress.coins}",
        )

    # Deduct coins and add XP boost
    progress.coins -= XP_BOOST_COST
    progress.xp_boost_2x += 1

    await session.commit()
    await session.refresh(progress)

    return {
        "success": True,
        "coins_remaining": progress.coins,
        "xp_boosts": progress.xp_boost_2x,
        "message": "2x XP Boost purchased! Activate it for 30 minutes of double XP.",
    }


@router.post("/me/power-ups/hint-reveal/buy")
async def buy_hint_reveal(
    current_user: User = Depends(get_current_user),
    session: AsyncSession = Depends(get_session),
) -> dict:
    """Purchase a Hint Reveal power-up with coins.

    Cost: 50 coins
    Effect: Reveals a hint for any exercise (tracked in perfect_protection counter)
    """
    HINT_COST = 50

    result = await session.execute(
        select(UserProgress).where(UserProgress.user_id == current_user.id).with_for_update()
    )
    progress = result.scalar_one_or_none()

    if not progress:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Progress not found")

    if progress.coins < HINT_COST:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Not enough coins. Need {HINT_COST}, have {progress.coins}",
        )

    # Deduct coins and add hint
    progress.coins -= HINT_COST
    progress.perfect_protection += 1

    await session.commit()
    await session.refresh(progress)

    return {
        "success": True,
        "coins_remaining": progress.coins,
        "hints_available": progress.perfect_protection,
        "message": "Hint Reveal purchased! Use it on any tricky exercise.",
    }


@router.post("/me/power-ups/time-warp/buy")
async def buy_time_warp(
    current_user: User = Depends(get_current_user),
    session: AsyncSession = Depends(get_session),
) -> dict:
    """Purchase a Time Warp (Skip Question) power-up with coins.

    Cost: 100 coins
    Effect: Skip any difficult question and mark it correct
    """
    TIME_WARP_COST = 100

    result = await session.execute(
        select(UserProgress).where(UserProgress.user_id == current_user.id).with_for_update()
    )
    progress = result.scalar_one_or_none()

    if not progress:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Progress not found")

    if progress.coins < TIME_WARP_COST:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Not enough coins. Need {TIME_WARP_COST}, have {progress.coins}",
        )

    # Deduct coins and add time warp
    progress.coins -= TIME_WARP_COST
    progress.time_warp += 1

    await session.commit()
    await session.refresh(progress)

    return {
        "success": True,
        "coins_remaining": progress.coins,
        "skips_available": progress.time_warp,
        "message": "Skip Question purchased! Use it to skip any difficult question.",
    }


# ---------------------------------------------------------------------
# Power-Up Activation Endpoints
# ---------------------------------------------------------------------


@router.post("/me/power-ups/xp-boost/activate")
async def activate_xp_boost(
    current_user: User = Depends(get_current_user),
    session: AsyncSession = Depends(get_session),
) -> dict:
    """Activate a 2x XP Boost for 30 minutes.

    Returns:
        - success: bool
        - expires_at: ISO timestamp when boost expires
        - message: success message
    """
    result = await session.execute(
        select(UserProgress).where(UserProgress.user_id == current_user.id).with_for_update()
    )
    progress = result.scalar_one_or_none()

    if not progress:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Progress not found")

    if progress.xp_boost_2x <= 0:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="No 2x XP Boosts available. Purchase one from the shop!",
        )

    # Consume one boost
    progress.xp_boost_2x -= 1

    # Calculate expiration (30 minutes from now)
    now = datetime.now(timezone.utc)
    expires_at = now + timedelta(minutes=30)

    await session.commit()
    await session.refresh(progress)

    return {
        "success": True,
        "expires_at": expires_at.isoformat(),
        "xp_boosts_remaining": progress.xp_boost_2x,
        "message": "2x XP Boost activated! You'll earn double XP for 30 minutes.",
    }


@router.post("/me/power-ups/hint/use")
async def use_hint(
    current_user: User = Depends(get_current_user),
    session: AsyncSession = Depends(get_session),
) -> dict:
    """Use a hint to reveal answer help.

    Consumes one hint from the user's inventory.
    """
    result = await session.execute(
        select(UserProgress).where(UserProgress.user_id == current_user.id).with_for_update()
    )
    progress = result.scalar_one_or_none()

    if not progress:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Progress not found")

    if progress.perfect_protection <= 0:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="No hints available. Purchase hints from the shop!",
        )

    # Consume one hint
    progress.perfect_protection -= 1

    await session.commit()
    await session.refresh(progress)

    return {
        "success": True,
        "hints_remaining": progress.perfect_protection,
        "message": "Hint revealed!",
    }


@router.post("/me/power-ups/skip/use")
async def use_skip(
    current_user: User = Depends(get_current_user),
    session: AsyncSession = Depends(get_session),
) -> dict:
    """Use a skip to bypass a difficult question.

    Consumes one skip from the user's inventory.
    """
    result = await session.execute(
        select(UserProgress).where(UserProgress.user_id == current_user.id).with_for_update()
    )
    progress = result.scalar_one_or_none()

    if not progress:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Progress not found")

    if progress.time_warp <= 0:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="No skips available. Purchase skips from the shop!",
        )

    # Consume one skip
    progress.time_warp -= 1

    await session.commit()
    await session.refresh(progress)

    return {
        "success": True,
        "skips_remaining": progress.time_warp,
        "message": "Question skipped!",
    }


@router.get("/me/history")
async def get_lesson_history(
    current_user: User = Depends(get_current_user),
    session: AsyncSession = Depends(get_session),
    limit: int = 50,
    offset: int = 0,
) -> dict:
    """Get user's lesson history with pagination.

    Returns the most recent lessons completed by the user.
    """
    result = await session.execute(
        select(LearningEvent)
        .where(
            LearningEvent.user_id == current_user.id,
            LearningEvent.event_type == "lesson_complete",
        )
        .order_by(LearningEvent.event_timestamp.desc())
        .limit(limit)
        .offset(offset)
    )
    events = result.scalars().all()

    return {
        "lessons": [
            {
                "id": event.id,
                "lesson_id": event.data.get("lesson_id") if event.data else None,
                "timestamp": event.event_timestamp.isoformat(),
                "xp_gained": event.data.get("xp_gained", 0) if event.data else 0,
                "time_spent_minutes": event.data.get("time_spent_minutes", 0) if event.data else 0,
                "level_up": event.data.get("level_up", False) if event.data else False,
                "old_level": event.data.get("old_level", 0) if event.data else 0,
                "new_level": event.data.get("new_level", 0) if event.data else 0,
            }
            for event in events
        ],
        "total": len(events),
        "limit": limit,
        "offset": offset,
    }


__all__ = ["router"]
