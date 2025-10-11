from __future__ import annotations

from typing import Annotated, Literal

from pydantic import BaseModel, ConfigDict, Field, field_validator, model_validator

SourceKind = Literal["daily", "canon", "text_range"]
ExerciseType = Literal[
    "alphabet",
    "match",
    "cloze",
    "translate",
    "grammar",
    "listening",
    "speaking",
    "wordbank",
    "truefalse",
    "multiplechoice",
    "dialogue",  # Complete a dialogue conversation
    "conjugation",  # Conjugate verbs
    "declension",  # Decline nouns/adjectives
    "synonym",  # Match synonyms/antonyms
    "contextmatch",  # Choose word that fits context
    "reorder",  # Reorder sentence fragments into coherent text
    "dictation",  # Write what you hear (spelling practice)
    "etymology",  # Learn word origins and relationships
]
LessonProfile = Literal["beginner", "intermediate"]
LessonProviderName = Literal["echo", "openai", "anthropic", "google"]
RegisterMode = Literal["literary", "colloquial"]


class TextRange(BaseModel):
    """Text range for targeted vocabulary/grammar extraction"""

    ref_start: str = Field(min_length=1)
    ref_end: str = Field(min_length=1)


class LessonGenerateRequest(BaseModel):
    language: str = Field(default="grc", min_length=2)
    profile: LessonProfile = Field(default="beginner")
    sources: list[SourceKind] = Field(default_factory=lambda: ["daily"])
    exercise_types: list[ExerciseType] = Field(default_factory=lambda: ["alphabet", "match", "translate"])
    k_canon: int = Field(default=1, ge=0, le=10)
    include_audio: bool = False
    provider: LessonProviderName = Field(default="echo")
    model: str | None = None
    text_range: TextRange | None = None
    task_count: int = Field(default=20, ge=1, le=100)  # Number of tasks to generate
    # Use alias to avoid shadowing BaseModel.register method
    language_register: RegisterMode = Field(default="literary", alias="register")

    @field_validator("language", mode="before")
    @classmethod
    def _normalize_language(cls, value: str) -> str:
        return value.lower().strip()

    @field_validator("sources")
    @classmethod
    def _dedupe_sources(cls, value: list[SourceKind]) -> list[SourceKind]:
        seen: set[str] = set()
        deduped: list[SourceKind] = []
        for item in value:
            if item not in seen:
                seen.add(item)
                deduped.append(item)
        return deduped or ["daily"]

    @field_validator("exercise_types")
    @classmethod
    def _dedupe_exercise_types(cls, value: list[ExerciseType]) -> list[ExerciseType]:
        seen: set[str] = set()
        deduped: list[ExerciseType] = []
        for item in value:
            if item not in seen:
                seen.add(item)
                deduped.append(item)
        return deduped or ["alphabet", "match", "translate"]

    @model_validator(mode="after")
    def _enforce_language_and_canon(self) -> "LessonGenerateRequest":
        # Multi-language support enabled! Supported languages:
        # grc (Classical Greek), lat (Latin), hbo (Biblical Hebrew),
        # san (Sanskrit), cop (Coptic), egy (Egyptian), akk (Akkadian)
        supported_languages = {"grc", "lat", "hbo", "san", "cop", "egy", "akk"}
        if self.language not in supported_languages:
            raise ValueError(
                f"Language '{self.language}' not supported. "
                f"Supported: {', '.join(sorted(supported_languages))}"
            )
        if "canon" not in self.sources:
            object.__setattr__(self, "k_canon", 0)
        elif self.k_canon == 0:
            object.__setattr__(self, "k_canon", 1)
        return self

    model_config = ConfigDict(populate_by_name=True)


class LessonMeta(BaseModel):
    language: str
    profile: LessonProfile
    provider: str
    model: str
    note: str | None = None

    model_config = ConfigDict(exclude_none=True)

    def model_dump(self, *args, **kwargs):
        kwargs.setdefault("exclude_none", True)
        return super().model_dump(*args, **kwargs)


class AlphabetTask(BaseModel):
    type: Literal["alphabet"] = "alphabet"
    prompt: str
    options: list[str] = Field(min_length=2)
    answer: str


class MatchPair(BaseModel):
    native: str  # Language-agnostic: contains the word in the target language (grc, lat, hbo, san, etc.)
    en: str


class MatchTask(BaseModel):
    type: Literal["match"] = "match"
    pairs: list[MatchPair] = Field(min_length=1)


class ClozeBlank(BaseModel):
    surface: str
    idx: int = Field(ge=0)


