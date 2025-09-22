from __future__ import annotations

import random
from dataclasses import dataclass
from typing import Sequence

from sqlalchemy.ext.asyncio import AsyncSession

from app.lesson.models import (
    AlphabetTask,
    ClozeBlank,
    ClozeTask,
    LessonGenerateRequest,
    LessonMeta,
    LessonResponse,
    MatchPair,
    MatchTask,
    TranslateTask,
)
from app.lesson.providers import DailyLine, LessonContext, LessonProvider, LessonProviderError


@dataclass(frozen=True)
class _Letter:
    name: str
    symbol: str


_ALPHABET: tuple[_Letter, ...] = (
    _Letter("alpha", "α"),
    _Letter("beta", "β"),
    _Letter("gamma", "γ"),
    _Letter("delta", "δ"),
    _Letter("epsilon", "ε"),
    _Letter("zeta", "ζ"),
    _Letter("eta", "η"),
    _Letter("theta", "θ"),
    _Letter("iota", "ι"),
    _Letter("kappa", "κ"),
    _Letter("lambda", "λ"),
    _Letter("mu", "μ"),
    _Letter("nu", "ν"),
    _Letter("xi", "ξ"),
    _Letter("omicron", "ο"),
    _Letter("pi", "π"),
    _Letter("rho", "ρ"),
    _Letter("sigma", "σ"),
    _Letter("tau", "τ"),
    _Letter("upsilon", "υ"),
    _Letter("phi", "φ"),
    _Letter("chi", "χ"),
    _Letter("psi", "ψ"),
    _Letter("omega", "ω"),
)


class EchoLessonProvider(LessonProvider):
    name = "echo"

    async def generate(
        self,
        *,
        request: LessonGenerateRequest,
        session: AsyncSession,
        token: str | None,
        context: LessonContext,
    ) -> LessonResponse:
        rng = random.Random(context.seed)
        tasks = []

        for exercise in request.exercise_types:
            if exercise == "alphabet":
                tasks.append(_build_alphabet_task(rng))
            elif exercise == "match":
                tasks.append(_build_match_task(context, rng))
            elif exercise == "cloze":
                tasks.append(_build_cloze_task(context, rng))
            elif exercise == "translate":
                tasks.append(_build_translate_task(context, rng))

        if not tasks:
            raise LessonProviderError("Echo provider could not build any tasks")

        meta = LessonMeta(
            language=request.language,
            profile=request.profile,
            provider=self.name,
            model=self.name,
        )
        return LessonResponse(meta=meta, tasks=tasks)


def _build_alphabet_task(rng: random.Random) -> AlphabetTask:
    target = rng.choice(_ALPHABET)
    options = {target.symbol}
    while len(options) < 4:
        options.add(rng.choice(_ALPHABET).symbol)
    option_list = list(options)
    rng.shuffle(option_list)
    prompt = f"Select the letter named '{target.name}'"
    return AlphabetTask(prompt=prompt, options=option_list, answer=target.symbol)


def _build_match_task(context: LessonContext, rng: random.Random) -> MatchTask:
    pool = list(context.daily_lines) or list(_fallback_daily_lines())
    if len(pool) < 2:
        raise LessonProviderError("Insufficient daily lines for match task")
    count = min(3, len(pool))
    selected = rng.sample(pool, count)
    pairs = [MatchPair(grc=_choose_variant(line, rng), en=line.en) for line in selected]
    rng.shuffle(pairs)
    return MatchTask(pairs=pairs)


def _build_cloze_task(context: LessonContext, rng: random.Random) -> ClozeTask:
    if context.canonical_lines:
        source = rng.choice(context.canonical_lines)
        source_kind = "canon"
        ref = source.ref
        text = source.text
    else:
        fallback = list(context.daily_lines) or list(_fallback_daily_lines())
        line = rng.choice(fallback)
        source_kind = "daily"
        ref = None
        text = _choose_variant(line, rng)
    tokens = text.split()
    if not tokens:
        raise LessonProviderError("Cannot build cloze task from empty text")
    blanks_needed = 2 if len(tokens) >= 3 else 1
    blank_indices = sorted(rng.sample(range(len(tokens)), k=blanks_needed))
    blanks = []
    for idx in blank_indices:
        blanks.append(ClozeBlank(surface=tokens[idx], idx=idx))
        tokens[idx] = "____"
    cloze_text = " ".join(tokens)
    return ClozeTask(source_kind=source_kind, ref=ref, text=cloze_text, blanks=blanks)


def _build_translate_task(context: LessonContext, rng: random.Random) -> TranslateTask:
    pool = list(context.daily_lines) or list(_fallback_daily_lines())
    line = rng.choice(pool)
    text = _choose_variant(line, rng)
    return TranslateTask(
        direction="grc->en",
        text=text,
        rubric="Write a natural English translation.",
    )


def _choose_variant(line: DailyLine, rng: random.Random) -> str:
    variants: Sequence[str] = line.variants or (line.grc,)
    return rng.choice(tuple(variants))


def _fallback_daily_lines() -> tuple[DailyLine, ...]:
    return (
        DailyLine(grc="Χαῖρε!", en="Hello!", variants=("Χαῖρε!", "χαῖρε!")),
        DailyLine(grc="Ἔρρωσο.", en="Farewell.", variants=("Ἔρρωσο.",)),
        DailyLine(grc="Τί ὄνομά σου;", en="What is your name?"),
        DailyLine(grc="Παρακαλῶ.", en="You're welcome."),
    )
