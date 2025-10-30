"""LLM prompt templates for dynamic lesson generation.

This module provides pedagogically-designed prompts that transform LLM providers
from template-fillers into true lesson designers. Each prompt guides the model
to reason about student level, learning objectives, and pedagogical best practices.
"""

from __future__ import annotations

from typing import TYPE_CHECKING, Sequence

if TYPE_CHECKING:
    from app.lesson.providers.base import CanonicalLine, DailyLine, GrammarPattern, VocabularyItem

from app.lesson.language_config import get_script_guidelines


def get_system_prompt(language: str = "grc") -> str:
    """Get system prompt with language-specific script guidelines.

    Args:
        language: ISO 639-3 language code (e.g., 'grc', 'lat')

    Returns:
        System prompt with script guidelines
    """
    script_guide = get_script_guidelines(language)
    return (
        f"⚠️ TARGET LANGUAGE: {language.upper()} ⚠️\n"
        f"You are an expert pedagogue designing {language} lessons. "
        f"ALL exercises must be in {language}, NOT Greek or any other language! "
        "Generate exercises that match the requested types. "
        'Output ONLY valid JSON with structure: {"tasks": [...]}\n'
        "Each task must follow the exact JSON schema specified in the prompts. "
        f"CRITICAL: Use ONLY {language} text in all 'native' fields, alphabet prompts, and exercises. "
        f"Script Guidelines: {script_guide}"
    )


# Legacy system prompt for backward compatibility
SYSTEM_PROMPT = get_system_prompt("grc")

# Language-agnostic pedagogy instructions
# Language-specific instructions come from get_system_prompt(language)
_PEDAGOGY_CORE = """
**Pedagogical Principles:**
- Beginner students need simple vocabulary, clear patterns, repetition
- Intermediate students can handle complex syntax, compound sentences, nuance
- Distractors should be morphologically plausible but semantically wrong
- Provide scaffolding: easier exercises build skills for harder ones
"""

ALPHABET_PROMPT = (
    _PEDAGOGY_CORE
    + """
**Task:** Generate an alphabet recognition exercise for a {profile} student learning {language}.

**Requirements:**
- Present one {language} letter (lowercase or uppercase) from the target language script
- Ask student to identify it by name (e.g., "aleph", "alpha", "beth", "beta")
- Provide 4 options: 1 correct + 3 plausible distractors
- Distractors should be visually similar letters from the SAME language script
- Use the correct script for {language} (e.g., Hebrew script for Hebrew,
  Greek script for Greek, Coptic script for Coptic)

**Output JSON Schema:**
{{
  "type": "alphabet",
  "prompt": "Select the letter named 'X'",
  "options": ["<letter1>", "<letter2>", "<letter3>", "<letter4>"],
  "answer": "<correct_letter>"
}}

⚠️ CRITICAL: Use {language} script letters in options and answer, NOT Greek letters!
⚠️ If {language} is Hebrew (hbo), use Hebrew letters (א, ב, ג, ד).
⚠️ If {language} is Coptic (cop), use Coptic letters (ⲁ, ⲃ, ⲅ, ⲇ).
⚠️ If {language} is Greek (grc), use Greek letters (α, β, γ, δ).
⚠️ If {language} is Latin (lat), use Latin letters (a, b, c, d).
Generate ONE alphabet exercise now using {language} script.
"""
)

MATCH_PROMPT = (
    _PEDAGOGY_CORE
    + """
**Task:** Generate a vocabulary matching exercise for a {profile} student.

**Context:** {context}

**Curriculum Examples (use as inspiration, vary freely):**
{seed_examples}

**Requirements:**
- Create 3-5 phrase pairs for target language
- Use historically accurate script as specified
- Match difficulty to {profile} level:
  * Beginner: Single words, basic greetings, simple nouns/verbs
  * Intermediate: Phrases, idioms, compound sentences
- Ensure cultural/historical authenticity
- Vary morphology: include different cases, tenses, moods

**Output JSON Schema:**
{{
  "type": "match",
  "pairs": [
    {{"native": "<target_language_text>", "en": "<english_translation>"}},
    {{"native": "<target_language_text>", "en": "<english_translation>"}}
  ]
}}

⚠️ CRITICAL: Use the TARGET LANGUAGE ({language}) in the "native" field, NOT Greek!
Generate ONE match exercise with 3-5 pairs now using the seed examples above.
"""
)

