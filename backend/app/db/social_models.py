"""Social features models for friend connections and leaderboards.

This module defines the social networking features including:
- Friend relationships
- Leaderboard rankings
- Friend challenges
- Daily challenges
- Challenge streaks
"""

from __future__ import annotations

from datetime import datetime

from sqlalchemy import (
    Boolean,
    DateTime,
    Float,
    ForeignKey,
    Index,
    Integer,
    String,
    Text,
    UniqueConstraint,
)
from sqlalchemy.orm import Mapped, mapped_column
from sqlalchemy.sql import func

from .models import Base, TimestampMixin

# ---------------------------------------------------------------------
# Social Features
# ---------------------------------------------------------------------


class Friendship(TimestampMixin, Base):
    """Represents a friendship connection between two users.

    Uses a bidirectional model where each friendship creates two records
    (one for each direction) to simplify queries.
    """

    __tablename__ = "friendship"

    id: Mapped[int] = mapped_column(primary_key=True)
    user_id: Mapped[int] = mapped_column(ForeignKey("user.id"), index=True)
    friend_id: Mapped[int] = mapped_column(ForeignKey("user.id"), index=True)

    # Status: pending, accepted, blocked
    status: Mapped[str] = mapped_column(String(20), default="pending")

    # Who initiated the request
    initiated_by_user_id: Mapped[int] = mapped_column(ForeignKey("user.id"))

    # When the friendship was accepted (if accepted)
    accepted_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), default=None)

    __table_args__ = (
        UniqueConstraint("user_id", "friend_id", name="uq_friendship"),
        Index("ix_friendship_user_status", "user_id", "status"),
    )

    def __repr__(self) -> str:  # pragma: no cover
        return f"<Friendship user_id={self.user_id} friend_id={self.friend_id} status={self.status}>"


class FriendChallenge(TimestampMixin, Base):
    """Represents a challenge between friends.

    Examples:
    - Race to 100 XP
    - Complete 5 lessons first
    - Maintain 7-day streak
    """

    __tablename__ = "friend_challenge"

    id: Mapped[int] = mapped_column(primary_key=True)

    # Participants
    initiator_user_id: Mapped[int] = mapped_column(ForeignKey("user.id"), index=True)
    opponent_user_id: Mapped[int] = mapped_column(ForeignKey("user.id"), index=True)

    # Challenge details
    challenge_type: Mapped[str] = mapped_column(String(50))  # "xp_race", "lesson_count", "streak"
    target_value: Mapped[int] = mapped_column(Integer)  # Target to reach

    # Progress tracking
    initiator_progress: Mapped[int] = mapped_column(Integer, default=0)
    opponent_progress: Mapped[int] = mapped_column(Integer, default=0)

    # Status
    status: Mapped[str] = mapped_column(String(20), default="pending")  # pending, active, completed, expired
    winner_user_id: Mapped[int | None] = mapped_column(ForeignKey("user.id"), default=None)

    # Timestamps
    starts_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())
    expires_at: Mapped[datetime] = mapped_column(DateTime(timezone=True))
    completed_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), default=None)

    __table_args__ = (
        Index("ix_challenge_status", "status"),
        Index("ix_challenge_participants", "initiator_user_id", "opponent_user_id"),
    )

    def __repr__(self) -> str:  # pragma: no cover
        return f"<FriendChallenge {self.challenge_type} {self.initiator_user_id} vs {self.opponent_user_id}>"


class LeaderboardEntry(Base):
    """Cached leaderboard rankings for fast queries.

    Updated periodically (e.g., every 5 minutes) to avoid expensive
    real-time calculations. Separate tables for different leaderboard types.
    """

    __tablename__ = "leaderboard_entry"

    id: Mapped[int] = mapped_column(primary_key=True)
    user_id: Mapped[int] = mapped_column(ForeignKey("user.id"), index=True)

    # Leaderboard type: "global", "regional", "friends"
    board_type: Mapped[str] = mapped_column(String(20), index=True)

    # Optional regional identifier (for local/regional boards)
    region: Mapped[str | None] = mapped_column(String(50), default=None)

    # Ranking data
    rank: Mapped[int] = mapped_column(Integer)
    xp_total: Mapped[int] = mapped_column(Integer)
    level: Mapped[int] = mapped_column(Integer)

    # When this entry was calculated
    calculated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        server_default=func.now(),
        index=True,
    )

    __table_args__ = (
        Index("ix_leaderboard_type_rank", "board_type", "rank"),
        Index("ix_leaderboard_user_type", "user_id", "board_type"),
        Index("ix_leaderboard_region", "board_type", "region", "rank"),
    )

    def __repr__(self) -> str:  # pragma: no cover
        return f"<LeaderboardEntry user_id={self.user_id} {self.board_type} rank={self.rank}>"


