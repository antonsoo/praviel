"""User, authentication, and profile models for the ancient languages learning platform.

This module defines the user management and gamification tracking tables.
Follows the design from docs/gamification_ideas.md for comprehensive progress tracking.
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
from sqlalchemy.dialects.postgresql import JSONB
from sqlalchemy.orm import Mapped, mapped_column, relationship
from sqlalchemy.sql import func

from .models import Base, TimestampMixin

# ---------------------------------------------------------------------
# User Authentication & Profile
# ---------------------------------------------------------------------


class PasswordResetToken(Base):
    """Password reset token storage.

    Stores password reset tokens with expiration for secure password recovery.
    Replaces in-memory token storage with persistent database storage.
    """

    __tablename__ = "password_reset_token"

    id: Mapped[int] = mapped_column(primary_key=True)
    user_id: Mapped[int] = mapped_column(ForeignKey("user.id"), index=True)

    # Secure random token
    token: Mapped[str] = mapped_column(String(255), unique=True, index=True)

    # Expiration (typically 15 minutes from creation)
    expires_at: Mapped[datetime] = mapped_column(DateTime(timezone=True))

    # When token was created
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())

    # Track if token was used
    used_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), default=None)

    def __repr__(self) -> str:  # pragma: no cover
        return f"<PasswordResetToken user_id={self.user_id} expires={self.expires_at}>"


class User(TimestampMixin, Base):
    """Core user account for authentication and identification."""

    __tablename__ = "user"

    id: Mapped[int] = mapped_column(primary_key=True)
    username: Mapped[str] = mapped_column(String(50), unique=True, index=True)
    email: Mapped[str] = mapped_column(String(255), unique=True, index=True)
    hashed_password: Mapped[str] = mapped_column(String(255))
    is_active: Mapped[bool] = mapped_column(Boolean, default=True)
    is_superuser: Mapped[bool] = mapped_column(Boolean, default=False)

    # Relationships
    profile: Mapped["UserProfile"] = relationship(
        "UserProfile", back_populates="user", uselist=False, cascade="all, delete-orphan"
    )
    api_configs: Mapped[list["UserAPIConfig"]] = relationship(
        "UserAPIConfig", back_populates="user", cascade="all, delete-orphan"
    )
    preferences: Mapped["UserPreferences"] = relationship(
        "UserPreferences", back_populates="user", uselist=False, cascade="all, delete-orphan"
    )
    progress: Mapped["UserProgress"] = relationship(
        "UserProgress", back_populates="user", uselist=False, cascade="all, delete-orphan"
    )
    skills: Mapped[list["UserSkill"]] = relationship(
        "UserSkill", back_populates="user", cascade="all, delete-orphan"
    )
    achievements: Mapped[list["UserAchievement"]] = relationship(
        "UserAchievement", back_populates="user", cascade="all, delete-orphan"
    )
    text_stats: Mapped[list["UserTextStats"]] = relationship(
        "UserTextStats", back_populates="user", cascade="all, delete-orphan"
    )
    srs_cards: Mapped[list["UserSRSCard"]] = relationship(
        "UserSRSCard", back_populates="user", cascade="all, delete-orphan"
    )
    events: Mapped[list["LearningEvent"]] = relationship(
        "LearningEvent", back_populates="user", cascade="all, delete-orphan"
    )
    quests: Mapped[list["UserQuest"]] = relationship(
        "UserQuest", back_populates="user", cascade="all, delete-orphan"
    )

    def __repr__(self) -> str:  # pragma: no cover
        return f"<User {self.username!r}>"


class UserProfile(TimestampMixin, Base):
    """Optional user profile information (all fields nullable for privacy)."""

    __tablename__ = "user_profile"

    id: Mapped[int] = mapped_column(primary_key=True)
    user_id: Mapped[int] = mapped_column(ForeignKey("user.id"), unique=True, index=True)

    # Optional personal information
    real_name: Mapped[str | None] = mapped_column(String(100), default=None)
    discord_username: Mapped[str | None] = mapped_column(String(50), default=None)
    phone: Mapped[str | None] = mapped_column(String(20), default=None)

    # Payment integration (store payment provider token/customer ID, NOT raw card data)
    payment_provider: Mapped[str | None] = mapped_column(String(50), default=None)
    payment_customer_id: Mapped[str | None] = mapped_column(String(255), default=None)

    # Relationship
    user: Mapped["User"] = relationship("User", back_populates="profile")

    def __repr__(self) -> str:  # pragma: no cover
        return f"<UserProfile user_id={self.user_id}>"


class UserAPIConfig(TimestampMixin, Base):
    """Per-user API key configurations (BYOK - Bring Your Own Key).

    Each user can configure their own API keys for different providers.
    Keys should be encrypted at rest (implementation detail for security layer).
    """

    __tablename__ = "user_api_config"

    id: Mapped[int] = mapped_column(primary_key=True)
    user_id: Mapped[int] = mapped_column(ForeignKey("user.id"), index=True)

    # Provider name: "openai", "anthropic", "google", "elevenlabs", etc.
    provider: Mapped[str] = mapped_column(String(50))

    # Encrypted API key (encrypt before storing, decrypt on retrieval)
    encrypted_api_key: Mapped[str] = mapped_column(Text)

    # Optional: provider-specific metadata (model preferences, rate limits, etc.)
    meta: Mapped[dict | None] = mapped_column(JSONB, default=None)

    # Unique constraint: one config per user per provider
    __table_args__ = (UniqueConstraint("user_id", "provider", name="uq_user_provider"),)

    # Relationship
    user: Mapped["User"] = relationship("User", back_populates="api_configs")

    def __repr__(self) -> str:  # pragma: no cover
        return f"<UserAPIConfig user_id={self.user_id} provider={self.provider!r}>"


class UserPreferences(TimestampMixin, Base):
    """User-specific application preferences and defaults."""

    __tablename__ = "user_preferences"

    id: Mapped[int] = mapped_column(primary_key=True)
    user_id: Mapped[int] = mapped_column(ForeignKey("user.id"), unique=True, index=True)

    # Default LLM provider preference
    default_llm_provider: Mapped[str | None] = mapped_column(String(50), default=None)
    default_chat_model: Mapped[str | None] = mapped_column(String(100), default=None)
    default_lesson_model: Mapped[str | None] = mapped_column(String(100), default=None)
    default_tts_model: Mapped[str | None] = mapped_column(String(100), default=None)

    # UI/UX preferences
    theme: Mapped[str | None] = mapped_column(String(20), default="auto")  # auto, light, dark
    language_focus: Mapped[str | None] = mapped_column(String(20), default=None)  # grc, lat, etc.

    # Learning preferences
    daily_xp_goal: Mapped[int] = mapped_column(Integer, default=50)
    srs_daily_new_cards: Mapped[int] = mapped_column(Integer, default=10)
    srs_daily_review_limit: Mapped[int] = mapped_column(Integer, default=100)

    # Additional settings as JSON
    settings: Mapped[dict | None] = mapped_column(JSONB, default=None)

    # Relationship
    user: Mapped["User"] = relationship("User", back_populates="preferences")

    def __repr__(self) -> str:  # pragma: no cover
        return f"<UserPreferences user_id={self.user_id}>"


# ---------------------------------------------------------------------
# Progress & Gamification
# ---------------------------------------------------------------------


class UserProgress(TimestampMixin, Base):
    """Overall user progress and gamification metrics.

    Tracks high-level stats like XP, level, streak, total lessons completed.
    Corresponds to the existing Flutter ProgressService but now persisted per-user.
    """

    __tablename__ = "user_progress"

    id: Mapped[int] = mapped_column(primary_key=True)
    user_id: Mapped[int] = mapped_column(ForeignKey("user.id"), unique=True, index=True)

    # Core gamification metrics
    xp_total: Mapped[int] = mapped_column(Integer, default=0)
    level: Mapped[int] = mapped_column(Integer, default=0)  # Calculated from XP
    streak_days: Mapped[int] = mapped_column(Integer, default=0)
    max_streak: Mapped[int] = mapped_column(Integer, default=0)

    # Activity tracking
    total_lessons: Mapped[int] = mapped_column(Integer, default=0)
    total_exercises: Mapped[int] = mapped_column(Integer, default=0)
    total_time_minutes: Mapped[int] = mapped_column(Integer, default=0)

    # Last activity timestamps
    last_lesson_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), default=None)
    last_streak_update: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), default=None)

    # Additional stats as JSON (flexible for new metrics)
    stats: Mapped[dict | None] = mapped_column(JSONB, default=None)

    # Relationship
    user: Mapped["User"] = relationship("User", back_populates="progress")

    def __repr__(self) -> str:  # pragma: no cover
        return f"<UserProgress user_id={self.user_id} xp={self.xp_total} level={self.level}>"


class UserSkill(TimestampMixin, Base):
    """Per-topic skill tracking with Elo-based ratings.

    From gamification_ideas.md: topic_id could map to grammar topics,
    morphosyntax categories, or text difficulty levels.
    """

    __tablename__ = "user_skill"

    id: Mapped[int] = mapped_column(primary_key=True)
    user_id: Mapped[int] = mapped_column(ForeignKey("user.id"), index=True)

    # Topic identifier (could be grammar_topic.id or a category slug)
    topic_type: Mapped[str] = mapped_column(String(50))  # "grammar", "morph", "vocab"
    topic_id: Mapped[str] = mapped_column(String(200))  # slug or reference

    # Skill metrics
    elo_rating: Mapped[float] = mapped_column(Float, default=1000.0)
    accuracy: Mapped[float | None] = mapped_column(Float, default=None)  # 0.0-1.0
    total_attempts: Mapped[int] = mapped_column(Integer, default=0)
    correct_attempts: Mapped[int] = mapped_column(Integer, default=0)

    # Recency for decay calculation
    last_practiced_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), default=None)

    # Additional metadata
    meta: Mapped[dict | None] = mapped_column(JSONB, default=None)

    __table_args__ = (
        UniqueConstraint("user_id", "topic_type", "topic_id", name="uq_user_topic"),
        Index("ix_user_skill_user_topic", "user_id", "topic_type"),
    )

    # Relationship
    user: Mapped["User"] = relationship("User", back_populates="skills")

    def __repr__(self) -> str:  # pragma: no cover
        return (
            f"<UserSkill user_id={self.user_id} {self.topic_type}/{self.topic_id} elo={self.elo_rating:.0f}>"
        )


class UserAchievement(TimestampMixin, Base):
    """Badges, milestones, and collections unlocked by the user.

    Examples: "First Lesson Complete", "10-Day Streak", "Master of Genitive Absolute",
    "LSJ Headwords Unlocked: 100", "Smyth §§ Collected: 50"
    """

    __tablename__ = "user_achievement"

    id: Mapped[int] = mapped_column(primary_key=True)
    user_id: Mapped[int] = mapped_column(ForeignKey("user.id"), index=True)

    # Achievement identifier
    achievement_type: Mapped[str] = mapped_column(String(50))  # "badge", "milestone", "collection"
    achievement_id: Mapped[str] = mapped_column(String(200))  # slug or ID

    # When unlocked
    unlocked_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())

    # Progress toward next tier (e.g., "50/100 headwords")
    progress_current: Mapped[int | None] = mapped_column(Integer, default=None)
    progress_target: Mapped[int | None] = mapped_column(Integer, default=None)

    # Metadata (tier, icon, description, etc.)
    meta: Mapped[dict | None] = mapped_column(JSONB, default=None)

    __table_args__ = (
        UniqueConstraint("user_id", "achievement_type", "achievement_id", name="uq_user_achievement"),
    )

    # Relationship
    user: Mapped["User"] = relationship("User", back_populates="achievements")

    def __repr__(self) -> str:  # pragma: no cover
        return f"<UserAchievement user_id={self.user_id} {self.achievement_type}/{self.achievement_id}>"


class UserTextStats(TimestampMixin, Base):
    """Per-work or per-text reading statistics.

    Tracks lemma coverage, reading speed (WPM), comprehension, etc.
    for specific works (e.g., Iliad Book 1, Plato's Apology).
    """

    __tablename__ = "user_text_stats"

    id: Mapped[int] = mapped_column(primary_key=True)
    user_id: Mapped[int] = mapped_column(ForeignKey("user.id"), index=True)
    work_id: Mapped[int] = mapped_column(ForeignKey("text_work.id"), index=True)

    # Coverage metrics
    lemma_coverage_pct: Mapped[float | None] = mapped_column(Float, default=None)  # 0.0-100.0
    tokens_seen: Mapped[int] = mapped_column(Integer, default=0)
    unique_lemmas_known: Mapped[int] = mapped_column(Integer, default=0)

    # Reading performance
    avg_wpm: Mapped[float | None] = mapped_column(Float, default=None)
    comprehension_pct: Mapped[float | None] = mapped_column(Float, default=None)  # 0.0-100.0

    # Progress tracking
    segments_completed: Mapped[int] = mapped_column(Integer, default=0)
    last_segment_ref: Mapped[str | None] = mapped_column(String(100), default=None)

    # Hintless reading streaks
    max_hintless_run: Mapped[int] = mapped_column(Integer, default=0)  # consecutive sentences

    # Additional stats
    stats: Mapped[dict | None] = mapped_column(JSONB, default=None)

    __table_args__ = (UniqueConstraint("user_id", "work_id", name="uq_user_work"),)

    # Relationships
    user: Mapped["User"] = relationship("User", back_populates="text_stats")

    def __repr__(self) -> str:  # pragma: no cover
        return (
            f"<UserTextStats user_id={self.user_id} work_id={self.work_id} "
            f"coverage={self.lemma_coverage_pct}%>"
        )


# ---------------------------------------------------------------------
# SRS (Spaced Repetition System) Tracking
# ---------------------------------------------------------------------


class UserSRSCard(TimestampMixin, Base):
    """SRS flashcard state for a user learning a specific item (lemma, grammar concept, etc.).

    Implements FSRS (Free Spaced Repetition Scheduler) algorithm parameters.
    Tracks P(recall) for intelligent review scheduling.
    """

    __tablename__ = "user_srs_card"

    id: Mapped[int] = mapped_column(primary_key=True)
    user_id: Mapped[int] = mapped_column(ForeignKey("user.id"), index=True)

    # Card content identifiers
    card_type: Mapped[str] = mapped_column(String(50))  # "lemma", "grammar", "morph"
    content_id: Mapped[str] = mapped_column(String(200))  # lexeme.id, grammar_topic.slug, etc.

    # FSRS parameters (based on FSRS-4.5 or SM-2 fallback)
    stability: Mapped[float] = mapped_column(Float, default=1.0)  # Days until P(recall)=0.9
    difficulty: Mapped[float] = mapped_column(Float, default=5.0)  # 1.0 (easy) to 10.0 (hard)
    elapsed_days: Mapped[int] = mapped_column(Integer, default=0)
    scheduled_days: Mapped[int] = mapped_column(Integer, default=0)
    reps: Mapped[int] = mapped_column(Integer, default=0)
    lapses: Mapped[int] = mapped_column(Integer, default=0)
    state: Mapped[str] = mapped_column(String(20), default="new")  # new, learning, review, relearning

    # Calculated P(recall) for prioritization
    p_recall: Mapped[float | None] = mapped_column(Float, default=None)

    # Review scheduling
    due_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())
    last_review_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), default=None)

    # Additional FSRS state
    fsrs_params: Mapped[dict | None] = mapped_column(JSONB, default=None)

    __table_args__ = (
        UniqueConstraint("user_id", "card_type", "content_id", name="uq_user_card"),
        Index("ix_user_srs_due", "user_id", "due_at"),
        Index("ix_user_srs_state", "user_id", "state"),
    )

    # Relationship
    user: Mapped["User"] = relationship("User", back_populates="srs_cards")

    def __repr__(self) -> str:  # pragma: no cover
        return f"<UserSRSCard user_id={self.user_id} {self.card_type}/{self.content_id} state={self.state}>"


# ---------------------------------------------------------------------
# Learning Events & Analytics
# ---------------------------------------------------------------------


class LearningEvent(Base):
    """Event log for learning activities and analytics.

    Captures all learning interactions for analysis, coaching, and gamification.
    From gamification_ideas.md instrumentation section.
    """

    __tablename__ = "learning_event"

    id: Mapped[int] = mapped_column(primary_key=True)
    user_id: Mapped[int] = mapped_column(ForeignKey("user.id"), index=True)

    # Event metadata
    event_type: Mapped[str] = mapped_column(String(50), index=True)  # lesson_start, exercise_result, etc.
    event_timestamp: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), index=True
    )

    # Event data (flexible JSON for different event types)
    # Examples:
    # - exercise_result: {topic, tags, msd, correct, time_ms, hint_used}
    # - reader_tap: {token_id, lemma, msd}
    # - chat_turn: {chars, errors, hint_used, register}
    # - srs_review: {card_id, quality (0-5), next_interval_days, p_recall}
    data: Mapped[dict] = mapped_column(JSONB)

    # Optional: link to specific entities
    lesson_id: Mapped[str | None] = mapped_column(String(100), default=None)
    work_id: Mapped[int | None] = mapped_column(ForeignKey("text_work.id"), default=None)

    __table_args__ = (
        Index("ix_learning_event_user_type", "user_id", "event_type"),
        Index("ix_learning_event_user_time", "user_id", "event_timestamp"),
    )

    # Relationship
    user: Mapped["User"] = relationship("User", back_populates="events")

    def __repr__(self) -> str:  # pragma: no cover
        return f"<LearningEvent user_id={self.user_id} type={self.event_type}>"


# ---------------------------------------------------------------------
# Quests & Challenges
# ---------------------------------------------------------------------


class UserQuest(TimestampMixin, Base):
    """Active and completed quests/challenges for a user.

    Examples: "Master genitive absolute", "Scan 10 hexameter lines",
    "Zero-hint Iliad 1.1-1.10", "Read 1000 lines this week"
    """

    __tablename__ = "user_quest"

    id: Mapped[int] = mapped_column(primary_key=True)
    user_id: Mapped[int] = mapped_column(ForeignKey("user.id"), index=True)

    # Quest definition
    quest_type: Mapped[str] = mapped_column(String(50))  # "mastery", "reading", "streak"
    quest_id: Mapped[str] = mapped_column(String(200))  # slug or identifier
    title: Mapped[str] = mapped_column(String(255))
    description: Mapped[str | None] = mapped_column(Text, default=None)

    # Progress tracking
    progress_current: Mapped[int] = mapped_column(Integer, default=0)
    progress_target: Mapped[int] = mapped_column(Integer, default=1)
    status: Mapped[str] = mapped_column(String(20), default="active")  # active, completed, failed, expired

    # Timestamps
    started_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())
    completed_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), default=None)
    expires_at: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True), default=None
    )  # For time-limited quests

    # Rewards
    xp_reward: Mapped[int] = mapped_column(Integer, default=0)
    achievement_reward: Mapped[str | None] = mapped_column(String(200), default=None)

    # Additional metadata
    meta: Mapped[dict | None] = mapped_column(JSONB, default=None)

    __table_args__ = (Index("ix_user_quest_status", "user_id", "status"),)

    # Relationship
    user: Mapped["User"] = relationship("User", back_populates="quests")

    def __repr__(self) -> str:  # pragma: no cover
        return f"<UserQuest user_id={self.user_id} {self.quest_id} {self.status}>"


# Export all models
__all__ = [
    "PasswordResetToken",
    "User",
    "UserProfile",
    "UserAPIConfig",
    "UserPreferences",
    "UserProgress",
    "UserSkill",
    "UserAchievement",
    "UserTextStats",
    "UserSRSCard",
    "LearningEvent",
    "UserQuest",
]
