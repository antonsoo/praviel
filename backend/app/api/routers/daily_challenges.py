"""Daily challenges API endpoints for engagement boost."""

import logging
from datetime import UTC, datetime, timedelta, timezone
from typing import List

from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel
from sqlalchemy import and_, desc, func, or_, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.db.session import get_db
from app.db.social_models import ChallengeStreak, DailyChallenge, DoubleOrNothing, WeeklyChallenge
from app.db.user_models import User, UserProgress
from app.security.auth import get_current_user

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/challenges", tags=["Daily Challenges"])

# ---------------------------------------------------------------------
# Pydantic Models
# ---------------------------------------------------------------------


class DailyChallengeResponse(BaseModel):
    """Daily challenge data."""

    id: int
    challenge_type: str
    difficulty: str
    title: str
    description: str
    target_value: int
    current_progress: int
    coin_reward: int
    xp_reward: int
    is_completed: bool
    is_weekend_bonus: bool
    expires_at: datetime
    completed_at: datetime | None = None


class ChallengeStreakResponse(BaseModel):
    """Challenge streak data."""

    current_streak: int
    longest_streak: int
    total_days_completed: int
    last_completion_date: datetime
    is_active_today: bool


class ChallengeProgressUpdate(BaseModel):
    """Update progress on a challenge."""

    challenge_id: int
    increment: int


class ChallengeLeaderboardEntry(BaseModel):
    """Leaderboard entry for challenge completion."""

    user_id: int
    username: str
    challenges_completed: int
    current_streak: int
    longest_streak: int
    total_rewards: int
    rank: int


class ChallengeLeaderboardResponse(BaseModel):
    """Challenge leaderboard response."""

    entries: List[ChallengeLeaderboardEntry]
    user_rank: int
    total_users: int


# ---------------------------------------------------------------------
# Daily Challenge Endpoints
# ---------------------------------------------------------------------