class PowerUpInventory(TimestampMixin, Base):
    """User's power-up inventory (streak shields, XP boosts, etc.)."""

    __tablename__ = "power_up_inventory"

    id: Mapped[int] = mapped_column(primary_key=True)
    user_id: Mapped[int] = mapped_column(ForeignKey("user.id"), index=True)

    # Power-up type
    power_up_type: Mapped[str] = mapped_column(String(50))  # "streak_freeze", "xp_boost", "hint_reveal"

    # Quantity owned
    quantity: Mapped[int] = mapped_column(Integer, default=0)

    # Active usage tracking
    active_count: Mapped[int] = mapped_column(Integer, default=0)  # Currently active instances

    __table_args__ = (UniqueConstraint("user_id", "power_up_type", name="uq_user_powerup"),)

    def __repr__(self) -> str:  # pragma: no cover
        return f"<PowerUpInventory user_id={self.user_id} {self.power_up_type} qty={self.quantity}>"


class PowerUpUsage(TimestampMixin, Base):
    """Log of power-up usage."""

    __tablename__ = "power_up_usage"

    id: Mapped[int] = mapped_column(primary_key=True)
    user_id: Mapped[int] = mapped_column(ForeignKey("user.id"), index=True)

    power_up_type: Mapped[str] = mapped_column(String(50), index=True)

    # When activated and when it expires
    activated_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())
    expires_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), default=None)

    # Whether still active
    is_active: Mapped[bool] = mapped_column(Boolean, default=True)

    __table_args__ = (Index("ix_powerup_usage_active", "user_id", "is_active"),)

    def __repr__(self) -> str:  # pragma: no cover
        return f"<PowerUpUsage user_id={self.user_id} {self.power_up_type} active={self.is_active}>"


class DailyChallenge(TimestampMixin, Base):
    """Represents a user's daily challenge.

    Daily challenges are auto-generated challenges that refresh every 24 hours,
    encouraging users to return daily and complete specific tasks.
    """

    __tablename__ = "daily_challenge"

    id: Mapped[int] = mapped_column(primary_key=True)
    user_id: Mapped[int] = mapped_column(ForeignKey("user.id"), index=True)

    # Challenge details
    challenge_type: Mapped[str] = mapped_column(String(50))  # lessons_completed, xp_earned, etc.
    difficulty: Mapped[str] = mapped_column(String(20))  # easy, medium, hard, expert
    title: Mapped[str] = mapped_column(String(100))
    description: Mapped[str] = mapped_column(String(255))

    # Progress tracking
    target_value: Mapped[int] = mapped_column(Integer)
    current_progress: Mapped[int] = mapped_column(Integer, default=0)

    # Rewards
    coin_reward: Mapped[int] = mapped_column(Integer)
    xp_reward: Mapped[int] = mapped_column(Integer)

    # Status
    is_completed: Mapped[bool] = mapped_column(Boolean, default=False)
    is_weekend_bonus: Mapped[bool] = mapped_column(Boolean, default=False)
    completed_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), default=None)
    expires_at: Mapped[datetime] = mapped_column(DateTime(timezone=True))

    __table_args__ = (Index("ix_daily_challenge_user_active", "user_id", "is_completed", "expires_at"),)

    def __repr__(self) -> str:  # pragma: no cover
        return f"<DailyChallenge user_id={self.user_id} {self.challenge_type} {self.difficulty}>"


