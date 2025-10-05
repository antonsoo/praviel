"""Database models and utilities."""

from .models import (
    Base,
    GrammarTopic,
    Language,
    Lexeme,
    SourceDoc,
    TextSegment,
    TextWork,
    TimestampMixin,
    Token,
)
from .session import SessionLocal, engine, get_db
from .user_models import (
    LearningEvent,
    User,
    UserAchievement,
    UserAPIConfig,
    UserPreferences,
    UserProfile,
    UserProgress,
    UserQuest,
    UserSkill,
    UserSRSCard,
    UserTextStats,
)

__all__ = [
    # Core models
    "Base",
    "TimestampMixin",
    "Language",
    "SourceDoc",
    "TextWork",
    "TextSegment",
    "Token",
    "Lexeme",
    "GrammarTopic",
    # User models
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
    # Session
    "SessionLocal",
    "engine",
    "get_db",
]
