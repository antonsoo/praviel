"""AI-Driven Vocabulary Generation and Management System.

This module provides intelligent, adaptive vocabulary generation and tracking
using LLM capabilities for personalized learning experiences.
"""

from __future__ import annotations

import logging
from datetime import datetime, timedelta
from enum import Enum
from typing import Any, Optional

from pydantic import BaseModel, Field
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.db.models import UserVocabulary


class ProficiencyLevel(str, Enum):
    """User proficiency levels for adaptive content generation."""

    ABSOLUTE_BEGINNER = "absolute_beginner"  # Never studied this language
    BEGINNER = "beginner"  # 0-6 months, < 100 words
    ELEMENTARY = "elementary"  # 6-12 months, 100-500 words
    INTERMEDIATE = "intermediate"  # 1-2 years, 500-1500 words
    UPPER_INTERMEDIATE = "upper_intermediate"  # 2-3 years, 1500-3000 words
    ADVANCED = "advanced"  # 3-5 years, 3000-5000 words
    PROFICIENT = "proficient"  # 5-10 years, 5000-8000 words
    EXPERT = "expert"  # 10+ years, 8000+ words, can read classical texts


class VocabularyDifficulty(str, Enum):
    """Vocabulary difficulty classifications."""

    CORE_BASIC = "core_basic"  # Top 100 most frequent words
    BASIC = "basic"  # Top 500 most frequent
    INTERMEDIATE = "intermediate"  # Top 1500
    ADVANCED = "advanced"  # Top 5000
    SPECIALIZED = "specialized"  # Domain-specific (religious, military, etc)
    RARE = "rare"  # Literary, archaic, technical


class MasteryLevel(str, Enum):
    """User's mastery of individual vocabulary items."""

    NEW = "new"  # Never seen
    LEARNING = "learning"  # Seen 1-3 times, <50% recall
    FAMILIAR = "familiar"  # Seen 4-10 times, 50-80% recall
    KNOWN = "known"  # Seen 10+ times, >80% recall
    MASTERED = "mastered"  # Consistently correct, >95% recall


class VocabularyGenerationRequest(BaseModel):
    """Request for AI-generated vocabulary."""

    language_code: str = Field(..., description="ISO 639-3 language code")
    user_id: int = Field(
        default=-1, description="User ID for personalization (auto-filled from auth token, -1 for anonymous)"
    )
    proficiency_level: ProficiencyLevel = Field(..., description="User's current proficiency")
    count: int = Field(default=10, ge=1, le=100, description="Number of words to generate")
    exclude_known: bool = Field(True, description="Exclude words user has already mastered")
    topic: Optional[str] = Field(None, description="Optional topic/domain focus")
    difficulty_range: tuple[VocabularyDifficulty, VocabularyDifficulty] = Field(
        (VocabularyDifficulty.BASIC, VocabularyDifficulty.INTERMEDIATE),
        description="Range of acceptable difficulties",
    )
    context_type: str = Field("mixed", description="Context type: daily, literary, religious, military")
    provider: Optional[str] = Field(None, description="LLM provider: openai, anthropic, google, or echo")


class VocabularyItem(BaseModel):
    """A generated vocabulary item with metadata."""

    word: str = Field(..., description="Word in target language")
    translation: str = Field(..., description="Translation in user's language")
    transliteration: Optional[str] = Field(None, description="Romanized form if non-Latin script")
    part_of_speech: str = Field(..., description="Grammatical category")
    difficulty: VocabularyDifficulty = Field(..., description="Difficulty level")
    frequency_rank: Optional[int] = Field(None, description="Corpus frequency rank (1 = most common)")
    example_sentence: str = Field(..., description="Example sentence in target language")
    example_translation: str = Field(..., description="Example sentence translation")
    etymology: Optional[str] = Field(None, description="Word origin/etymology")
    semantic_field: str = Field(..., description="Semantic category (food, family, etc)")
    related_words: list[str] = Field(default_factory=list, description="Related vocabulary")
    cultural_notes: Optional[str] = Field(None, description="Cultural/historical context")


