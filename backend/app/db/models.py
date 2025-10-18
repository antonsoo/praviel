from __future__ import annotations

from datetime import datetime

from pgvector.sqlalchemy import Vector
from sqlalchemy import (
    DateTime,
    ForeignKey,
    Index,
    Integer,
    String,
    Text,
)
from sqlalchemy.dialects.postgresql import JSONB
from sqlalchemy.orm import DeclarativeBase, Mapped, mapped_column, relationship
from sqlalchemy.sql import func

# ---------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------

# Keep this aligned with the embedding model you use (e.g., OpenAI 1536)
EMBED_DIM = 1536


# ---------------------------------------------------------------------
# Base + mixins
# ---------------------------------------------------------------------


class Base(DeclarativeBase):
    """Declarative base for all ORM models."""


class TimestampMixin:
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), nullable=False
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        server_default=func.now(),
        onupdate=func.now(),
        nullable=False,
    )


# ---------------------------------------------------------------------
# Core tables (mirror your actual DB + indexes)
# ---------------------------------------------------------------------


class Language(TimestampMixin, Base):
    __tablename__ = "language"

    id: Mapped[int] = mapped_column(primary_key=True)
    # Your DB currently has a UNIQUE index named ix_language_code.
    # This shape (unique + index) reproduces that behavior.
    code: Mapped[str] = mapped_column(String(8), unique=True, index=True)
    name: Mapped[str] = mapped_column(String(64))

    def __repr__(self) -> str:  # pragma: no cover
        return f"<Language {self.code!r}>"


class SourceDoc(TimestampMixin, Base):
    __tablename__ = "source_doc"

    id: Mapped[int] = mapped_column(primary_key=True)
    slug: Mapped[str] = mapped_column(String(64), unique=True, index=True)  # Match DB: 64 not 200
    title: Mapped[str] = mapped_column(String(256))  # Match DB: NOT NULL and 256 not 255
    license: Mapped[dict | None] = mapped_column(JSONB, default=None)  # Added missing field
    meta: Mapped[dict | None] = mapped_column(JSONB, default=None)

    def __repr__(self) -> str:  # pragma: no cover
        return f"<SourceDoc {self.slug!r}>"


class TextWork(TimestampMixin, Base):
    __tablename__ = "text_work"

    id: Mapped[int] = mapped_column(primary_key=True)
    language_id: Mapped[int] = mapped_column(ForeignKey("language.id"), index=True)
    source_id: Mapped[int] = mapped_column(ForeignKey("source_doc.id"))  # NOT NULL to match migration
    # Note: No slug column in migration - removed to match actual DB schema
    author: Mapped[str] = mapped_column(String(128))
    title: Mapped[str] = mapped_column(String(256))
    ref_scheme: Mapped[str] = mapped_column(String(64))

    language: Mapped["Language"] = relationship("Language")
    source: Mapped["SourceDoc"] = relationship("SourceDoc")

    def __repr__(self) -> str:  # pragma: no cover
        return f"<TextWork id={self.id} title={self.title!r} by {self.author!r}>"


class TextSegment(TimestampMixin, Base):
    __tablename__ = "text_segment"

    id: Mapped[int] = mapped_column(primary_key=True)
    work_id: Mapped[int] = mapped_column(ForeignKey("text_work.id"), index=True)
    ref: Mapped[str | None] = mapped_column(String(100), default=None)

    # original, NFC-normalized, and accent/case-folded content
    # Match migration column names: text_raw, text_nfc, text_fold
    text_raw: Mapped[str] = mapped_column(Text)
    text_nfc: Mapped[str] = mapped_column(Text)
    text_fold: Mapped[str] = mapped_column(Text)

    # Vector embedding for semantic search
    emb: Mapped[bytes | None] = mapped_column(Vector(1536), default=None)

    # Additional metadata in JSONB format
    meta: Mapped[dict | None] = mapped_column(JSONB)

    work: Mapped["TextWork"] = relationship("TextWork")

    def __repr__(self) -> str:  # pragma: no cover
        return f"<TextSegment work_id={self.work_id} ref={self.ref!r}>"