class ClozeTask(BaseModel):
    type: Literal["cloze"] = "cloze"
    source_kind: SourceKind
    ref: str | None = None
    text: str
    blanks: list[ClozeBlank] = Field(min_length=1)
    options: list[str] | None = None


class TranslateTask(BaseModel):
    type: Literal["translate"] = "translate"
    direction: Literal["native->en", "en->native"] = "native->en"  # Language-agnostic direction
    text: str
    rubric: str | None = None
    sampleSolution: str | None = None  # Example correct translation for validation


class GrammarTask(BaseModel):
    """Identify if sentence has correct grammar"""

    type: Literal["grammar"] = "grammar"
    sentence: str
    is_correct: bool
    error_explanation: str | None = None


class ListeningTask(BaseModel):
    """Listen to audio and select correct word/phrase"""

    type: Literal["listening"] = "listening"
    audio_url: str | None = None
    audio_text: str  # What they should hear
    options: list[str] = Field(min_length=2)
    answer: str


class SpeakingTask(BaseModel):
    """Practice pronunciation by speaking"""

    type: Literal["speaking"] = "speaking"
    prompt: str
    target_text: str
    phonetic_guide: str | None = None


class WordBankTask(BaseModel):
    """Arrange words to form correct sentence"""

    type: Literal["wordbank"] = "wordbank"
    words: list[str] = Field(min_length=2)
    correct_order: list[int]  # Indices of words in correct order
    translation: str


class TrueFalseTask(BaseModel):
    """True/False about grammar or vocabulary"""

    type: Literal["truefalse"] = "truefalse"
    statement: str
    is_true: bool
    explanation: str


class MultipleChoiceTask(BaseModel):
    """Multiple choice comprehension question"""

    type: Literal["multiplechoice"] = "multiplechoice"
    question: str
    context: str | None = None
    options: list[str] = Field(min_length=2)
    answer_index: int = Field(ge=0)


class DialogueLine(BaseModel):
    speaker: str
    text: str


class DialogueTask(BaseModel):
    """Complete a dialogue conversation"""

    type: Literal["dialogue"] = "dialogue"
    lines: list[DialogueLine] = Field(min_length=2)
    missing_index: int = Field(ge=0)
    options: list[str] = Field(min_length=2)
    answer: str


class ConjugationTask(BaseModel):
    """Conjugate a verb"""

    type: Literal["conjugation"] = "conjugation"
    verb_infinitive: str
    verb_meaning: str
    person: str  # e.g., "1st person singular"
    tense: str  # e.g., "present", "aorist"
    answer: str


class DeclensionTask(BaseModel):
    """Decline a noun or adjective"""

    type: Literal["declension"] = "declension"
    word: str
    word_meaning: str
    case: str  # e.g., "genitive"
    number: str  # "singular" or "plural"
    answer: str


class SynonymTask(BaseModel):
    """Match synonyms or identify antonyms"""

    type: Literal["synonym"] = "synonym"
    word: str
    task_type: Literal["synonym", "antonym"]
    options: list[str] = Field(min_length=2)
    answer: str


class ContextMatchTask(BaseModel):
    """Choose the word that best fits the context"""

    type: Literal["contextmatch"] = "contextmatch"
    sentence: str  # Sentence with blank
    context_hint: str | None = None
    options: list[str] = Field(min_length=2)
    answer: str


class ReorderTask(BaseModel):
    """Reorder sentence fragments into coherent text"""

    type: Literal["reorder"] = "reorder"
    fragments: list[str] = Field(min_length=2)
    correct_order: list[int]  # Indices in correct order
    translation: str


class DictationTask(BaseModel):
    """Write what you hear (spelling practice)"""

    type: Literal["dictation"] = "dictation"
    audio_url: str | None = None
    target_text: str
    hint: str | None = None


class EtymologyTask(BaseModel):
    """Learn word origins and relationships"""

    type: Literal["etymology"] = "etymology"
    question: str
    word: str
    options: list[str] = Field(min_length=2)
    answer_index: int = Field(ge=0)
    explanation: str


LessonTask = Annotated[
    AlphabetTask
    | MatchTask
    | ClozeTask
    | TranslateTask
    | GrammarTask
    | ListeningTask
    | SpeakingTask
    | WordBankTask
    | TrueFalseTask
    | MultipleChoiceTask
    | DialogueTask
    | ConjugationTask
    | DeclensionTask
    | SynonymTask
    | ContextMatchTask
    | ReorderTask
    | DictationTask
    | EtymologyTask,
    Field(discriminator="type"),
]


class LessonResponse(BaseModel):
    meta: LessonMeta
    tasks: list[LessonTask]
