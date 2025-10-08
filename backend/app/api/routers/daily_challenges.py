"""Daily challenges API endpoints for engagement boost."""

from datetime import datetime, timedelta
from typing import List

from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel
from sqlalchemy import and_, desc, func, or_, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.db.session import get_db
from app.db.social_models import ChallengeStreak, DailyChallenge
from app.db.user_models import User, UserProgress
from app.security.auth import get_current_user

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
    now = datetime.utcnow()

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
        challenge.completed_at = datetime.utcnow()
        was_completed = True

        # Grant rewards
        progress_query = select(UserProgress).where(UserProgress.user_id == current_user.id)
        progress_result = await db.execute(progress_query)
        progress = progress_result.scalar_one_or_none()

        if progress:
            progress.xp_total += challenge.xp_reward
            # Note: Coins would be added to a separate coins system
            # For now, we're just tracking XP

    await db.commit()

    # Check if all challenges completed today for streak update
    if was_completed:
        await _check_and_update_streak(current_user, db)

    return {
        "message": "Progress updated",
        "current_progress": challenge.current_progress,
        "is_completed": challenge.is_completed,
        "rewards_granted": was_completed,
        "coin_reward": challenge.coin_reward if was_completed else 0,
        "xp_reward": challenge.xp_reward if was_completed else 0,
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
            last_completion_date=datetime.utcnow(),
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


# ---------------------------------------------------------------------
# Helper Functions
# ---------------------------------------------------------------------


async def _generate_daily_challenges(user: User, db: AsyncSession) -> List[DailyChallenge]:
    """Generate new daily challenges for a user."""
    now = datetime.utcnow()
    tomorrow = (now + timedelta(days=1)).replace(hour=0, minute=0, second=0, microsecond=0)

    # Check if it's weekend
    is_weekend = now.weekday() in [5, 6]  # Saturday=5, Sunday=6
    reward_multiplier = 2.0 if is_weekend else 1.0

    # Get user's level for difficulty scaling
    progress_query = select(UserProgress).where(UserProgress.user_id == user.id)
    progress_result = await db.execute(progress_query)
    progress = progress_result.scalar_one_or_none()
    user_level = progress.level if progress else 1

    # Generate challenges
    challenges = []

    # Easy challenge - lessons completed
    easy_challenge = DailyChallenge(
        user_id=user.id,
        challenge_type="lessons_completed",
        difficulty="easy",
        title=f"{'🎉 Weekend ' if is_weekend else ''}Quick Learner",
        description="Complete 2 lessons today",
        target_value=2,
        current_progress=0,
        coin_reward=int(50 * reward_multiplier),
        xp_reward=int(25 * reward_multiplier),
        is_weekend_bonus=is_weekend,
        expires_at=tomorrow,
    )
    challenges.append(easy_challenge)

    # Medium challenge - XP earned
    medium_challenge = DailyChallenge(
        user_id=user.id,
        challenge_type="xp_earned",
        difficulty="medium",
        title=f"{'🎉 Weekend ' if is_weekend else ''}XP Hunter",
        description=f"Earn {user_level * 50} XP today",
        target_value=user_level * 50,
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
    now = datetime.utcnow()

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