CLOZE_PROMPT = (
    _PEDAGOGY_CORE
    + """
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
- Preserve original target language exactly (polytonic NFC)

**Output JSON Schema:**
{{
  "type": "cloze",
  "source_kind": "{source_kind}",
  "ref": "{ref}",
  "text": "<target_language_text_with_blanks>",
  "blanks": [
    {{"surface": "<removed_word>", "idx": <word_position>}}
  ],
  "options": ["<correct_answer>", "<distractor1>", "<distractor2>", "<distractor3>"]
}}

⚠️ CRITICAL: Use the source text exactly as provided above, do not substitute Greek!
Generate ONE cloze exercise now.
"""
)

TRANSLATE_PROMPT = (
    _PEDAGOGY_CORE
    + """
**Task:** Generate a translation exercise for a {profile} student.

**Context:** {context}

**Curriculum Examples (vary from these):**
{seed_examples}

**Requirements:**
- Provide target language sentence appropriate for {profile} level:
  * Beginner: 3-8 words, simple syntax, common vocabulary
  * Intermediate: 8-15 words, subordinate clauses, literary/historical vocab
- Use polytonic target language (NFC normalized)
- Ask for natural English translation
- Optionally provide rubric (e.g., "Focus on verb mood", "Preserve tone")

**Output JSON Schema:**
{{
  "type": "translate",
  "direction": "native->en",
  "text": "<target_language_text>",
  "rubric": "Write a natural, conversational English translation."
}}

⚠️ CRITICAL: Use the TARGET LANGUAGE from the curriculum examples above, NOT Greek!
Generate ONE translation exercise now based on the seed examples.
"""
)


def format_daily_examples(daily_lines: list[DailyLine], language: str = "grc", limit: int = 5) -> str:
    """Format daily lines as seed examples for prompts."""
    examples = []
    for line in daily_lines[:limit]:
        native_text = line.text
        examples.append(f'- {language}: "{native_text}" → en: "{line.en}"')
    return "\n".join(examples) if examples else "(No examples available)"


def format_canonical_context(canonical_lines: list[CanonicalLine], limit: int = 3) -> str:
    """Format canonical lines as context for prompts."""
    contexts = []
    for line in canonical_lines[:limit]:
        contexts.append(f"{line.ref}: {line.text}")
    return "\n".join(contexts) if contexts else "(No canonical texts available)"


def format_vocabulary_items(items: Sequence["VocabularyItem"], limit: int = 8) -> str:
    """Format vocabulary items for prompts."""
    formatted: list[str] = []
    for item in list(items)[:limit]:
        surfaces = ", ".join(item.surface_forms[:3]) if item.surface_forms else "(no surface forms)"
        formatted.append(f"- {item.lemma}: {surfaces} (freq={item.frequency})")
    return "\n".join(formatted) if formatted else "(No vocabulary data available)"


def format_grammar_patterns(patterns: Sequence["GrammarPattern"], limit: int = 5) -> str:
    """Format grammar patterns for prompts."""
    formatted: list[str] = []
    for pattern in list(patterns)[:limit]:
        examples = ", ".join(pattern.examples[:3]) if pattern.examples else "(no examples)"
        formatted.append(f"- {pattern.pattern}: {pattern.description} (examples: {examples})")
    return "\n".join(formatted) if formatted else "(No grammar patterns available)"


def format_text_samples(samples: Sequence[str], limit: int = 5) -> str:
    """Format text samples for prompts."""
    preview: list[str] = []
    for sample in list(samples)[:limit]:
        preview.append(f"- {sample}")
    return "\n".join(preview) if preview else "(No text samples available)"


def build_alphabet_prompt(profile: str, language: str = "grc") -> str:
    """Build alphabet exercise prompt."""
    return ALPHABET_PROMPT.format(profile=profile, language=language)


def build_match_prompt(
    profile: str,
    context: str,
    daily_lines: list[DailyLine],
    language: str = "grc",
) -> str:
    """Build match exercise prompt with curriculum examples."""
    seed_examples = format_daily_examples(daily_lines, language=language, limit=5)
    return MATCH_PROMPT.format(
        profile=profile,
        context=context,
        seed_examples=seed_examples,
        language=language,
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
    language: str = "grc",
) -> str:
    """Build translation exercise prompt with curriculum examples."""
    seed_examples = format_daily_examples(daily_lines, language=language, limit=3)
    return TRANSLATE_PROMPT.format(
        profile=profile,
        context=context,
        seed_examples=seed_examples,
    )


