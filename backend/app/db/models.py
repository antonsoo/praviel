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
    slug: Mapped[str] = mapped_column(String(200), unique=True, index=True)
    title: Mapped[str | None] = mapped_column(String(255), default=None)
    meta: Mapped[dict | None] = mapped_column(JSONB, default=None)

    def __repr__(self) -> str:  # pragma: no cover
        return f"<SourceDoc {self.slug!r}>"


class TextWork(TimestampMixin, Base):
    __tablename__ = "text_work"

    id: Mapped[int] = mapped_column(primary_key=True)
    language_id: Mapped[int] = mapped_column(ForeignKey("language.id"), index=True)
    source_id: Mapped[int | None] = mapped_column(ForeignKey("source_doc.id"), nullable=True)
    slug: Mapped[str] = mapped_column(String(200), unique=True, index=True)
    title: Mapped[str | None] = mapped_column(String(255), default=None)

    language: Mapped["Language"] = relationship("Language")
    source: Mapped["SourceDoc"] = relationship("SourceDoc")

    def __repr__(self) -> str:  # pragma: no cover
        return f"<TextWork {self.slug!r}>"


class TextSegment(TimestampMixin, Base):
    __tablename__ = "text_segment"

    id: Mapped[int] = mapped_column(primary_key=True)
    work_id: Mapped[int] = mapped_column(ForeignKey("text_work.id"), index=True)
    ref: Mapped[str | None] = mapped_column(String(100), default=None)

    # original, NFC-normalized, and accent/case-folded content
    content: Mapped[str] = mapped_column(Text)
    content_nfc: Mapped[str] = mapped_column(Text)
    content_fold: Mapped[str] = mapped_column(Text)

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
    language_id: Mapped[int] = mapped_column(ForeignKey("language.id"), index=True)

    slug: Mapped[str] = mapped_column(String(200), unique=True, index=True)
    title: Mapped[str] = mapped_column(String(255))
    body: Mapped[str] = mapped_column(Text)

    # pgvector embedding
    emb: Mapped[list[float] | None] = mapped_column(Vector(EMBED_DIM), nullable=True)
    data: Mapped[dict | None] = mapped_column(JSONB, default=None)

    language: Mapped["Language"] = relationship("Language")

    def __repr__(self) -> str:  # pragma: no cover
        return f"<GrammarTopic {self.slug!r}>"


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
]