class ChallengeStreak(TimestampMixin, Base):
    """Tracks a user's daily challenge completion streak.

    Streaks increment when user completes ALL daily challenges within 24 hours,
    and reset if they miss a day.
    """

    __tablename__ = "challenge_streak"

    id: Mapped[int] = mapped_column(primary_key=True)
    user_id: Mapped[int] = mapped_column(ForeignKey("user.id"), unique=True, index=True)

    # Streak tracking
    current_streak: Mapped[int] = mapped_column(Integer, default=0)
    longest_streak: Mapped[int] = mapped_column(Integer, default=0)
    total_days_completed: Mapped[int] = mapped_column(Integer, default=0)

    # Last completion
    last_completion_date: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())
    is_active_today: Mapped[bool] = mapped_column(Boolean, default=False)

    def __repr__(self) -> str:  # pragma: no cover
        return f"<ChallengeStreak user_id={self.user_id} current={self.current_streak}>"


class DoubleOrNothing(TimestampMixin, Base):
    """Double or Nothing challenge - wager coins for 7+ day commitment.

    Highly successful engagement mechanic for boosting daily goal completion.
    Users wager coins and must complete daily goals for N days to win 2x back.
    """

    __tablename__ = "double_or_nothing"

    id: Mapped[int] = mapped_column(primary_key=True)
    user_id: Mapped[int] = mapped_column(ForeignKey("user.id"), index=True)

    # Challenge parameters
    wager_amount: Mapped[int] = mapped_column(Integer)  # Coins wagered
    days_required: Mapped[int] = mapped_column(Integer)  # Usually 7, 14, or 30
    days_completed: Mapped[int] = mapped_column(Integer, default=0)

    # Status flags
    is_active: Mapped[bool] = mapped_column(Boolean, default=True)
    is_won: Mapped[bool] = mapped_column(Boolean, default=False)
    is_lost: Mapped[bool] = mapped_column(Boolean, default=False)

    # Timestamps
    started_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())
    completed_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), default=None)

    __table_args__ = (Index("ix_double_or_nothing_active", "user_id", "is_active"),)

    def __repr__(self) -> str:  # pragma: no cover
        return (
            f"<DoubleOrNothing user_id={self.user_id} wager={self.wager_amount} "
            f"days={self.days_completed}/{self.days_required}>"
        )


class WeeklyChallenge(TimestampMixin, Base):
    """Weekly special challenges with 5-10x rewards and limited-time availability.

    Research shows limited-time offers boost engagement by 25-35% (Temu, Starbucks case studies).
    These challenges run Monday-Sunday and create scarcity and urgency.
    """

    __tablename__ = "weekly_challenge"

    id: Mapped[int] = mapped_column(primary_key=True)
    user_id: Mapped[int] = mapped_column(ForeignKey("user.id"), index=True)

    # Challenge details
    challenge_type: Mapped[str] = mapped_column(String(50))  # weekly_warrior, perfect_week, etc.
    difficulty: Mapped[str] = mapped_column(String(20))  # easy, medium, hard, epic
    title: Mapped[str] = mapped_column(String(200))
    description: Mapped[str] = mapped_column(Text)

    # Progress tracking
    target_value: Mapped[int] = mapped_column(Integer)  # e.g., 7 days of daily goals
    current_progress: Mapped[int] = mapped_column(Integer, default=0)

    # Rewards (5-10x normal)
    coin_reward: Mapped[int] = mapped_column(Integer)
    xp_reward: Mapped[int] = mapped_column(Integer)

    # Status
    is_completed: Mapped[bool] = mapped_column(Boolean, default=False)
    completed_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), default=None)

    # Time constraints
    expires_at: Mapped[datetime] = mapped_column(DateTime(timezone=True))  # Sunday midnight UTC
    week_start: Mapped[datetime] = mapped_column(DateTime(timezone=True))  # Monday 00:00 UTC

    # Special features
    reward_multiplier: Mapped[float] = mapped_column(Float, default=5.0)  # 5x to 10x
    is_special_event: Mapped[bool] = mapped_column(Boolean, default=False)  # Holiday bonuses

    __table_args__ = (
        Index("ix_weekly_challenge_active", "user_id", "is_completed"),
        Index("ix_weekly_challenge_week", "user_id", "week_start"),
    )

    def __repr__(self) -> str:  # pragma: no cover
        return f"<WeeklyChallenge user_id={self.user_id} {self.challenge_type} {self.difficulty}>"


# Export all models
__all__ = [
    "Friendship",
    "FriendChallenge",
    "LeaderboardEntry",
    "PowerUpInventory",
    "PowerUpUsage",
    "DailyChallenge",
    "ChallengeStreak",
    "DoubleOrNothing",
    "WeeklyChallenge",
]