class VocabularyGenerationResponse(BaseModel):
    """Response containing generated vocabulary."""

    items: list[VocabularyItem] = Field(..., description="Generated vocabulary items")
    proficiency_level: ProficiencyLevel = Field(..., description="Level for which vocab was generated")
    total_known_words: int = Field(..., description="User's total known words in this language")
    estimated_proficiency: ProficiencyLevel = Field(
        ..., description="Estimated proficiency based on known vocabulary"
    )
    next_review_date: datetime = Field(..., description="Recommended date for spaced repetition review")


class VocabularyEngine:
    """AI-powered vocabulary generation and management engine."""

    def __init__(
        self,
        db: AsyncSession,
        llm_provider: Any,  # OpenAI, Anthropic, or Google provider
        token: str | None = None,
    ):
        """Initialize vocabulary engine.

        Args:
            db: Database session
            llm_provider: LLM provider for generation
            token: API token for provider
        """
        self.db = db
        self.llm = llm_provider
        self.token = token

    async def generate_vocabulary(self, request: VocabularyGenerationRequest) -> VocabularyGenerationResponse:
        """Generate personalized vocabulary using LLM.

        This is the core AI-driven generation method that:
        1. Analyzes user's current knowledge
        2. Determines optimal next words to learn
        3. Generates contextually rich vocabulary items
        4. Schedules spaced repetition

        Args:
            request: Vocabulary generation request

        Returns:
            Generated vocabulary with metadata
        """
        from app.lesson.vocabulary_cache import cache_generated_vocabulary, get_cached_vocabulary

        # Get user's current vocabulary knowledge
        known_words = await self._get_user_vocabulary(request.user_id, request.language_code)

        # Estimate proficiency based on known vocabulary
        estimated_proficiency = self._estimate_proficiency(len(known_words))

        # Check cache first for efficiency
        cached_items = await get_cached_vocabulary(self.db, request, known_words)

        if cached_items and len(cached_items) >= request.count:
            # Use cached vocabulary
            items = cached_items[: request.count]
        else:
            # Build LLM prompt for vocabulary generation
            prompt = self._build_generation_prompt(request, known_words)

            # Call LLM API directly
            llm_response = await self._call_llm_api(
                prompt=prompt,
                provider_name=self.llm.name,
                token=self.token,
            )

            # Parse LLM response into vocabulary items with script transformations
            items = self._parse_llm_response(llm_response, request.language_code)

            # Cache generated vocabulary for future use
            await cache_generated_vocabulary(self.db, items, request)

        # Calculate next review date using spaced repetition
        next_review = self._calculate_next_review(request.proficiency_level)

        return VocabularyGenerationResponse(
            items=items,
            proficiency_level=request.proficiency_level,
            total_known_words=len(known_words),
            estimated_proficiency=estimated_proficiency,
            next_review_date=next_review,
        )

    async def record_vocabulary_interaction(
        self,
        user_id: int,
        language_code: str,
        word: str,
        correct: bool,
        response_time_ms: int,
    ) -> None:
        """Record user interaction with vocabulary for spaced repetition.

        Args:
            user_id: User ID
            language_code: Language code
            word: Vocabulary word
            correct: Whether user answered correctly
            response_time_ms: Response time in milliseconds
        """
        # Get or create vocabulary record
        stmt = select(UserVocabulary).where(
            UserVocabulary.user_id == user_id,
            UserVocabulary.language_code == language_code,
            UserVocabulary.word == word,
        )
        result = await self.db.execute(stmt)
        vocab = result.scalar_one_or_none()

        if not vocab:
            vocab = UserVocabulary(
                user_id=user_id,
                language_code=language_code,
                word=word,
                times_seen=0,
                times_correct=0,
                mastery_level=MasteryLevel.NEW.value,
            )
            self.db.add(vocab)

        # Update interaction statistics
        vocab.times_seen += 1
        if correct:
            vocab.times_correct += 1

        vocab.last_seen = datetime.utcnow()
        vocab.avg_response_time_ms = (
            (vocab.avg_response_time_ms * (vocab.times_seen - 1) + response_time_ms) / vocab.times_seen
            if vocab.avg_response_time_ms
            else response_time_ms
        )

        # Update mastery level using spaced repetition algorithm
        vocab.mastery_level = self._calculate_mastery_level(
            times_seen=vocab.times_seen,
            accuracy=vocab.times_correct / vocab.times_seen,
            avg_response_time=vocab.avg_response_time_ms,
        ).value

        # Calculate next review date using SM-2 algorithm (SuperMemo)
        vocab.next_review = self._calculate_sm2_interval(
            current_interval=vocab.interval_days or 1,
            ease_factor=vocab.ease_factor or 2.5,
            correct=correct,
        )

        await self.db.commit()

    async def get_review_vocabulary(
        self, user_id: int, language_code: str, count: int = 20
    ) -> list[VocabularyItem]:
        """Get vocabulary due for review based on spaced repetition.

        Args:
            user_id: User ID
            language_code: Language code
            count: Number of words to review

        Returns:
            List of vocabulary items due for review
        """
        stmt = (
            select(UserVocabulary)
            .where(
                UserVocabulary.user_id == user_id,
                UserVocabulary.language_code == language_code,
                UserVocabulary.next_review <= datetime.utcnow(),
            )
            .order_by(UserVocabulary.next_review.asc())
            .limit(count)
        )

        result = await self.db.execute(stmt)
        vocab_records = result.scalars().all()

        # Generate full vocabulary items for each word using LLM
        items = []
        for record in vocab_records:
            item = await self._enrich_vocabulary_item(
                language_code=language_code, word=record.word, user_id=user_id
            )
            items.append(item)

        return items

    def _build_generation_prompt(self, request: VocabularyGenerationRequest, known_words: set[str]) -> str:
        """Build LLM prompt for vocabulary generation.

        Args:
            request: Generation request
            known_words: Set of words user already knows

        Returns:
            LLM prompt
        """
        from app.lesson.language_config import get_language_config

        lang_config = get_language_config(request.language_code)

        # Build comprehensive prompt
        prompt = f"""You are an expert linguist and language teacher specializing in {lang_config.name}.

**Task:** Generate {request.count} vocabulary words for a learner at {request.proficiency_level.value} level.

**Language:** {lang_config.name} ({request.language_code})
**Native script:** {lang_config.native_name}
**Proficiency level:** {request.proficiency_level.value}
**Difficulty range:** {request.difficulty_range[0].value} to {request.difficulty_range[1].value}
**Context type:** {request.context_type}
{f"**Topic focus:** {request.topic}" if request.topic else ""}

**User's current vocabulary size:** {len(known_words)} words

**Requirements:**
1. Generate words appropriate for {request.proficiency_level.value} learners
2. Include a mix of:
   - Core vocabulary (nouns, verbs, adjectives)
   - Grammatical words (prepositions, conjunctions)
   - {request.context_type}-specific terminology
3. Each word must include:
   - The word in {lang_config.name} script: {lang_config.native_name}
   - English translation
   - Transliteration (if non-Latin script)
   - Part of speech
   - Difficulty level (core_basic, basic, intermediate, advanced, specialized, rare)
   - Frequency rank (estimate based on corpus frequency, 1 = most common)
   - Example sentence in {lang_config.name} showing natural usage
   - Example sentence translation
   - Etymology or word origin
   - Semantic field (family, food, religion, nature, etc)
   - Related words (synonyms, antonyms, derivatives)
   - Cultural/historical notes (if relevant)

4. **CRITICAL:** Do NOT include these words user already knows: {", ".join(list(known_words)[:50])}{"..." if len(known_words) > 50 else ""}

5. **CRITICAL - Authentic Script Conventions:**
   {self._get_script_guidelines(request.language_code)}

**Output format (JSON):**
{{
  "vocabulary": [
    {{
      "word": "word in {lang_config.native_name} script",
      "translation": "English translation",
      "transliteration": "romanized form",
      "part_of_speech": "noun|verb|adjective|etc",
      "difficulty": "core_basic|basic|intermediate|advanced|specialized|rare",
      "frequency_rank": 123,
      "example_sentence": "Example in {lang_config.native_name}",
      "example_translation": "Example in English",
      "etymology": "Word origin/etymology",
      "semantic_field": "category",
      "related_words": ["word1", "word2"],
      "cultural_notes": "Optional cultural context"
    }}
  ]
}}

Generate vocabulary that helps the learner progress from {request.proficiency_level.value} to the next level."""

        return prompt

    def _parse_llm_response(
        self, llm_response: str, language_code: str | None = None
    ) -> list[VocabularyItem]:
        """Parse LLM JSON response into vocabulary items.

        Args:
            llm_response: JSON response from LLM
            language_code: Optional language code for script transformations

        Returns:
            List of vocabulary items with authentic script applied
        """
        import json

        data = json.loads(llm_response)
        items = []

        for vocab_data in data.get("vocabulary", []):
            # Normalize raw fields defensively
            raw_word = self._coerce_to_text(vocab_data.get("word"))
            raw_example = self._coerce_to_text(vocab_data.get("example_sentence"))
            raw_related = vocab_data.get("related_words", [])

            if language_code:
                word = self._apply_script_transformation(raw_word, language_code)
                example = self._apply_script_transformation(raw_example, language_code)
                related = [
                    self._apply_script_transformation(self._coerce_to_text(entry), language_code)
                    for entry in raw_related
                    if self._coerce_to_text(entry)
                ]
            else:
                word = raw_word
                example = raw_example
                related = [
                    self._coerce_to_text(entry) for entry in raw_related if self._coerce_to_text(entry)
                ]

            item = VocabularyItem(
                word=word,
                translation=vocab_data["translation"],
                transliteration=vocab_data.get("transliteration"),
                part_of_speech=vocab_data["part_of_speech"],
                difficulty=VocabularyDifficulty(vocab_data["difficulty"]),
                frequency_rank=vocab_data.get("frequency_rank"),
                example_sentence=example,
                example_translation=vocab_data["example_translation"],
                etymology=vocab_data.get("etymology"),
                semantic_field=vocab_data["semantic_field"],
                related_words=related,
                cultural_notes=vocab_data.get("cultural_notes"),
            )
            items.append(item)

        return items

    def _coerce_to_text(self, value: Any) -> str:
        """Coerce heterogeneous LLM payloads into plain text."""
        if isinstance(value, str):
            return value
        if isinstance(value, dict):
            for candidate in ("text", "surface", "value", "word"):
                inner = value.get(candidate)
                if isinstance(inner, str):
                    return inner
        if isinstance(value, list):
            parts = [self._coerce_to_text(entry) for entry in value]
            return " ".join(part for part in parts if part)
        if value is None:
            return ""
        return str(value)

    def _apply_script_transformation(self, text: str, language_code: str) -> str:
        """Apply authentic script transformations to text.

        Args:
            text: Text to transform
            language_code: Language code

        Returns:
            Text with authentic script applied
        """
        from app.lesson.script_utils import apply_script_transform

        return apply_script_transform(text, language_code)

    def _get_script_guidelines(self, language_code: str) -> str:
        """Get detailed script guidelines for AI prompts.

        Args:
            language_code: Language code

        Returns:
            Formatted script guidelines
        """
        from app.lesson.language_config import get_script_guidelines

        return get_script_guidelines(language_code)

    async def _get_user_vocabulary(self, user_id: int, language_code: str) -> set[str]:
        """Get set of words user has already learned.

        Args:
            user_id: User ID
            language_code: Language code

        Returns:
            Set of known words
        """
        stmt = select(UserVocabulary.word).where(
            UserVocabulary.user_id == user_id,
            UserVocabulary.language_code == language_code,
            UserVocabulary.mastery_level.in_([MasteryLevel.KNOWN.value, MasteryLevel.MASTERED.value]),
        )

        result = await self.db.execute(stmt)
        return set(result.scalars().all())

    def _estimate_proficiency(self, known_word_count: int) -> ProficiencyLevel:
        """Estimate proficiency level based on vocabulary size.

        Args:
            known_word_count: Number of known words

        Returns:
            Estimated proficiency level
        """
        if known_word_count == 0:
            return ProficiencyLevel.ABSOLUTE_BEGINNER
        elif known_word_count < 100:
            return ProficiencyLevel.BEGINNER
        elif known_word_count < 500:
            return ProficiencyLevel.ELEMENTARY
        elif known_word_count < 1500:
            return ProficiencyLevel.INTERMEDIATE
        elif known_word_count < 3000:
            return ProficiencyLevel.UPPER_INTERMEDIATE
        elif known_word_count < 5000:
            return ProficiencyLevel.ADVANCED
        elif known_word_count < 8000:
            return ProficiencyLevel.PROFICIENT
        else:
            return ProficiencyLevel.EXPERT

    def _calculate_mastery_level(
        self, times_seen: int, accuracy: float, avg_response_time: int
    ) -> MasteryLevel:
        """Calculate mastery level using AI-driven algorithm.

        Args:
            times_seen: Number of times word was shown
            accuracy: Accuracy rate (0.0-1.0)
            avg_response_time: Average response time in ms

        Returns:
            Mastery level
        """
        # Fast response (<2s) + high accuracy = better mastery
        speed_bonus = 1.0 if avg_response_time < 2000 else 0.8

        if times_seen == 0:
            return MasteryLevel.NEW
        elif times_seen <= 3:
            return MasteryLevel.LEARNING
        elif times_seen <= 10:
            if accuracy >= 0.8 and speed_bonus > 0.9:
                return MasteryLevel.KNOWN
            elif accuracy >= 0.5:
                return MasteryLevel.FAMILIAR
            else:
                return MasteryLevel.LEARNING
        else:  # times_seen > 10
            if accuracy >= 0.95 and speed_bonus > 0.9:
                return MasteryLevel.MASTERED
            elif accuracy >= 0.8:
                return MasteryLevel.KNOWN
            elif accuracy >= 0.5:
                return MasteryLevel.FAMILIAR
            else:
                return MasteryLevel.LEARNING

    def _calculate_next_review(self, proficiency_level: ProficiencyLevel) -> datetime:
        """Calculate next review date based on proficiency.

        Args:
            proficiency_level: User's proficiency level

        Returns:
            Next review datetime
        """
        # Higher proficiency = longer intervals between reviews
        intervals = {
            ProficiencyLevel.ABSOLUTE_BEGINNER: 1,  # 1 day
            ProficiencyLevel.BEGINNER: 2,
            ProficiencyLevel.ELEMENTARY: 3,
            ProficiencyLevel.INTERMEDIATE: 5,
            ProficiencyLevel.UPPER_INTERMEDIATE: 7,
            ProficiencyLevel.ADVANCED: 10,
            ProficiencyLevel.PROFICIENT: 14,
            ProficiencyLevel.EXPERT: 21,
        }

        days = intervals.get(proficiency_level, 3)
        return datetime.utcnow() + timedelta(days=days)

    def _calculate_sm2_interval(self, current_interval: int, ease_factor: float, correct: bool) -> datetime:
        """Calculate next review using SuperMemo SM-2 algorithm.

        Args:
            current_interval: Current interval in days
            ease_factor: Ease factor (2.5 default)
            correct: Whether answer was correct

        Returns:
            Next review datetime
        """
        if not correct:
            # Reset to 1 day if incorrect
            next_interval = 1
            new_ease_factor = max(1.3, ease_factor - 0.2)
        else:
            # Increase interval based on ease factor
            if current_interval == 1:
                next_interval = 6
            else:
                next_interval = int(current_interval * ease_factor)

            new_ease_factor = ease_factor + 0.1

        return datetime.utcnow() + timedelta(days=next_interval)

    async def _enrich_vocabulary_item(self, language_code: str, word: str, user_id: int) -> VocabularyItem:
        """Enrich a single vocabulary word with LLM-generated context.

        Args:
            language_code: Language code
            word: Vocabulary word
            user_id: User ID for personalization

        Returns:
            Enriched vocabulary item
        """
        # Build enrichment prompt
        prompt = f"""Provide comprehensive information about this word:

**Word:** {word}
**Language:** {language_code}

Generate a JSON response with:
- translation (English)
- transliteration (if non-Latin script)
- part_of_speech
- difficulty (core_basic, basic, intermediate, advanced, specialized, rare)
- frequency_rank
- example_sentence (in original language)
- example_translation
- etymology
- semantic_field
- related_words (list)
- cultural_notes

Format as JSON."""

        llm_response = await self.llm.generate(
            prompt=prompt,
            response_format="json_object",
            temperature=0.3,
            max_output_tokens=800,
        )

        import json

        data = json.loads(llm_response)

        return VocabularyItem(
            word=word,
            translation=data["translation"],
            transliteration=data.get("transliteration"),
            part_of_speech=data["part_of_speech"],
            difficulty=VocabularyDifficulty(data["difficulty"]),
            frequency_rank=data.get("frequency_rank"),
            example_sentence=data["example_sentence"],
            example_translation=data["example_translation"],
            etymology=data.get("etymology"),
            semantic_field=data["semantic_field"],
            related_words=data.get("related_words", []),
            cultural_notes=data.get("cultural_notes"),
        )

    async def _call_llm_api(self, prompt: str, provider_name: str, token: str | None) -> str:
        """Call LLM API directly to generate vocabulary.

        Args:
            prompt: LLM prompt
            provider_name: Provider name (openai, anthropic, google)
            token: API token

        Returns:
            JSON string response from LLM
        """
        logger = logging.getLogger("app.vocab")

        if provider_name == "openai":
            return await self._call_openai_api(prompt, token, logger)
        elif provider_name == "anthropic":
            return await self._call_anthropic_api(prompt, token, logger)
        elif provider_name == "google":
            return await self._call_google_api(prompt, token, logger)
        else:
            raise ValueError(f"Unsupported provider: {provider_name}")

    async def _call_openai_api(self, prompt: str, token: str | None, logger) -> str:
        """Call OpenAI GPT-5 Responses API."""

        import httpx

        model = "gpt-5-mini"
        url = "https://api.openai.com/v1/responses"

        payload = {
            "model": model,
            "input": [{"role": "user", "content": [{"type": "input_text", "text": prompt}]}],
            "max_output_tokens": 4000,
            "text": {"format": {"type": "json_object"}},
        }

        headers = {
            "Authorization": f"Bearer {token}",
            "Content-Type": "application/json",
        }

        logger.info(f"[Vocab] Calling OpenAI {model}")

        async with httpx.AsyncClient(timeout=60.0) as client:
            response = await client.post(url, headers=headers, json=payload)
            data = response.json()

            # Check for API error before raising HTTP error
            if "error" in data:
                error_info = data["error"]
                error_msg = error_info.get("message", str(error_info))
                logger.error(f"[Vocab OpenAI] API error: {error_msg}")
                raise ValueError(f"OpenAI API error: {error_msg}")

            response.raise_for_status()

        # Log the full response for debugging
        logger.info(f"[Vocab OpenAI] Response status: {response.status_code}")
        logger.info(f"[Vocab OpenAI] Response keys: {list(data.keys())}")

        # Extract from Responses API
        return self._extract_openai_output_text(data)

    async def _call_anthropic_api(self, prompt: str, token: str | None, logger) -> str:
        """Call Anthropic Claude 4.5 API."""
        import httpx

        model = "claude-4.5-sonnet"
        url = "https://api.anthropic.com/v1/messages"

        payload = {
            "model": model,
            "max_tokens": 4000,
            "temperature": 0.7,
            "messages": [{"role": "user", "content": prompt}],
        }

        headers = {
            "x-api-key": token,
            "Content-Type": "application/json",
            "anthropic-version": "2023-06-01",
        }

        logger.info(f"[Vocab] Calling Anthropic {model}")

        async with httpx.AsyncClient(timeout=60.0) as client:
            response = await client.post(url, headers=headers, json=payload)
            response.raise_for_status()
            data = response.json()

        logger.info(f"[Vocab Anthropic] Response keys: {list(data.keys())}")

        content = data.get("content", [])
        if content and len(content) > 0:
            text = content[0].get("text", "")
            if text:
                logger.info("[Vocab Anthropic] Extracted from content[0].text")
                return text

        # Fallback: check for direct text field
        if "text" in data:
            logger.info("[Vocab Anthropic] Found 'text' field in response")
            return data["text"]

        logger.error(f"[Vocab Anthropic] No content found. Full response: {data}")
        raise ValueError(f"No content in Anthropic response. Available keys: {list(data.keys())}")

    async def _call_google_api(self, prompt: str, token: str | None, logger) -> str:
        """Call Google Gemini 2.5 API."""
        import httpx

        model = "gemini-2.5-flash"
        url = f"https://generativelanguage.googleapis.com/v1beta/models/{model}:generateContent"

        payload = {
            "contents": [{"parts": [{"text": prompt}]}],
            "generationConfig": {
                "temperature": 0.7,
                "maxOutputTokens": 4000,
                "responseMimeType": "application/json",
            },
        }

        headers = {"Content-Type": "application/json"}
        params = {"key": token}

        logger.info(f"[Vocab] Calling Google {model}")

        async with httpx.AsyncClient(timeout=60.0) as client:
            response = await client.post(url, headers=headers, json=payload, params=params)
            response.raise_for_status()
            data = response.json()

        logger.info(f"[Vocab Google] Response keys: {list(data.keys())}")

        candidates = data.get("candidates", [])
        if candidates and len(candidates) > 0:
            content = candidates[0].get("content", {})
            parts = content.get("parts", [])
            if parts and len(parts) > 0:
                text = parts[0].get("text", "")
                if text:
                    logger.info("[Vocab Google] Extracted from candidates[0].content.parts[0].text")
                    return text

        # Fallback: check for direct text field
        if "text" in data:
            logger.info("[Vocab Google] Found 'text' field in response")
            return data["text"]

        # Fallback: check for content field
        if "content" in data:
            content = data["content"]
            if isinstance(content, str):
                logger.info("[Vocab Google] Found 'content' string in response")
                return content

        logger.error(f"[Vocab Google] No content found. Full response: {data}")
        raise ValueError(f"No content in Google response. Available keys: {list(data.keys())}")

    def _extract_openai_output_text(self, data: dict[str, Any]) -> str:
        """Extract plain text payload from OpenAI Responses API reply.

        This uses the same extraction logic as the lesson provider to ensure consistency.
        """
        logger = logging.getLogger("app.vocab.openai")

        logger.info(f"[Vocab OpenAI] Response keys: {list(data.keys())}")

        # Check for incomplete response (reasoning consumed all tokens)
        if data.get("status") == "incomplete":
            reason = data.get("incomplete_details", {}).get("reason", "unknown")
            if reason == "max_output_tokens":
                raise ValueError(
                    "Response incomplete: reasoning consumed all tokens. "
                    "Try increasing max_output_tokens in vocabulary generation."
                )
            raise ValueError(f"Response incomplete: {reason}")

        # FALLBACK 1: Try ChatCompletion format first (most common)
        if "choices" in data:
            logger.info("[Vocab OpenAI] Found 'choices' - trying ChatCompletion format")
            choices = data.get("choices", [])
            if choices:
                message = choices[0].get("message", {})
                content = message.get("content")
                if content:
                    logger.info("[Vocab OpenAI] Extracted from choices[0].message.content")
                    return content

        # PRIMARY: Check for Responses API format (GPT-5)
        output_items = data.get("output") or []
        logger.info(f"[Vocab OpenAI] Output items: {len(output_items)}")

        if not output_items:
            # FALLBACK 2: Check for direct text field in response
            if "text" in data:
                logger.info("[Vocab OpenAI] Found 'text' field directly in response")
                return data["text"]

            # FALLBACK 3: Check for content field
            if "content" in data:
                logger.info("[Vocab OpenAI] Found 'content' field in response")
                content = data["content"]
                if isinstance(content, str):
                    return content
                elif isinstance(content, list) and content:
                    # Try to extract text from first content item
                    first_item = content[0]
                    if isinstance(first_item, dict) and "text" in first_item:
                        return first_item["text"]
                    elif isinstance(first_item, str):
                        return first_item

            raise ValueError(f"OpenAI API: missing output array. Available keys: {list(data.keys())}")

        # Find message items with output_text
        for idx, item in enumerate(output_items):
            logger.info(f"[Vocab OpenAI] Item {idx}: type={item.get('type')}, keys={list(item.keys())}")
            if item.get("type") == "message":
                content_items = item.get("content") or []
                logger.info(f"[Vocab OpenAI] Message has {len(content_items)} content items")
                for cidx, content in enumerate(content_items):
                    content_type = content.get("type")
                    logger.info(
                        f"[Vocab OpenAI] Content {cidx}: type={content_type}, keys={list(content.keys())}"
                    )
                    if content_type == "output_text":
                        text = content.get("text")
                        if text:
                            logger.info("[Vocab OpenAI] Found output_text.text")
                            return text
                    # Fallback: try 'text' field directly
                    elif "text" in content:
                        text = content.get("text")
                        if text:
                            logger.info("[Vocab OpenAI] Found text field in content")
                            return text
            # FALLBACK 4: If item has text directly (non-message type)
            elif "text" in item:
                text = item.get("text")
                if text:
                    logger.info(f"[Vocab OpenAI] Found text in item {idx} (non-message)")
                    return text

        # If we get here, we couldn't find output_text
        logger.error(f"[Vocab OpenAI] Could not extract text. Full response: {data}")
        raise ValueError(f"No output_text found in OpenAI response. Response keys: {list(data.keys())}")
