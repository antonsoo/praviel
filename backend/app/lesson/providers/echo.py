from __future__ import annotations

import hashlib
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


def _daily_ref(line: DailyLine) -> str:
    digest = hashlib.sha1(line.grc.encode("utf-8")).hexdigest()[:8]
    return f"daily:{digest}"


_PUNCTUATION_SUFFIXES = "·,.;:—!?…"
_BLANK_TOKEN = "____"


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
    # Use text_range vocabulary if available
    if context.text_range_data and context.text_range_data.vocabulary:
        vocab_items = list(context.text_range_data.vocabulary)
        count = min(3, len(vocab_items))
        selected = rng.sample(vocab_items, count)
        pairs = [
            MatchPair(
                grc=item.surface_forms[0] if item.surface_forms else item.lemma,
                en=f"{item.lemma} (appears {item.frequency}x)"
            )
            for item in selected
        ]
        rng.shuffle(pairs)
        return MatchTask(pairs=pairs)
    # Use text_range samples as fallback (when tokens not available)
    elif context.text_range_data and context.text_range_data.text_samples:
        samples = list(context.text_range_data.text_samples)
        if len(samples) < 2:
            # Fall through to daily lines
            pass
        else:
            count = min(3, len(samples))
            selected = rng.sample(samples, count)
            # Extract first 3-5 words from each sample
            pairs = []
            for sample in selected:
                words = sample.split()[:3]
                if words:  # Ensure non-empty
                    grc_text = " ".join(words)
                    en_text = f"from {context.text_range_data.ref_start}-{context.text_range_data.ref_end}"
                    pairs.append(MatchPair(grc=grc_text, en=en_text))
            if pairs:
                rng.shuffle(pairs)
                return MatchTask(pairs=pairs)
            # If no valid pairs, fall through to daily lines

    # Fallback to daily lines
    pool = list(context.daily_lines) or list(_fallback_daily_lines())
    if len(pool) < 2:
        raise LessonProviderError("Insufficient daily lines for match task")
    count = min(3, len(pool))
    selected = rng.sample(pool, count)
    pairs = [MatchPair(grc=_choose_variant(line, rng), en=line.en) for line in selected]
    rng.shuffle(pairs)
    return MatchTask(pairs=pairs)


def _build_cloze_task(context: LessonContext, rng: random.Random) -> ClozeTask:
    # Use text_range samples if available
    if context.text_range_data and context.text_range_data.text_samples:
        text = rng.choice(context.text_range_data.text_samples)
        source_kind = "text_range"
        ref = f"{context.text_range_data.ref_start}-{context.text_range_data.ref_end}"
    elif context.canonical_lines:
        source = rng.choice(context.canonical_lines)
        source_kind = "canon"
        ref = source.ref
        text = source.text
    else:
        fallback = list(context.daily_lines) or list(_fallback_daily_lines())
        line = rng.choice(fallback)
        source_kind = "daily"
        ref = _daily_ref(line)
        text = _choose_variant(line, rng)

    tokens = text.split()
    if not tokens:
        raise LessonProviderError("Cannot build cloze task from empty text")

    sanitized_tokens: list[str] = []
    suffixes: list[str] = []
    candidate_indices: list[int] = []
    for idx, token in enumerate(tokens):
        core, suffix = _split_cloze_token(token)
        sanitized_tokens.append(core)
        suffixes.append(suffix)
        if core:
            candidate_indices.append(idx)

    if not candidate_indices:
        raise LessonProviderError("Cannot build cloze task from punctuation-only text")

    blanks_needed = 2 if len(tokens) >= 3 else 1
    blanks_count = min(len(candidate_indices), blanks_needed)
    blanks_count = max(1, blanks_count)
    chosen_indices = sorted(rng.sample(candidate_indices, k=blanks_count))

    display_tokens = list(tokens)
    blanks: list[ClozeBlank] = []
    blank_surfaces: list[str] = []
    for idx in chosen_indices:
        surface = sanitized_tokens[idx]
        if not surface:
            continue
        blanks.append(ClozeBlank(surface=surface, idx=idx))
        blank_surfaces.append(surface)
        display_tokens[idx] = f"{_BLANK_TOKEN}{suffixes[idx]}"

    if not blanks:
        raise LessonProviderError("Failed to build cloze blanks from line")

    options = _build_cloze_options(
        blank_surfaces,
        sanitized_tokens,
        chosen_indices,
        context,
        rng,
    )

    cloze_text = " ".join(display_tokens)
    return ClozeTask(
        source_kind=source_kind,
        ref=ref,
        text=cloze_text,
        blanks=blanks,
        options=options,
    )


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


def _split_cloze_token(token: str) -> tuple[str, str]:
    core = token.rstrip(_PUNCTUATION_SUFFIXES)
    if not core:
        return "", ""
    return core, token[len(core) :]


def _token_surfaces(text: str) -> list[str]:
    surfaces: list[str] = []
    for raw in text.split():
        core, _ = _split_cloze_token(raw)
        if core:
            surfaces.append(core)
    return surfaces


def _gather_cloze_distractors(
    sanitized_tokens: Sequence[str],
    chosen_indices: Sequence[int],
    context: LessonContext,
    exclude: set[str],
) -> list[str]:
    seen = set(exclude)
    candidates: list[str] = []

    for idx, token in enumerate(sanitized_tokens):
        if idx in chosen_indices:
            continue
        if not token or token in seen:
            continue
        seen.add(token)
        candidates.append(token)

    def add_from_text(text: str) -> None:
        for candidate in _token_surfaces(text):
            if candidate in seen:
                continue
            seen.add(candidate)
            candidates.append(candidate)

    for line in context.canonical_lines:
        add_from_text(line.text)
    for line in context.daily_lines:
        add_from_text(line.grc)
        for variant in line.variants:
            add_from_text(variant)

    if not context.daily_lines:
        for fallback in _fallback_daily_lines():
            add_from_text(fallback.grc)
            for variant in fallback.variants:
                add_from_text(variant)

    return candidates


def _build_cloze_options(
    blank_surfaces: Sequence[str],
    sanitized_tokens: Sequence[str],
    chosen_indices: Sequence[int],
    context: LessonContext,
    rng: random.Random,
) -> list[str] | None:
    if not blank_surfaces:
        return None

    unique_correct = list(dict.fromkeys(blank_surfaces))
    options = list(unique_correct)
    seen = set(options)
    target_total = len(unique_correct) + 3
    min_total = len(unique_correct) + 2

    candidates = _gather_cloze_distractors(
        sanitized_tokens,
        chosen_indices,
        context,
        set(unique_correct),
    )
    rng.shuffle(candidates)

    for candidate in candidates:
        if candidate in seen:
            continue
        seen.add(candidate)
        options.append(candidate)
        if len(options) >= target_total:
            break

    if len(options) < min_total:
        alphabet_candidates = [letter.symbol for letter in _ALPHABET if letter.symbol not in seen]
        rng.shuffle(alphabet_candidates)
        for candidate in alphabet_candidates:
            seen.add(candidate)
            options.append(candidate)
            if len(options) >= min_total:
                break

    rng.shuffle(options)
    return options


def _fallback_daily_lines() -> tuple[DailyLine, ...]:
    return (
        DailyLine(grc="Χαῖρε!", en="Hello!", variants=("Χαῖρε!", "χαῖρε!")),
        DailyLine(grc="Ἔρρωσο.", en="Farewell.", variants=("Ἔρρωσο.",)),
        DailyLine(grc="Τί ὄνομά σου;", en="What is your name?"),
        DailyLine(grc="Παρακαλῶ.", en="You're welcome."),
    )
