# Import Python datetime for modern typing
from datetime import datetime

from pgvector.sqlalchemy import Vector
from sqlalchemy import (
    DateTime,
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

from app.core.config import settings
from app.db.session import Base

EMBED_DIM = settings.EMBED_DIM


# Updated TimestampMixin with Python datetime typing
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


class Language(TimestampMixin, Base):
    __tablename__ = "language"
    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    code: Mapped[str] = mapped_column(String(8), unique=True, index=True)
    name: Mapped[str] = mapped_column(String(64))


class SourceDoc(TimestampMixin, Base):
    __tablename__ = "source_doc"
    id: Mapped[int] = mapped_column(primary_key=True)
    slug: Mapped[str] = mapped_column(String(64), unique=True)
    title: Mapped[str] = mapped_column(String(256))
    license: Mapped[dict | None] = mapped_column(JSONB)
    meta: Mapped[dict | None] = mapped_column(JSONB)


class TextWork(TimestampMixin, Base):
    __tablename__ = "text_work"
    id: Mapped[int] = mapped_column(primary_key=True)
    language_id: Mapped[int] = mapped_column(ForeignKey("language.id"), index=True)
    source_id: Mapped[int] = mapped_column(ForeignKey("source_doc.id"))
    author: Mapped[str] = mapped_column(String(128))
    title: Mapped[str] = mapped_column(String(256))
    ref_scheme: Mapped[str] = mapped_column(String(64))
    language: Mapped["Language"] = relationship("Language")
    source: Mapped["SourceDoc"] = relationship("SourceDoc")


class TextSegment(TimestampMixin, Base):
    __tablename__ = "text_segment"
    id: Mapped[int] = mapped_column(primary_key=True)
    work_id: Mapped[int] = mapped_column(ForeignKey("text_work.id"), index=True)
    ref: Mapped[str] = mapped_column(String(64))
    text_raw: Mapped[str] = mapped_column(Text)
    text_nfc: Mapped[str] = mapped_column(Text)
    text_fold: Mapped[str] = mapped_column(Text)
    emb: Mapped[list[float] | None] = mapped_column(Vector(EMBED_DIM))
    meta: Mapped[dict | None] = mapped_column(JSONB)
    __table_args__ = (UniqueConstraint("work_id", "ref", name="uq_segment_ref"),)


class Token(TimestampMixin, Base):
    __tablename__ = "token"
    id: Mapped[int] = mapped_column(primary_key=True)
    segment_id: Mapped[int] = mapped_column(ForeignKey("text_segment.id"), index=True)
    idx: Mapped[int] = mapped_column(Integer)
    surface: Mapped[str] = mapped_column(String(150))
    surface_nfc: Mapped[str] = mapped_column(String(150), index=True)
    surface_fold: Mapped[str] = mapped_column(String(150), index=True)
    lemma: Mapped[str | None] = mapped_column(String(150), index=True)
    lemma_fold: Mapped[str | None] = mapped_column(String(150), index=True)
    msd: Mapped[dict | None] = mapped_column(JSONB)
    __table_args__ = (Index("ix_token_loc", "segment_id", "idx"),)


class Lexeme(TimestampMixin, Base):
    __tablename__ = "lexeme"
    id: Mapped[int] = mapped_column(primary_key=True)
    language_id: Mapped[int] = mapped_column(ForeignKey("language.id"), index=True)
    lemma: Mapped[str] = mapped_column(String(150), index=True)
    lemma_fold: Mapped[str] = mapped_column(String(150), index=True)
    pos: Mapped[str | None] = mapped_column(String(32))
    data: Mapped[dict | None] = mapped_column(JSONB)
    language: Mapped["Language"] = relationship("Language")
    __table_args__ = (
        UniqueConstraint("language_id", "lemma", name="uq_lex_lang_lemma"),
        # New Index: Optimized lookup by language and lemma
        Index("ix_lexeme_lang_lemma", "language_id", "lemma"),
    )


class GrammarTopic(TimestampMixin, Base):
    __tablename__ = "grammar_topic"
    id: Mapped[int] = mapped_column(primary_key=True)
    source_id: Mapped[int] = mapped_column(ForeignKey("source_doc.id"))
    anchor: Mapped[str] = mapped_column(String(64))
    title: Mapped[str] = mapped_column(String(256))
    body: Mapped[str] = mapped_column(Text)
    body_fold: Mapped[str] = mapped_column(Text)
    emb: Mapped[list[float] | None] = mapped_column(Vector(EMBED_DIM))