class Token(TimestampMixin, Base):
    __tablename__ = "token"

    id: Mapped[int] = mapped_column(primary_key=True)
    segment_id: Mapped[int] = mapped_column(ForeignKey("text_segment.id"), index=True)
    idx: Mapped[int] = mapped_column(Integer)  # position within segment

    surface: Mapped[str] = mapped_column(String(150))
    surface_nfc: Mapped[str] = mapped_column(String(150), index=True)
    surface_fold: Mapped[str] = mapped_column(String(150), index=True)

    lemma: Mapped[str | None] = mapped_column(String(150), index=True)
    lemma_fold: Mapped[str | None] = mapped_column(String(150), index=True)

    msd: Mapped[dict | None] = mapped_column(JSONB)

    # Matches your DB: ix_token_segment_id is created by the column index,
    # and this explicit composite index enforces location uniqueness ordering.
    __table_args__ = (Index("ix_token_loc", "segment_id", "idx"),)

    segment: Mapped["TextSegment"] = relationship("TextSegment")

    def __repr__(self) -> str:  # pragma: no cover
        return f"<Token seg={self.segment_id} idx={self.idx} {self.surface!r}>"


class Lexeme(TimestampMixin, Base):
    __tablename__ = "lexeme"

    id: Mapped[int] = mapped_column(primary_key=True)
    language_id: Mapped[int] = mapped_column(ForeignKey("language.id"), index=True)

    lemma: Mapped[str] = mapped_column(String(150), index=True)
    lemma_fold: Mapped[str] = mapped_column(String(150), index=True)

    pos: Mapped[str | None] = mapped_column(String(32))
    data: Mapped[dict | None] = mapped_column(JSONB)

    language: Mapped["Language"] = relationship("Language")

    # Keep indexes consistent with what Alembic already generated
    __table_args__ = (
        Index("ix_lexeme_lang_lemma", "language_id", "lemma"),
        Index("ix_lexeme_language_id", "language_id"),
        Index("ix_lexeme_lemma", "lemma"),
        Index("ix_lexeme_lemma_fold", "lemma_fold"),
    )

    def __repr__(self) -> str:  # pragma: no cover
        return f"<Lexeme {self.lemma!r} lang={self.language_id}>"


class GrammarTopic(TimestampMixin, Base):
    __tablename__ = "grammar_topic"

    id: Mapped[int] = mapped_column(primary_key=True)
    source_id: Mapped[int] = mapped_column(ForeignKey("source_doc.id"))  # Match migration
    anchor: Mapped[str] = mapped_column(String(64))  # Match migration
    title: Mapped[str] = mapped_column(String(256))
    body: Mapped[str] = mapped_column(Text)
    body_fold: Mapped[str] = mapped_column(Text)  # Match migration

    # pgvector embedding
    emb: Mapped[bytes | None] = mapped_column(Vector(1536), nullable=True)

    source: Mapped["SourceDoc"] = relationship("SourceDoc")

    def __repr__(self) -> str:  # pragma: no cover
        return f"<GrammarTopic anchor={self.anchor!r} title={self.title!r}>"


class UserVocabulary(TimestampMixin, Base):
    """Track user's vocabulary knowledge with spaced repetition."""

    __tablename__ = "user_vocabulary"

    id: Mapped[int] = mapped_column(primary_key=True)
    user_id: Mapped[int] = mapped_column(ForeignKey("user.id"), index=True)
    language_code: Mapped[str] = mapped_column(String(8), index=True)

    # Vocabulary word
    word: Mapped[str] = mapped_column(String(150), index=True)
    word_normalized: Mapped[str] = mapped_column(String(150), index=True)

    # Learning statistics
    times_seen: Mapped[int] = mapped_column(Integer, default=0)
    times_correct: Mapped[int] = mapped_column(Integer, default=0)
    last_seen: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))

    # Spaced repetition (SM-2 algorithm)
    interval_days: Mapped[int | None] = mapped_column(Integer, default=1)
    ease_factor: Mapped[float | None] = mapped_column(default=2.5)
    next_review: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), index=True)

    # Mastery tracking
    mastery_level: Mapped[str] = mapped_column(
        String(32), index=True
    )  # new, learning, familiar, known, mastered
    avg_response_time_ms: Mapped[int | None] = mapped_column(Integer)

    # Additional metadata (renamed from metadata to avoid SQLAlchemy reserved name)
    meta: Mapped[dict | None] = mapped_column(JSONB)

    user: Mapped["User"] = relationship("User")

    __table_args__ = (
        Index("ix_user_vocab_unique", "user_id", "language_code", "word", unique=True),
        Index("ix_user_vocab_review", "user_id", "language_code", "next_review"),
    )

    def __repr__(self) -> str:  # pragma: no cover
        return f"<UserVocabulary user={self.user_id} lang={self.language_code} word={self.word!r}>"


