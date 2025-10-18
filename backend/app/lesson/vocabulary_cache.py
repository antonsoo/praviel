"""Caching utilities for generated vocabulary to reduce LLM API calls."""

from __future__ import annotations

from datetime import datetime

from sqlalchemy import and_, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.db.models import GeneratedVocabulary
from app.lesson.vocabulary_engine import (
    VocabularyDifficulty,
    VocabularyGenerationRequest,
    VocabularyItem,
)


async def get_cached_vocabulary(
    session: AsyncSession,
    request: VocabularyGenerationRequest,
    known_words: set[str],
) -> list[VocabularyItem]:
    """Retrieve cached vocabulary matching the request parameters.

    Args:
        session: Database session
        request: Vocabulary generation request
        known_words: Set of words user already knows

    Returns:
        List of cached vocabulary items that match criteria
    """
    # Query for cached vocabulary matching language, proficiency, and difficulty
    stmt = (
        select(GeneratedVocabulary)
        .where(
            and_(
                GeneratedVocabulary.language_code == request.language_code,
                GeneratedVocabulary.proficiency_level == request.proficiency_level.value,
                GeneratedVocabulary.difficulty.in_(
                    [d.value for d in [request.difficulty_range[0], request.difficulty_range[1]]]
                ),
            )
        )
        .limit(request.count * 2)
    )  # Get more than needed to filter

    result = await session.execute(stmt)
    cached_records = result.scalars().all()

    items = []
    for record in cached_records:
        # Skip words user already knows
        if record.word in known_words:
            continue

        # Parse vocabulary data from JSON
        vocab_data = record.vocabulary_data

        try:
            item = VocabularyItem(
                word=vocab_data["word"],
                translation=vocab_data["translation"],
                transliteration=vocab_data.get("transliteration"),
                part_of_speech=vocab_data["part_of_speech"],
                difficulty=VocabularyDifficulty(vocab_data["difficulty"]),
                frequency_rank=vocab_data.get("frequency_rank"),
                example_sentence=vocab_data["example_sentence"],
                example_translation=vocab_data["example_translation"],
                etymology=vocab_data.get("etymology"),
                semantic_field=vocab_data["semantic_field"],
                related_words=vocab_data.get("related_words", []),
                cultural_notes=vocab_data.get("cultural_notes"),
            )
            items.append(item)

            # Update request count
            record.times_requested += 1
            record.last_requested = datetime.utcnow()

        except (KeyError, ValueError):
            # Skip malformed cache entries
            continue

        if len(items) >= request.count:
            break

    await session.commit()
    return items


async def cache_generated_vocabulary(
    session: AsyncSession,
    items: list[VocabularyItem],
    request: VocabularyGenerationRequest,
) -> None:
    """Cache generated vocabulary items for future use.

    Args:
        session: Database session
        items: Generated vocabulary items to cache
        request: Original generation request
    """
    import unicodedata

    for item in items:
        # Check if already cached
        stmt = select(GeneratedVocabulary).where(
            and_(
                GeneratedVocabulary.language_code == request.language_code,
                GeneratedVocabulary.word == item.word,
            )
        )
        result = await session.execute(stmt)
        existing = result.scalar_one_or_none()

        if existing:
            # Update request count
            existing.times_requested += 1
            existing.last_requested = datetime.utcnow()
        else:
            # Create new cache entry
            vocabulary_data = {
                "word": item.word,
                "translation": item.translation,
                "transliteration": item.transliteration,
                "part_of_speech": item.part_of_speech,
                "difficulty": item.difficulty.value,
                "frequency_rank": item.frequency_rank,
                "example_sentence": item.example_sentence,
                "example_translation": item.example_translation,
                "etymology": item.etymology,
                "semantic_field": item.semantic_field,
                "related_words": item.related_words,
                "cultural_notes": item.cultural_notes,
            }

            cached_vocab = GeneratedVocabulary(
                language_code=request.language_code,
                word=item.word,
                word_normalized=unicodedata.normalize("NFC", item.word.lower()),
                proficiency_level=request.proficiency_level.value,
                difficulty=item.difficulty.value,
                semantic_field=item.semantic_field,
                vocabulary_data=vocabulary_data,
                times_requested=1,
                last_requested=datetime.utcnow(),
            )
            session.add(cached_vocab)

    await session.commit()