GRAMMAR_PROMPT = (
    _PEDAGOGY_CORE
    + """
**Task:** Create a grammar judgment exercise for a {profile} student.

**Grammar Patterns to Emphasize:**
{grammar_patterns}

**Reference Text Samples:**
{text_samples}

**Requirements:**
- Provide one Classical target language sentence.
- Set "is_correct" to true if the sentence is grammatically correct, otherwise false.
- When "is_correct" is false, explain the precise issue in "error_explanation".
- Keep vocabulary and difficulty appropriate for {profile} level.
- Use NFC-normalized polytonic target language.

**Output JSON Schema:**
{{
  "type": "grammar",
  "sentence": "Ὁ παῖς τὸ βιβλίον φέρει.",
  "is_correct": false,
  "error_explanation": "Article and noun disagree in case."
}}

Generate ONE grammar exercise now.
"""
)


LISTENING_PROMPT = (
    _PEDAGOGY_CORE
    + """
**Task:** Create a listening comprehension exercise for a {profile} student.

**Useful Daily Expressions:**
{daily_examples}

**Requirements:**
- Provide one short sentence in polytonic target language for "audio_text".
- Supply 3-4 plausible options (strings) that sound similar.
- Set "answer" to exactly match the correct option.
- Keep vocabulary aligned with the {profile} level.
- Output target language text in NFC normalization.

**Output JSON Schema:**
{{
  "type": "listening",
  "audio_text": "Χαῖρε, φίλε.",
  "options": ["Χαῖρε, φίλε.", "Χαῖρετε, φίλοι.", "Χαίρει ὁ φίλος."],
  "answer": "Χαῖρε, φίλε."
}}

Generate ONE listening exercise now.
"""
)


SPEAKING_PROMPT = (
    _PEDAGOGY_CORE
    + """
**Task:** Create a speaking exercise for a {profile} student using {register} register.

**Useful Expressions:**
{daily_examples}

**Requirements:**
- Provide an instructional "prompt" describing what the learner should say.
- Set "target_text" to the ideal target language utterance (polytonic NFC).
- Optionally add a concise Latin-letter pronunciation guide in "phonetic_guide".
- Ensure vocabulary and politeness align with the {register} register.

**Output JSON Schema:**
{{
  "type": "speaking",
  "prompt": "Greet your teacher politely in the target language.",
  "target_text": "Χαῖρε, διδάσκαλε.",
  "phonetic_guide": "KHAI-re, di-DAS-ka-le"
}}

Generate ONE speaking exercise now.
"""
)


WORDBANK_PROMPT = (
    _PEDAGOGY_CORE
    + """
**Task:** Create a word bank ordering exercise for a {profile} student.

**Reference Sentences:**
{text_samples}

**Requirements:**
- Provide 4-7 target language words in "words".
- Supply "correct_order" as zero-based indices describing the correct sentence order.
- Include an idiomatic English gloss in "translation".
- Ensure only one correct solution exists and target language text is NFC-normalized.

**Output JSON Schema:**
{{
  "type": "wordbank",
  "words": ["Χαῖρε", "ὦ", "φίλε"],
  "correct_order": [0, 1, 2],
  "translation": "Greetings, friend."
}}

Generate ONE word bank exercise now.
"""
)


TRUEFALSE_PROMPT = (
    _PEDAGOGY_CORE
    + """
**Task:** Create a true/false statement about Classical target language for a {profile} student.

**Grammar Patterns to Reference:**
{grammar_patterns}

**Requirements:**
- Provide a factual statement in "statement".
- Set "is_true" to true or false.
- Always supply a concise justification in "explanation".
- Use terminology appropriate to the learner's level.

**Output JSON Schema:**
{{
  "type": "truefalse",
  "statement": "The aorist tense can describe a completed action.",
  "is_true": true,
  "explanation": "Aorist indicates a completed past action without ongoing aspect."
}}

Generate ONE true/false exercise now.
"""
)


