"""LLM prompt templates for dynamic lesson generation.

This module provides pedagogically-designed prompts that transform LLM providers
from template-fillers into true lesson designers. Each prompt guides the model
to reason about student level, learning objectives, and pedagogical best practices.
"""

from __future__ import annotations

from typing import TYPE_CHECKING

if TYPE_CHECKING:
    from app.lesson.providers.base import DailyLine, CanonicalLine

# System prompt for lesson generation (used by all providers)
SYSTEM_PROMPT = (
    "You are an expert pedagogue designing Classical Greek lessons. "
    "Generate exercises that match the requested types. "
    "Output ONLY valid JSON with structure: {\"tasks\": [...]}\n"
    "Each task must follow the exact JSON schema specified in the prompts. "
    "Use proper polytonic Greek (NFC normalized Unicode)."
)

# Shared pedagogy instructions across all prompts
_PEDAGOGY_CORE = """
You are an expert pedagogue teaching Classical Greek (Koine).

**Pedagogical Principles:**
- Beginner students need simple vocabulary, clear patterns, repetition
- Intermediate students can handle complex syntax, compound sentences, nuance
- Always use proper polytonic Greek in NFC normalized Unicode
- Distractors should be morphologically plausible but semantically wrong
- Provide scaffolding: easier exercises build skills for harder ones
"""

ALPHABET_PROMPT = _PEDAGOGY_CORE + """
**Task:** Generate an alphabet recognition exercise for a {profile} student.

**Requirements:**
- Present one Greek letter (lowercase or uppercase)
- Ask student to identify it by name (e.g., "alpha", "beta")
- Provide 4 options: 1 correct + 3 plausible distractors
- Distractors should be visually similar letters (e.g., ο/ω, ε/η, ν/υ)

**Output JSON Schema:**
{{
  "type": "alphabet",
  "prompt": "Select the letter named 'X'",
  "options": ["α", "β", "γ", "δ"],
  "answer": "β"
}}

Generate ONE alphabet exercise now.
"""

MATCH_PROMPT = _PEDAGOGY_CORE + """
**Task:** Generate a vocabulary matching exercise for a {profile} student.

**Context:** {context}

**Curriculum Examples (use as inspiration, vary freely):**
{seed_examples}

**Requirements:**
- Create 3-5 Greek-English phrase pairs
- Greek phrases must be in polytonic, NFC normalized
- Match difficulty to {profile} level:
  * Beginner: Single words, basic greetings, simple nouns/verbs
  * Intermediate: Phrases, idioms, compound sentences
- Ensure cultural/historical authenticity
- Vary morphology: include different cases, tenses, moods

**Output JSON Schema:**
{{
  "type": "match",
  "pairs": [
    {{"grc": "Χαῖρε", "en": "Hello"}},
    {{"grc": "Τί κάνεις;", "en": "How are you?"}}
  ]
}}

Generate ONE match exercise with 3-5 pairs now.
"""

CLOZE_PROMPT = _PEDAGOGY_CORE + """
**Task:** Generate a fill-in-the-blank (cloze) exercise for a {profile} student.

**Source Material:**
{source_kind}: {ref}
Text: {canonical_text}

**Requirements:**
- Remove 1-2 pedagogically significant words (prefer verbs, key nouns, particles)
- Replace removed words with "____" (4 underscores)
- Provide 4-6 options: correct answer(s) + morphologically similar distractors
- Distractors must:
  * Be same part of speech (verb → verb, noun → noun)
  * Have similar inflection pattern
  * Make grammatical sense (even if semantically wrong)
- Track blank positions (0-indexed word position)
- Preserve original Greek exactly (polytonic NFC)

**Output JSON Schema:**
{{
  "type": "cloze",
  "source_kind": "{source_kind}",
  "ref": "{ref}",
  "text": "Μῆνιν ____ θεὰ Πηληϊάδεω Ἀχιλῆος",
  "blanks": [
    {{"surface": "ἄειδε", "idx": 1}}
  ],
  "options": ["ἄειδε", "λέγω", "γράφω", "ἔχω", "φημί"]
}}

Generate ONE cloze exercise now.
"""

TRANSLATE_PROMPT = _PEDAGOGY_CORE + """
**Task:** Generate a translation exercise for a {profile} student.

**Context:** {context}

**Curriculum Examples (vary from these):**
{seed_examples}

**Requirements:**
- Provide Greek sentence appropriate for {profile} level:
  * Beginner: 3-8 words, simple syntax, common vocabulary
  * Intermediate: 8-15 words, subordinate clauses, literary/historical vocab
- Use polytonic Greek (NFC normalized)
- Ask for natural English translation
- Optionally provide rubric (e.g., "Focus on verb mood", "Preserve tone")

**Output JSON Schema:**
{{
  "type": "translate",
  "direction": "grc->en",
  "text": "Χαῖρε· τί κάνεις;",
  "rubric": "Write a natural, conversational English translation."
}}

Generate ONE translation exercise now.
"""


def format_daily_examples(daily_lines: list[DailyLine], limit: int = 5) -> str:
    """Format daily lines as seed examples for prompts."""
    examples = []
    for line in daily_lines[:limit]:
        examples.append(f"- grc: \"{line.grc}\" → en: \"{line.en}\"")
    return "\n".join(examples) if examples else "(No examples available)"


def format_canonical_context(canonical_lines: list[CanonicalLine], limit: int = 3) -> str:
    """Format canonical lines as context for prompts."""
    contexts = []
    for line in canonical_lines[:limit]:
        contexts.append(f"{line.ref}: {line.text}")
    return "\n".join(contexts) if contexts else "(No canonical texts available)"


def build_alphabet_prompt(profile: str) -> str:
    """Build alphabet exercise prompt."""
    return ALPHABET_PROMPT.format(profile=profile)


def build_match_prompt(
    profile: str,
    context: str,
    daily_lines: list[DailyLine],
) -> str:
    """Build match exercise prompt with curriculum examples."""
    seed_examples = format_daily_examples(daily_lines, limit=5)
    return MATCH_PROMPT.format(
        profile=profile,
        context=context,
        seed_examples=seed_examples,
    )


def build_cloze_prompt(
    profile: str,
    source_kind: str,
    ref: str,
    canonical_text: str,
) -> str:
    """Build cloze exercise prompt from canonical text."""
    return CLOZE_PROMPT.format(
        profile=profile,
        source_kind=source_kind,
        ref=ref,
        canonical_text=canonical_text,
    )


def build_translate_prompt(
    profile: str,
    context: str,
    daily_lines: list[DailyLine],
) -> str:
    """Build translation exercise prompt with curriculum examples."""
    seed_examples = format_daily_examples(daily_lines, limit=3)
    return TRANSLATE_PROMPT.format(
        profile=profile,
        context=context,
        seed_examples=seed_examples,
    )
