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
class LessonContext:
    daily_lines: tuple[DailyLine, ...]
    canonical_lines: tuple[CanonicalLine, ...]
    seed: int


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
    pass


PROVIDERS: dict[str, LessonProvider] = {}


def get_provider(name: str) -> LessonProvider:
    provider = PROVIDERS.get(name)
    if provider is None:
        raise LessonProviderError(f"Unknown lesson provider '{name}'")
    return provider