MULTIPLE_CHOICE_PROMPT = (
    _PEDAGOGY_CORE
    + """
**Task:** Create a multiple choice comprehension question for a {profile} student.

**Reference Text Samples:**
{text_samples}

**Requirements:**
- Optionally provide a short target language passage in "context".
- Ask a focused question in "question".
- Provide 3-4 answer options (strings).
- Set "answer_index" to the zero-based index of the correct option.
- Ensure distractors are plausible yet demonstrably wrong.

**Output JSON Schema:**
{{
  "type": "multiplechoice",
  "context": "Καλημέρα· πῶς ἔχεις;",
  "question": "What is the speaker asking?",
  "options": ["How are you?", "Where are you going?", "Who are you?"],
  "answer_index": 0
}}

Generate ONE multiple choice exercise now.
"""
)


DIALOGUE_PROMPT = (
    _PEDAGOGY_CORE
    + """
**Task:** Create a dialogue completion exercise for a {profile} student ({register} register).

**Useful Expressions:**
{daily_examples}

**Requirements:**
- Provide at least 3 dialogue lines in "lines" (each line needs "speaker" and "text").
- Use "missing_index" to indicate the line that should be blank.
- Provide 3-4 candidate replies in "options".
- Set "answer" to the exact target language line that correctly completes the dialogue.
- Keep all target language text NFC-normalized.

**Output JSON Schema:**
{{
  "type": "dialogue",
  "lines": [
    {{"speaker": "Μαρία", "text": "Χαῖρε, Νίκε."}},
    {{"speaker": "Νίκος", "text": "____"}},
    {{"speaker": "Μαρία", "text": "Εὖ γε."}}
  ],
  "missing_index": 1,
  "options": [
    "Τί πράττεις;",
    "Τίς εἶ σύ;",
    "Χαίρετε, φίλοι."
  ],
  "answer": "Τί πράττεις;"
}}

Generate ONE dialogue exercise now.
"""
)


CONJUGATION_PROMPT = (
    _PEDAGOGY_CORE
    + """
**Task:** Create a verb conjugation exercise for a {profile} student.

**Vocabulary Pool:**
{vocabulary}

**Requirements:**
- Provide the dictionary form in "verb_infinitive" and its English gloss in "verb_meaning".
- Specify the person and number in "person" (e.g., "1st person singular").
- Specify the tense/mood/voice in "tense".
- Provide the correctly conjugated form in "answer".
- Use high-frequency verbs when possible for beginner level.

**Output JSON Schema:**
{{
  "type": "conjugation",
  "verb_infinitive": "λύω",
  "verb_meaning": "to loosen",
  "person": "1st person singular",
  "tense": "present indicative active",
  "answer": "λύω"
}}

Generate ONE conjugation exercise now.
"""
)


DECLENSION_PROMPT = (
    _PEDAGOGY_CORE
    + """
**Task:** Create a noun/adjective declension exercise for a {profile} student.

**Vocabulary Pool:**
{vocabulary}

**Requirements:**
- Provide the target lemma in "word" with English gloss in "word_meaning".
- Specify "case" and "number".
- Provide the correctly inflected form in "answer".
- Emphasize forms relevant to the learner's level.

**Output JSON Schema:**
{{
  "type": "declension",
  "word": "λόγος",
  "word_meaning": "word",
  "case": "genitive",
  "number": "singular",
  "answer": "λόγου"
}}

Generate ONE declension exercise now.
"""
)


SYNONYM_PROMPT = (
    _PEDAGOGY_CORE
    + """
**Task:** Create a synonym or antonym identification exercise for a {profile} student.

**Vocabulary Pool:**
{vocabulary}

**Requirements:**
- Provide the target language headword in "word".
- Set "task_type" to "synonym" or "antonym".
- Supply 3-4 target language options; include exactly one correct match.
- Set "answer" to the correct option string.
- Choose vocabulary aligned with learner proficiency.

**Output JSON Schema:**
{{
  "type": "synonym",
  "word": "χαῖρε",
  "task_type": "synonym",
  "options": ["χαῖρε", "χάρις", "χαρίζομαι"],
  "answer": "χαῖρε"
}}

Generate ONE synonym/antonym exercise now.
"""
)


CONTEXTMATCH_PROMPT = (
    _PEDAGOGY_CORE
    + """
**Task:** Create a context match exercise for a {profile} student.

**Reference Text Samples:**
{text_samples}

**Requirements:**
- Provide a sentence with a single blank "____" in "sentence".
- Offer 3-4 plausible options in "options".
- Set "answer" to the option that best fits the blank.
- Optionally include a short explanation or hint in "context_hint".
- Use NFC-normalized target language.

**Output JSON Schema:**
{{
  "type": "contextmatch",
  "sentence": "Ὁ μαθητὴς ____ τὸ βιβλίον.",
  "context_hint": "Focus on the verb that means 'to carry'.",
  "options": ["φέρει", "λέγει", "γράφει"],
  "answer": "φέρει"
}}

Generate ONE context match exercise now.
"""
)


