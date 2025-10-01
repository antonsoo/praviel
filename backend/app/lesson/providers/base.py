from __future__ import annotations

from dataclasses import dataclass
from typing import Protocol

from sqlalchemy.ext.asyncio import AsyncSession

from app.lesson.models import LessonGenerateRequest, LessonResponse


@dataclass(slots=True)
class DailyLine:
    grc: str
    en: str
    variants: tuple[str, ...] = ()


@dataclass(slots=True)
class CanonicalLine:
    ref: str
    text: str


@dataclass(slots=True)
class VocabularyItem:
    """Vocabulary extracted from text range"""
    lemma: str
    surface_forms: tuple[str, ...]
    frequency: int


@dataclass(slots=True)
class GrammarPattern:
    """Grammar pattern identified in text range"""
    pattern: str  # e.g., "aorist passive"
    description: str  # e.g., "3rd person singular aorist passive indicative"
    examples: tuple[str, ...]  # surface forms demonstrating pattern


@dataclass(slots=True)
class TextRangeData:
    """Extracted linguistic data from text range"""
    ref_start: str
    ref_end: str
    vocabulary: tuple[VocabularyItem, ...]
    grammar_patterns: tuple[GrammarPattern, ...]
    text_samples: tuple[str, ...]  # Representative sentences


@dataclass(slots=True)
class LessonContext:
    daily_lines: tuple[DailyLine, ...]
    canonical_lines: tuple[CanonicalLine, ...]
    seed: int
    text_range_data: TextRangeData | None = None
    register: str = "literary"


class LessonProvider(Protocol):
    name: str

    async def generate(
        self,
        *,
        request: LessonGenerateRequest,
        session: AsyncSession,
        token: str | None,
        context: LessonContext,
    ) -> LessonResponse: ...


class LessonProviderError(RuntimeError):
    def __init__(self, message: str, *, note: str | None = None):
        super().__init__(message)
        self.note = note


PROVIDERS: dict[str, LessonProvider] = {}


def get_provider(name: str) -> LessonProvider:
    provider = PROVIDERS.get(name)
    if provider is None:
        raise LessonProviderError(f"Unknown lesson provider '{name}'")
    return provider
