"""Pydantic schemas for user authentication and profile management."""

from __future__ import annotations

from datetime import datetime

from pydantic import BaseModel, EmailStr, Field, field_validator

from app.core.validation import validate_password

# ---------------------------------------------------------------------
# Authentication Schemas
# ---------------------------------------------------------------------


class UserRegisterRequest(BaseModel):
    """Request to register a new user account."""

    username: str = Field(min_length=3, max_length=50, pattern=r"^[a-zA-Z0-9_-]+$")
    email: EmailStr
    password: str = Field(min_length=8, max_length=100)

    @field_validator("password")
    @classmethod
    def validate_password_strength(cls, v: str) -> str:
        """Validate password has minimum complexity using comprehensive validation."""
        result = validate_password(v)

        if not result.is_valid:
            # Combine all errors into a single message
            error_msg = "; ".join(result.errors)
            raise ValueError(error_msg)

        return v


class UserLoginRequest(BaseModel):
    """Request to log in with username/email and password."""

    username_or_email: str = Field(min_length=1)
    password: str = Field(min_length=1)


class TokenResponse(BaseModel):
    """Response containing JWT access and refresh tokens."""

    access_token: str
    refresh_token: str
    token_type: str = "bearer"


class TokenRefreshRequest(BaseModel):
    """Request to refresh an access token using a refresh token."""

    refresh_token: str


# ---------------------------------------------------------------------
# User Profile Schemas
# ---------------------------------------------------------------------


class UserProfileBase(BaseModel):
    """Base user profile data (what users see and can update)."""

    username: str
    email: EmailStr


class UserProfilePublic(UserProfileBase):
    """Public user profile (safe to return in API responses)."""

    id: int
    is_active: bool
    created_at: datetime

    # Optional profile fields
    real_name: str | None = None
    discord_username: str | None = None

    model_config = {"from_attributes": True}


class UserProfileUpdate(BaseModel):
    """Request to update user profile."""

    real_name: str | None = Field(None, max_length=100)
    discord_username: str | None = Field(None, max_length=50)
    phone: str | None = Field(None, max_length=20)

    # Email/username changes should be separate endpoints with verification


class PasswordChangeRequest(BaseModel):
    """Request to change user password."""

    old_password: str = Field(..., min_length=8, max_length=100)
    new_password: str = Field(..., min_length=8, max_length=100)

    @field_validator("new_password")
    @classmethod
    def validate_password_strength(cls, v: str) -> str:
        """Ensure new password meets complexity requirements."""
        result = validate_password(v)

        if not result.is_valid:
            error_msg = "; ".join(result.errors)
            raise ValueError(error_msg)

        return v


class UserPreferencesUpdate(BaseModel):
    """Request to update user preferences."""

    default_llm_provider: str | None = Field(None, max_length=50)
    default_chat_model: str | None = Field(None, max_length=100)
    default_lesson_model: str | None = Field(None, max_length=100)
    default_tts_model: str | None = Field(None, max_length=100)
    theme: str | None = Field(None, pattern=r"^(auto|light|dark)$")
    language_focus: str | None = Field(None, max_length=20)
    daily_xp_goal: int | None = Field(None, ge=0, le=10000)
    srs_daily_new_cards: int | None = Field(None, ge=0, le=100)
    srs_daily_review_limit: int | None = Field(None, ge=0, le=1000)


class UserPreferencesResponse(BaseModel):
    """Response containing user preferences."""

    default_llm_provider: str | None = None
    default_chat_model: str | None = None
    default_lesson_model: str | None = None
    default_tts_model: str | None = None
    theme: str | None = None
    language_focus: str | None = None
    daily_xp_goal: int = 50
    srs_daily_new_cards: int = 10
    srs_daily_review_limit: int = 100

    model_config = {"from_attributes": True}


# ---------------------------------------------------------------------
# API Key Management Schemas
# ---------------------------------------------------------------------


class UserAPIKeyCreate(BaseModel):
    """Request to add/update an API key for a provider."""

    provider: str = Field(min_length=1, max_length=50, pattern=r"^(openai|anthropic|google|elevenlabs)$")
    api_key: str = Field(min_length=1, max_length=500)


class UserAPIKeyResponse(BaseModel):
    """Response showing configured API key providers (without exposing keys)."""

    provider: str
    configured: bool = True
    created_at: datetime
    updated_at: datetime

    model_config = {"from_attributes": True}


class UserAPIKeyDelete(BaseModel):
    """Request to delete an API key."""

    provider: str = Field(min_length=1, max_length=50)