REORDER_PROMPT = (
    _PEDAGOGY_CORE
    + """
**Task:** Create a sentence reordering exercise for a {profile} student.

**Reference Text Samples:**
{text_samples}

**Requirements:**
- Provide 4-6 short target language fragments in "fragments".
- Supply "correct_order" as zero-based indices showing the proper order.
- Include a natural English gloss in "translation".
- Ensure fragments combine into a grammatical sentence.

**Output JSON Schema:**
{{
  "type": "reorder",
  "fragments": ["τὸ βιβλίον", "ὁ μαθητής", "φέρει"],
  "correct_order": [1, 2, 0],
  "translation": "The student carries the book."
}}

Generate ONE reorder exercise now.
"""
)


DICTATION_PROMPT = (
    _PEDAGOGY_CORE
    + """
**Task:** Create a dictation exercise for a {profile} student.

**Useful Expressions:**
{daily_examples}

**Requirements:**
- Provide a short sentence (3-10 words) in "target_text".
- Optionally include a helpful hint in "hint".
- Keep vocabulary suitable for the learner's level.
- Output polytonic target language using NFC normalization.

**Output JSON Schema:**
{{
  "type": "dictation",
  "target_text": "Χαῖρε, φίλε.",
  "hint": "Friendly greeting."
}}

Generate ONE dictation exercise now.
"""
)


ETYMOLOGY_PROMPT = (
    _PEDAGOGY_CORE
    + """
**Task:** Create an etymology multiple choice question for a {profile} student.

**Vocabulary Pool:**
{vocabulary}

**Requirements:**
- Provide a compelling question in "question".
- Set "word" to the target language root or compound being studied.
- Supply 3-4 options showing derivative meanings or cognates.
- Set "answer_index" to the zero-based index of the correct option.
- Explain the reasoning in "explanation".

**Output JSON Schema:**
{{
  "type": "etymology",
  "question": "Which English word derives from λόγος?",
  "word": "λόγος",
  "options": ["logic", "legend", "lagoon"],
  "answer_index": 0,
  "explanation": "'Logic' comes from λόγος meaning reason or word."
}}

Generate ONE etymology exercise now.
"""
)


COMPREHENSION_PROMPT = (
    _PEDAGOGY_CORE
    + """
**Task:** Create a reading comprehension exercise for a {profile} student.

**Source Material:**
{source_kind}: {ref}
Text: {canonical_text}

**Requirements:**
- Provide the original ancient language passage in "passage" (use NFC-normalized polytonic text).
- For beginner students, optionally include an English "translation" to help understanding.
- Create 2-4 comprehension questions in "questions" array.
- Each question must have:
  * A clear "question" string (in English)
  * 3-4 answer "options" (strings)
  * An "answer_index" (zero-based index of correct option)
- Questions should test:
  * Literal comprehension (who, what, when, where)
  * Inference (why, how)
  * Vocabulary in context
  * Grammar understanding
- Distractors should be plausible but clearly wrong upon careful reading.

**Output JSON Schema:**
{{
  "type": "comprehension",
  "source_kind": "{source_kind}",
  "ref": "{ref}",
  "passage": "Μῆνιν ἄειδε θεὰ Πηληϊάδεω Ἀχιλῆος οὐλομένην...",
  "translation": "Sing, goddess, the anger of Achilles...",
  "questions": [
    {{
      "question": "What is the subject of the verb 'sing'?",
      "options": ["the goddess", "Achilles", "the anger", "the poet"],
      "answer_index": 0
    }},
    {{
      "question": "Whose anger is being described?",
      "options": ["Zeus", "Achilles", "Hector", "Agamemnon"],
      "answer_index": 1
    }}
  ]
}}

Generate ONE reading comprehension exercise with 2-4 questions now.
"""
)


def build_grammar_prompt(
    profile: str,
    grammar_patterns: Sequence["GrammarPattern"],
    text_samples: Sequence[str],
) -> str:
    """Build grammar judgment prompt."""
    return GRAMMAR_PROMPT.format(
        profile=profile,
        grammar_patterns=format_grammar_patterns(grammar_patterns),
        text_samples=format_text_samples(text_samples),
    )