@router.get("/daily", response_model=List[DailyChallengeResponse])
async def get_daily_challenges(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Get user's active daily challenges.

    Challenges expire after 24 hours and are auto-generated daily.
    """
    now = datetime.now(timezone.utc)

    # Get active challenges (not expired, not completed)
    query = (
        select(DailyChallenge)
        .where(
            and_(
                DailyChallenge.user_id == current_user.id,
                DailyChallenge.expires_at > now,
            )
        )
        .order_by(DailyChallenge.difficulty, DailyChallenge.created_at)
    )

    result = await db.execute(query)
    challenges = result.scalars().all()

    # If no challenges exist, generate new ones
    if not challenges:
        challenges = await _generate_daily_challenges(current_user, db)

    return [
        DailyChallengeResponse(
            id=c.id,
            challenge_type=c.challenge_type,
            difficulty=c.difficulty,
            title=c.title,
            description=c.description,
            target_value=c.target_value,
            current_progress=c.current_progress,
            coin_reward=c.coin_reward,
            xp_reward=c.xp_reward,
            is_completed=c.is_completed,
            is_weekend_bonus=c.is_weekend_bonus,
            expires_at=c.expires_at,
            completed_at=c.completed_at,
        )
        for c in challenges
    ]


@router.post("/update-progress", response_model=dict)
async def update_challenge_progress(
    update: ChallengeProgressUpdate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Update progress on a specific challenge."""
    # Get the challenge
    query = select(DailyChallenge).where(
        and_(
            DailyChallenge.id == update.challenge_id,
            DailyChallenge.user_id == current_user.id,
        )
    )

    result = await db.execute(query)
    challenge = result.scalar_one_or_none()

    if not challenge:
        raise HTTPException(status_code=404, detail="Challenge not found")

    if challenge.is_completed:
        return {"message": "Challenge already completed", "rewards_granted": False}

    # Update progress
    challenge.current_progress += update.increment
    was_completed = False

    # Check if just completed
    if challenge.current_progress >= challenge.target_value and not challenge.is_completed:
        challenge.is_completed = True
        challenge.completed_at = datetime.now(timezone.utc)
        was_completed = True

        # Grant rewards
        progress_query = select(UserProgress).where(UserProgress.user_id == current_user.id)
        progress_result = await db.execute(progress_query)
        progress = progress_result.scalar_one_or_none()

        if progress:
            progress.xp_total += challenge.xp_reward
            progress.coins += challenge.coin_reward  # Now persisted to database!

            # ADAPTIVE DIFFICULTY: Update performance stats
            await _update_performance_stats(progress, challenge, completed=True)

    await db.commit()

    # Check if all challenges completed today for streak update
    if was_completed:
        await _check_and_update_streak(current_user, db)

    # Get updated coins balance
    final_progress_query = select(UserProgress).where(UserProgress.user_id == current_user.id)
    final_progress_result = await db.execute(final_progress_query)
    final_progress = final_progress_result.scalar_one_or_none()
    coins_remaining = final_progress.coins if final_progress else 0

    return {
        "message": "Progress updated",
        "current_progress": challenge.current_progress,
        "is_completed": challenge.is_completed,
        "rewards_granted": was_completed,
        "coin_reward": challenge.coin_reward if was_completed else 0,
        "xp_reward": challenge.xp_reward if was_completed else 0,
        "coins_remaining": coins_remaining,
    }


@router.get("/streak", response_model=ChallengeStreakResponse)
async def get_challenge_streak(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Get user's challenge completion streak."""
    query = select(ChallengeStreak).where(ChallengeStreak.user_id == current_user.id)

    result = await db.execute(query)
    streak = result.scalar_one_or_none()

    if not streak:
        # Create initial streak record
        streak = ChallengeStreak(
            user_id=current_user.id,
            current_streak=0,
            longest_streak=0,
            total_days_completed=0,
            last_completion_date=datetime.now(timezone.utc),
            is_active_today=False,
        )
        db.add(streak)
        await db.commit()
        await db.refresh(streak)

    return ChallengeStreakResponse(
        current_streak=streak.current_streak,
        longest_streak=streak.longest_streak,
        total_days_completed=streak.total_days_completed,
        last_completion_date=streak.last_completion_date,
        is_active_today=streak.is_active_today,
    )


@router.get("/leaderboard", response_model=ChallengeLeaderboardResponse)
async def get_challenge_leaderboard(
    limit: int = 50,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Get challenge completion leaderboard.

    Ranks users by:
    1. Current streak (primary)
    2. Total challenges completed (secondary)
    """
    # Build leaderboard query
    query = (
        select(
            ChallengeStreak.user_id,
            ChallengeStreak.current_streak,
            ChallengeStreak.longest_streak,
            ChallengeStreak.total_days_completed,
            User.username,
            func.count(DailyChallenge.id).label("challenges_completed"),
            func.sum(DailyChallenge.coin_reward).label("total_rewards"),
        )
        .join(User, User.id == ChallengeStreak.user_id)
        .outerjoin(
            DailyChallenge,
            and_(
                DailyChallenge.user_id == ChallengeStreak.user_id,
                DailyChallenge.is_completed == True,  # noqa: E712
            ),
        )
        .where(User.is_active == True)  # noqa: E712
        .group_by(
            ChallengeStreak.user_id,
            ChallengeStreak.current_streak,
            ChallengeStreak.longest_streak,
            ChallengeStreak.total_days_completed,
            User.username,
        )
        .order_by(desc(ChallengeStreak.current_streak), desc("challenges_completed"))
        .limit(limit)
    )

    result = await db.execute(query)
    rows = result.fetchall()

    # Build leaderboard entries
    entries = []
    user_rank = None
    for rank, row in enumerate(rows, start=1):
        user_id, current_streak, longest_streak, total_days, username, challenges_completed, total_rewards = (
            row
        )

        if user_id == current_user.id:
            user_rank = rank

        entries.append(
            ChallengeLeaderboardEntry(
                user_id=user_id,
                username=username,
                challenges_completed=challenges_completed or 0,
                current_streak=current_streak,
                longest_streak=longest_streak,
                total_rewards=total_rewards or 0,
                rank=rank,
            )
        )

    # If user not in top N, find their rank
    if user_rank is None:
        # Count users with better streaks/challenges
        count_query = select(func.count()).select_from(
            select(ChallengeStreak.user_id)
            .join(User)
            .where(
                and_(
                    User.is_active == True,  # noqa: E712
                    or_(
                        ChallengeStreak.current_streak
                        > (
                            select(ChallengeStreak.current_streak).where(
                                ChallengeStreak.user_id == current_user.id
                            )
                        ),
                        and_(
                            ChallengeStreak.current_streak
                            == (
                                select(ChallengeStreak.current_streak).where(
                                    ChallengeStreak.user_id == current_user.id
                                )
                            ),
                            ChallengeStreak.total_days_completed
                            > (
                                select(ChallengeStreak.total_days_completed).where(
                                    ChallengeStreak.user_id == current_user.id
                                )
                            ),
                        ),
                    ),
                )
            )
            .subquery()
        )

        count_result = await db.execute(count_query)
        count = count_result.scalar() or 0
        user_rank = count + 1

    # Total users
    total_query = select(func.count(ChallengeStreak.user_id)).join(User).where(User.is_active == True)  # noqa: E712
    total_result = await db.execute(total_query)
    total_users = total_result.scalar() or 0

    return ChallengeLeaderboardResponse(
        entries=entries,
        user_rank=user_rank,
        total_users=total_users,
    )


@router.post("/purchase-streak-freeze", response_model=dict)
async def purchase_streak_freeze(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Purchase a streak freeze for 200 coins (Duolingo uses 50 gems).

    Research shows streak freeze reduces churn by 21%!
    """
    STREAK_FREEZE_COST = 200  # coins

    # Get user progress
    progress_query = select(UserProgress).where(UserProgress.user_id == current_user.id)
    progress_result = await db.execute(progress_query)
    progress = progress_result.scalar_one_or_none()

    if not progress:
        raise HTTPException(status_code=404, detail="User progress not found")

    if progress.coins < STREAK_FREEZE_COST:
        raise HTTPException(
            status_code=400,
            detail=f"Insufficient coins. Need {STREAK_FREEZE_COST}, have {progress.coins}",
        )

    # Deduct coins and add streak freeze
    progress.coins -= STREAK_FREEZE_COST
    progress.streak_freezes += 1

    await db.commit()

    return {
        "message": "Streak freeze purchased!",
        "streak_freezes_owned": progress.streak_freezes,
        "coins_remaining": progress.coins,
    }


@router.post("/use-streak-freeze", response_model=dict)
async def use_streak_freeze(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Automatically use a streak freeze when user misses a day.

    This endpoint would be called by a daily cron job or when user logs in
    after missing a day.
    """
    # Get user progress
    progress_query = select(UserProgress).where(UserProgress.user_id == current_user.id)
    progress_result = await db.execute(progress_query)
    progress = progress_result.scalar_one_or_none()

    if not progress:
        raise HTTPException(status_code=404, detail="User progress not found")

    if progress.streak_freezes <= 0:
        return {
            "message": "No streak freezes available",
            "streak_lost": True,
            "new_streak": 0,
        }

    # Use a streak freeze
    progress.streak_freezes -= 1
    progress.streak_freeze_used_today = True

    await db.commit()

    return {
        "message": "Streak freeze activated! Your streak is protected for today.",
        "streak_freezes_remaining": progress.streak_freezes,
        "streak_protected": True,
        "current_streak": progress.streak_days,
    }


@router.post("/double-or-nothing/start", response_model=dict)
async def start_double_or_nothing(
    wager: int,
    days: int = 7,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Start a Double or Nothing challenge.

    Wager coins to commit to N days of daily goals. Win 2x back if successful!
    Duolingo data shows this mechanic massively boosts commitment.
    """
    if days not in [7, 14, 30]:
        raise HTTPException(status_code=400, detail="Days must be 7, 14, or 30")

    if wager < 100:
        raise HTTPException(status_code=400, detail="Minimum wager is 100 coins")

    # Get user progress
    progress_query = select(UserProgress).where(UserProgress.user_id == current_user.id)
    progress_result = await db.execute(progress_query)
    progress = progress_result.scalar_one_or_none()

    if not progress:
        raise HTTPException(status_code=404, detail="User progress not found")

    if progress.coins < wager:
        raise HTTPException(
            status_code=400,
            detail=f"Insufficient coins. Need {wager}, have {progress.coins}",
        )

    # Check for active challenge
    active_query = select(DoubleOrNothing).where(
        and_(
            DoubleOrNothing.user_id == current_user.id,
            DoubleOrNothing.is_active == True,  # noqa: E712
        )
    )
    active_result = await db.execute(active_query)
    active_challenge = active_result.scalar_one_or_none()

    if active_challenge:
        raise HTTPException(
            status_code=400,
            detail=(
                f"You already have an active Double or Nothing challenge "
                f"({active_challenge.days_completed}/{active_challenge.days_required} days)"
            ),
        )

    # Deduct wager and create challenge
    progress.coins -= wager

    challenge = DoubleOrNothing(
        user_id=current_user.id,
        wager_amount=wager,
        days_required=days,
        days_completed=0,
        is_active=True,
    )
    db.add(challenge)

    await db.commit()

    return {
        "message": (
            f"Double or Nothing started! Complete your goals for {days} days to win {wager * 2} coins!"
        ),
        "challenge_id": challenge.id,
        "wager": wager,
        "potential_reward": wager * 2,
        "days_required": days,
        "coins_remaining": progress.coins,
    }


@router.get("/double-or-nothing/status", response_model=dict)
async def get_double_or_nothing_status(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Get status of active Double or Nothing challenge."""
    active_query = select(DoubleOrNothing).where(
        and_(
            DoubleOrNothing.user_id == current_user.id,
            DoubleOrNothing.is_active == True,  # noqa: E712
        )
    )
    active_result = await db.execute(active_query)
    challenge = active_result.scalar_one_or_none()

    if not challenge:
        return {
            "has_active_challenge": False,
            "message": "No active Double or Nothing challenge",
        }

    return {
        "has_active_challenge": True,
        "challenge_id": challenge.id,
        "wager_amount": challenge.wager_amount,
        "potential_reward": challenge.wager_amount * 2,
        "days_required": challenge.days_required,
        "days_completed": challenge.days_completed,
        "days_remaining": challenge.days_required - challenge.days_completed,
        "started_at": challenge.started_at,
    }


@router.post("/double-or-nothing/complete-day", response_model=dict)
async def complete_double_or_nothing_day(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Mark a day as completed for active double-or-nothing challenge.

    Called when user completes all daily challenges.
    Automatically awards 2x coins if challenge is completed.
    """
    active_query = select(DoubleOrNothing).where(
        and_(
            DoubleOrNothing.user_id == current_user.id,
            DoubleOrNothing.is_active == True,  # noqa: E712
        )
    )
    active_result = await db.execute(active_query)
    challenge = active_result.scalar_one_or_none()

    if not challenge:
        raise HTTPException(status_code=404, detail="No active double-or-nothing challenge")

    # Increment days completed
    challenge.days_completed += 1
    await db.flush()

    # Check if challenge is now complete
    if challenge.days_completed >= challenge.days_required:
        # Award 2x coins!
        reward = challenge.wager_amount * 2

        # Get user progress
        progress_query = select(UserProgress).where(UserProgress.user_id == current_user.id)
        progress_result = await db.execute(progress_query)
        progress = progress_result.scalar_one_or_none()

        if progress:
            progress.coins += reward
            challenge.completed_at = datetime.now(UTC)
            challenge.is_active = False
            await db.commit()

            return {
                "success": True,
                "days_completed": challenge.days_completed,
                "days_required": challenge.days_required,
                "challenge_completed": True,
                "coins_awarded": reward,
                "coins_remaining": progress.coins,
                "message": f"Double-or-nothing complete! Won {reward} coins! 🎉",
            }

    # Not complete yet
    await db.commit()
    return {
        "success": True,
        "days_completed": challenge.days_completed,
        "days_required": challenge.days_required,
        "challenge_completed": False,
        "coins_awarded": None,
        "message": f"Day {challenge.days_completed}/{challenge.days_required} complete!",
    }


# ---------------------------------------------------------------------
# Helper Functions
# ---------------------------------------------------------------------


def _calculate_adaptive_difficulty(progress: UserProgress) -> str:
    """Calculate optimal difficulty based on user performance.

    Research shows adaptive difficulty increases DAU by 47%!
    Algorithm based on ML personalization best practices.
    """
    if not progress:
        return "medium"

    success_rate = progress.challenge_success_rate
    consecutive_successes = progress.consecutive_successes
    consecutive_failures = progress.consecutive_failures

    # New users: start medium
    if progress.total_challenges_attempted < 5:
        return "medium"

    # Adaptive algorithm
    # Success rate > 80% AND 3+ consecutive successes → increase difficulty
    if success_rate >= 0.8 and consecutive_successes >= 3:
        return "hard"

    # Success rate > 90% AND 5+ consecutive successes → epic difficulty
    if success_rate >= 0.9 and consecutive_successes >= 5:
        return "epic"

    # Success rate < 40% OR 3+ consecutive failures → decrease difficulty
    if success_rate < 0.4 or consecutive_failures >= 3:
        return "easy"

    # Success rate < 60% AND 2+ consecutive failures → easy
    if success_rate < 0.6 and consecutive_failures >= 2:
        return "easy"

    # Sweet spot: 60-80% success rate → medium (optimal engagement)
    return "medium"


async def _update_performance_stats(
    progress: UserProgress, challenge: DailyChallenge, completed: bool
) -> None:
    """Update user performance stats for adaptive difficulty."""
    progress.total_challenges_attempted += 1

    if completed:
        progress.total_challenges_completed += 1
        progress.consecutive_successes += 1
        progress.consecutive_failures = 0
    else:
        progress.consecutive_failures += 1
        progress.consecutive_successes = 0

    # Recalculate success rate
    if progress.total_challenges_attempted > 0:
        progress.challenge_success_rate = (
            progress.total_challenges_completed / progress.total_challenges_attempted
        )

    # Update preferred difficulty
    progress.preferred_difficulty = _calculate_adaptive_difficulty(progress)


async def _generate_daily_challenges(user: User, db: AsyncSession) -> List[DailyChallenge]:
    """Generate new daily challenges for a user."""
    now = datetime.now(timezone.utc)
    tomorrow = (now + timedelta(days=1)).replace(hour=0, minute=0, second=0, microsecond=0)

    # Check if it's weekend
    is_weekend = now.weekday() in [5, 6]  # Saturday=5, Sunday=6
    reward_multiplier = 2.0 if is_weekend else 1.0

    # Get user's level and adaptive difficulty
    progress_query = select(UserProgress).where(UserProgress.user_id == user.id)
    progress_result = await db.execute(progress_query)
    progress = progress_result.scalar_one_or_none()
    user_level = progress.level if progress else 1

    # ADAPTIVE DIFFICULTY: Calculate optimal challenge difficulty
    adaptive_difficulty = _calculate_adaptive_difficulty(progress) if progress else "medium"

    # Difficulty multipliers for targets and rewards
    diff_multipliers = {
        "easy": 0.7,
        "medium": 1.0,
        "hard": 1.5,
        "epic": 2.5,
    }
    diff_mult = diff_multipliers.get(adaptive_difficulty, 1.0)

    # Generate challenges with adaptive difficulty
    challenges = []

    # Challenge 1 - lessons completed (adapts to user performance)
    lessons_target = max(1, int(2 * diff_mult))
    challenge_1 = DailyChallenge(
        user_id=user.id,
        challenge_type="lessons_completed",
        difficulty=adaptive_difficulty,
        title=f"{'🎉 Weekend ' if is_weekend else ''}{adaptive_difficulty.title()} Learner",
        description=f"Complete {lessons_target} lessons today",
        target_value=lessons_target,
        current_progress=0,
        coin_reward=int(50 * reward_multiplier * diff_mult),
        xp_reward=int(25 * reward_multiplier * diff_mult),
        is_weekend_bonus=is_weekend,
        expires_at=tomorrow,
    )
    challenges.append(challenge_1)

    # Medium challenge - XP earned
    # Fix: Ensure minimum target of 50 XP for level 0/1 users
    xp_target = max(50, user_level * 50)
    medium_challenge = DailyChallenge(
        user_id=user.id,
        challenge_type="xp_earned",
        difficulty="medium",
        title=f"{'🎉 Weekend ' if is_weekend else ''}XP Hunter",
        description=f"Earn {xp_target} XP today",
        target_value=xp_target,
        current_progress=0,
        coin_reward=int(100 * reward_multiplier),
        xp_reward=int(50 * reward_multiplier),
        is_weekend_bonus=is_weekend,
        expires_at=tomorrow,
    )
    challenges.append(medium_challenge)

    # Hard challenge (if user level >= 3)
    if user_level >= 3:
        hard_challenge = DailyChallenge(
            user_id=user.id,
            challenge_type="perfect_score",
            difficulty="hard",
            title=f"{'🎉 Weekend ' if is_weekend else ''}Perfectionist",
            description="Get perfect score on 3 lessons",
            target_value=3,
            current_progress=0,
            coin_reward=int(200 * reward_multiplier),
            xp_reward=int(100 * reward_multiplier),
            is_weekend_bonus=is_weekend,
            expires_at=tomorrow,
        )
        challenges.append(hard_challenge)

    # Streak challenge
    streak_challenge = DailyChallenge(
        user_id=user.id,
        challenge_type="streak_maintain",
        difficulty="medium",
        title=f"{'🎉 Weekend ' if is_weekend else ''}Streak Keeper",
        description="Maintain your streak today",
        target_value=1,
        current_progress=0,
        coin_reward=int(75 * reward_multiplier),
        xp_reward=int(30 * reward_multiplier),
        is_weekend_bonus=is_weekend,
        expires_at=tomorrow,
    )
    challenges.append(streak_challenge)

    # Add all to database
    for challenge in challenges:
        db.add(challenge)

    await db.commit()

    # Refresh to get IDs
    for challenge in challenges:
        await db.refresh(challenge)

    return challenges


async def _check_and_update_streak(user: User, db: AsyncSession):
    """Check if all challenges completed and update streak."""
    now = datetime.now(timezone.utc)

    # Get today's challenges
    today_query = select(DailyChallenge).where(
        and_(
            DailyChallenge.user_id == user.id,
            DailyChallenge.expires_at > now,
        )
    )

    today_result = await db.execute(today_query)
    today_challenges = today_result.scalars().all()

    # Check if all completed
    all_completed = all(c.is_completed for c in today_challenges)

    if all_completed:
        # Get or create streak
        streak_query = select(ChallengeStreak).where(ChallengeStreak.user_id == user.id)
        streak_result = await db.execute(streak_query)
        streak = streak_result.scalar_one_or_none()

        if not streak:
            streak = ChallengeStreak(
                user_id=user.id,
                current_streak=0,
                longest_streak=0,
                total_days_completed=0,
            )
            db.add(streak)

        # Check if already counted today
        if not streak.is_active_today:
            # Increment streak
            streak.current_streak += 1
            streak.total_days_completed += 1
            streak.last_completion_date = now
            streak.is_active_today = True

            # Update longest streak if needed
            if streak.current_streak > streak.longest_streak:
                streak.longest_streak = streak.current_streak

            # Grant milestone bonuses
            milestone_rewards = {
                7: (100, 50),  # 7 days: 100 coins, 50 XP
                30: (500, 250),  # 30 days: 500 coins, 250 XP
                100: (2000, 1000),  # 100 days: 2000 coins, 1000 XP
            }

            if streak.current_streak in milestone_rewards:
                coins, xp = milestone_rewards[streak.current_streak]
                # Grant XP
                progress_query = select(UserProgress).where(UserProgress.user_id == user.id)
                progress_result = await db.execute(progress_query)
                progress = progress_result.scalar_one_or_none()
                if progress:
                    progress.xp_total += xp

            await db.commit()


# ---------------------------------------------------------------------
# Weekly Special Challenges - Limited-time 5-10x rewards
# ---------------------------------------------------------------------


class WeeklyChallengeResponse(BaseModel):
    """Weekly challenge data."""

    id: int
    challenge_type: str
    difficulty: str
    title: str
    description: str
    target_value: int
    current_progress: int
    coin_reward: int
    xp_reward: int
    is_completed: bool
    completed_at: datetime | None
    expires_at: datetime
    week_start: datetime
    reward_multiplier: float
    is_special_event: bool
    days_remaining: int


@router.get("/weekly", response_model=List[WeeklyChallengeResponse])
async def get_weekly_challenges(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Get user's weekly special challenges with 5-10x rewards.

    Research shows limited-time offers boost engagement by 25-35% (Temu, Starbucks case studies).
    Weekly challenges run Monday-Sunday and auto-generate if none exist.
    """
    try:
        logger.info(f"GET /weekly - User {current_user.id} requesting weekly challenges")
        now = datetime.now(timezone.utc)

        # Get current week's challenges (not expired)
        query = (
            select(WeeklyChallenge)
            .where(
                and_(
                    WeeklyChallenge.user_id == current_user.id,
                    WeeklyChallenge.expires_at > now,
                )
            )
            .order_by(WeeklyChallenge.created_at)
        )

        result = await db.execute(query)
        challenges = result.scalars().all()
        logger.info(f"Found {len(challenges)} existing weekly challenges")

        # Auto-generate if no active challenges
        if not challenges:
            logger.info("No active challenges, generating new ones...")
            challenges = await _generate_weekly_challenges(current_user, db)
            await db.commit()
            logger.info(f"Generated {len(challenges)} new weekly challenges")

        # Calculate days remaining and convert to response
        response = []
        for c in challenges:
            days_remaining = max(0, (c.expires_at - now).days)
            response.append(
                WeeklyChallengeResponse(
                    id=c.id,
                    challenge_type=c.challenge_type,
                    difficulty=c.difficulty,
                    title=c.title,
                    description=c.description,
                    target_value=c.target_value,
                    current_progress=c.current_progress,
                    coin_reward=c.coin_reward,
                    xp_reward=c.xp_reward,
                    is_completed=c.is_completed,
                    completed_at=c.completed_at,
                    expires_at=c.expires_at,
                    week_start=c.week_start,
                    reward_multiplier=c.reward_multiplier,
                    is_special_event=c.is_special_event,
                    days_remaining=days_remaining,
                )
            )

        logger.info(f"Returning {len(response)} weekly challenges")
        return response
    except Exception as e:
        logger.error(f"Error in get_weekly_challenges: {type(e).__name__}: {e}", exc_info=True)
        raise


@router.post("/weekly/update-progress", response_model=dict)
async def update_weekly_challenge_progress(
    progress: ChallengeProgressUpdate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Update progress on a weekly challenge and grant rewards if completed."""
    # Get challenge
    query = select(WeeklyChallenge).where(
        and_(
            WeeklyChallenge.id == progress.challenge_id,
            WeeklyChallenge.user_id == current_user.id,
        )
    )

    result = await db.execute(query)
    challenge = result.scalar_one_or_none()

    if not challenge:
        raise HTTPException(status_code=404, detail="Weekly challenge not found")

    if challenge.is_completed:
        raise HTTPException(status_code=400, detail="Challenge already completed")

    # Check if expired
    now = datetime.now(timezone.utc)
    if challenge.expires_at < now:
        raise HTTPException(status_code=400, detail="Challenge has expired")

    # Update progress
    challenge.current_progress = min(challenge.current_progress + progress.increment, challenge.target_value)

    # Check if completed
    completed = False
    if challenge.current_progress >= challenge.target_value:
        challenge.is_completed = True
        challenge.completed_at = now
        completed = True

        # Grant rewards
        progress_query = select(UserProgress).where(UserProgress.user_id == current_user.id)
        progress_result = await db.execute(progress_query)
        user_progress = progress_result.scalar_one_or_none()

        if user_progress:
            user_progress.xp_total += challenge.xp_reward
            user_progress.coins += challenge.coin_reward

    await db.commit()

    # Get updated coins balance
    final_progress_query = select(UserProgress).where(UserProgress.user_id == current_user.id)
    final_progress_result = await db.execute(final_progress_query)
    final_progress = final_progress_result.scalar_one_or_none()
    coins_remaining = final_progress.coins if final_progress else 0

    return {
        "success": True,
        "completed": completed,
        "current_progress": challenge.current_progress,
        "target_value": challenge.target_value,
        "rewards_granted": {"coins": challenge.coin_reward, "xp": challenge.xp_reward} if completed else None,
        "coins_remaining": coins_remaining,
    }


async def _generate_weekly_challenges(user: User, db: AsyncSession) -> List[WeeklyChallenge]:
    """Generate weekly special challenges with 5-10x rewards.

    Research shows:
    - Limited-time offers boost engagement by 25-35%
    - Scarcity and urgency drive action (Temu case study)
    - Weekly goals increase commitment by 40% (fitness apps)
    """
    now = datetime.now(timezone.utc)

    # Calculate this week's Monday and Sunday
    days_since_monday = now.weekday()
    week_start = (now - timedelta(days=days_since_monday)).replace(hour=0, minute=0, second=0, microsecond=0)
    expires_at = week_start + timedelta(days=6, hours=23, minutes=59, seconds=59)

    # Get user progress for adaptive difficulty
    progress_query = select(UserProgress).where(UserProgress.user_id == user.id)
    progress_result = await db.execute(progress_query)
    progress = progress_result.scalar_one_or_none()

    # Determine difficulty and multiplier
    adaptive_difficulty = _calculate_adaptive_difficulty(progress) if progress else "medium"

    # Reward multipliers (5x to 10x for weekly challenges)
    base_multipliers = {"easy": 5.0, "medium": 7.0, "hard": 9.0, "epic": 10.0}
    reward_mult = base_multipliers.get(adaptive_difficulty, 7.0)

    # Check for special events (holidays, weekends)
    is_special_event = False  # Can be enhanced with holiday detection

    # Generate 2 weekly challenges
    challenges = []

    # Challenge 1: Weekly Warrior - Complete N daily challenges this week
    daily_target = {"easy": 3, "medium": 5, "hard": 7, "epic": 7}[adaptive_difficulty]
    challenge_1 = WeeklyChallenge(
        user_id=user.id,
        challenge_type="weekly_warrior",
        difficulty=adaptive_difficulty,
        title=f"🏆 Weekly Warrior ({adaptive_difficulty.title()})",
        description=(
            f"Complete {daily_target} daily challenge sets before Sunday midnight to earn HUGE rewards!"
        ),
        target_value=daily_target,
        current_progress=0,
        coin_reward=int(500 * reward_mult),
        xp_reward=int(250 * reward_mult),
        is_completed=False,
        expires_at=expires_at,
        week_start=week_start,
        reward_multiplier=reward_mult,
        is_special_event=is_special_event,
    )

    # Challenge 2: Perfect Week - Maintain streak all week
    challenge_2 = WeeklyChallenge(
        user_id=user.id,
        challenge_type="perfect_week",
        difficulty=adaptive_difficulty,
        title=f"⭐ Perfect Week ({adaptive_difficulty.title()})",
        description="Don't break your streak all week! Complete at least 1 daily challenge every day.",
        target_value=7,
        current_progress=0,
        coin_reward=int(800 * reward_mult),
        xp_reward=int(400 * reward_mult),
        is_completed=False,
        expires_at=expires_at,
        week_start=week_start,
        reward_multiplier=reward_mult,
        is_special_event=is_special_event,
    )

    challenges.extend([challenge_1, challenge_2])
    db.add_all(challenges)

    # Flush to get IDs (don't commit yet - caller will commit)
    await db.flush()
    for challenge in challenges:
        await db.refresh(challenge)

    return challenges