class UserProficiency(TimestampMixin, Base):
    """Track user's overall proficiency per language."""

    __tablename__ = "user_proficiency"

    id: Mapped[int] = mapped_column(primary_key=True)
    user_id: Mapped[int] = mapped_column(ForeignKey("user.id"), index=True)
    language_code: Mapped[str] = mapped_column(String(8), index=True)

    # Proficiency assessment
    proficiency_level: Mapped[str] = mapped_column(String(32))  # absolute_beginner -> expert
    estimated_vocabulary_size: Mapped[int] = mapped_column(Integer, default=0)

    # Learning progress
    total_study_time_minutes: Mapped[int] = mapped_column(Integer, default=0)
    total_lessons_completed: Mapped[int] = mapped_column(Integer, default=0)
    current_streak_days: Mapped[int] = mapped_column(Integer, default=0)
    longest_streak_days: Mapped[int] = mapped_column(Integer, default=0)
    last_study_date: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))

    # Assessment data
    last_assessment_date: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    assessment_scores: Mapped[dict | None] = mapped_column(JSONB)

    user: Mapped["User"] = relationship("User")

    __table_args__ = (Index("ix_user_prof_unique", "user_id", "language_code", unique=True),)

    def __repr__(self) -> str:  # pragma: no cover
        return (
            f"<UserProficiency user={self.user_id} lang={self.language_code} level={self.proficiency_level}>"
        )


class VocabularyMastery(TimestampMixin, Base):
    """Historical record of vocabulary mastery milestones."""

    __tablename__ = "vocabulary_mastery"

    id: Mapped[int] = mapped_column(primary_key=True)
    user_id: Mapped[int] = mapped_column(ForeignKey("user.id"), index=True)
    language_code: Mapped[str] = mapped_column(String(8), index=True)
    word: Mapped[str] = mapped_column(String(150))

    # Milestone tracking
    mastery_achieved: Mapped[str] = mapped_column(String(32))  # mastery level achieved
    achieved_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), index=True)

    # Context of achievement
    total_encounters: Mapped[int] = mapped_column(Integer)
    final_accuracy: Mapped[float] = mapped_column()

    user: Mapped["User"] = relationship("User")

    __table_args__ = (Index("ix_vocab_mastery_timeline", "user_id", "language_code", "achieved_at"),)

    def __repr__(self) -> str:  # pragma: no cover
        return f"<VocabularyMastery user={self.user_id} word={self.word!r} level={self.mastery_achieved}>"


class GeneratedVocabulary(TimestampMixin, Base):
    """Cache of AI-generated vocabulary to reduce API calls."""

    __tablename__ = "generated_vocabulary"

    id: Mapped[int] = mapped_column(primary_key=True)
    language_code: Mapped[str] = mapped_column(String(8), index=True)

    # The generated word
    word: Mapped[str] = mapped_column(String(150), index=True)
    word_normalized: Mapped[str] = mapped_column(String(150), index=True)

    # Generation metadata
    proficiency_level: Mapped[str] = mapped_column(String(32), index=True)
    difficulty: Mapped[str] = mapped_column(String(32), index=True)
    semantic_field: Mapped[str] = mapped_column(String(64), index=True)

    # Complete vocabulary data (JSON from LLM)
    vocabulary_data: Mapped[dict] = mapped_column(JSONB)

    # Usage tracking
    times_requested: Mapped[int] = mapped_column(Integer, default=0)
    last_requested: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))

    # Vector embedding for semantic search
    emb: Mapped[bytes | None] = mapped_column(Vector(1536))

    __table_args__ = (
        Index("ix_gen_vocab_lookup", "language_code", "proficiency_level", "difficulty"),
        Index("ix_gen_vocab_semantic", "language_code", "semantic_field"),
    )

    def __repr__(self) -> str:  # pragma: no cover
        return f"<GeneratedVocabulary lang={self.language_code} word={self.word!r}>"


__all__ = [
    "Base",
    "TimestampMixin",
    "EMBED_DIM",
    "Language",
    "SourceDoc",
    "TextWork",
    "TextSegment",
    "Token",
    "Lexeme",
    "GrammarTopic",
    "UserVocabulary",
    "UserProficiency",
    "VocabularyMastery",
    "GeneratedVocabulary",
]