def build_listening_prompt(
    profile: str,
    daily_lines: Sequence[DailyLine],
    language: str = "grc",
) -> str:
    """Build listening comprehension prompt."""
    return LISTENING_PROMPT.format(
        profile=profile,
        daily_examples=format_daily_examples(list(daily_lines), language=language, limit=5),
    )


def build_speaking_prompt(
    profile: str,
    register: str,
    daily_lines: Sequence[DailyLine],
    language: str = "grc",
) -> str:
    """Build speaking exercise prompt."""
    return SPEAKING_PROMPT.format(
        profile=profile,
        register=register,
        daily_examples=format_daily_examples(list(daily_lines), language=language, limit=5),
    )


def build_wordbank_prompt(
    profile: str,
    text_samples: Sequence[str],
) -> str:
    """Build word bank prompt."""
    return WORDBANK_PROMPT.format(
        profile=profile,
        text_samples=format_text_samples(text_samples),
    )


def build_truefalse_prompt(
    profile: str,
    grammar_patterns: Sequence["GrammarPattern"],
) -> str:
    """Build true/false prompt."""
    return TRUEFALSE_PROMPT.format(
        profile=profile,
        grammar_patterns=format_grammar_patterns(grammar_patterns),
    )


def build_multiplechoice_prompt(
    profile: str,
    text_samples: Sequence[str],
) -> str:
    """Build multiple choice prompt."""
    return MULTIPLE_CHOICE_PROMPT.format(
        profile=profile,
        text_samples=format_text_samples(text_samples),
    )


def build_dialogue_prompt(
    profile: str,
    daily_lines: Sequence[DailyLine],
    register: str,
    language: str = "grc",
) -> str:
    """Build dialogue completion prompt."""
    return DIALOGUE_PROMPT.format(
        profile=profile,
        register=register,
        daily_examples=format_daily_examples(list(daily_lines), language=language, limit=5),
    )


def build_conjugation_prompt(
    profile: str,
    vocabulary: Sequence["VocabularyItem"],
) -> str:
    """Build conjugation drill prompt."""
    return CONJUGATION_PROMPT.format(
        profile=profile,
        vocabulary=format_vocabulary_items(vocabulary),
    )


def build_declension_prompt(
    profile: str,
    vocabulary: Sequence["VocabularyItem"],
) -> str:
    """Build declension drill prompt."""
    return DECLENSION_PROMPT.format(
        profile=profile,
        vocabulary=format_vocabulary_items(vocabulary),
    )


def build_synonym_prompt(
    profile: str,
    vocabulary: Sequence["VocabularyItem"],
) -> str:
    """Build synonym/antonym prompt."""
    return SYNONYM_PROMPT.format(
        profile=profile,
        vocabulary=format_vocabulary_items(vocabulary),
    )


def build_contextmatch_prompt(
    profile: str,
    text_samples: Sequence[str],
) -> str:
    """Build context match prompt."""
    return CONTEXTMATCH_PROMPT.format(
        profile=profile,
        text_samples=format_text_samples(text_samples),
    )


def build_reorder_prompt(
    profile: str,
    text_samples: Sequence[str],
) -> str:
    """Build reorder prompt."""
    return REORDER_PROMPT.format(
        profile=profile,
        text_samples=format_text_samples(text_samples),
    )


def build_dictation_prompt(
    profile: str,
    daily_lines: Sequence[DailyLine],
    language: str = "grc",
) -> str:
    """Build dictation prompt."""
    return DICTATION_PROMPT.format(
        profile=profile,
        daily_examples=format_daily_examples(list(daily_lines), language=language, limit=5),
    )


def build_etymology_prompt(
    profile: str,
    vocabulary: Sequence["VocabularyItem"],
) -> str:
    """Build etymology prompt."""
    return ETYMOLOGY_PROMPT.format(
        profile=profile,
        vocabulary=format_vocabulary_items(vocabulary),
    )


def build_comprehension_prompt(
    profile: str,
    source_kind: str,
    ref: str,
    canonical_text: str,
) -> str:
    """Build reading comprehension prompt from canonical text."""
    return COMPREHENSION_PROMPT.format(
        profile=profile,
        source_kind=source_kind,
        ref=ref,
        canonical_text=canonical_text,
    )