# ---------------------------------------------------------------------
# Progress & Gamification Schemas
# ---------------------------------------------------------------------


class UserProgressResponse(BaseModel):
    """Response containing user progress and gamification metrics."""

    # Core metrics
    xp_total: int
    level: int
    streak_days: int
    max_streak: int

    # Coins and power-ups
    coins: int = 0
    streak_freezes: int = 0

    # Activity stats
    total_lessons: int
    total_exercises: int
    total_time_minutes: int

    # Timestamps
    last_lesson_at: datetime | None = None
    last_streak_update: datetime | None = None

    # XP to next level calculation
    xp_for_current_level: int
    xp_for_next_level: int
    xp_to_next_level: int
    progress_to_next_level: float  # 0.0 to 1.0

    model_config = {"from_attributes": True}

    @staticmethod
    def calculate_level(xp: int) -> int:
        """Calculate level from XP: Level = floor(sqrt(XP/100))."""
        import math

        if xp <= 0:
            return 0
        return int(math.sqrt(xp / 100))

    @staticmethod
    def get_xp_for_level(level: int) -> int:
        """Get XP required for a level: XP = level^2 * 100."""
        return level * level * 100


class ProgressUpdateRequest(BaseModel):
    """Request to update user progress (called after lesson completion)."""

    xp_gained: int = Field(ge=0, le=1000)
    lesson_id: str | None = None
    time_spent_minutes: int | None = Field(None, ge=0, le=1440)
    is_perfect: bool | None = None
    words_learned_count: int | None = Field(None, ge=0)


class UserSkillResponse(BaseModel):
    """Response containing skill data for a specific topic."""

    topic_type: str
    topic_id: str
    elo_rating: float
    accuracy: float | None = None
    total_attempts: int
    correct_attempts: int
    last_practiced_at: datetime | None = None

    model_config = {"from_attributes": True}


class UserAchievementResponse(BaseModel):
    """Response containing achievement/badge data."""

    achievement_type: str
    achievement_id: str
    unlocked_at: datetime
    progress_current: int | None = None
    progress_target: int | None = None

    model_config = {"from_attributes": True}


class UserTextStatsResponse(BaseModel):
    """Response containing per-work reading statistics."""

    work_id: int
    lemma_coverage_pct: float | None = None
    tokens_seen: int
    unique_lemmas_known: int
    avg_wpm: float | None = None
    comprehension_pct: float | None = None
    segments_completed: int
    last_segment_ref: str | None = None
    max_hintless_run: int

    model_config = {"from_attributes": True}


# ---------------------------------------------------------------------
# SRS Schemas
# ---------------------------------------------------------------------


class SRSCardResponse(BaseModel):
    """Response containing SRS card state."""

    card_type: str
    content_id: str
    state: str
    reps: int
    lapses: int
    p_recall: float | None = None
    due_at: datetime
    last_review_at: datetime | None = None

    model_config = {"from_attributes": True}


class SRSReviewRequest(BaseModel):
    """Request to submit an SRS review."""

    card_id: int
    quality: int = Field(ge=0, le=5)  # 0=total blackout, 5=perfect recall
    time_ms: int | None = Field(None, ge=0)


class SRSDueCardsResponse(BaseModel):
    """Response containing cards due for review."""

    due_count: int
    cards: list[SRSCardResponse]


# ---------------------------------------------------------------------
# Quest Schemas
# ---------------------------------------------------------------------


class UserQuestResponse(BaseModel):
    """Response containing quest data."""

    id: int
    quest_type: str
    quest_id: str
    title: str
    description: str | None = None
    progress_current: int
    progress_target: int
    status: str
    started_at: datetime
    completed_at: datetime | None = None
    expires_at: datetime | None = None
    xp_reward: int
    achievement_reward: str | None = None

    model_config = {"from_attributes": True}


__all__ = [
    "UserRegisterRequest",
    "UserLoginRequest",
    "TokenResponse",
    "TokenRefreshRequest",
    "UserProfilePublic",
    "UserProfileUpdate",
    "UserPreferencesUpdate",
    "UserPreferencesResponse",
    "UserAPIKeyCreate",
    "UserAPIKeyResponse",
    "UserAPIKeyDelete",
    "UserProgressResponse",
    "ProgressUpdateRequest",
    "UserSkillResponse",
    "UserAchievementResponse",
    "UserTextStatsResponse",
    "SRSCardResponse",
    "SRSReviewRequest",
    "SRSDueCardsResponse",
    "UserQuestResponse",
]
