from __future__ import annotations

from typing import Annotated, Literal

from pydantic import BaseModel, Field, field_validator, model_validator

SourceKind = Literal["daily", "canon"]
ExerciseType = Literal["alphabet", "match", "cloze", "translate"]
LessonProfile = Literal["beginner", "intermediate"]
LessonProviderName = Literal["echo", "openai"]


class LessonGenerateRequest(BaseModel):
    language: str = Field(default="grc", min_length=2)
    profile: LessonProfile = Field(default="beginner")
    sources: list[SourceKind] = Field(default_factory=lambda: ["daily"])
    exercise_types: list[ExerciseType] = Field(default_factory=lambda: ["alphabet", "match", "translate"])
    k_canon: int = Field(default=1, ge=0, le=10)
    include_audio: bool = False
    provider: LessonProviderName = Field(default="echo")
    model: str | None = None

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
        if self.language != "grc":
            raise ValueError("Only 'grc' lessons are supported in v0")
        if "canon" not in self.sources:
            object.__setattr__(self, "k_canon", 0)
        elif self.k_canon == 0:
            object.__setattr__(self, "k_canon", 1)
        return self


class LessonMeta(BaseModel):
    language: str
    profile: LessonProfile
    provider: str
    model: str


class AlphabetTask(BaseModel):
    type: Literal["alphabet"] = "alphabet"
    prompt: str
    options: list[str] = Field(min_length=2)
    answer: str


class MatchPair(BaseModel):
    grc: str
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
    direction: Literal["grc->en", "en->grc"] = "grc->en"
    text: str
    rubric: str | None = None


LessonTask = Annotated[AlphabetTask | MatchTask | ClozeTask | TranslateTask, Field(discriminator="type")]


class LessonResponse(BaseModel):
    meta: LessonMeta
    tasks: list[LessonTask]
