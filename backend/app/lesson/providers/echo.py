from __future__ import annotations

import hashlib
import logging
import random
from typing import Sequence

import epitran
from sqlalchemy.ext.asyncio import AsyncSession

from app.lesson.language_config import get_language_config
from app.lesson.models import (
    AlphabetTask,
    ClozeBlank,
    ClozeTask,
    ComprehensionQuestion,
    ConjugationTask,
    ContextMatchTask,
    DeclensionTask,
    DialogueLine,
    DialogueTask,
    DictationTask,
    EtymologyTask,
    GrammarTask,
    LessonGenerateRequest,
    LessonMeta,
    LessonResponse,
    ListeningTask,
    MatchPair,
    MatchTask,
    MultipleChoiceTask,
    ReadingComprehensionTask,
    ReorderTask,
    SpeakingTask,
    SynonymTask,
    TranslateTask,
    TrueFalseTask,
    WordBankTask,
)
from app.lesson.providers import DailyLine, LessonContext, LessonProvider, LessonProviderError
from app.lesson.script_utils import apply_script_transform, get_alphabet_for_language

logger = logging.getLogger(__name__)


def _grc(text: str) -> str:
    """Transform Greek text to authentic epigraphic form (uppercase, no accents).

    This helper ensures all hardcoded Greek vocabulary follows the authentic
    script conventions defined in language_config.py.
    """
    return apply_script_transform(text, "grc")


def _lat(text: str) -> str:
    """Transform Latin text to authentic form (uppercase, V for U).

    This helper ensures all hardcoded Latin vocabulary follows the authentic
    script conventions defined in language_config.py.
    """
    return apply_script_transform(text, "lat")


def _daily_ref(line: DailyLine) -> str:
    digest = hashlib.sha1(line.text.encode("utf-8")).hexdigest()[:8]
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

        # Generate the requested number of tasks by cycling through exercise types
        target_count = request.task_count
        exercise_types = request.exercise_types

        if not exercise_types:
            raise LessonProviderError("No exercise types specified")

        # Shuffle exercise types for variety
        shuffled_types = list(exercise_types)
        rng.shuffle(shuffled_types)

        # Generate tasks by cycling through types
        language = request.language
        used_match_pairs: set[tuple[str, str]] = set()  # Track used pairs to avoid duplicates

        for i in range(target_count):
            exercise = shuffled_types[i % len(shuffled_types)]

            if exercise == "alphabet":
                tasks.append(_build_alphabet_task(language, rng))
            elif exercise == "match":
                tasks.append(_build_match_task(language, context, rng, used_match_pairs))
            elif exercise == "cloze":
                tasks.append(_build_cloze_task(language, context, rng))
            elif exercise == "translate":
                tasks.append(_build_translate_task(language, context, rng))
            elif exercise == "grammar":
                tasks.append(_build_grammar_task(language, context, rng))
            elif exercise == "listening":
                tasks.append(_build_listening_task(language, context, rng))
            elif exercise == "speaking":
                tasks.append(_build_speaking_task(language, context, rng))
            elif exercise == "wordbank":
                tasks.append(_build_wordbank_task(language, context, rng))
            elif exercise == "truefalse":
                tasks.append(_build_truefalse_task(language, context, rng))
            elif exercise == "multiplechoice":
                tasks.append(_build_multiplechoice_task(language, context, rng))
            elif exercise == "dialogue":
                tasks.append(_build_dialogue_task(language, context, rng))
            elif exercise == "conjugation":
                tasks.append(_build_conjugation_task(language, context, rng))
            elif exercise == "declension":
                tasks.append(_build_declension_task(language, context, rng))
            elif exercise == "synonym":
                tasks.append(_build_synonym_task(language, context, rng))
            elif exercise == "contextmatch":
                tasks.append(_build_contextmatch_task(language, context, rng))
            elif exercise == "reorder":
                tasks.append(_build_reorder_task(language, context, rng))
            elif exercise == "dictation":
                tasks.append(_build_dictation_task(language, context, rng))
            elif exercise == "etymology":
                tasks.append(_build_etymology_task(language, context, rng))
            elif exercise == "comprehension":
                tasks.append(_build_comprehension_task(language, context, rng))

        if not tasks:
            raise LessonProviderError("Echo provider could not build any tasks")

        # Generate audio for audio-requiring tasks if include_audio is True
        if request.include_audio:
            tasks = await _populate_audio_urls(tasks, language, token)

        meta = LessonMeta(
            language=request.language,
            profile=request.profile,
            provider=self.name,
            model=self.name,
        )
        return LessonResponse(meta=meta, tasks=tasks)


def _build_alphabet_task(language: str, rng: random.Random) -> AlphabetTask:
    """Build alphabet task dynamically for any language."""
    # Get alphabet characters for this language
    alphabet_chars = get_alphabet_for_language(language)

    # Filter out empty strings, whitespace, and non-string values (defensive)
    alphabet_chars = [c for c in alphabet_chars if isinstance(c, str) and c and c.strip()]

    # Ensure we have enough characters
    if len(alphabet_chars) < 4:
        # This shouldn't happen with the new fallback logic, but just in case
        config = get_language_config(language)
        return AlphabetTask(
            prompt=f"Select a character from {config.name}",
            options=["A", "B", "C", "D"],
            answer="A",
        )

    # Select target character and 3 distractors
    target = rng.choice(alphabet_chars)
    options = {target}
    attempts = 0
    while len(options) < 4 and attempts < 100:
        distractor = rng.choice(alphabet_chars)
        if isinstance(distractor, str) and distractor != target and distractor.strip():
            options.add(distractor)
        attempts += 1

    # If we couldn't get 4 distinct characters, pad with random choices
    while len(options) < 4:
        options.add(rng.choice(alphabet_chars))

    option_list = list(options)
    rng.shuffle(option_list)

    # Apply script transform to ensure correct case/form
    target = apply_script_transform(target, language)
    option_list = [apply_script_transform(opt, language) for opt in option_list]

    prompt = f"Select the letter '{target}'"
    return AlphabetTask(prompt=prompt, options=option_list, answer=target)


def _build_match_task(
    language: str, context: LessonContext, rng: random.Random, used_pairs: set[tuple[str, str]] | None = None
) -> MatchTask:
    # Latin word pairs - EXPANDED 3x for variety
    if language == "lat":
        latin_pairs = [
            # Verbs (expanded)
            MatchPair(native="AMO", en="I love"),
            MatchPair(native="VIDEO", en="I see"),
            MatchPair(native="DVCO", en="I lead"),
            MatchPair(native="CAPIO", en="I take"),
            MatchPair(native="AVDIO", en="I hear"),
            MatchPair(native="SVM", en="I am"),
            MatchPair(native="DO", en="I give"),
            MatchPair(native="FACIO", en="I make/do"),
            MatchPair(native="VENIO", en="I come"),
            MatchPair(native="DICO", en="I say/speak"),
            MatchPair(native="SCRIBO", en="I write"),
            MatchPair(native="LEGO", en="I read/choose"),
            MatchPair(native="MONEO", en="I warn/advise"),
            MatchPair(native="PONO", en="I place/put"),
            MatchPair(native="STO", en="I stand"),
            # Nouns (expanded)
            MatchPair(native="ROSA", en="rose"),
            MatchPair(native="PVELLA", en="girl"),
            MatchPair(native="BELLVM", en="war"),
            MatchPair(native="PAX", en="peace"),
            MatchPair(native="REX", en="king"),
            MatchPair(native="VRBS", en="city"),
            MatchPair(native="TERRA", en="land/earth"),
            MatchPair(native="VITA", en="life"),
            MatchPair(native="MORS", en="death"),
            MatchPair(native="TEMPVS", en="time"),
            MatchPair(native="HOMO", en="human/man"),
            MatchPair(native="FEMINA", en="woman"),
            MatchPair(native="PVER", en="boy"),
            MatchPair(native="MATER", en="mother"),
            MatchPair(native="PATER", en="father"),
            MatchPair(native="FRATER", en="brother"),
            MatchPair(native="SOROR", en="sister"),
            # Adjectives
            MatchPair(native="MAGNVS", en="great/large"),
            MatchPair(native="BONVS", en="good"),
            MatchPair(native="MALVS", en="bad/evil"),
            MatchPair(native="NOVVS", en="new"),
            MatchPair(native="VETVS", en="old"),
            MatchPair(native="PVLCHER", en="beautiful"),
            MatchPair(native="FORTIS", en="strong/brave"),
        ]
        count = min(5, len(latin_pairs))
        selected = rng.sample(latin_pairs, count)
        rng.shuffle(selected)
        return MatchTask(pairs=selected)

    # Hebrew word pairs - EXPANDED 2x for variety
    if language == "hbo":
        hebrew_pairs = [
            # Core vocabulary
            MatchPair(native="שָׁלוֹם", en="peace, hello"),
            MatchPair(native="אָמֵן", en="amen, truly"),
            MatchPair(native="אֱלֹהִים", en="God"),
            MatchPair(native="מֶלֶךְ", en="king"),
            MatchPair(native="דָּבָר", en="word, thing"),
            MatchPair(native="יָד", en="hand"),
            MatchPair(native="בַּיִת", en="house"),
            MatchPair(native="אִישׁ", en="man"),
            MatchPair(native="אִשָּׁה", en="woman"),
            MatchPair(native="בֵּן", en="son"),
            MatchPair(native="בַּת", en="daughter"),
            MatchPair(native="אָב", en="father"),
            MatchPair(native="אֵם", en="mother"),
            MatchPair(native="עִיר", en="city"),
            MatchPair(native="אֶרֶץ", en="land, earth"),
            MatchPair(native="שָׁמַיִם", en="heaven, sky"),
            # Expanded vocabulary
            MatchPair(native="יוֹם", en="day"),
            MatchPair(native="לַיְלָה", en="night"),
            MatchPair(native="מַיִם", en="water"),
            MatchPair(native="אֵשׁ", en="fire"),
            MatchPair(native="רוּחַ", en="spirit, wind"),
            MatchPair(native="לֵב", en="heart"),
            MatchPair(native="נֶפֶשׁ", en="soul, life"),
            MatchPair(native="עַיִן", en="eye"),
            MatchPair(native="אֹזֶן", en="ear"),
            MatchPair(native="פֶּה", en="mouth"),
            MatchPair(native="חַיִּים", en="life"),
            MatchPair(native="מָוֶת", en="death"),
            MatchPair(native="אַהֲבָה", en="love"),
            MatchPair(native="אֱמֶת", en="truth"),
        ]
        count = min(5, len(hebrew_pairs))
        selected = rng.sample(hebrew_pairs, count)
        rng.shuffle(selected)
        return MatchTask(pairs=selected)

    # Sanskrit word pairs - EXPANDED 2x for variety
    if language == "san":
        sanskrit_pairs = [
            # Core vocabulary
            MatchPair(native="नमस्ते", en="namaste, greetings"),
            MatchPair(native="देव", en="god"),
            MatchPair(native="धर्म", en="dharma, duty"),
            MatchPair(native="कर्म", en="karma, action"),
            MatchPair(native="योग", en="yoga, union"),
            MatchPair(native="वेद", en="veda, knowledge"),
            MatchPair(native="गुरु", en="guru, teacher"),
            MatchPair(native="माता", en="mother"),
            MatchPair(native="पिता", en="father"),
            MatchPair(native="पुत्र", en="son"),
            MatchPair(native="जल", en="water"),
            MatchPair(native="अग्नि", en="fire"),
            MatchPair(native="वायु", en="wind, air"),
            MatchPair(native="पृथिवी", en="earth"),
            MatchPair(native="आकाश", en="sky, space"),
            # Expanded vocabulary
            MatchPair(native="प्रेम", en="love"),
            MatchPair(native="सत्य", en="truth"),
            MatchPair(native="शान्ति", en="peace"),
            MatchPair(native="ज्ञान", en="knowledge"),
            MatchPair(native="भक्ति", en="devotion"),
            MatchPair(native="आत्मन्", en="self, soul"),
            MatchPair(native="ब्रह्मन्", en="brahman, ultimate reality"),
            MatchPair(native="मन्त्र", en="mantra, sacred utterance"),
            MatchPair(native="राजा", en="king"),
            MatchPair(native="रानी", en="queen"),
            MatchPair(native="नगर", en="city"),
            MatchPair(native="ग्राम", en="village"),
            MatchPair(native="पुस्तक", en="book"),
            MatchPair(native="भाषा", en="language"),
            MatchPair(native="संस्कृत", en="Sanskrit"),
        ]
        count = min(5, len(sanskrit_pairs))
        selected = rng.sample(sanskrit_pairs, count)
        rng.shuffle(selected)
        return MatchTask(pairs=selected)

    # For any other unsupported languages, use placeholder
    # Support both Classical Greek (grc-cls) and Koine Greek (grc-koi)
    if not language.startswith("grc"):
        return MatchTask(
            pairs=[
                MatchPair(native=f"Coming soon for {language}", en="Placeholder 1"),
                MatchPair(native=f"Coming soon for {language}", en="Placeholder 2"),
            ]
        )

    # Greek content (grc-cls and grc-koi)
    # Use text_range vocabulary if available
    if context.text_range_data and context.text_range_data.vocabulary:
        vocab_items = list(context.text_range_data.vocabulary)
        count = min(3, len(vocab_items))
        selected = rng.sample(vocab_items, count)
        pairs = [
            MatchPair(
                native=apply_script_transform(
                    item.surface_forms[0] if item.surface_forms else item.lemma, language
                ),
                en=f"{item.lemma} (appears {item.frequency}x)",
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
                    native_text = apply_script_transform(" ".join(words), language)
                    en_text = f"from {context.text_range_data.ref_start}-{context.text_range_data.ref_end}"
                    pairs.append(MatchPair(native=native_text, en=en_text))
            if pairs:
                rng.shuffle(pairs)
                return MatchTask(pairs=pairs)
            # If no valid pairs, fall through to daily lines

    # For languages without specific support, return placeholder pairs
    if not language.startswith("grc") and language not in ("lat", "hbo", "san"):
        config = get_language_config(language)
        placeholder_pairs = [
            MatchPair(native=f"{config.name} word 1", en="Coming soon"),
            MatchPair(native=f"{config.name} word 2", en="Coming soon"),
            MatchPair(native=f"{config.name} word 3", en="Coming soon"),
        ]
        return MatchTask(pairs=placeholder_pairs)

    # Fallback to daily lines (only for Greek now)
    pool = list(context.daily_lines) or list(_fallback_daily_lines())
    if len(pool) < 2:
        raise LessonProviderError("Insufficient daily lines for match task")
    count = min(3, len(pool))

    def _pair_for_line(line: DailyLine) -> tuple[MatchPair, tuple[str, str]]:
        native = apply_script_transform(_choose_variant(line, rng), language)
        key = (native.strip(), line.en.strip())
        return MatchPair(native=native, en=line.en), key

    shuffled_pool = pool[:]
    rng.shuffle(shuffled_pool)
    chosen_pairs: list[MatchPair] = []
    chosen_keys: set[tuple[str, str]] = set()
    used_keys = used_pairs if used_pairs is not None else set()

    for line in shuffled_pool:
        pair, key = _pair_for_line(line)
        if key in chosen_keys or key in used_keys:
            continue
        chosen_pairs.append(pair)
        chosen_keys.add(key)
        if len(chosen_pairs) >= count:
            break

    if not chosen_pairs:
        # Attempt to supplement with canonical lines for additional variety
        canon_candidates = list(context.canonical_lines)
        rng.shuffle(canon_candidates)
        for canonical in canon_candidates:
            snippet = " ".join(canonical.text.split()[:3]).strip()
            if not snippet:
                continue
            native = apply_script_transform(snippet, language)
            key = (native.strip(), f"From {canonical.ref}")
            if key in chosen_keys or key in used_keys:
                continue
            chosen_pairs.append(MatchPair(native=native, en=f"From {canonical.ref}"))
            chosen_keys.add(key)
            if len(chosen_pairs) >= max(1, count):
                break

    if not chosen_pairs:
        # As a final fallback, synthesize unique placeholder pairs to uphold task integrity
        base_index = len(used_keys) + 1 if used_keys else 1
        attempts = 0
        while len(chosen_pairs) < count and attempts < count * 4:
            marker = base_index + attempts
            native = apply_script_transform(f"ΛΕΞΙΣ {marker}", language)
            en_label = f"Vocabulary builder {marker}"
            key = (native.strip(), en_label)
            attempts += 1
            if key in chosen_keys or key in used_keys:
                continue
            chosen_pairs.append(MatchPair(native=native, en=en_label))
            chosen_keys.add(key)

    if not chosen_pairs:
        raise LessonProviderError("Unable to generate unique match pairs")

    if used_pairs is not None:
        used_pairs.update(chosen_keys)

    rng.shuffle(chosen_pairs)
    return MatchTask(pairs=chosen_pairs)


def _build_cloze_task(language: str, context: LessonContext, rng: random.Random) -> ClozeTask:
    # Latin sentences - MASSIVELY EXPANDED to 35+ sentences
    if language == "lat":
        latin_sentences = [
            # Core sentences
            "amo puellam",
            "puella rosam amat",
            "puer librum legit",
            "magister discipulos docet",
            "miles gladium portat",
            "femina aquam portat",
            "rex populum regit",
            "nauta navem ducit",
            "poeta carmina scribit",
            "agricola terram colit",
            # Family and relationships
            "pater filium vocat",
            "mater cenam parat",
            "frater sororem iuvat",
            "dominus servum laudat",
            "amicus amicum adiuvat",
            # Actions and professions
            "dux exercitum ducit",
            "orator verba dicit",
            "medicus aegrotum curat",
            "senator legem scribit",
            "philosophus de vita cogitat",
            # Descriptions
            "urbs magna est",
            "vita brevis est",
            "mors certa est",
            "bellum longum erat",
            "pax dulcis est",
            "tempus fugit celeriter",
            "fortuna variat semper",
            "virtus laudanda est",
            # Complex sentences
            "puella in horto ambulat",
            "miles cum gladio pugnat",
            "poeta de amore canit",
            "agricola in agro laborat",
            "nauta trans mare navigat",
            "rex in palatio sedet",
            "discipulus a magistro discit",
            "civis pro patria pugnat",
        ]
        raw_text = rng.choice(latin_sentences)
        source_kind = "daily"
        ref = "latin:daily"
    # Hebrew sentences - MASSIVELY EXPANDED to 25+ sentences
    elif language == "hbo":
        hebrew_sentences = [
            # Core sentences
            "הָאִישׁ הוֹלֵךְ לַבַּיִת",
            "הַמֶּלֶךְ יוֹשֵׁב עַל־הַכִּסֵּא",
            "הָאִשָּׁה קוֹרֵאת אֶת־הַסֵּפֶר",
            "הַיֶּלֶד אוֹכֵל לֶחֶם",
            "הַכֹּהֵן מִתְפַּלֵּל בַּמִּקְדָּשׁ",
            "הַנָּבִיא דוֹבֵר אֶת־דְּבַר יהוה",
            "הָעָם שׁוֹמֵעַ אֶת־הַקּוֹל",
            "הַחָכָם כּוֹתֵב סֵפֶר",
            # Expanded sentences
            "הָאָב אוֹהֵב אֶת־בְּנוֹ",
            "הָאֵם נוֹתֶנֶת לֶחֶם לַיְּלָדִים",
            "הַמּוֹרֶה מְלַמֵּד אֶת־הַתַּלְמִידִים",
            "הַשּׁוֹפֵט שׁוֹפֵט בְּצֶדֶק",
            "הַגִּבּוֹר לוֹחֵם בַּמִּלְחָמָה",
            "הָאִשָּׁה עוֹבֶדֶת בַּשָּׂדֶה",
            "הַנַּעַר רוֹעֶה אֶת־הַצֹּאן",
            "הָעֶבֶד עוֹבֵד קָשֶׁה",
            "הַשּׁוֹמֵר שׁוֹמֵר אֶת־הָעִיר",
            "הַכּוֹכָבִים מְאִירִים בַּלַּיְלָה",
            "הַשֶּׁמֶשׁ זוֹרַחַת בַּיּוֹם",
            "הָרוּחַ נוֹשֶׁבֶת בַּשָּׂדֶה",
            "הַגֶּשֶׁם יוֹרֵד מִן־הַשָּׁמַיִם",
            "הָאֱמֶת תַּצִּיל אֹתְךָ",
            "הַחֶסֶד טוֹב מִזָּהָב",
            "הַשָּׁלוֹם יָבוֹא אֶל־הָאָרֶץ",
            "הַדֶּרֶךְ אֲרֻכָּה מְאֹד",
        ]
        raw_text = rng.choice(hebrew_sentences)
        source_kind = "daily"
        ref = "hebrew:daily"
    # Sanskrit sentences - MASSIVELY EXPANDED to 25+ sentences
    elif language == "san":
        sanskrit_sentences = [
            # Core sentences
            "बालः गृहं गच्छति",
            "देवः सूर्यम् पश्यति",
            "गुरुः शिष्यं पाठयति",
            "पिता पुत्रं वदति",
            "नरः जलं पिबति",
            "बालिका पुष्पं पश्यति",
            "राजा नगरं रक्षति",
            "माता अन्नं पचति",
            # Expanded sentences
            "मुनिः वनं गच्छति",
            "योद्धा युद्धं करोति",
            "कविः काव्यं रचयति",
            "वाणिज्यः धनं लभते",
            "भक्तः देवं पूजयति",
            "छात्रः पुस्तकं पठति",
            "वैद्यः रोगिणं चिकित्सति",
            "नृत्यकः नृत्यं करोति",
            "सूर्यः प्रकाशयति",
            "चन्द्रः रात्रौ शोभते",
            "वायुः वहति",
            "अग्निः दहति",
            "जलं प्रवहति",
            "पृथिवी सर्वं धारयति",
            "आकाशः विस्तृतः अस्ति",
            "धर्मः रक्षति रक्षितः",
            "सत्यं एव जयते",
            "प्रेम सर्वत्र विजयी",
        ]
        raw_text = rng.choice(sanskrit_sentences)
        source_kind = "daily"
        ref = "sanskrit:daily"
    # For any other non-Greek languages
    elif language and not language.startswith("grc"):
        return ClozeTask(
            source_kind="daily",
            ref=None,
            text=f"Coming soon for {language}: ____",
            blanks=[ClozeBlank(surface="placeholder", idx=0)],
            options=["placeholder"],
        )
    # Greek - use text_range samples if available
    elif context.text_range_data and context.text_range_data.text_samples:
        raw_text = rng.choice(context.text_range_data.text_samples)
        source_kind = "text_range"
        ref = f"{context.text_range_data.ref_start}-{context.text_range_data.ref_end}"
    elif context.canonical_lines:
        source = rng.choice(context.canonical_lines)
        source_kind = "canon"
        ref = source.ref
        raw_text = source.text
    else:
        fallback = list(context.daily_lines) or list(_fallback_daily_lines())
        line = rng.choice(fallback)
        source_kind = "daily"
        ref = _daily_ref(line)
        raw_text = _choose_variant(line, rng)

    # Split BEFORE applying script transform to avoid scriptio continua removing spaces
    tokens = raw_text.split()
    # Apply script transform to each token individually to preserve word boundaries
    tokens = [apply_script_transform(token, language) for token in tokens]
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


def _build_translate_task(language: str, context: LessonContext, rng: random.Random) -> TranslateTask:
    # Latin translations - MASSIVELY EXPANDED to 30+ translations
    if language == "lat":
        latin_translations = [
            # Core phrases
            ("amo te", "I love you"),
            ("puella rosam amat", "The girl loves the rose"),
            ("puer librum legit", "The boy reads the book"),
            ("magister bonus est", "The teacher is good"),
            ("femina aquam portat", "The woman carries water"),
            ("rex populum regit", "The king rules the people"),
            ("miles fortis est", "The soldier is brave"),
            ("poeta carmina scribit", "The poet writes songs"),
            # Expanded sentences
            ("pater filium vocat", "The father calls his son"),
            ("mater cenam parat", "The mother prepares dinner"),
            ("frater sororem iuvat", "The brother helps his sister"),
            ("vita brevis est", "Life is short"),
            ("tempus fugit", "Time flies"),
            ("veritas liberat", "Truth liberates"),
            ("amicus verus rarus est", "A true friend is rare"),
            ("sapientia melior est auro", "Wisdom is better than gold"),
            ("labor omnia vincit", "Work conquers all"),
            ("fortuna fortes adiuvat", "Fortune helps the brave"),
            ("mens sana in corpore sano", "A sound mind in a sound body"),
            ("ars longa vita brevis", "Art is long, life is short"),
            # More complex
            ("philosophus de natura cogitat", "The philosopher thinks about nature"),
            ("orator populo verba dicit", "The orator speaks words to the people"),
            ("agricola in agro laborat", "The farmer works in the field"),
            ("nauta per mare navigat", "The sailor sails across the sea"),
            ("discipulus libros legit", "The student reads books"),
            ("medicus aegrotos curat", "The doctor heals the sick"),
            ("poeta de amore canit", "The poet sings about love"),
            ("miles pro patria pugnat", "The soldier fights for his homeland"),
            ("civis legibus paret", "The citizen obeys the laws"),
            ("dux exercitum bene ducit", "The leader leads the army well"),
        ]
        text, answer = rng.choice(latin_translations)
        return TranslateTask(
            direction="native->en",
            text=apply_script_transform(text, language),
            rubric="Write a natural English translation.",
            sampleSolution=answer,
        )

    # Hebrew translations - MASSIVELY EXPANDED to 25+ translations
    if language == "hbo":
        hebrew_translations = [
            # Core phrases
            ("שָׁלוֹם", "peace, hello"),
            ("הָאִישׁ הוֹלֵךְ", "the man walks"),
            ("הַמֶּלֶךְ גָּדוֹל", "the king is great"),
            ("אֱלֹהִים טוֹב", "God is good"),
            ("הָאִשָּׁה קוֹרֵאת", "the woman reads"),
            ("הַיֶּלֶד אוֹכֵל", "the child eats"),
            # Expanded phrases
            ("הָאָב אוֹהֵב", "the father loves"),
            ("הָאֵם נוֹתֶנֶת", "the mother gives"),
            ("הַנָּבִיא דוֹבֵר", "the prophet speaks"),
            ("הַכֹּהֵן מִתְפַּלֵּל", "the priest prays"),
            ("הַחָכָם לוֹמֵד", "the wise man learns"),
            ("הָעָם שׁוֹמֵעַ", "the people hear"),
            ("הַגִּבּוֹר לוֹחֵם", "the hero fights"),
            ("הַשּׁוֹפֵט שׁוֹפֵט", "the judge judges"),
            # More complex
            ("הָאֱמֶת תּוֹשִׁיעַ", "truth will save"),
            ("הַחֶסֶד גָּדוֹל", "kindness is great"),
            ("הַשָּׁלוֹם טוֹב", "peace is good"),
            ("הַתּוֹרָה חָכְמָה", "the Torah is wisdom"),
            ("הַדֶּרֶךְ אֲרֻכָּה", "the way is long"),
            ("הַחַיִּים קְצָרִים", "life is short"),
            ("הָאוֹר מֵאִיר", "the light shines"),
            ("הַחֹשֶׁךְ עָבַר", "the darkness passed"),
            ("הַצֶּדֶק יָנוּם", "righteousness will triumph"),
            ("הָאַהֲבָה חֲזָקָה", "love is strong"),
            ("הָעֹשֶׁר חָלַף", "wealth passes away"),
        ]
        text, answer = rng.choice(hebrew_translations)
        return TranslateTask(
            direction="native->en",
            text=apply_script_transform(text, language),
            rubric="Write a natural English translation.",
            sampleSolution=answer,
        )

    # Sanskrit translations - MASSIVELY EXPANDED to 25+ translations
    if language == "san":
        sanskrit_translations = [
            # Core phrases
            ("नमस्ते", "greetings, namaste"),
            ("बालः गच्छति", "the boy goes"),
            ("देवः महान्", "the god is great"),
            ("गुरुः वदति", "the teacher speaks"),
            ("माता पचति", "the mother cooks"),
            ("नरः पिबति", "the man drinks"),
            # Expanded phrases
            ("पिता आगच्छति", "the father comes"),
            ("शिष्यः पठति", "the student reads"),
            ("राजा शासति", "the king rules"),
            ("योद्धा युध्यते", "the warrior fights"),
            ("कविः लिखति", "the poet writes"),
            ("वैद्यः चिकित्सति", "the doctor heals"),
            ("भक्तः पूजयति", "the devotee worships"),
            ("मुनिः ध्यायति", "the sage meditates"),
            # Wisdom phrases
            ("सत्यम् एव जयते", "truth alone triumphs"),
            ("धर्मः रक्षति रक्षितः", "dharma protects those who protect it"),
            ("ज्ञानं परमं बलम्", "knowledge is supreme power"),
            ("अहिंसा परमो धर्मः", "non-violence is the highest dharma"),
            ("प्रेम सर्वत्र जयति", "love conquers everywhere"),
            ("मनः शान्तिः सुखम्", "peace of mind is happiness"),
            ("कालः सर्वं नाशयति", "time destroys everything"),
            ("कर्म फलदायकम्", "action bears fruit"),
            ("वाक् शक्तिः महती", "the power of speech is great"),
            ("आत्मा अमरः अस्ति", "the soul is immortal"),
            ("विद्या धनं सर्वोत्तमम्", "knowledge is the best wealth"),
        ]
        text, answer = rng.choice(sanskrit_translations)
        return TranslateTask(
            direction="native->en",
            text=apply_script_transform(text, language),
            rubric="Write a natural English translation.",
            sampleSolution=answer,
        )

    # For any other non-Greek languages
    if language and not language.startswith("grc"):
        return TranslateTask(
            direction="native->en",
            text=f"Coming soon for {language}",
            rubric="Translation exercise",
            sampleSolution="placeholder",
        )

    # Greek
    pool = list(context.daily_lines) or list(_fallback_daily_lines())
    line = rng.choice(pool)
    text = apply_script_transform(_choose_variant(line, rng), language)
    return TranslateTask(
        direction="native->en",
        text=text,
        rubric="Write a natural English translation.",
        sampleSolution=line.en,
    )


def _build_grammar_task(language: str, context: LessonContext, rng: random.Random) -> GrammarTask:
    # Latin grammar - MASSIVELY EXPANDED
    if language == "lat":
        latin_correct = [
            ("puella rosam amat", "The girl loves the rose", "Correct accusative case for direct object"),
            ("puer bonus est", "The boy is good", "Correct nominative case for subject"),
            ("magistri discipulos docent", "The teachers teach the students", "Correct plural agreement"),
            ("femina aquam portat", "The woman carries water", "Correct accusative singular"),
            ("miles fortis pugnat", "The brave soldier fights", "Correct nominative agreement"),
            ("rex populum regit", "The king rules the people", "Correct accusative case"),
            ("pueri libros legunt", "The boys read books", "Correct plural agreement"),
            ("dominus servos vocat", "The master calls the slaves", "Correct plural accusative"),
            ("poeta carmina scribit", "The poet writes songs", "Correct neuter plural accusative"),
            ("agricola terram colit", "The farmer cultivates the land", "Correct accusative feminine"),
            ("pater filium amat", "The father loves his son", "Correct accusative singular"),
            ("mater filias vocat", "The mother calls her daughters", "Correct accusative plural"),
            ("dux milites ducit", "The leader leads the soldiers", "Correct accusative plural"),
            ("nauta navem videt", "The sailor sees the ship", "Correct accusative feminine"),
            ("cives leges servant", "The citizens keep the laws", "Correct plural agreement"),
        ]
        latin_incorrect = [
            ("puella rosae amat", "Incorrect case: should be rosam (accusative) not rosae"),
            ("puer bonum est", "Incorrect case: should be bonus (nominative) not bonum"),
            ("magistri discipulos docet", "Incorrect number: plural subject needs plural verb docent"),
            ("femina aqua portat", "Incorrect case: should be aquam (accusative) not aqua"),
            ("pueri librum legunt", "Incorrect number: plural subject needs plural object libros"),
            ("rex populo regit", "Incorrect case: should be populum (accusative) not populo"),
            ("dominus servo vocat", "Incorrect number: should be servos (plural) for correct sense"),
            ("poeta carmina scribunt", "Incorrect number: singular subject needs singular verb scribit"),
            ("pater filio amat", "Incorrect case: should be filium (accusative) not filio"),
            ("milites fortis pugnat", "Incorrect agreement: plural subject needs plural verb pugnant"),
        ]
        is_correct = rng.choice([True, False])
        if is_correct:
            sentence, _trans, expl = rng.choice(latin_correct)
            return GrammarTask(sentence=sentence, is_correct=True, error_explanation=None)
        else:
            sentence, expl = rng.choice(latin_incorrect)
            return GrammarTask(sentence=sentence, is_correct=False, error_explanation=expl)

    # Hebrew grammar - MASSIVELY EXPANDED
    if language == "hbo":
        hebrew_correct = [
            ("הָאִישׁ הוֹלֵךְ", "The man walks", "Correct masculine singular participle"),
            ("הָאִשָּׁה הוֹלֶכֶת", "The woman walks", "Correct feminine singular participle"),
            ("הָאֲנָשִׁים הוֹלְכִים", "The men walk", "Correct masculine plural participle"),
            ("הַנָּשִׁים הוֹלְכוֹת", "The women walk", "Correct feminine plural participle"),
            ("הַיֶּלֶד אוֹכֵל", "The child eats", "Correct masculine singular verb"),
            ("הַיְּלָדִים אוֹכְלִים", "The children eat", "Correct masculine plural verb"),
            ("הַמֶּלֶךְ יוֹשֵׁב", "The king sits", "Correct masculine singular participle"),
            ("הַכֹּהֵן מִתְפַּלֵּל", "The priest prays", "Correct masculine singular reflexive"),
            ("הַנָּבִיא דוֹבֵר", "The prophet speaks", "Correct masculine singular participle"),
            ("הַתּוֹרָה קְדוֹשָׁה", "The Torah is holy", "Correct feminine singular adjective"),
        ]
        hebrew_incorrect = [
            ("הָאִישׁ הוֹלֶכֶת", "Incorrect gender: masculine subject with feminine verb"),
            ("הָאִשָּׁה הוֹלֵךְ", "Incorrect gender: feminine subject with masculine verb"),
            ("הָאֲנָשִׁים הוֹלֵךְ", "Incorrect number: plural subject with singular verb"),
            ("הַיֶּלֶד אוֹכְלִים", "Incorrect number: singular subject with plural verb"),
            ("הַמֶּלֶךְ יוֹשֶׁבֶת", "Incorrect gender: masculine subject with feminine participle"),
            ("הַנָּשִׁים הוֹלְכִים", "Incorrect gender: feminine plural with masculine form"),
            ("הַתּוֹרָה קָדוֹשׁ", "Incorrect gender: feminine noun with masculine adjective"),
        ]
        is_correct = rng.choice([True, False])
        if is_correct:
            sentence, _trans, expl = rng.choice(hebrew_correct)
            return GrammarTask(sentence=sentence, is_correct=True, error_explanation=None)
        else:
            sentence, expl = rng.choice(hebrew_incorrect)
            return GrammarTask(sentence=sentence, is_correct=False, error_explanation=expl)

    # Sanskrit grammar - MASSIVELY EXPANDED
    if language == "san":
        sanskrit_correct = [
            ("बालः गच्छति", "The boy goes", "Correct nominative singular with 3rd person singular verb"),
            ("बालौ गच्छतः", "The two boys go", "Correct dual agreement"),
            ("बालाः गच्छन्ति", "The boys go", "Correct plural agreement"),
            ("बाला गच्छति", "The girl goes", "Correct feminine singular"),
            ("बाले गच्छतः", "The two girls go", "Correct feminine dual"),
            ("बालाः गच्छन्ति", "The girls go", "Correct feminine plural"),
            ("गुरुः पठति", "The teacher reads", "Correct nominative singular"),
            ("गुरवः पठन्ति", "The teachers read", "Correct nominative plural"),
            ("फलं पतति", "The fruit falls", "Correct neuter singular"),
            ("फलानि पतन्ति", "The fruits fall", "Correct neuter plural"),
        ]
        sanskrit_incorrect = [
            ("बालः गच्छन्ति", "Incorrect number: singular subject with plural verb"),
            ("बालाः गच्छति", "Incorrect number: plural subject with singular verb"),
            ("बाला गच्छन्ति", "Incorrect number: singular feminine with plural verb"),
            ("गुरुः पठन्ति", "Incorrect number: singular with plural verb"),
            ("फलं पतन्ति", "Incorrect number: neuter singular with plural verb"),
            ("बालौ गच्छति", "Incorrect number: dual subject with singular verb"),
            ("गुरवः पठति", "Incorrect number: plural subject with singular verb"),
        ]
        is_correct = rng.choice([True, False])
        if is_correct:
            sentence, _trans, expl = rng.choice(sanskrit_correct)
            return GrammarTask(sentence=sentence, is_correct=True, error_explanation=None)
        else:
            sentence, expl = rng.choice(sanskrit_incorrect)
            return GrammarTask(sentence=sentence, is_correct=False, error_explanation=expl)

    # For other non-Greek languages
    if not language.startswith("grc"):
        return GrammarTask(
            sentence=f"Coming soon for {language}",
            is_correct=True,
            error_explanation=None,
        )
    # Common grammar patterns for Greek (20+ examples each)
    correct_patterns = [
        (_grc("ὁ ἄνθρωπος ἔρχεται."), "The man comes.", "Correct subject-verb agreement (3rd singular)"),
        (_grc("οἱ ἄνθρωποι ἔρχονται."), "The men come.", "Correct plural agreement"),
        (_grc("ἡ γυνὴ λέγει τὸν λόγον."), "The woman speaks the word.", "Correct article-noun agreement"),
        (_grc("ὁ διδάσκαλος γράφει."), "The teacher writes.", "Correct singular agreement"),
        (_grc("αἱ κόραι τρέχουσιν."), "The girls run.", "Correct feminine plural"),
        (_grc("τὸ τέκνον παίζει."), "The child plays.", "Correct neuter singular"),
        (_grc("οἱ στρατιῶται μάχονται."), "The soldiers fight.", "Correct plural agreement"),
        (_grc("ἡ θάλασσα κινεῖται."), "The sea moves.", "Correct feminine singular"),
        (_grc("τὰ δῶρα φέρομεν."), "We bring the gifts.", "Correct 1st person plural"),
        (_grc("ὁ ποιητὴς ᾄδει."), "The poet sings.", "Correct masculine singular"),
        (_grc("αἱ μοῦσαι ᾄδουσιν."), "The muses sing.", "Correct feminine plural"),
        (_grc("τὸ βιβλίον ἐστίν."), "The book is.", "Correct neuter singular with εἰμί"),
        (_grc("οἱ θεοὶ ἄρχουσιν."), "The gods rule.", "Correct masculine plural"),
        (_grc("ἡ πόλις νικᾷ."), "The city wins.", "Correct feminine singular"),
        (_grc("τὰ ὅπλα κεῖται."), "The weapons lie.", "Correct neuter plural"),
        (_grc("ὁ ἥρως ἀποθνῄσκει."), "The hero dies.", "Correct masculine singular"),
        (_grc("αἱ νῆες πλέουσιν."), "The ships sail.", "Correct feminine plural"),
        (_grc("τὸ ἔργον γίγνεται."), "The work becomes.", "Correct neuter singular"),
        (_grc("οἱ φίλοι μένουσιν."), "The friends remain.", "Correct masculine plural"),
        (_grc("ἡ ἀλήθεια φαίνεται."), "The truth appears.", "Correct feminine singular"),
        (_grc("τὰ ζῷα τρέχει."), "The animals run.", "Correct neuter plural with 3rd singular"),
    ]
    incorrect_patterns = [
        (_grc("ὁ ἄνθρωπος ἔρχονται."), _grc("Verb should be ἔρχεται (singular) not ἔρχονται (plural)")),
        (_grc("οἱ ἄνθρωπος ἔρχεται."), _grc("Article οἱ (plural) doesn't match ἄνθρωπος (singular)")),
        (_grc("τὸν γυνή λέγει."), _grc("Article τὸν (masculine) doesn't match γυνή (feminine)")),
        (_grc("ἡ γυνὴ λέγουσιν."), _grc("Verb λέγουσιν (plural) doesn't match ἡ γυνή (singular)")),
        (_grc("οἱ κόραι τρέχει."), _grc("Verb should be τρέχουσιν (plural) not τρέχει (singular)")),
        (_grc("τὸ τέκνον παίζουσιν."), _grc("Neuter singular τέκνον requires singular verb, not παίζουσιν")),
        (_grc("ὁ στρατιῶται μάχεται."), _grc("Article ὁ (singular) doesn't match στρατιῶται (plural)")),
        (_grc("ἡ θάλασσα κινοῦνται."), _grc("Singular θάλασσα requires singular verb κινεῖται")),
        (_grc("τὰ δῶρα φέρει."), _grc("Neuter plural δῶρα requires φέρομεν or φέρουσιν")),
        (_grc("ὁ ποιητὴς ᾄδουσιν."), _grc("Singular ποιητής requires ᾄδει not ᾄδουσιν")),
        (_grc("αἱ μοῦσαι ᾄδει."), _grc("Plural μοῦσαι requires ᾄδουσιν not ᾄδει")),
        (_grc("τὸ βιβλίον εἰσίν."), _grc("Neuter singular requires ἐστίν not εἰσίν")),
        (_grc("οἱ θεοὶ ἄρχει."), _grc("Plural θεοί requires ἄρχουσιν not ἄρχει")),
        (_grc("ἡ πόλις νικῶσιν."), _grc("Singular πόλις requires νικᾷ not νικῶσιν")),
        (_grc("τὰ ὅπλα κεῖσθε."), _grc("Neuter plural requires κεῖται or κεῖνται not κεῖσθε")),
        (_grc("ὁ ἥρως ἀποθνῄσκουσιν."), _grc("Singular ἥρως requires ἀποθνῄσκει")),
        (_grc("αἱ νῆες πλεῖ."), _grc("Plural νῆες requires πλέουσιν not πλεῖ")),
        (_grc("τὸ ἔργον γίγνονται."), _grc("Singular ἔργον requires γίγνεται")),
        (_grc("οἱ φίλοι μένει."), _grc("Plural φίλοι requires μένουσιν not μένει")),
        (_grc("ἡ ἀλήθεια φαίνονται."), _grc("Singular ἀλήθεια requires φαίνεται")),
        (_grc("τὰ ζῷα τρέχουσιν."), _grc("Neuter plural typically takes singular verb τρέχει")),
    ]

    is_correct = rng.choice([True, False])
    if is_correct:
        sentence, _translation, explanation = rng.choice(correct_patterns)
        return GrammarTask(
            sentence=sentence,
            is_correct=True,
            error_explanation=None,
        )
    else:
        sentence, explanation = rng.choice(incorrect_patterns)
        return GrammarTask(
            sentence=sentence,
            is_correct=False,
            error_explanation=explanation,
        )


def _build_listening_task(language: str, context: LessonContext, rng: random.Random) -> ListeningTask:
    # Latin listening - EXPANDED 3x for variety
    if language == "lat":
        latin_words = [
            "amo",
            "video",
            "duco",
            "capio",
            "audio",
            "sum",
            "do",
            "facio",
            "venio",
            "dico",
            "puella",
            "rosa",
            "bellum",
            "pax",
            "rex",
            "urbs",
            "terra",
            "vita",
            "homo",
            "femina",
            "magnus",
            "bonus",
            "malus",
            "novus",
            "pulcher",
            "fortis",
            "puer",
            "mater",
            "pater",
            "soror",
        ]
        audio_text = apply_script_transform(rng.choice(latin_words), language)
        options = [
            apply_script_transform(word, language)
            for word in rng.sample(latin_words, min(4, len(latin_words)))
        ]
        if audio_text not in options:
            options[0] = audio_text
        rng.shuffle(options)
        return ListeningTask(audio_url=None, audio_text=audio_text, options=options, answer=audio_text)

    # Hebrew listening - EXPANDED 3x for variety
    if language == "hbo":
        hebrew_words = [
            "שָׁלוֹם",
            "אֱלֹהִים",
            "מֶלֶךְ",
            "דָּבָר",
            "אִישׁ",
            "אִשָּׁה",
            "בַּיִת",
            "יָד",
            "עִיר",
            "אֶרֶץ",
            "שָׁמַיִם",
            "יוֹם",
            "לַיְלָה",
            "מַיִם",
            "אֵשׁ",
            "לֵב",
            "נֶפֶשׁ",
            "חַיִּים",
            "אַהֲבָה",
            "אֱמֶת",
        ]
        audio_text = apply_script_transform(rng.choice(hebrew_words), language)
        options = [
            apply_script_transform(word, language)
            for word in rng.sample(hebrew_words, min(4, len(hebrew_words)))
        ]
        if audio_text not in options:
            options[0] = audio_text
        rng.shuffle(options)
        return ListeningTask(audio_url=None, audio_text=audio_text, options=options, answer=audio_text)

    # Sanskrit listening - EXPANDED 3x for variety
    if language == "san":
        sanskrit_words = [
            "नमस्ते",
            "देव",
            "धर्म",
            "कर्म",
            "योग",
            "वेद",
            "गुरु",
            "माता",
            "पिता",
            "पुत्र",
            "जल",
            "अग्नि",
            "वायु",
            "पृथिवी",
            "आकाश",
            "प्रेम",
            "सत्य",
            "शान्ति",
            "ज्ञान",
            "आत्मन्",
        ]
        audio_text = apply_script_transform(rng.choice(sanskrit_words), language)
        options = [
            apply_script_transform(word, language)
            for word in rng.sample(sanskrit_words, min(4, len(sanskrit_words)))
        ]
        if audio_text not in options:
            options[0] = audio_text
        rng.shuffle(options)
        return ListeningTask(audio_url=None, audio_text=audio_text, options=options, answer=audio_text)

    # For other non-Greek languages
    if language and not language.startswith("grc"):
        return ListeningTask(
            audio_url=None,
            audio_text=f"Coming soon for {language}",
            options=["placeholder"],
            answer="placeholder",
        )
    # Use daily lines or vocabulary as listening material
    if context.text_range_data and context.text_range_data.vocabulary:
        vocab_items = list(context.text_range_data.vocabulary)
        target = rng.choice(vocab_items)
        audio_text = target.surface_forms[0] if target.surface_forms else target.lemma

        # Build distractors from other vocab
        options = {audio_text}
        for item in vocab_items:
            if len(options) >= 4:
                break
            candidate = item.surface_forms[0] if item.surface_forms else item.lemma
            if candidate != audio_text:
                options.add(candidate)

        option_list = list(options)
        rng.shuffle(option_list)

        return ListeningTask(
            audio_url=None,  # TTS integration pending
            audio_text=audio_text,
            options=option_list,
            answer=audio_text,
        )
    else:
        # Fallback to daily lines
        pool = list(context.daily_lines) or list(_fallback_daily_lines())
        target = rng.choice(pool)
        audio_text = apply_script_transform(_choose_variant(target, rng), language)

        # Build distractors from other lines
        options = {audio_text}
        for line in pool:
            if len(options) >= 4:
                break
            candidate = apply_script_transform(_choose_variant(line, rng), language)
            if candidate != audio_text:
                options.add(candidate)

        # If we don't have enough options, add some Greek words as distractors
        if len(options) < 2:
            fallback_words = ["ἄνθρωπος", "λόγος", "θεός", "πόλις", "δόξα"]
            for word in fallback_words:
                if word != audio_text and word not in options:
                    options.add(word)
                if len(options) >= 4:
                    break

        option_list = list(options)
        rng.shuffle(option_list)

        return ListeningTask(
            audio_url=None,
            audio_text=audio_text,
            options=option_list,
            answer=audio_text,
        )


def _build_speaking_task(language: str, context: LessonContext, rng: random.Random) -> SpeakingTask:
    # Latin speaking
    if language == "lat":
        latin_phrases = ["amo te", "salve", "vale", "pax vobiscum"]
        text = rng.choice(latin_phrases)
        return SpeakingTask(
            prompt="Speak this Latin phrase:",
            target_text=text,
            phonetic_guide=_generate_phonetic_guide(text, "lat-Latn"),
        )

    # Hebrew speaking
    if language == "hbo":
        hebrew_phrases = ["שָׁלוֹם", "בָּרוּךְ", "תּוֹדָה"]
        text = rng.choice(hebrew_phrases)
        return SpeakingTask(
            prompt="Speak this Hebrew word:",
            target_text=text,
            phonetic_guide=_generate_phonetic_guide(text, "heb-Hebr"),
        )

    # Sanskrit speaking
    if language == "san":
        sanskrit_phrases = ["नमस्ते", "धन्यवाद", "शान्तिः"]
        text = rng.choice(sanskrit_phrases)
        return SpeakingTask(
            prompt="Speak this Sanskrit word:",
            target_text=text,
            phonetic_guide=_generate_phonetic_guide(text, "san-Deva"),
        )

    # For other non-Greek languages
    if language and not language.startswith("grc"):
        return SpeakingTask(
            prompt=f"Speak aloud (Coming soon for {language})",
            target_text="placeholder",
            phonetic_guide=None,
        )
    # Use alphabet letters or common phrases
    alphabet = get_alphabet_for_language(language)
    if alphabet and rng.choice([True, False]):
        # Letter pronunciation practice - just use the letter string itself
        letter = rng.choice(alphabet)
        return SpeakingTask(
            prompt=f"Say the letter: {letter}",
            target_text=letter,
            phonetic_guide=None,  # Alphabet names not available in simplified structure
        )
    else:
        # Word/phrase pronunciation
        pool = list(context.daily_lines) or list(_fallback_daily_lines())
        line = rng.choice(pool)
        text = apply_script_transform(_choose_variant(line, rng), language)
        return SpeakingTask(
            prompt="Speak this phrase aloud:",
            target_text=text,
            phonetic_guide=_generate_phonetic_guide(text, "grc-Grek"),
        )


def _build_wordbank_task(language: str, context: LessonContext, rng: random.Random) -> WordBankTask:
    # Latin wordbank
    if language == "lat":
        sentences = ["puella rosam amat", "puer librum legit", "rex populum regit"]
        text = rng.choice(sentences)
        words = text.split()
        indexed_words = list(enumerate(words))
        rng.shuffle(indexed_words)
        scrambled = [w for _, w in indexed_words]
        correct_order = [0] * len(words)
        for scrambled_idx, (orig_idx, _) in enumerate(indexed_words):
            correct_order[orig_idx] = scrambled_idx
        return WordBankTask(
            words=scrambled, correct_order=correct_order, translation="Arrange in correct order"
        )

    # Hebrew wordbank
    if language == "hbo":
        sentences = ["הָאִישׁ הוֹלֵךְ לַבַּיִת", "הַמֶּלֶךְ יוֹשֵׁב"]
        text = rng.choice(sentences)
        words = text.split()
        indexed_words = list(enumerate(words))
        rng.shuffle(indexed_words)
        scrambled = [w for _, w in indexed_words]
        correct_order = [0] * len(words)
        for scrambled_idx, (orig_idx, _) in enumerate(indexed_words):
            correct_order[orig_idx] = scrambled_idx
        return WordBankTask(
            words=scrambled, correct_order=correct_order, translation="Arrange in correct order"
        )

    # Sanskrit wordbank
    if language == "san":
        sentences = ["बालः गृहं गच्छति", "गुरुः शिष्यं पाठयति"]
        text = rng.choice(sentences)
        words = text.split()
        indexed_words = list(enumerate(words))
        rng.shuffle(indexed_words)
        scrambled = [w for _, w in indexed_words]
        correct_order = [0] * len(words)
        for scrambled_idx, (orig_idx, _) in enumerate(indexed_words):
            correct_order[orig_idx] = scrambled_idx
        return WordBankTask(
            words=scrambled, correct_order=correct_order, translation="Arrange in correct order"
        )

    # For other non-Greek languages
    if not language.startswith("grc"):
        return WordBankTask(
            words=["Coming", "soon"],
            correct_order=[0, 1],
            translation=f"Translation exercise for {language}",
        )
    # Build from daily lines or text samples
    if context.text_range_data and context.text_range_data.text_samples:
        text = apply_script_transform(rng.choice(context.text_range_data.text_samples), language)
        source_kind = "text_range"
    elif context.canonical_lines:
        source = rng.choice(context.canonical_lines)
        text = apply_script_transform(source.text, language)
        source_kind = "canon"
    else:
        fallback = list(context.daily_lines) or list(_fallback_daily_lines())
        line = rng.choice(fallback)
        text = apply_script_transform(_choose_variant(line, rng), language)
        source_kind = "daily"

    # Split into words and create scrambled version
    words = text.split()
    if len(words) < 2:
        # Fallback to a multi-word phrase
        fallback_line = DailyLine(text="τί ὄνομά σου;", en="What is your name?")
        words = fallback_line.text.split()
        translation = fallback_line.en
    else:
        # Use corresponding English if available
        if source_kind == "daily" and context.daily_lines:
            for line in context.daily_lines:
                if _choose_variant(line, rng) == text:
                    translation = line.en
                    break
            else:
                translation = "Arrange these words in the correct order."
        else:
            translation = "Arrange these words in the correct order."

    # Create scrambled version and track how to unscramble
    # correct_order[i] tells which index in scrambled_words gives the i-th original word
    # Example: original = ["A", "B", "C"], scrambled = ["C", "A", "B"]
    # correct_order = [1, 2, 0] means: words[1]="A", words[2]="B", words[0]="C"
    indexed_words = list(enumerate(words))  # [(0,"A"), (1,"B"), (2,"C")]
    rng.shuffle(indexed_words)  # [(2,"C"), (0,"A"), (1,"B")]

    scrambled_words = [word for _, word in indexed_words]  # ["C", "A", "B"]

    # Build mapping: for each original position, find where it ended up in scrambled
    correct_order = [0] * len(words)
    for scrambled_idx, (original_idx, _) in enumerate(indexed_words):
        correct_order[original_idx] = scrambled_idx
    # Result: correct_order = [1, 2, 0]

    return WordBankTask(
        words=scrambled_words,
        correct_order=correct_order,
        translation=translation,
    )


def _build_truefalse_task(language: str, context: LessonContext, rng: random.Random) -> TrueFalseTask:
    # Latin true/false
    if language == "lat":
        lat_true = [("Latin has five declensions", "Latin nouns are grouped into five declensions")]
        lat_false = [("Latin has articles", "Latin does not have definite or indefinite articles")]
        is_true = rng.choice([True, False])
        if is_true:
            stmt, expl = rng.choice(lat_true)
            return TrueFalseTask(statement=stmt, is_true=True, explanation=expl)
        else:
            stmt, expl = rng.choice(lat_false)
            return TrueFalseTask(statement=stmt, is_true=False, explanation=expl)

    # Hebrew true/false
    if language == "hbo":
        hbo_true = [("Hebrew is written right to left", "Hebrew script is read from right to left")]
        hbo_false = [("Hebrew has lowercase letters", "Hebrew does not distinguish upper and lowercase")]
        is_true = rng.choice([True, False])
        if is_true:
            stmt, expl = rng.choice(hbo_true)
            return TrueFalseTask(statement=stmt, is_true=True, explanation=expl)
        else:
            stmt, expl = rng.choice(hbo_false)
            return TrueFalseTask(statement=stmt, is_true=False, explanation=expl)

    # Sanskrit true/false
    if language == "san":
        san_true = [("Sanskrit has eight cases", "Sanskrit nouns decline through eight cases")]
        san_false = [("Sanskrit uses Latin script", "Sanskrit uses Devanagari script")]
        is_true = rng.choice([True, False])
        if is_true:
            stmt, expl = rng.choice(san_true)
            return TrueFalseTask(statement=stmt, is_true=True, explanation=expl)
        else:
            stmt, expl = rng.choice(san_false)
            return TrueFalseTask(statement=stmt, is_true=False, explanation=expl)

    # For other non-Greek languages
    if language and not language.startswith("grc"):
        return TrueFalseTask(
            prompt=f"True or False (Coming soon for {language})",
            answer=True,
            explanation="Placeholder",
        )
    # Grammar and vocabulary facts (20+ examples each)
    true_statements = [
        (
            "The Greek alphabet has 24 letters.",
            "The Greek alphabet contains exactly 24 letters from alpha to omega.",
        ),
        (
            "Greek nouns have gender (masculine, feminine, neuter).",
            "Greek nouns are classified into three genders.",
        ),
        (
            "The article 'ὁ' is masculine nominative singular.",
            "ὁ is the masculine form of the definite article.",
        ),
        (
            "Greek verbs conjugate for person and number.",
            "Greek verbs change form based on who performs the action.",
        ),
        (
            "The word 'λόγος' means word or reason.",
            "λόγος is a fundamental Greek word with multiple meanings.",
        ),
        (
            "Epsilon (ε) and eta (η) both represent 'e' sounds.",
            "Greek has two letters for different 'e' vowel sounds.",
        ),
        (
            "The accusative case marks the direct object.",
            "In Greek, accusative is primarily for direct objects.",
        ),
        (
            "Greek uses different letters for different breathing marks.",
            "Smooth and rough breathing affect pronunciation.",
        ),
        ("The dative case can express location.", "The dative has many uses including location and means."),
        ("Omega (ω) is a long 'o' sound.", "Omega represents the long 'o' in contrast to omicron."),
        ("The genitive case shows possession.", "Genitive is used for possession, among other functions."),
        (
            "Greek verbs have middle voice in addition to active and passive.",
            "Middle voice is unique to Greek grammar.",
        ),
        ("The aorist tense indicates completed action.", "Aorist is the simple past tense in Greek."),
        (
            "Neuter plural subjects typically take singular verbs.",
            "This is a unique feature of Greek grammar.",
        ),
        ("The particle μέν is often paired with δέ.", "These particles create balanced contrasts."),
        (
            "Greek uses movable nu (ν) at the end of some words.",
            "Movable nu appears before vowels or at the end.",
        ),
        ("The optative mood expresses wishes.", "The optative is used for potential and wishes."),
        (
            "Deponent verbs are middle/passive in form but active in meaning.",
            "Some Greek verbs have this property.",
        ),
        ("The dual number exists in Homer.", "Homer preserves archaic dual forms for pairs."),
        ("Sigma (σ/ς) changes form at word-end.", "Final sigma is written as ς."),
    ]
    false_statements = [
        (
            "The Greek alphabet has 26 letters.",
            "The Greek alphabet has 24 letters, not 26 (which is English).",
        ),
        (
            "Greek has no definite article.",
            "Greek has a definite article (ὁ, ἡ, τό) but no indefinite article.",
        ),
        (
            "All Greek verbs are regular.",
            "Greek has many irregular verbs, especially common ones like εἰμί (to be).",
        ),
        (
            "Greek word order is always subject-verb-object.",
            "Greek word order is flexible due to case endings.",
        ),
        (
            "The nominative case is used for direct objects.",
            "Direct objects use the accusative case, not nominative.",
        ),
        ("Theta (θ) and tau (τ) represent the same sound.", "Theta is 'th' while tau is 't'."),
        (
            "Greek has five cases like Latin.",
            "Greek has five cases (nominative, genitive, dative, accusative, vocative).",
        ),
        ("Beta (β) is pronounced like English 'b' in all periods.", "In modern Greek, beta sounds like 'v'."),
        (
            "The infinitive is the main form used for commands.",
            "Commands use the imperative mood, not infinitive.",
        ),
        (
            "Gamma (γ) always sounds like 'g' in 'go'.",
            "Before certain vowels, gamma sounds like 'n' or 'ng'.",
        ),
        (
            "Greek has only two tenses: present and past.",
            "Greek has present, imperfect, future, aorist, perfect, pluperfect.",
        ),
        ("The article 'ἡ' is masculine.", "ἡ is the feminine nominative singular article."),
        (
            "Participles in Greek cannot be used as nouns.",
            "Greek participles frequently function as substantives.",
        ),
        (
            "The subjunctive mood is rare in Greek.",
            "The subjunctive is very common in Greek for purpose, fear, etc.",
        ),
        (
            "Zeta (ζ) represents the 'z' sound alone.",
            "Zeta represents 'zd' or 'dz' in ancient pronunciation.",
        ),
        ("Greek has no future tense.", "Greek has a well-developed future tense."),
        (
            "The vocative case is identical to nominative in all declensions.",
            "Vocative differs from nominative in many declensions.",
        ),
        (
            "Ancient Greek had only one dialect.",
            "Greek had multiple dialects: Attic, Ionic, Doric, Aeolic, etc.",
        ),
        (
            "The perfect tense indicates ongoing action.",
            "Perfect indicates completed action with present relevance.",
        ),
        (
            "Greek prepositions only take one case.",
            "Many Greek prepositions take multiple cases with different meanings.",
        ),
    ]

    is_true = rng.choice([True, False])
    if is_true:
        statement, explanation = rng.choice(true_statements)
        return TrueFalseTask(
            statement=statement,
            is_true=True,
            explanation=explanation,
        )
    else:
        statement, explanation = rng.choice(false_statements)
        return TrueFalseTask(
            statement=statement,
            is_true=False,
            explanation=explanation,
        )


def _build_multiplechoice_task(
    language: str, context: LessonContext, rng: random.Random
) -> MultipleChoiceTask:
    # Latin multiple choice
    if language == "lat":
        questions = [
            {
                "question": "What does 'amo' mean?",
                "context": None,
                "options": ["I love", "I see", "I hear", "I go"],
                "answer_index": 0,
            },
            {
                "question": "What case is used for direct objects?",
                "context": None,
                "options": ["Nominative", "Genitive", "Accusative", "Ablative"],
                "answer_index": 2,
            },
        ]
        q = rng.choice(questions)
        return MultipleChoiceTask(
            question=q["question"], context=q["context"], options=q["options"], answer_index=q["answer_index"]
        )

    # Hebrew multiple choice
    if language == "hbo":
        questions = [
            {
                "question": "What does 'שָׁלוֹם' mean?",
                "context": None,
                "options": ["peace", "war", "house", "king"],
                "answer_index": 0,
            },
            {
                "question": "Hebrew is read in which direction?",
                "context": None,
                "options": ["Left to right", "Right to left", "Top to bottom", "Bottom to top"],
                "answer_index": 1,
            },
        ]
        q = rng.choice(questions)
        return MultipleChoiceTask(
            question=q["question"], context=q["context"], options=q["options"], answer_index=q["answer_index"]
        )

    # Sanskrit multiple choice
    if language == "san":
        questions = [
            {
                "question": "What does 'नमस्ते' mean?",
                "context": None,
                "options": ["greetings", "goodbye", "yes", "no"],
                "answer_index": 0,
            },
            {
                "question": "How many cases does Sanskrit have?",
                "context": None,
                "options": ["5", "6", "7", "8"],
                "answer_index": 3,
            },
        ]
        q = rng.choice(questions)
        return MultipleChoiceTask(
            question=q["question"], context=q["context"], options=q["options"], answer_index=q["answer_index"]
        )

    # For other non-Greek languages
    if language and not language.startswith("grc"):
        return MultipleChoiceTask(
            prompt=f"Multiple choice (Coming soon for {language})",
            options=["placeholder"],
            answer="placeholder",
            explanation="Placeholder",
        )
    # Comprehension questions about vocabulary or grammar (20+ examples)
    questions = [
        {
            "question": "What does 'ἄνθρωπος' mean?",
            "context": None,
            "options": ["human, person", "city", "word", "god"],
            "answer_index": 0,
        },
        {
            "question": "What does 'λόγος' mean?",
            "context": None,
            "options": ["god", "human", "word, reason", "city"],
            "answer_index": 2,
        },
        {
            "question": "What case is used for the direct object in Greek?",
            "context": None,
            "options": ["Nominative", "Genitive", "Dative", "Accusative"],
            "answer_index": 3,
        },
        {
            "question": "Which letter makes the 'th' sound in English?",
            "context": "Like in 'think' or 'theater'",
            "options": ["τ (tau)", "θ (theta)", "δ (delta)", "φ (phi)"],
            "answer_index": 1,
        },
        {
            "question": "What does 'θεός' mean?",
            "context": None,
            "options": ["sea", "god", "war", "peace"],
            "answer_index": 1,
        },
        {
            "question": "What does 'πόλις' mean?",
            "context": None,
            "options": ["many", "city-state", "war", "love"],
            "answer_index": 1,
        },
        {
            "question": "Which case shows possession?",
            "context": None,
            "options": ["Nominative", "Genitive", "Dative", "Accusative"],
            "answer_index": 1,
        },
        {
            "question": "What is the nominative plural of 'ὁ'?",
            "context": "Masculine definite article",
            "options": ["τοῦ", "τῷ", "τόν", "οἱ"],
            "answer_index": 3,
        },
        {
            "question": "What does 'ἀγαθός' mean?",
            "context": None,
            "options": ["bad", "good", "beautiful", "wise"],
            "answer_index": 1,
        },
        {
            "question": "Which letter is omega?",
            "context": "The long 'o' sound",
            "options": ["ο", "ω", "α", "ε"],
            "answer_index": 1,
        },
        {
            "question": "What does 'φιλέω' mean?",
            "context": None,
            "options": ["to hate", "to love/like", "to fight", "to run"],
            "answer_index": 1,
        },
        {
            "question": "What voice is unique to Greek?",
            "context": "Beyond active and passive",
            "options": ["Subjunctive", "Middle", "Infinitive", "Imperative"],
            "answer_index": 1,
        },
        {
            "question": "What does 'γίγνομαι' mean?",
            "context": None,
            "options": ["to become, to be", "to see", "to hear", "to speak"],
            "answer_index": 0,
        },
        {
            "question": "Which letter is alpha?",
            "context": "The first letter",
            "options": ["ω", "β", "α", "γ"],
            "answer_index": 2,
        },
        {
            "question": "What does 'δικαιοσύνη' mean?",
            "context": None,
            "options": ["wisdom", "courage", "justice", "temperance"],
            "answer_index": 2,
        },
        {
            "question": "What tense indicates simple past action?",
            "context": None,
            "options": ["Present", "Imperfect", "Aorist", "Perfect"],
            "answer_index": 2,
        },
        {
            "question": "What does 'σοφία' mean?",
            "context": None,
            "options": ["justice", "wisdom", "courage", "beauty"],
            "answer_index": 1,
        },
        {
            "question": "Which case is used with most prepositions?",
            "context": "Varies by preposition",
            "options": ["Only nominative", "Only genitive", "Multiple cases", "Only accusative"],
            "answer_index": 2,
        },
        {
            "question": "What does 'ἀρετή' mean?",
            "context": None,
            "options": ["virtue, excellence", "vice", "weakness", "ignorance"],
            "answer_index": 0,
        },
        {
            "question": "What is the feminine article (nominative singular)?",
            "context": None,
            "options": ["ὁ", "ἡ", "τό", "οἱ"],
            "answer_index": 1,
        },
        {
            "question": "What does 'πρᾶξις' mean?",
            "context": None,
            "options": ["thought", "action, deed", "word", "feeling"],
            "answer_index": 1,
        },
        {
            "question": "Which mood expresses wishes?",
            "context": None,
            "options": ["Indicative", "Subjunctive", "Optative", "Imperative"],
            "answer_index": 2,
        },
        {
            "question": "What does 'ψυχή' mean?",
            "context": None,
            "options": ["body", "soul, life", "mind", "spirit"],
            "answer_index": 1,
        },
        {
            "question": "What is the neuter article (nominative singular)?",
            "context": None,
            "options": ["ὁ", "ἡ", "τό", "τά"],
            "answer_index": 2,
        },
    ]

    selected = rng.choice(questions)
    return MultipleChoiceTask(
        question=selected["question"],
        context=selected["context"],
        options=selected["options"],
        answer_index=selected["answer_index"],
    )


def _choose_variant(line: DailyLine, rng: random.Random) -> str:
    variants: Sequence[str] = line.variants or (line.text,)
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
        add_from_text(line.text)
        for variant in line.variants:
            add_from_text(variant)

    if not context.daily_lines:
        for fallback in _fallback_daily_lines():
            add_from_text(fallback.text)
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
        from app.lesson.script_utils import get_alphabet_for_language

        alphabet_candidates = [letter for letter in get_alphabet_for_language("grc") if letter not in seen]
        rng.shuffle(alphabet_candidates)
        for candidate in alphabet_candidates:
            seen.add(candidate)
            options.append(candidate)
            if len(options) >= min_total:
                break

    rng.shuffle(options)
    return options


def _fallback_daily_lines() -> tuple[DailyLine, ...]:
    """Fallback Greek daily lines.

    Note: These use lowercase with accents. They should be transformed to
    uppercase without accents when used, via apply_script_transform().
    """
    return (
        DailyLine(text="ΧΑΙΡΕ", en="Hello!", language="grc-cls", variants=("ΧΑΙΡΕ",)),
        DailyLine(text="ΕΡΡΩΣΟ", en="Farewell.", language="grc-cls", variants=("ΕΡΡΩΣΟ",)),
        DailyLine(text="ΤΙ ΟΝΟΜΑ ΣΟΥ", en="What is your name?", language="grc-cls"),
        DailyLine(text="ΠΑΡΑΚΑΛΩ", en="You're welcome.", language="grc-cls"),
        DailyLine(text="ΚΑΛΟΣ", en="good/beautiful", language="grc-cls"),
        DailyLine(text="ΜΕΓΑΣ", en="great/large", language="grc-cls"),
        DailyLine(text="ΛΟΓΟΣ", en="word/speech/reason", language="grc-cls"),
        DailyLine(text="ΑΝΘΡΩΠΟΣ", en="human/person", language="grc-cls"),
    )


def _build_dialogue_task(language: str, context: LessonContext, rng: random.Random) -> DialogueTask:
    # Latin dialogue
    if language == "lat":
        dialogues = [
            {
                "lines": [
                    DialogueLine(speaker="Marcus", text="SALVE!", translation="Hello!"),
                    DialogueLine(speaker="Julia", text="SALVE, AMICE!", translation="Hello, friend!"),
                ],
                "options": ["Salve, amice!", "Vale", "Gratias"],
                "answer": "Salve, amice!",
            },
        ]
        d = rng.choice(dialogues)
        return DialogueTask(lines=d["lines"], missing_index=1, options=d["options"], answer=d["answer"])

    # Hebrew dialogue
    if language == "hbo":
        dialogues = [
            {
                "lines": [
                    DialogueLine(speaker="דָּוִד", text="שָׁלוֹם", translation="Peace"),
                    DialogueLine(speaker="שָׂרָה", text="שָׁלוֹם לְךָ", translation="Peace to you"),
                ],
                "options": ["שָׁלוֹם לְךָ", "תּוֹדָה", "בָּרוּךְ"],
                "answer": "שָׁלוֹם לְךָ",
            },
        ]
        d = rng.choice(dialogues)
        return DialogueTask(lines=d["lines"], missing_index=1, options=d["options"], answer=d["answer"])

    # Sanskrit dialogue
    if language == "san":
        dialogues = [
            {
                "lines": [
                    DialogueLine(speaker="रामः", text="नमस्ते", translation="Greetings"),
                    DialogueLine(speaker="सीता", text="नमस्ते", translation="Greetings"),
                ],
                "options": ["नमस्ते", "धन्यवाद", "शान्तिः"],
                "answer": "नमस्ते",
            },
        ]
        d = rng.choice(dialogues)
        return DialogueTask(lines=d["lines"], missing_index=1, options=d["options"], answer=d["answer"])

    # For other non-Greek languages
    if language and not language.startswith("grc"):
        return DialogueTask(
            prompt=f"Dialogue (Coming soon for {language})",
            lines=[DialogueLine(speaker="Speaker", text="Placeholder", translation="Placeholder")],
        )
    """Complete a dialogue conversation"""
    dialogues = [
        {
            "lines": [
                ("Σωκράτης", "Χαῖρε, ὦ Πλάτων. Τί πράττεις;"),
                ("Πλάτων", "___"),
                ("Σωκράτης", "Καλῶς λέγεις."),
            ],
            "missing_idx": 1,
            "options": [
                "Καλῶς, εὐχαριστῶ. Τί πράττεις σύ;",
                "Οὐ καλῶς. Ἀπέρχομαι.",
                "Οὐκ οἶδα.",
                "Χαῖρε!",
            ],
            "answer": "Καλῶς, εὐχαριστῶ. Τί πράττεις σύ;",
        },
        {
            "lines": [
                ("Πολίτης", "Ποῦ ἐστιν ἡ ἀγορά;"),
                ("Ξένος", "___"),
                ("Πολίτης", "Εὐχαριστῶ πολλά."),
            ],
            "missing_idx": 1,
            "options": [
                "Ἡ ἀγορά ἐστιν ἐκεῖ.",
                "Οὐκ οἶδα τί λέγεις.",
                "Τίς εἶ σύ;",
                "Χαῖρε, φίλε.",
            ],
            "answer": "Ἡ ἀγορά ἐστιν ἐκεῖ.",
        },
        {
            "lines": [
                ("Διδάσκαλος", "Τί μανθάνεις σήμερον;"),
                ("Μαθητής", "___"),
                ("Διδάσκαλος", "Εὖ γε!"),
            ],
            "missing_idx": 1,
            "options": [
                "Μανθάνω τὴν γλῶτταν τὴν Ἑλληνικήν.",
                "Οὐ μανθάνω οὐδέν.",
                "Τί ἐστι τοῦτο;",
                "Χαίρομαι.",
            ],
            "answer": "Μανθάνω τὴν γλῶτταν τὴν Ἑλληνικήν.",
        },
        {
            "lines": [
                ("Ἀγοραστής", "Πόσον ἐστὶ τὸ βιβλίον;"),
                ("Πωλητής", "___"),
                ("Ἀγοραστής", "Λαμβάνω αὐτό."),
            ],
            "missing_idx": 1,
            "options": [
                "Τρεῖς δραχμαί.",
                "Οὐκ ἔχω βιβλία.",
                "Πολὺ ἐστίν.",
                "Ἀπέρχομαι νῦν.",
            ],
            "answer": "Τρεῖς δραχμαί.",
        },
        {
            "lines": [
                ("Μήτηρ", "Ποῦ ἐστιν ὁ πατήρ σου;"),
                ("Παῖς", "___"),
                ("Μήτηρ", "Καλῶς. Μένε ἐνταῦθα."),
            ],
            "missing_idx": 1,
            "options": [
                "Ἐν τῇ ἀγορᾷ ἐστίν.",
                "Οὐκ οἶδα.",
                "Ἀπέρχεται.",
                "Πάρεστιν ὧδε.",
            ],
            "answer": "Ἐν τῇ ἀγορᾷ ἐστίν.",
        },
        {
            "lines": [
                ("Ὁδοιπόρος", "Πόσον ἀπέχει ἡ Ἀθήνη;"),
                ("Κώμης", "___"),
                ("Ὁδοιπόρος", "Εὐχαριστῶ σοι."),
            ],
            "missing_idx": 1,
            "options": [
                "Δέκα στάδια ἀπέχει.",
                "Οὐκ οἶδα τὴν ὁδόν.",
                "Ἡ Ἀθήνη μεγάλη ἐστίν.",
                "Πόρρω ἐστίν.",
            ],
            "answer": "Δέκα στάδια ἀπέχει.",
        },
        {
            "lines": [
                ("Φίλος Α", "Βούλει παίζειν μετ' ἐμοῦ;"),
                ("Φίλος Β", "___"),
                ("Φίλος Α", "Ἄγωμεν!"),
            ],
            "missing_idx": 1,
            "options": [
                "Ναί, βούλομαι.",
                "Οὔ, οὐ βούλομαι.",
                "Τί ἐστι τοῦτο;",
                "Ἀπέρχομαι οἴκαδε.",
            ],
            "answer": "Ναί, βούλομαι.",
        },
        {
            "lines": [
                ("Ξένος", "Τίνος ὄνομα φέρεις;"),
                ("Νεανίας", "___"),
                ("Ξένος", "Χαίρω τῇ γνώσει σου."),
            ],
            "missing_idx": 1,
            "options": [
                "Ἀλέξανδρος καλοῦμαι.",
                "Οὐκ οἶδα.",
                "Τίς εἶ σύ;",
                "Ποῦ οἰκεῖς;",
            ],
            "answer": "Ἀλέξανδρος καλοῦμαι.",
        },
        {
            "lines": [
                ("Γέρων", "Πῶς ἔχεις σήμερον;"),
                ("Νεανίας", "___"),
                ("Γέρων", "Χαίρω ἀκούων τοῦτο."),
            ],
            "missing_idx": 1,
            "options": [
                "Εὖ ἔχω, εὐχαριστῶ.",
                "Κακῶς ἔχω.",
                "Τί λέγεις;",
                "Πῶς ἔχεις σύ;",
            ],
            "answer": "Εὖ ἔχω, εὐχαριστῶ.",
        },
        {
            "lines": [
                ("Μαθητής", "Δύναμαι ἐρωτᾶν;"),
                ("Διδάσκαλος", "___"),
                ("Μαθητής", "Τί σημαίνει τοῦτο τὸ ῥῆμα;"),
            ],
            "missing_idx": 1,
            "options": [
                "Ναί, ἐρώτα.",
                "Οὔ, σιώπα.",
                "Οὐκ οἶδα.",
                "Μάνθανε πρῶτον.",
            ],
            "answer": "Ναί, ἐρώτα.",
        },
        {
            "lines": [
                ("Κῆρυξ", "Ἄκουε, ὦ δῆμε!"),
                ("Πολίτης", "___"),
                ("Κῆρυξ", "Ἡ ἐκκλησία ἄρχεται."),
            ],
            "missing_idx": 1,
            "options": [
                "Τί λέγεις; Ἀκούομεν.",
                "Σιώπα!",
                "Ἀπέρχομαι.",
                "Οὐ θέλω ἀκούειν.",
            ],
            "answer": "Τί λέγεις; Ἀκούομεν.",
        },
        {
            "lines": [
                ("Παιδίον", "Πεινῶ, μῆτερ."),
                ("Μήτηρ", "___"),
                ("Παιδίον", "Εὐχαριστῶ, μῆτερ."),
            ],
            "missing_idx": 1,
            "options": [
                "Λαβὲ ἄρτον.",
                "Ὕστερον φάγε.",
                "Οὐκ ἔχω ἄρτον.",
                "Περίμενε ἐδῶ.",
            ],
            "answer": "Λαβὲ ἄρτον.",
        },
        # Extended dialogues to reach 30+ (market, travel, philosophy)
        {
            "lines": [
                ("Ἔμπορος", "Βούλει ἀγοράζειν τοῦτο;"),
                ("Πελάτης", "___"),
                ("Ἔμπορος", "Καλῶς. Δύο δραχμαί."),
            ],
            "missing_idx": 1,
            "options": [
                "Ναί, πόσον ἐστίν;",
                "Οὔ, οὐ βούλομαι.",
                "Τί ἐστι τοῦτο;",
                "Ἀπέρχομαι.",
            ],
            "answer": "Ναί, πόσον ἐστίν;",
        },
        {
            "lines": [
                ("Ναύτης", "Ἡ θάλασσα ἀγρία ἐστι σήμερον."),
                ("Κυβερνήτης", "___"),
                ("Ναύτης", "Συμφωνῶ. Μένωμεν."),
            ],
            "missing_idx": 1,
            "options": [
                "Μὴ πλέωμεν νῦν.",
                "Πλέωμεν ταχέως!",
                "Τί λέγεις;",
                "Ἡ θάλασσα καλή ἐστιν.",
            ],
            "answer": "Μὴ πλέωμεν νῦν.",
        },
        {
            "lines": [
                ("Ῥήτωρ", "Πῶς πείσω τὴν ἐκκλησίαν;"),
                ("Σύμβουλος", "___"),
                ("Ῥήτωρ", "Σοφὸς εἶ."),
            ],
            "missing_idx": 1,
            "options": [
                "Λέγε τὴν ἀλήθειαν μετὰ πάθους.",
                "Σιώπα καὶ ἄκουε.",
                "Οὐκ οἶδα.",
                "Ἀπέρχου νῦν.",
            ],
            "answer": "Λέγε τὴν ἀλήθειαν μετὰ πάθους.",
        },
        {
            "lines": [
                ("Ἰατρός", "Ποῦ ἀλγεῖς;"),
                ("Ἀσθενής", "___"),
                ("Ἰατρός", "Δώσω σοι φάρμακον."),
            ],
            "missing_idx": 1,
            "options": [
                "Ἡ κεφαλή μου ἀλγεῖ.",
                "Εὖ ἔχω.",
                "Οὐκ ἀλγῶ.",
                "Τί θέλεις;",
            ],
            "answer": "Ἡ κεφαλή μου ἀλγεῖ.",
        },
        {
            "lines": [
                ("Γεωργός", "Ἡ σπορὰ καλὴ ἔσται φέτος."),
                ("Γείτων", "___"),
                ("Γεωργός", "Ναί, εὐχαριστῶ τοῖς θεοῖς."),
            ],
            "missing_idx": 1,
            "options": [
                "Οἱ θεοὶ εὐμενεῖς εἰσιν;",
                "Ἡ σπορὰ κακή ἐστιν.",
                "Οὐ πιστεύω.",
                "Τί σπείρεις;",
            ],
            "answer": "Οἱ θεοὶ εὐμενεῖς εἰσιν;",
        },
        {
            "lines": [
                ("Φιλόσοφος", "Τί ἐστιν ἀρετή;"),
                ("Μαθητής", "___"),
                ("Φιλόσοφος", "Ὀρθῶς. Σκέπτομαι μετὰ σοῦ."),
            ],
            "missing_idx": 1,
            "options": [
                "Οὐκ οἶδα, ἀλλὰ ζητῶ.",
                "Ἡ ἀρετὴ οὐκ ἔστιν.",
                "Τί λέγεις;",
                "Ἀπέρχομαι.",
            ],
            "answer": "Οὐκ οἶδα, ἀλλὰ ζητῶ.",
        },
        {
            "lines": [
                ("Ἱερεύς", "Θύομεν τοῖς θεοῖς αὔριον."),
                ("Πολίτης", "___"),
                ("Ἱερεύς", "Φέρε κριὸν ἢ βοῦν."),
            ],
            "missing_idx": 1,
            "options": [
                "Τί δεῖ φέρειν;",
                "Οὐ θέλω θύειν.",
                "Ποῖοι θεοί;",
                "Πότε ἀφικνοῦμαι;",
            ],
            "answer": "Τί δεῖ φέρειν;",
        },
        {
            "lines": [
                ("Στρατηγός", "Πῶς νικήσομεν τοὺς πολεμίους;"),
                ("Ταξίαρχος", "___"),
                ("Στρατηγός", "Ἄριστον σχέδιον!"),
            ],
            "missing_idx": 1,
            "options": [
                "Προσβάλλωμεν νυκτός.",
                "Φεύγωμεν ταχέως.",
                "Οὐ δυνάμεθα νικᾶν.",
                "Τί λέγεις;",
            ],
            "answer": "Προσβάλλωμεν νυκτός.",
        },
        {
            "lines": [
                ("Βιβλιοπώλης", "Ζητεῖς τινα βιβλίον;"),
                ("Ἀναγνώστης", "___"),
                ("Βιβλιοπώλης", "Ἔχω αὐτό. Ἑπτὰ δραχμαί."),
            ],
            "missing_idx": 1,
            "options": [
                "Ναί, τὰ Ὁμήρου ἔπη.",
                "Οὔ, οὐδὲν θέλω.",
                "Πόσα βιβλία ἔχεις;",
                "Οὐκ ἀναγιγνώσκω.",
            ],
            "answer": "Ναί, τὰ Ὁμήρου ἔπη.",
        },
        {
            "lines": [
                ("Ποιητής", "Ἀκούεις τὴν ᾠδήν μου;"),
                ("Κριτής", "___"),
                ("Ποιητής", "Χαίρω!"),
            ],
            "missing_idx": 1,
            "options": [
                "Ναί, καλή ἐστιν.",
                "Οὔ, κακή ἐστιν.",
                "Τί ᾄδεις;",
                "Οὐκ ἀκούω.",
            ],
            "answer": "Ναί, καλή ἐστιν.",
        },
        {
            "lines": [
                ("Γυμναστής", "Θέλεις ἀσκεῖν σήμερον;"),
                ("Ἀθλητής", "___"),
                ("Γυμναστής", "Ἄρχωμεν!"),
            ],
            "missing_idx": 1,
            "options": [
                "Ναί, ἕτοιμός εἰμι.",
                "Οὔ, κάμνω.",
                "Τί ἐστι τοῦτο;",
                "Πότε ἀσκοῦμεν;",
            ],
            "answer": "Ναί, ἕτοιμός εἰμι.",
        },
        {
            "lines": [
                ("Νομοθέτης", "Ὁ νόμος δίκαιός ἐστιν;"),
                ("Πολίτης", "___"),
                ("Νομοθέτης", "Ψηφιζώμεθα οὖν."),
            ],
            "missing_idx": 1,
            "options": [
                "Ναί, συμφωνῶ.",
                "Οὔ, ἄδικός ἐστιν.",
                "Τίς γράφει νόμους;",
                "Οὐκ οἶδα.",
            ],
            "answer": "Ναί, συμφωνῶ.",
        },
        {
            "lines": [
                ("Τραγῳδός", "Ἡ τραγῳδία ἀρχέσθω!"),
                ("Θεατής", "___"),
                ("Τραγῳδός", "Εὐχαριστῶ."),
            ],
            "missing_idx": 1,
            "options": [
                "Σιωπῶμεν καὶ ἀκούωμεν.",
                "Ἀπέρχομαι.",
                "Τί ἐστι τραγῳδία;",
                "Οὐ θέλω ἀκούειν.",
            ],
            "answer": "Σιωπῶμεν καὶ ἀκούωμεν.",
        },
        {
            "lines": [
                ("Ξένος", "Ποῦ εὑρίσκω καταγώγιον;"),
                ("Κώμης", "___"),
                ("Ξένος", "Πολλὰ εὐχαριστῶ."),
            ],
            "missing_idx": 1,
            "options": [
                "Παρὰ τὴν ἀγορὰν ἐστι πανδοκεῖον.",
                "Οὐκ οἶδα.",
                "Τί ζητεῖς;",
                "Οὐκ ἔστι πανδοκεῖον.",
            ],
            "answer": "Παρὰ τὴν ἀγορὰν ἐστι πανδοκεῖον.",
        },
        {
            "lines": [
                ("Μάγειρος", "Τί βούλει φαγεῖν;"),
                ("Δειπνητής", "___"),
                ("Μάγειρος", "Εὐθέως παρασκευάσω."),
            ],
            "missing_idx": 1,
            "options": [
                "Ἰχθὺν καὶ ἄρτον παρακαλῶ.",
                "Οὐ πεινῶ.",
                "Τί ἔχεις;",
                "Οὐ θέλω.",
            ],
            "answer": "Ἰχθὺν καὶ ἄρτον παρακαλῶ.",
        },
        {
            "lines": [
                ("Χορηγός", "Ἡ παράστασις ἑτοίμη ἐστίν;"),
                ("Χορευτής", "___"),
                ("Χορηγός", "Ἀγαθόν. Ἀρχώμεθα."),
            ],
            "missing_idx": 1,
            "options": [
                "Ναί, πάντες ἕτοιμοί εἰσμεν.",
                "Οὔ, δεῖ χρόνου.",
                "Τί ἐστι παράστασις;",
                "Οὐ χορεύομεν.",
            ],
            "answer": "Ναί, πάντες ἕτοιμοί εἰσμεν.",
        },
        {
            "lines": [
                ("Μαντις", "Τί βούλει μαθεῖν περὶ μέλλοντος;"),
                ("Ἱκέτης", "___"),
                ("Μάντις", "Βλέπω νίκην ἐν τῇ μάχῃ."),
            ],
            "missing_idx": 1,
            "options": [
                "Νικήσω ἐν τῇ μάχῃ;",
                "Οὐ πιστεύω μαντικῇ.",
                "Τί βλέπεις;",
                "Πόσον κοστίζει;",
            ],
            "answer": "Νικήσω ἐν τῇ μάχῃ;",
        },
        {
            "lines": [
                ("Παιδαγωγός", "Μανθάνεις τὰ γράμματα καλῶς."),
                ("Παῖς", "___"),
                ("Παιδαγωγός", "Σπούδαζε οὕτως αἰεί."),
            ],
            "missing_idx": 1,
            "options": [
                "Εὐχαριστῶ. Φιλῶ μανθάνειν.",
                "Οὐ θέλω μανθάνειν.",
                "Τί εἰσι γράμματα;",
                "Κάμνω.",
            ],
            "answer": "Εὐχαριστῶ. Φιλῶ μανθάνειν.",
        },
        {
            "lines": [
                ("Τεχνίτης", "Κατασκευάσω σοι σκεῦος."),
                ("Πελάτης", "___"),
                ("Τεχνίτης", "Πέντε ἡμέρας δεῖ."),
            ],
            "missing_idx": 1,
            "options": [
                "Πόσον χρόνον δεῖ;",
                "Οὐ θέλω σκεῦος.",
                "Τί ἐστι σκεῦος;",
                "Πόσον κοστίζει;",
            ],
            "answer": "Πόσον χρόνον δεῖ;",
        },
        {
            "lines": [
                ("Ἀγγελιοφόρος", "Φέρω ἀγγελίαν ἐκ τῆς πόλεως."),
                ("Στρατηγός", "___"),
                ("Ἀγγελιοφόρος", "Οἱ σύμμαχοι ἀφίκοντο."),
            ],
            "missing_idx": 1,
            "options": [
                "Τίνα ἀγγελίαν φέρεις;",
                "Οὐ θέλω ἀκούειν.",
                "Ποία πόλις;",
                "Ἄπελθε.",
            ],
            "answer": "Τίνα ἀγγελίαν φέρεις;",
        },
    ]

    dialogue = rng.choice(dialogues)
    lines = [DialogueLine(speaker=speaker, text=text) for speaker, text in dialogue["lines"]]

    return DialogueTask(
        lines=lines,
        missing_index=dialogue["missing_idx"],
        options=dialogue["options"],
        answer=dialogue["answer"],
    )


def _build_conjugation_task(language: str, context: LessonContext, rng: random.Random) -> ConjugationTask:
    """Conjugate a verb"""
    # Latin conjugations
    if language == "lat":
        latin_conjugations = [
            # First conjugation: amo (present)
            {
                "infinitive": "amo",
                "meaning": "to love",
                "person": "1st person singular",
                "tense": "present",
                "answer": "amo",
            },
            {
                "infinitive": "amo",
                "meaning": "to love",
                "person": "2nd person singular",
                "tense": "present",
                "answer": "amas",
            },
            {
                "infinitive": "amo",
                "meaning": "to love",
                "person": "3rd person singular",
                "tense": "present",
                "answer": "amat",
            },
            {
                "infinitive": "amo",
                "meaning": "to love",
                "person": "1st person plural",
                "tense": "present",
                "answer": "amamus",
            },
            {
                "infinitive": "amo",
                "meaning": "to love",
                "person": "2nd person plural",
                "tense": "present",
                "answer": "amatis",
            },
            {
                "infinitive": "amo",
                "meaning": "to love",
                "person": "3rd person plural",
                "tense": "present",
                "answer": "amant",
            },
            # First conjugation: amo (imperfect)
            {
                "infinitive": "amo",
                "meaning": "to love",
                "person": "1st person singular",
                "tense": "imperfect",
                "answer": "amabam",
            },
            {
                "infinitive": "amo",
                "meaning": "to love",
                "person": "2nd person singular",
                "tense": "imperfect",
                "answer": "amabas",
            },
            {
                "infinitive": "amo",
                "meaning": "to love",
                "person": "3rd person singular",
                "tense": "imperfect",
                "answer": "amabat",
            },
            # First conjugation: amo (future)
            {
                "infinitive": "amo",
                "meaning": "to love",
                "person": "1st person singular",
                "tense": "future",
                "answer": "amabo",
            },
            {
                "infinitive": "amo",
                "meaning": "to love",
                "person": "2nd person singular",
                "tense": "future",
                "answer": "amabis",
            },
            {
                "infinitive": "amo",
                "meaning": "to love",
                "person": "3rd person singular",
                "tense": "future",
                "answer": "amabit",
            },
            # Second conjugation: video (present)
            {
                "infinitive": "video",
                "meaning": "to see",
                "person": "1st person singular",
                "tense": "present",
                "answer": "video",
            },
            {
                "infinitive": "video",
                "meaning": "to see",
                "person": "2nd person singular",
                "tense": "present",
                "answer": "vides",
            },
            {
                "infinitive": "video",
                "meaning": "to see",
                "person": "3rd person singular",
                "tense": "present",
                "answer": "videt",
            },
            {
                "infinitive": "video",
                "meaning": "to see",
                "person": "1st person plural",
                "tense": "present",
                "answer": "videmus",
            },
            # Second conjugation: video (imperfect)
            {
                "infinitive": "video",
                "meaning": "to see",
                "person": "1st person singular",
                "tense": "imperfect",
                "answer": "videbam",
            },
            {
                "infinitive": "video",
                "meaning": "to see",
                "person": "3rd person singular",
                "tense": "imperfect",
                "answer": "videbat",
            },
            # Second conjugation: video (future)
            {
                "infinitive": "video",
                "meaning": "to see",
                "person": "1st person singular",
                "tense": "future",
                "answer": "videbo",
            },
            {
                "infinitive": "video",
                "meaning": "to see",
                "person": "3rd person singular",
                "tense": "future",
                "answer": "videbit",
            },
            # Third conjugation: duco (present)
            {
                "infinitive": "duco",
                "meaning": "to lead",
                "person": "1st person singular",
                "tense": "present",
                "answer": "duco",
            },
            {
                "infinitive": "duco",
                "meaning": "to lead",
                "person": "2nd person singular",
                "tense": "present",
                "answer": "ducis",
            },
            {
                "infinitive": "duco",
                "meaning": "to lead",
                "person": "3rd person singular",
                "tense": "present",
                "answer": "ducit",
            },
            {
                "infinitive": "duco",
                "meaning": "to lead",
                "person": "1st person plural",
                "tense": "present",
                "answer": "ducimus",
            },
            # Third conjugation: duco (imperfect)
            {
                "infinitive": "duco",
                "meaning": "to lead",
                "person": "1st person singular",
                "tense": "imperfect",
                "answer": "ducebam",
            },
            {
                "infinitive": "duco",
                "meaning": "to lead",
                "person": "3rd person singular",
                "tense": "imperfect",
                "answer": "ducebat",
            },
            # Third conjugation: duco (future)
            {
                "infinitive": "duco",
                "meaning": "to lead",
                "person": "1st person singular",
                "tense": "future",
                "answer": "ducam",
            },
            {
                "infinitive": "duco",
                "meaning": "to lead",
                "person": "3rd person singular",
                "tense": "future",
                "answer": "ducet",
            },
            # Third conjugation -io: capio (present)
            {
                "infinitive": "capio",
                "meaning": "to take",
                "person": "1st person singular",
                "tense": "present",
                "answer": "capio",
            },
            {
                "infinitive": "capio",
                "meaning": "to take",
                "person": "2nd person singular",
                "tense": "present",
                "answer": "capis",
            },
            {
                "infinitive": "capio",
                "meaning": "to take",
                "person": "3rd person singular",
                "tense": "present",
                "answer": "capit",
            },
            {
                "infinitive": "capio",
                "meaning": "to take",
                "person": "1st person plural",
                "tense": "present",
                "answer": "capimus",
            },
            # Third conjugation -io: capio (imperfect)
            {
                "infinitive": "capio",
                "meaning": "to take",
                "person": "1st person singular",
                "tense": "imperfect",
                "answer": "capiebam",
            },
            {
                "infinitive": "capio",
                "meaning": "to take",
                "person": "3rd person singular",
                "tense": "imperfect",
                "answer": "capiebat",
            },
            # Third conjugation -io: capio (future)
            {
                "infinitive": "capio",
                "meaning": "to take",
                "person": "1st person singular",
                "tense": "future",
                "answer": "capiam",
            },
            {
                "infinitive": "capio",
                "meaning": "to take",
                "person": "3rd person singular",
                "tense": "future",
                "answer": "capiet",
            },
            # Fourth conjugation: audio (present)
            {
                "infinitive": "audio",
                "meaning": "to hear",
                "person": "1st person singular",
                "tense": "present",
                "answer": "audio",
            },
            {
                "infinitive": "audio",
                "meaning": "to hear",
                "person": "2nd person singular",
                "tense": "present",
                "answer": "audis",
            },
            {
                "infinitive": "audio",
                "meaning": "to hear",
                "person": "3rd person singular",
                "tense": "present",
                "answer": "audit",
            },
            {
                "infinitive": "audio",
                "meaning": "to hear",
                "person": "1st person plural",
                "tense": "present",
                "answer": "audimus",
            },
            # Fourth conjugation: audio (imperfect)
            {
                "infinitive": "audio",
                "meaning": "to hear",
                "person": "1st person singular",
                "tense": "imperfect",
                "answer": "audiebam",
            },
            {
                "infinitive": "audio",
                "meaning": "to hear",
                "person": "3rd person singular",
                "tense": "imperfect",
                "answer": "audiebat",
            },
            # Fourth conjugation: audio (future)
            {
                "infinitive": "audio",
                "meaning": "to hear",
                "person": "1st person singular",
                "tense": "future",
                "answer": "audiam",
            },
            {
                "infinitive": "audio",
                "meaning": "to hear",
                "person": "3rd person singular",
                "tense": "future",
                "answer": "audiet",
            },
        ]
        conj = rng.choice(latin_conjugations)
        return ConjugationTask(
            verb_infinitive=conj["infinitive"],
            verb_meaning=conj["meaning"],
            person=conj["person"],
            tense=conj["tense"],
            answer=conj["answer"],
        )

    # Hebrew conjugations
    if language == "hbo":
        hebrew_conjugations = [
            # Pa'al (Qal) - קָטַל (to kill)
            {
                "infinitive": "קָטַל",
                "meaning": "to kill",
                "person": "3rd person masculine singular",
                "tense": "qatal (perfect)",
                "answer": "קָטַל",
            },
            {
                "infinitive": "קָטַל",
                "meaning": "to kill",
                "person": "3rd person feminine singular",
                "tense": "qatal (perfect)",
                "answer": "קָטְלָה",
            },
            {
                "infinitive": "קָטַל",
                "meaning": "to kill",
                "person": "2nd person masculine singular",
                "tense": "qatal (perfect)",
                "answer": "קָטַלְתָּ",
            },
            {
                "infinitive": "קָטַל",
                "meaning": "to kill",
                "person": "2nd person feminine singular",
                "tense": "qatal (perfect)",
                "answer": "קָטַלְתְּ",
            },
            {
                "infinitive": "קָטַל",
                "meaning": "to kill",
                "person": "1st person singular",
                "tense": "qatal (perfect)",
                "answer": "קָטַלְתִּי",
            },
            {
                "infinitive": "קָטַל",
                "meaning": "to kill",
                "person": "3rd person masculine plural",
                "tense": "qatal (perfect)",
                "answer": "קָטְלוּ",
            },
            {
                "infinitive": "קָטַל",
                "meaning": "to kill",
                "person": "3rd person masculine singular",
                "tense": "yiqtol (imperfect)",
                "answer": "יִקְטֹל",
            },
            {
                "infinitive": "קָטַל",
                "meaning": "to kill",
                "person": "3rd person feminine singular",
                "tense": "yiqtol (imperfect)",
                "answer": "תִּקְטֹל",
            },
            {
                "infinitive": "קָטַל",
                "meaning": "to kill",
                "person": "2nd person masculine singular",
                "tense": "yiqtol (imperfect)",
                "answer": "תִּקְטֹל",
            },
            {
                "infinitive": "קָטַל",
                "meaning": "to kill",
                "person": "1st person singular",
                "tense": "yiqtol (imperfect)",
                "answer": "אֶקְטֹל",
            },
            # שָׁמַר (to guard, keep)
            {
                "infinitive": "שָׁמַר",
                "meaning": "to guard",
                "person": "3rd person masculine singular",
                "tense": "qatal (perfect)",
                "answer": "שָׁמַר",
            },
            {
                "infinitive": "שָׁמַר",
                "meaning": "to guard",
                "person": "3rd person feminine singular",
                "tense": "qatal (perfect)",
                "answer": "שָׁמְרָה",
            },
            {
                "infinitive": "שָׁמַר",
                "meaning": "to guard",
                "person": "1st person singular",
                "tense": "qatal (perfect)",
                "answer": "שָׁמַרְתִּי",
            },
            {
                "infinitive": "שָׁמַר",
                "meaning": "to guard",
                "person": "3rd person masculine singular",
                "tense": "yiqtol (imperfect)",
                "answer": "יִשְׁמֹר",
            },
            {
                "infinitive": "שָׁמַר",
                "meaning": "to guard",
                "person": "1st person singular",
                "tense": "yiqtol (imperfect)",
                "answer": "אֶשְׁמֹר",
            },
            # Pi'el - דִּבֵּר (to speak)
            {
                "infinitive": "דִּבֵּר",
                "meaning": "to speak",
                "person": "3rd person masculine singular",
                "tense": "qatal (perfect)",
                "answer": "דִּבֵּר",
            },
            {
                "infinitive": "דִּבֵּר",
                "meaning": "to speak",
                "person": "3rd person feminine singular",
                "tense": "qatal (perfect)",
                "answer": "דִּבְּרָה",
            },
            {
                "infinitive": "דִּבֵּר",
                "meaning": "to speak",
                "person": "1st person singular",
                "tense": "qatal (perfect)",
                "answer": "דִּבַּרְתִּי",
            },
            {
                "infinitive": "דִּבֵּר",
                "meaning": "to speak",
                "person": "3rd person masculine singular",
                "tense": "yiqtol (imperfect)",
                "answer": "יְדַבֵּר",
            },
            {
                "infinitive": "דִּבֵּר",
                "meaning": "to speak",
                "person": "1st person singular",
                "tense": "yiqtol (imperfect)",
                "answer": "אֲדַבֵּר",
            },
            # Hif'il - הִגִּיד (to tell)
            {
                "infinitive": "הִגִּיד",
                "meaning": "to tell",
                "person": "3rd person masculine singular",
                "tense": "qatal (perfect)",
                "answer": "הִגִּיד",
            },
            {
                "infinitive": "הִגִּיד",
                "meaning": "to tell",
                "person": "3rd person feminine singular",
                "tense": "qatal (perfect)",
                "answer": "הִגִּידָה",
            },
            {
                "infinitive": "הִגִּיד",
                "meaning": "to tell",
                "person": "1st person singular",
                "tense": "qatal (perfect)",
                "answer": "הִגַּדְתִּי",
            },
            {
                "infinitive": "הִגִּיד",
                "meaning": "to tell",
                "person": "3rd person masculine singular",
                "tense": "yiqtol (imperfect)",
                "answer": "יַגִּיד",
            },
            {
                "infinitive": "הִגִּיד",
                "meaning": "to tell",
                "person": "1st person singular",
                "tense": "yiqtol (imperfect)",
                "answer": "אַגִּיד",
            },
        ]
        conj = rng.choice(hebrew_conjugations)
        return ConjugationTask(
            verb_infinitive=conj["infinitive"],
            verb_meaning=conj["meaning"],
            person=conj["person"],
            tense=conj["tense"],
            answer=conj["answer"],
        )

    # Sanskrit conjugations
    if language == "san":
        sanskrit_conjugations = [
            # First class (bhū-gaṇa): भू (bhū - to be, become)
            {
                "infinitive": "भू",
                "meaning": "to be",
                "person": "3rd person singular",
                "tense": "present",
                "answer": "भवति",
            },
            {
                "infinitive": "भू",
                "meaning": "to be",
                "person": "3rd person dual",
                "tense": "present",
                "answer": "भवतः",
            },
            {
                "infinitive": "भू",
                "meaning": "to be",
                "person": "3rd person plural",
                "tense": "present",
                "answer": "भवन्ति",
            },
            {
                "infinitive": "भू",
                "meaning": "to be",
                "person": "1st person singular",
                "tense": "present",
                "answer": "भवामि",
            },
            {
                "infinitive": "भू",
                "meaning": "to be",
                "person": "2nd person singular",
                "tense": "present",
                "answer": "भवसि",
            },
            {
                "infinitive": "भू",
                "meaning": "to be",
                "person": "3rd person singular",
                "tense": "imperfect",
                "answer": "अभवत्",
            },
            {
                "infinitive": "भू",
                "meaning": "to be",
                "person": "3rd person plural",
                "tense": "imperfect",
                "answer": "अभवन्",
            },
            # Fourth class (div-gaṇa): दिव् (div - to shine, play)
            {
                "infinitive": "दिव्",
                "meaning": "to shine",
                "person": "3rd person singular",
                "tense": "present",
                "answer": "दीव्यति",
            },
            {
                "infinitive": "दिव्",
                "meaning": "to shine",
                "person": "3rd person plural",
                "tense": "present",
                "answer": "दीव्यन्ति",
            },
            {
                "infinitive": "दिव्",
                "meaning": "to shine",
                "person": "1st person singular",
                "tense": "present",
                "answer": "दीव्यामि",
            },
            # Sixth class (tud-gaṇa): तुद् (tud - to strike)
            {
                "infinitive": "तुद्",
                "meaning": "to strike",
                "person": "3rd person singular",
                "tense": "present",
                "answer": "तुदति",
            },
            {
                "infinitive": "तुद्",
                "meaning": "to strike",
                "person": "3rd person plural",
                "tense": "present",
                "answer": "तुदन्ति",
            },
            {
                "infinitive": "तुद्",
                "meaning": "to strike",
                "person": "1st person singular",
                "tense": "present",
                "answer": "तुदामि",
            },
            # गम् (gam - to go)
            {
                "infinitive": "गम्",
                "meaning": "to go",
                "person": "3rd person singular",
                "tense": "present",
                "answer": "गच्छति",
            },
            {
                "infinitive": "गम्",
                "meaning": "to go",
                "person": "3rd person plural",
                "tense": "present",
                "answer": "गच्छन्ति",
            },
            {
                "infinitive": "गम्",
                "meaning": "to go",
                "person": "1st person singular",
                "tense": "present",
                "answer": "गच्छामि",
            },
            {
                "infinitive": "गम्",
                "meaning": "to go",
                "person": "2nd person singular",
                "tense": "present",
                "answer": "गच्छसि",
            },
            # पठ् (paṭh - to read)
            {
                "infinitive": "पठ्",
                "meaning": "to read",
                "person": "3rd person singular",
                "tense": "present",
                "answer": "पठति",
            },
            {
                "infinitive": "पठ्",
                "meaning": "to read",
                "person": "3rd person plural",
                "tense": "present",
                "answer": "पठन्ति",
            },
            {
                "infinitive": "पठ्",
                "meaning": "to read",
                "person": "1st person singular",
                "tense": "present",
                "answer": "पठामि",
            },
            # लिख् (likh - to write)
            {
                "infinitive": "लिख्",
                "meaning": "to write",
                "person": "3rd person singular",
                "tense": "present",
                "answer": "लिखति",
            },
            {
                "infinitive": "लिख्",
                "meaning": "to write",
                "person": "3rd person plural",
                "tense": "present",
                "answer": "लिखन्ति",
            },
            {
                "infinitive": "लिख्",
                "meaning": "to write",
                "person": "1st person singular",
                "tense": "present",
                "answer": "लिखामि",
            },
        ]
        conj = rng.choice(sanskrit_conjugations)
        return ConjugationTask(
            verb_infinitive=conj["infinitive"],
            verb_meaning=conj["meaning"],
            person=conj["person"],
            tense=conj["tense"],
            answer=conj["answer"],
        )

    # For any other unsupported languages, use placeholder
    if language and not language.startswith("grc"):
        return ConjugationTask(
            verb_infinitive="placeholder",
            verb_meaning="Coming soon",
            tense="present",
            person="1st person singular",
            answer="placeholder",
        )

    # Greek conjugations (original)
    conjugations = [
        {
            "infinitive": "λύω",
            "meaning": "to loosen",
            "person": "1st person singular",
            "tense": "present",
            "answer": "λύω",
        },
        {
            "infinitive": "λύω",
            "meaning": "to loosen",
            "person": "2nd person singular",
            "tense": "present",
            "answer": "λύεις",
        },
        {
            "infinitive": "λύω",
            "meaning": "to loosen",
            "person": "3rd person singular",
            "tense": "present",
            "answer": "λύει",
        },
        {
            "infinitive": "λύω",
            "meaning": "to loosen",
            "person": "1st person plural",
            "tense": "present",
            "answer": "λύομεν",
        },
        {
            "infinitive": "γράφω",
            "meaning": "to write",
            "person": "1st person singular",
            "tense": "present",
            "answer": "γράφω",
        },
        {
            "infinitive": "γράφω",
            "meaning": "to write",
            "person": "3rd person singular",
            "tense": "present",
            "answer": "γράφει",
        },
        {
            "infinitive": "γράφω",
            "meaning": "to write",
            "person": "3rd person plural",
            "tense": "present",
            "answer": "γράφουσι(ν)",
        },
        {
            "infinitive": "λέγω",
            "meaning": "to say",
            "person": "1st person singular",
            "tense": "present",
            "answer": "λέγω",
        },
        {
            "infinitive": "λέγω",
            "meaning": "to say",
            "person": "2nd person singular",
            "tense": "present",
            "answer": "λέγεις",
        },
        {
            "infinitive": "λέγω",
            "meaning": "to say",
            "person": "3rd person plural",
            "tense": "present",
            "answer": "λέγουσι(ν)",
        },
        {
            "infinitive": "φέρω",
            "meaning": "to carry",
            "person": "1st person singular",
            "tense": "present",
            "answer": "φέρω",
        },
        {
            "infinitive": "φέρω",
            "meaning": "to carry",
            "person": "3rd person singular",
            "tense": "present",
            "answer": "φέρει",
        },
        {
            "infinitive": "ἔχω",
            "meaning": "to have",
            "person": "1st person singular",
            "tense": "present",
            "answer": "ἔχω",
        },
        {
            "infinitive": "ἔχω",
            "meaning": "to have",
            "person": "3rd person singular",
            "tense": "present",
            "answer": "ἔχει",
        },
        # Aorist tense conjugations
        {
            "infinitive": "λύω",
            "meaning": "to loosen",
            "person": "1st person singular",
            "tense": "aorist",
            "answer": "ἔλυσα",
        },
        {
            "infinitive": "λύω",
            "meaning": "to loosen",
            "person": "2nd person singular",
            "tense": "aorist",
            "answer": "ἔλυσας",
        },
        {
            "infinitive": "λύω",
            "meaning": "to loosen",
            "person": "3rd person singular",
            "tense": "aorist",
            "answer": "ἔλυσε(ν)",
        },
        {
            "infinitive": "γράφω",
            "meaning": "to write",
            "person": "1st person singular",
            "tense": "aorist",
            "answer": "ἔγραψα",
        },
        {
            "infinitive": "γράφω",
            "meaning": "to write",
            "person": "3rd person singular",
            "tense": "aorist",
            "answer": "ἔγραψε(ν)",
        },
        {
            "infinitive": "λέγω",
            "meaning": "to say",
            "person": "1st person singular",
            "tense": "aorist",
            "answer": "εἶπον",
        },
        {
            "infinitive": "λέγω",
            "meaning": "to say",
            "person": "3rd person singular",
            "tense": "aorist",
            "answer": "εἶπε(ν)",
        },
        # Future tense conjugations
        {
            "infinitive": "λύω",
            "meaning": "to loosen",
            "person": "1st person singular",
            "tense": "future",
            "answer": "λύσω",
        },
        {
            "infinitive": "λύω",
            "meaning": "to loosen",
            "person": "3rd person singular",
            "tense": "future",
            "answer": "λύσει",
        },
        {
            "infinitive": "γράφω",
            "meaning": "to write",
            "person": "1st person singular",
            "tense": "future",
            "answer": "γράψω",
        },
        {
            "infinitive": "γράφω",
            "meaning": "to write",
            "person": "3rd person plural",
            "tense": "future",
            "answer": "γράψουσι(ν)",
        },
        {
            "infinitive": "φέρω",
            "meaning": "to carry",
            "person": "1st person singular",
            "tense": "future",
            "answer": "οἴσω",
        },
        {
            "infinitive": "λέγω",
            "meaning": "to say",
            "person": "1st person singular",
            "tense": "future",
            "answer": "ἐρῶ",
        },
        # Imperfect tense conjugations
        {
            "infinitive": "λύω",
            "meaning": "to loosen",
            "person": "1st person singular",
            "tense": "imperfect",
            "answer": "ἔλυον",
        },
        {
            "infinitive": "λύω",
            "meaning": "to loosen",
            "person": "2nd person singular",
            "tense": "imperfect",
            "answer": "ἔλυες",
        },
        {
            "infinitive": "λύω",
            "meaning": "to loosen",
            "person": "3rd person singular",
            "tense": "imperfect",
            "answer": "ἔλυε(ν)",
        },
        {
            "infinitive": "γράφω",
            "meaning": "to write",
            "person": "1st person singular",
            "tense": "imperfect",
            "answer": "ἔγραφον",
        },
        {
            "infinitive": "γράφω",
            "meaning": "to write",
            "person": "3rd person plural",
            "tense": "imperfect",
            "answer": "ἔγραφον",
        },
        {
            "infinitive": "ἔχω",
            "meaning": "to have",
            "person": "1st person singular",
            "tense": "imperfect",
            "answer": "εἶχον",
        },
        # Perfect tense conjugations
        {
            "infinitive": "λύω",
            "meaning": "to loosen",
            "person": "1st person singular",
            "tense": "perfect",
            "answer": "λέλυκα",
        },
        {
            "infinitive": "λύω",
            "meaning": "to loosen",
            "person": "3rd person singular",
            "tense": "perfect",
            "answer": "λέλυκε(ν)",
        },
        {
            "infinitive": "γράφω",
            "meaning": "to write",
            "person": "1st person singular",
            "tense": "perfect",
            "answer": "γέγραφα",
        },
        {
            "infinitive": "γράφω",
            "meaning": "to write",
            "person": "3rd person plural",
            "tense": "perfect",
            "answer": "γεγράφασι(ν)",
        },
        {
            "infinitive": "λέγω",
            "meaning": "to say",
            "person": "1st person singular",
            "tense": "perfect",
            "answer": "εἴρηκα",
        },
        {
            "infinitive": "ἔχω",
            "meaning": "to have",
            "person": "1st person singular",
            "tense": "perfect",
            "answer": "ἔσχηκα",
        },
    ]

    conj = rng.choice(conjugations)
    return ConjugationTask(
        verb_infinitive=conj["infinitive"],
        verb_meaning=conj["meaning"],
        person=conj["person"],
        tense=conj["tense"],
        answer=conj["answer"],
    )


def _build_declension_task(language: str, context: LessonContext, rng: random.Random) -> DeclensionTask:
    """Decline a noun or adjective"""
    # Latin declensions
    if language == "lat":
        latin_declensions = [
            # First declension: rosa (f)
            {"word": "rosa", "meaning": "rose", "case": "nominative", "number": "singular", "answer": "rosa"},
            {"word": "rosa", "meaning": "rose", "case": "genitive", "number": "singular", "answer": "rosae"},
            {"word": "rosa", "meaning": "rose", "case": "dative", "number": "singular", "answer": "rosae"},
            {
                "word": "rosa",
                "meaning": "rose",
                "case": "accusative",
                "number": "singular",
                "answer": "rosam",
            },
            {"word": "rosa", "meaning": "rose", "case": "ablative", "number": "singular", "answer": "rosa"},
            {"word": "rosa", "meaning": "rose", "case": "vocative", "number": "singular", "answer": "rosa"},
            {"word": "rosa", "meaning": "rose", "case": "nominative", "number": "plural", "answer": "rosae"},
            {"word": "rosa", "meaning": "rose", "case": "genitive", "number": "plural", "answer": "rosarum"},
            {"word": "rosa", "meaning": "rose", "case": "accusative", "number": "plural", "answer": "rosas"},
            # First declension: puella (f)
            {
                "word": "puella",
                "meaning": "girl",
                "case": "nominative",
                "number": "singular",
                "answer": "puella",
            },
            {
                "word": "puella",
                "meaning": "girl",
                "case": "genitive",
                "number": "singular",
                "answer": "puellae",
            },
            {
                "word": "puella",
                "meaning": "girl",
                "case": "dative",
                "number": "singular",
                "answer": "puellae",
            },
            {
                "word": "puella",
                "meaning": "girl",
                "case": "accusative",
                "number": "singular",
                "answer": "puellam",
            },
            {
                "word": "puella",
                "meaning": "girl",
                "case": "ablative",
                "number": "singular",
                "answer": "puella",
            },
            {
                "word": "puella",
                "meaning": "girl",
                "case": "nominative",
                "number": "plural",
                "answer": "puellae",
            },
            {
                "word": "puella",
                "meaning": "girl",
                "case": "genitive",
                "number": "plural",
                "answer": "puellarum",
            },
            # Second declension: servus (m)
            {
                "word": "servus",
                "meaning": "slave/servant",
                "case": "nominative",
                "number": "singular",
                "answer": "servus",
            },
            {
                "word": "servus",
                "meaning": "slave/servant",
                "case": "genitive",
                "number": "singular",
                "answer": "servi",
            },
            {
                "word": "servus",
                "meaning": "slave/servant",
                "case": "dative",
                "number": "singular",
                "answer": "servo",
            },
            {
                "word": "servus",
                "meaning": "slave/servant",
                "case": "accusative",
                "number": "singular",
                "answer": "servum",
            },
            {
                "word": "servus",
                "meaning": "slave/servant",
                "case": "ablative",
                "number": "singular",
                "answer": "servo",
            },
            {
                "word": "servus",
                "meaning": "slave/servant",
                "case": "vocative",
                "number": "singular",
                "answer": "serve",
            },
            {
                "word": "servus",
                "meaning": "slave/servant",
                "case": "nominative",
                "number": "plural",
                "answer": "servi",
            },
            {
                "word": "servus",
                "meaning": "slave/servant",
                "case": "genitive",
                "number": "plural",
                "answer": "servorum",
            },
            {
                "word": "servus",
                "meaning": "slave/servant",
                "case": "accusative",
                "number": "plural",
                "answer": "servos",
            },
            # Second declension: bellum (n)
            {
                "word": "bellum",
                "meaning": "war",
                "case": "nominative",
                "number": "singular",
                "answer": "bellum",
            },
            {"word": "bellum", "meaning": "war", "case": "genitive", "number": "singular", "answer": "belli"},
            {"word": "bellum", "meaning": "war", "case": "dative", "number": "singular", "answer": "bello"},
            {
                "word": "bellum",
                "meaning": "war",
                "case": "accusative",
                "number": "singular",
                "answer": "bellum",
            },
            {"word": "bellum", "meaning": "war", "case": "ablative", "number": "singular", "answer": "bello"},
            {"word": "bellum", "meaning": "war", "case": "nominative", "number": "plural", "answer": "bella"},
            {
                "word": "bellum",
                "meaning": "war",
                "case": "genitive",
                "number": "plural",
                "answer": "bellorum",
            },
            {"word": "bellum", "meaning": "war", "case": "accusative", "number": "plural", "answer": "bella"},
        ]
        decl = rng.choice(latin_declensions)
        return DeclensionTask(
            word=decl["word"],
            word_meaning=decl["meaning"],
            case=decl["case"],
            number=decl["number"],
            answer=decl["answer"],
        )

    # Hebrew declensions (nouns with pronominal suffixes and construct states)
    if language == "hbo":
        hebrew_declensions = [
            # Absolute state vs construct state
            {
                "word": "מֶלֶךְ",
                "meaning": "king",
                "case": "absolute state",
                "number": "singular",
                "answer": "מֶלֶךְ",
            },
            {
                "word": "מֶלֶךְ",
                "meaning": "king",
                "case": "construct state",
                "number": "singular",
                "answer": "מֶלֶךְ",
            },
            {
                "word": "מֶלֶךְ",
                "meaning": "king",
                "case": "absolute state",
                "number": "plural",
                "answer": "מְלָכִים",
            },
            {
                "word": "מֶלֶךְ",
                "meaning": "king",
                "case": "construct state",
                "number": "plural",
                "answer": "מַלְכֵי",
            },
            # Pronominal suffixes on מֶלֶךְ (king)
            {
                "word": "מֶלֶךְ",
                "meaning": "king",
                "case": "with 1st sing. suffix",
                "number": "singular",
                "answer": "מַלְכִּי",
            },
            {
                "word": "מֶלֶךְ",
                "meaning": "king",
                "case": "with 2nd masc. sing. suffix",
                "number": "singular",
                "answer": "מַלְכְּךָ",
            },
            {
                "word": "מֶלֶךְ",
                "meaning": "king",
                "case": "with 3rd masc. sing. suffix",
                "number": "singular",
                "answer": "מַלְכּוֹ",
            },
            # דָּבָר (word, thing)
            {
                "word": "דָּבָר",
                "meaning": "word",
                "case": "absolute state",
                "number": "singular",
                "answer": "דָּבָר",
            },
            {
                "word": "דָּבָר",
                "meaning": "word",
                "case": "construct state",
                "number": "singular",
                "answer": "דְּבַר",
            },
            {
                "word": "דָּבָר",
                "meaning": "word",
                "case": "absolute state",
                "number": "plural",
                "answer": "דְּבָרִים",
            },
            {
                "word": "דָּבָר",
                "meaning": "word",
                "case": "construct state",
                "number": "plural",
                "answer": "דִּבְרֵי",
            },
            {
                "word": "דָּבָר",
                "meaning": "word",
                "case": "with 1st sing. suffix",
                "number": "singular",
                "answer": "דְּבָרִי",
            },
            {
                "word": "דָּבָר",
                "meaning": "word",
                "case": "with 3rd masc. sing. suffix",
                "number": "singular",
                "answer": "דְּבָרוֹ",
            },
            # בַּיִת (house)
            {
                "word": "בַּיִת",
                "meaning": "house",
                "case": "absolute state",
                "number": "singular",
                "answer": "בַּיִת",
            },
            {
                "word": "בַּיִת",
                "meaning": "house",
                "case": "construct state",
                "number": "singular",
                "answer": "בֵּית",
            },
            {
                "word": "בַּיִת",
                "meaning": "house",
                "case": "absolute state",
                "number": "plural",
                "answer": "בָּתִּים",
            },
            {
                "word": "בַּיִת",
                "meaning": "house",
                "case": "construct state",
                "number": "plural",
                "answer": "בָּתֵּי",
            },
            {
                "word": "בַּיִת",
                "meaning": "house",
                "case": "with 1st sing. suffix",
                "number": "singular",
                "answer": "בֵּיתִי",
            },
            # אִישׁ (man)
            {
                "word": "אִישׁ",
                "meaning": "man",
                "case": "absolute state",
                "number": "singular",
                "answer": "אִישׁ",
            },
            {
                "word": "אִישׁ",
                "meaning": "man",
                "case": "construct state",
                "number": "singular",
                "answer": "אִישׁ",
            },
            {
                "word": "אִישׁ",
                "meaning": "man",
                "case": "absolute state",
                "number": "plural",
                "answer": "אֲנָשִׁים",
            },
            {
                "word": "אִישׁ",
                "meaning": "man",
                "case": "construct state",
                "number": "plural",
                "answer": "אַנְשֵׁי",
            },
            # יָד (hand)
            {"word": "יָד", "meaning": "hand", "case": "absolute state", "number": "singular", "answer": "יָד"},
            {
                "word": "יָד",
                "meaning": "hand",
                "case": "construct state",
                "number": "singular",
                "answer": "יַד",
            },
            {"word": "יָד", "meaning": "hand", "case": "absolute state", "number": "dual", "answer": "יָדַיִם"},
            {"word": "יָד", "meaning": "hand", "case": "construct state", "number": "dual", "answer": "יְדֵי"},
        ]
        decl = rng.choice(hebrew_declensions)
        return DeclensionTask(
            word=decl["word"],
            word_meaning=decl["meaning"],
            case=decl["case"],
            number=decl["number"],
            answer=decl["answer"],
        )

    # Sanskrit declensions
    if language == "san":
        sanskrit_declensions = [
            # Masculine a-stem: देव (deva - god)
            {"word": "देव", "meaning": "god", "case": "nominative", "number": "singular", "answer": "देवः"},
            {"word": "देव", "meaning": "god", "case": "accusative", "number": "singular", "answer": "देवम्"},
            {"word": "देव", "meaning": "god", "case": "instrumental", "number": "singular", "answer": "देवेन"},
            {"word": "देव", "meaning": "god", "case": "dative", "number": "singular", "answer": "देवाय"},
            {"word": "देव", "meaning": "god", "case": "ablative", "number": "singular", "answer": "देवात्"},
            {"word": "देव", "meaning": "god", "case": "genitive", "number": "singular", "answer": "देवस्य"},
            {"word": "देव", "meaning": "god", "case": "locative", "number": "singular", "answer": "देवे"},
            {"word": "देव", "meaning": "god", "case": "vocative", "number": "singular", "answer": "देव"},
            {"word": "देव", "meaning": "god", "case": "nominative", "number": "dual", "answer": "देवौ"},
            {"word": "देव", "meaning": "god", "case": "nominative", "number": "plural", "answer": "देवाः"},
            {"word": "देव", "meaning": "god", "case": "accusative", "number": "plural", "answer": "देवान्"},
            # Neuter a-stem: फल (phala - fruit)
            {"word": "फल", "meaning": "fruit", "case": "nominative", "number": "singular", "answer": "फलम्"},
            {"word": "फल", "meaning": "fruit", "case": "accusative", "number": "singular", "answer": "फलम्"},
            {"word": "फल", "meaning": "fruit", "case": "instrumental", "number": "singular", "answer": "फलेन"},
            {"word": "फल", "meaning": "fruit", "case": "genitive", "number": "singular", "answer": "फलस्य"},
            {"word": "फल", "meaning": "fruit", "case": "nominative", "number": "plural", "answer": "फलानि"},
            # Feminine ā-stem: सेना (senā - army)
            {"word": "सेना", "meaning": "army", "case": "nominative", "number": "singular", "answer": "सेना"},
            {"word": "सेना", "meaning": "army", "case": "accusative", "number": "singular", "answer": "सेनाम्"},
            {
                "word": "सेना",
                "meaning": "army",
                "case": "instrumental",
                "number": "singular",
                "answer": "सेनया",
            },
            {"word": "सेना", "meaning": "army", "case": "genitive", "number": "singular", "answer": "सेनायाः"},
            {"word": "सेना", "meaning": "army", "case": "nominative", "number": "plural", "answer": "सेनाः"},
            # Masculine i-stem: अग्नि (agni - fire)
            {
                "word": "अग्नि",
                "meaning": "fire",
                "case": "nominative",
                "number": "singular",
                "answer": "अग्निः",
            },
            {
                "word": "अग्नि",
                "meaning": "fire",
                "case": "accusative",
                "number": "singular",
                "answer": "अग्निम्",
            },
            {
                "word": "अग्नि",
                "meaning": "fire",
                "case": "instrumental",
                "number": "singular",
                "answer": "अग्निना",
            },
            {"word": "अग्नि", "meaning": "fire", "case": "genitive", "number": "singular", "answer": "अग्नेः"},
            {"word": "अग्नि", "meaning": "fire", "case": "nominative", "number": "plural", "answer": "अग्नयः"},
        ]
        decl = rng.choice(sanskrit_declensions)
        return DeclensionTask(
            word=decl["word"],
            word_meaning=decl["meaning"],
            case=decl["case"],
            number=decl["number"],
            answer=decl["answer"],
        )

    # For any other unsupported languages, use placeholder
    if language and not language.startswith("grc"):
        return DeclensionTask(
            word="placeholder",
            word_meaning="Coming soon",
            case="nominative",
            number="singular",
            answer="placeholder",
        )

    # Greek declensions (original)
    declensions = [
        {
            "word": "ἄνθρωπος",
            "meaning": "human",
            "case": "nominative",
            "number": "singular",
            "answer": "ὁ ἄνθρωπος",
        },
        {
            "word": "ἄνθρωπος",
            "meaning": "human",
            "case": "genitive",
            "number": "singular",
            "answer": "τοῦ ἀνθρώπου",
        },
        {
            "word": "ἄνθρωπος",
            "meaning": "human",
            "case": "accusative",
            "number": "singular",
            "answer": "τὸν ἄνθρωπον",
        },
        {
            "word": "ἄνθρωπος",
            "meaning": "human",
            "case": "nominative",
            "number": "plural",
            "answer": "οἱ ἄνθρωποι",
        },
        {"word": "λόγος", "meaning": "word", "case": "nominative", "number": "singular", "answer": "ὁ λόγος"},
        {"word": "λόγος", "meaning": "word", "case": "genitive", "number": "singular", "answer": "τοῦ λόγου"},
        {
            "word": "λόγος",
            "meaning": "word",
            "case": "accusative",
            "number": "singular",
            "answer": "τὸν λόγον",
        },
        {"word": "γυνή", "meaning": "woman", "case": "nominative", "number": "singular", "answer": "ἡ γυνή"},
        {
            "word": "γυνή",
            "meaning": "woman",
            "case": "genitive",
            "number": "singular",
            "answer": "τῆς γυναικός",
        },
        {"word": "πόλις", "meaning": "city", "case": "nominative", "number": "singular", "answer": "ἡ πόλις"},
        {
            "word": "πόλις",
            "meaning": "city",
            "case": "genitive",
            "number": "singular",
            "answer": "τῆς πόλεως",
        },
        {
            "word": "πόλις",
            "meaning": "city",
            "case": "accusative",
            "number": "singular",
            "answer": "τὴν πόλιν",
        },
        # Vocative case
        {
            "word": "ἄνθρωπος",
            "meaning": "human",
            "case": "vocative",
            "number": "singular",
            "answer": "ὦ ἄνθρωπε",
        },
        {
            "word": "λόγος",
            "meaning": "word",
            "case": "vocative",
            "number": "singular",
            "answer": "ὦ λόγε",
        },
        {
            "word": "υἱός",
            "meaning": "son",
            "case": "vocative",
            "number": "singular",
            "answer": "ὦ υἱέ",
        },
        {
            "word": "θεός",
            "meaning": "god",
            "case": "vocative",
            "number": "singular",
            "answer": "ὦ θεέ",
        },
        {
            "word": "φίλος",
            "meaning": "friend",
            "case": "vocative",
            "number": "singular",
            "answer": "ὦ φίλε",
        },
        {
            "word": "δεσπότης",
            "meaning": "master",
            "case": "vocative",
            "number": "singular",
            "answer": "ὦ δέσποτα",
        },
        # Dual number
        {
            "word": "ἄνθρωπος",
            "meaning": "human",
            "case": "nominative",
            "number": "dual",
            "answer": "τὼ ἀνθρώπω",
        },
        {
            "word": "ἄνθρωπος",
            "meaning": "human",
            "case": "genitive",
            "number": "dual",
            "answer": "τοῖν ἀνθρώποιν",
        },
        {
            "word": "ὀφθαλμός",
            "meaning": "eye",
            "case": "nominative",
            "number": "dual",
            "answer": "τὼ ὀφθαλμώ",
        },
        {
            "word": "χείρ",
            "meaning": "hand",
            "case": "nominative",
            "number": "dual",
            "answer": "τὼ χεῖρε",
        },
        {
            "word": "πούς",
            "meaning": "foot",
            "case": "nominative",
            "number": "dual",
            "answer": "τὼ πόδε",
        },
        {
            "word": "λόγος",
            "meaning": "word",
            "case": "accusative",
            "number": "dual",
            "answer": "τὼ λόγω",
        },
    ]

    decl = rng.choice(declensions)
    return DeclensionTask(
        word=decl["word"],
        word_meaning=decl["meaning"],
        case=decl["case"],
        number=decl["number"],
        answer=decl["answer"],
    )


def _build_synonym_task(language: str, context: LessonContext, rng: random.Random) -> SynonymTask:
    # Latin synonyms
    if language == "lat":
        synonyms = [
            {
                "word": "magnus",
                "task_type": "synonym",
                "options": ["great", "large", "big", "small"],
                "answer": "great",
            },
            {
                "word": "bonus",
                "task_type": "synonym",
                "options": ["good", "bad", "evil", "neutral"],
                "answer": "good",
            },
        ]
        s = rng.choice(synonyms)
        return SynonymTask(word=s["word"], task_type=s["task_type"], options=s["options"], answer=s["answer"])

    # Hebrew synonyms
    if language == "hbo":
        synonyms = [
            {
                "word": "טוֹב",
                "task_type": "synonym",
                "options": ["good", "bad", "evil", "neutral"],
                "answer": "good",
            },
            {
                "word": "גָּדוֹל",
                "task_type": "synonym",
                "options": ["great", "small", "medium", "tiny"],
                "answer": "great",
            },
        ]
        s = rng.choice(synonyms)
        return SynonymTask(word=s["word"], task_type=s["task_type"], options=s["options"], answer=s["answer"])

    # Sanskrit synonyms
    if language == "san":
        synonyms = [
            {
                "word": "महान्",
                "task_type": "synonym",
                "options": ["great", "small", "medium", "tiny"],
                "answer": "great",
            },
            {
                "word": "शुभ",
                "task_type": "synonym",
                "options": ["good", "bad", "evil", "neutral"],
                "answer": "good",
            },
        ]
        s = rng.choice(synonyms)
        return SynonymTask(word=s["word"], task_type=s["task_type"], options=s["options"], answer=s["answer"])

    # For other non-Greek languages
    if language and not language.startswith("grc"):
        return SynonymTask(
            prompt=f"Find synonym (Coming soon for {language})",
            options=["placeholder"],
            answer="placeholder",
        )
    """Match synonyms or identify antonyms"""
    synonym_tasks = [
        {
            "word": "ἀγαθός",
            "type": "synonym",
            "options": ["καλός", "κακός", "μέγας", "μικρός"],
            "answer": "καλός",
        },
        {
            "word": "κακός",
            "type": "synonym",
            "options": ["πονηρός", "ἀγαθός", "καλός", "δίκαιος"],
            "answer": "πονηρός",
        },
        {
            "word": "μέγας",
            "type": "antonym",
            "options": ["μικρός", "πολύς", "μακρός", "ὑψηλός"],
            "answer": "μικρός",
        },
        {
            "word": "καλός",
            "type": "antonym",
            "options": ["αἰσχρός", "ἀγαθός", "δίκαιος", "σοφός"],
            "answer": "αἰσχρός",
        },
        {
            "word": "σοφός",
            "type": "synonym",
            "options": ["φρόνιμος", "ἀφρων", "κακός", "μωρός"],
            "answer": "φρόνιμος",
        },
        {
            "word": "φιλέω",
            "type": "antonym",
            "options": ["μισέω", "ἀγαπάω", "στέργω", "ἐράω"],
            "answer": "μισέω",
        },
    ]

    task = rng.choice(synonym_tasks)
    return SynonymTask(
        word=task["word"],
        task_type=task["type"],
        options=task["options"],
        answer=task["answer"],
    )


def _build_contextmatch_task(language: str, context: LessonContext, rng: random.Random) -> ContextMatchTask:
    """Choose the word that best fits the context"""
    # Latin context match exercises
    if language == "lat":
        latin_context_tasks = [
            {
                "sentence": "Poeta ___ scribit.",
                "hint": "What does a poet write?",
                "options": ["librum", "gladium", "aquam", "viam"],
                "answer": "librum",
            },
            {
                "sentence": "Milites in ___ pugnant.",
                "hint": "Where do soldiers fight?",
                "options": ["bello", "rosa", "villa", "templo"],
                "answer": "bello",
            },
            {
                "sentence": "Puella ___ portat.",
                "hint": "What does a girl carry?",
                "options": ["rosam", "gladium", "scutum", "equum"],
                "answer": "rosam",
            },
            {
                "sentence": "Magister ___ docet.",
                "hint": "Who does a teacher teach?",
                "options": ["discipulos", "equos", "rosas", "templa"],
                "answer": "discipulos",
            },
            {
                "sentence": "___ in caelo lucet.",
                "hint": "What shines in the sky?",
                "options": ["Luna", "Terra", "Porta", "Via"],
                "answer": "Luna",
            },
        ]
        task = rng.choice(latin_context_tasks)
        return ContextMatchTask(
            sentence=task["sentence"],
            hint=task["hint"],
            options=task["options"],
            answer=task["answer"],
        )

    # Hebrew context match
    if language == "hbo":
        contexts = [
            {
                "sentence": "הָאִישׁ ___ לַבַּיִת",
                "hint": "How does the man move?",
                "options": ["הוֹלֵךְ", "יוֹשֵׁב", "כּוֹתֵב", "קוֹרֵא"],
                "answer": "הוֹלֵךְ",
            },
        ]
        task = rng.choice(contexts)
        return ContextMatchTask(
            sentence=task["sentence"], hint=task["hint"], options=task["options"], answer=task["answer"]
        )

    # Sanskrit context match
    if language == "san":
        contexts = [
            {
                "sentence": "बालः ___ गच्छति",
                "hint": "Where does the boy go?",
                "options": ["गृहं", "जलं", "अग्निं", "वायुं"],
                "answer": "गृहं",
            },
        ]
        task = rng.choice(contexts)
        return ContextMatchTask(
            sentence=task["sentence"], hint=task["hint"], options=task["options"], answer=task["answer"]
        )

    # For other non-Greek, non-Latin languages
    if language and not language.startswith("grc"):
        return ContextMatchTask(
            sentence=f"___ (Coming soon for {language})",
            hint="Placeholder",
            options=["placeholder"],
            answer="placeholder",
        )

    # Greek context match exercises (original)
    context_tasks = [
        {
            "sentence": "Ὁ ___ γράφει βιβλίον.",
            "hint": "Who writes books?",
            "options": ["ποιητής", "στρατιώτης", "ἵππος", "λίθος"],
            "answer": "ποιητής",
        },
        {
            "sentence": "Οἱ ___ μάχονται ἐν τῇ πολέμῳ.",
            "hint": "Who fights in war?",
            "options": ["στρατιῶται", "διδάσκαλοι", "παῖδες", "ποιηταί"],
            "answer": "στρατιῶται",
        },
        {
            "sentence": "Ἡ ___ ἐστὶ μεγάλη καὶ καλή.",
            "hint": "What is large and beautiful?",
            "options": ["πόλις", "στρατιώτης", "ἄνθρωπος", "λόγος"],
            "answer": "πόλις",
        },
        {
            "sentence": "Οἱ ___ διδάσκουσι τοὺς μαθητάς.",
            "hint": "Who teaches students?",
            "options": ["διδάσκαλοι", "μαθηταί", "πολῖται", "δοῦλοι"],
            "answer": "διδάσκαλοι",
        },
        {
            "sentence": "Ὁ ___  πλεῖ ἐν τῇ θαλάσσῃ.",
            "hint": "What sails on the sea?",
            "options": ["ναῦς", "ἵππος", "οἶκος", "ἄνθρωπος"],
            "answer": "ναῦς",
        },
        {
            "sentence": "Ἡ ___ φέρει ὕδωρ.",
            "hint": "What carries water?",
            "options": ["ὑδρία", "βιβλίον", "ξίφος", "ἀσπίς"],
            "answer": "ὑδρία",
        },
        {
            "sentence": "Οἱ ___ ἄρχουσι τῆς πόλεως.",
            "hint": "Who rules the city?",
            "options": ["ἄρχοντες", "δοῦλοι", "ξένοι", "παῖδες"],
            "answer": "ἄρχοντες",
        },
        {
            "sentence": "Τὸ ___ ἐστι καλόν.",
            "hint": "What is beautiful? (neuter)",
            "options": ["ἔργον", "ἄνθρωπος", "γυνή", "πόλις"],
            "answer": "ἔργον",
        },
        {
            "sentence": "Ὁ ___ θύει τοῖς θεοῖς.",
            "hint": "Who sacrifices to the gods?",
            "options": ["ἱερεύς", "στρατιώτης", "ποιητής", "ναύτης"],
            "answer": "ἱερεύς",
        },
        {
            "sentence": "Αἱ ___ ᾄδουσι καλῶς.",
            "hint": "Who sings beautifully? (feminine plural)",
            "options": ["μοῦσαι", "ἄνδρες", "παῖδες", "θεοί"],
            "answer": "μοῦσαι",
        },
        {
            "sentence": "Ὁ ___ κρίνει τὴν δίκην.",
            "hint": "Who judges the case?",
            "options": ["κριτής", "ποιητής", "ῥήτωρ", "μάντις"],
            "answer": "κριτής",
        },
        {
            "sentence": "Ἡ ___ λάμπει ἐν τῇ νυκτί.",
            "hint": "What shines in the night?",
            "options": ["σελήνη", "ἡμέρα", "γῆ", "πόλις"],
            "answer": "σελήνη",
        },
        {
            "sentence": "Οἱ ___ σπείρουσι τὸν σῖτον.",
            "hint": "Who sow the grain?",
            "options": ["γεωργοί", "ναῦται", "ποιηταί", "δικασταί"],
            "answer": "γεωργοί",
        },
        {
            "sentence": "Τὸ ___ τρέχει ταχέως.",
            "hint": "What runs swiftly? (animal)",
            "options": ["ἵππος", "οἶκος", "βιβλίον", "ὕδωρ"],
            "answer": "ἵππος",
        },
        {
            "sentence": "Ἡ ___ ἰᾶται τοὺς ἀσθενεῖς.",
            "hint": "Who heals the sick? (feminine)",
            "options": ["ἰάτρισσα", "ποιήτρια", "ῥήτειρα", "μαθήτρια"],
            "answer": "ἰάτρισσα",
        },
        {
            "sentence": "Οἱ ___ πωλοῦσιν ἐν τῇ ἀγορᾷ.",
            "hint": "Who sell in the marketplace?",
            "options": ["ἔμποροι", "φιλόσοφοι", "στρατηγοί", "μαθηταί"],
            "answer": "ἔμποροι",
        },
        {
            "sentence": "Τὸ ___ φέρει καρπόν.",
            "hint": "What bears fruit? (neuter)",
            "options": ["δένδρον", "ξίφος", "κράνος", "ἅρμα"],
            "answer": "δένδρον",
        },
        {
            "sentence": "Ὁ ___ κυβερνᾷ τὴν ναῦν.",
            "hint": "Who steers the ship?",
            "options": ["κυβερνήτης", "γεωργός", "ἱερεύς", "ποιμήν"],
            "answer": "κυβερνήτης",
        },
        {
            "sentence": "Αἱ ___ χορεύουσιν ἐν τῇ ἑορτῇ.",
            "hint": "Who dance at the festival? (young women)",
            "options": ["παρθένοι", "γέροντες", "στρατιῶται", "διδάσκαλοι"],
            "answer": "παρθένοι",
        },
        {
            "sentence": "Τὰ ___ πίπτει ἀπὸ τοῦ δένδρου.",
            "hint": "What falls from the tree? (plural neuter)",
            "options": ["φύλλα", "ναῦς", "πόλις", "ἄνθρωπος"],
            "answer": "φύλλα",
        },
        {
            "sentence": "Ὁ ___ ἄγει τὰ πρόβατα.",
            "hint": "Who leads the sheep?",
            "options": ["ποιμήν", "ναύτης", "ὁπλίτης", "ποιητής"],
            "answer": "ποιμήν",
        },
        {
            "sentence": "Ἡ ___ ἔχει πολλὰ βιβλία.",
            "hint": "What has many books?",
            "options": ["βιβλιοθήκη", "κρήνη", "ὁδός", "θύρα"],
            "answer": "βιβλιοθήκη",
        },
        {
            "sentence": "Οἱ ___ προσεύχονται ἐν τῷ ἱερῷ.",
            "hint": "Who pray in the temple?",
            "options": ["ἱερεῖς", "ἔμποροι", "ναῦται", "γεωργοί"],
            "answer": "ἱερεῖς",
        },
        {
            "sentence": "Τὸ ___ φωτίζει τὴν ἡμέραν.",
            "hint": "What illuminates the day?",
            "options": ["ἥλιος", "σελήνη", "ἀστήρ", "νύξ"],
            "answer": "ἥλιος",
        },
        {
            "sentence": "Ἡ ___ φυλάττει τὴν πόλιν.",
            "hint": "What guards the city? (fortification)",
            "options": ["τεῖχος", "ἀγορά", "οἰκία", "θύρα"],
            "answer": "τεῖχος",
        },
        {
            "sentence": "Οἱ ___ ἀγωνίζονται ἐν τῷ σταδίῳ.",
            "hint": "Who compete in the stadium?",
            "options": ["ἀθληταί", "διδάσκαλοι", "ποιηταί", "ῥήτορες"],
            "answer": "ἀθληταί",
        },
        {
            "sentence": "Τὸ ___ ῥεῖ εἰς τὴν θάλασσαν.",
            "hint": "What flows into the sea?",
            "options": ["ποταμός", "ὄρος", "δένδρον", "τεῖχος"],
            "answer": "ποταμός",
        },
        {
            "sentence": "Ὁ ___ λέγει ψευδῆ.",
            "hint": "Who tells lies?",
            "options": ["ψεύστης", "φιλόσοφος", "ἀλήθης", "σοφός"],
            "answer": "ψεύστης",
        },
        {
            "sentence": "Αἱ ___ τίκτουσι τέκνα.",
            "hint": "Who give birth to children?",
            "options": ["μητέρες", "πατέρες", "παῖδες", "γέροντες"],
            "answer": "μητέρες",
        },
        {
            "sentence": "Τὸ ___ ὑψηλόν ἐστιν.",
            "hint": "What is high? (geographical)",
            "options": ["ὄρος", "πεδίον", "θάλασσα", "λίμνη"],
            "answer": "ὄρος",
        },
    ]

    task = rng.choice(context_tasks)
    return ContextMatchTask(
        sentence=task["sentence"],
        context_hint=task.get("hint"),
        options=task["options"],
        answer=task["answer"],
    )


def _build_reorder_task(language: str, context: LessonContext, rng: random.Random) -> ReorderTask:
    """Reorder sentence fragments into coherent text"""
    # Latin reorder exercises
    if language == "lat":
        latin_reorder_tasks = [
            {
                "correct_sentence": ["Poeta", "librum", "scribit"],
                "translation": "The poet writes a book.",
            },
            {
                "correct_sentence": ["Puella", "rosam", "amat"],
                "translation": "The girl loves the rose.",
            },
            {
                "correct_sentence": ["Milites", "in bello", "pugnant"],
                "translation": "The soldiers fight in war.",
            },
            {
                "correct_sentence": ["Magister", "discipulos", "docet"],
                "translation": "The teacher teaches the students.",
            },
            {
                "correct_sentence": ["Agricola", "in agro", "laborat"],
                "translation": "The farmer works in the field.",
            },
        ]
        task = rng.choice(latin_reorder_tasks)
        correct_sentence = task["correct_sentence"]
        shuffled = list(correct_sentence)
        rng.shuffle(shuffled)
        # Find correct order indices
        correct_order = [shuffled.index(word) for word in correct_sentence]
        return ReorderTask(
            fragments=shuffled,
            correct_order=correct_order,
            translation=task["translation"],
        )

    # Hebrew reorder
    if language == "hbo":
        reorder_tasks = [
            {"correct_sentence": ["הָאִישׁ", "הוֹלֵךְ"], "translation": "The man walks"},
        ]
        task = rng.choice(reorder_tasks)
        correct_sentence = task["correct_sentence"]
        shuffled = list(correct_sentence)
        rng.shuffle(shuffled)
        correct_order = [shuffled.index(word) for word in correct_sentence]
        return ReorderTask(fragments=shuffled, correct_order=correct_order, translation=task["translation"])

    # Sanskrit reorder
    if language == "san":
        reorder_tasks = [
            {"correct_sentence": ["बालः", "गच्छति"], "translation": "The boy goes"},
        ]
        task = rng.choice(reorder_tasks)
        correct_sentence = task["correct_sentence"]
        shuffled = list(correct_sentence)
        rng.shuffle(shuffled)
        correct_order = [shuffled.index(word) for word in correct_sentence]
        return ReorderTask(fragments=shuffled, correct_order=correct_order, translation=task["translation"])

    # For other non-Greek, non-Latin languages
    if language and not language.startswith("grc"):
        return ReorderTask(
            fragments=["Coming", "soon", language],
            correct_order=[0, 1, 2],
            translation="Placeholder",
        )

    # Greek reorder exercises (original)
    reorder_tasks = [
        {
            "correct_sentence": ["ὁ ποιητής", "γράφει", "βιβλίον"],
            "translation": "The poet writes a book.",
        },
        {
            "correct_sentence": ["οἱ στρατιῶται", "μάχονται", "ἐν τῇ πολέμῳ"],
            "translation": "The soldiers fight in the war.",
        },
        {
            "correct_sentence": ["ἡ πόλις", "ἐστιν", "καλή"],
            "translation": "The city is beautiful.",
        },
        {
            "correct_sentence": ["οἱ θεοί", "ἄρχουσι", "τοῦ κόσμου"],
            "translation": "The gods rule the world.",
        },
        {
            "correct_sentence": ["ὁ διδάσκαλος", "διδάσκει", "τοὺς μαθητάς"],
            "translation": "The teacher teaches the students.",
        },
        {
            "correct_sentence": ["ἡ γυνή", "φέρει", "τὸ ὕδωρ"],
            "translation": "The woman carries the water.",
        },
        {
            "correct_sentence": ["τὰ τέκνα", "παίζουσιν", "ἐν τῇ ἀγορᾷ"],
            "translation": "The children play in the marketplace.",
        },
        {
            "correct_sentence": ["ὁ ἥρως", "νικᾷ", "τοὺς πολεμίους"],
            "translation": "The hero defeats the enemies.",
        },
        {
            "correct_sentence": ["αἱ μοῦσαι", "ᾄδουσιν", "ᾠδὰς καλάς"],
            "translation": "The muses sing beautiful songs.",
        },
        {
            "correct_sentence": ["ὁ φιλόσοφος", "ζητεῖ", "τὴν ἀλήθειαν"],
            "translation": "The philosopher seeks the truth.",
        },
        {
            "correct_sentence": ["ὁ ῥήτωρ", "πείθει", "τὸν δῆμον"],
            "translation": "The orator persuades the people.",
        },
        {
            "correct_sentence": ["ὁ ναύτης", "πλεῖ", "ἐπὶ τὴν νῆσον"],
            "translation": "The sailor sails to the island.",
        },
        {
            "correct_sentence": ["ἡ μήτηρ", "ἀγαπᾷ", "τὰ τέκνα"],
            "translation": "The mother loves the children.",
        },
        {
            "correct_sentence": ["οἱ πολῖται", "ψηφίζονται", "ἐν τῇ ἐκκλησίᾳ"],
            "translation": "The citizens vote in the assembly.",
        },
        {
            "correct_sentence": ["ὁ βασιλεύς", "κελεύει", "τοὺς στρατιώτας"],
            "translation": "The king commands the soldiers.",
        },
        {
            "correct_sentence": ["ἡ θάλασσα", "κινεῖται", "ὑπὸ τοῦ ἀνέμου"],
            "translation": "The sea is moved by the wind.",
        },
        {
            "correct_sentence": ["οἱ ἀθληταί", "τρέχουσιν", "ἐν τῷ σταδίῳ"],
            "translation": "The athletes run in the stadium.",
        },
        {
            "correct_sentence": ["ὁ ἰατρός", "θεραπεύει", "τὸν ἀσθενῆ"],
            "translation": "The doctor heals the sick person.",
        },
        {
            "correct_sentence": ["αἱ παρθένοι", "χορεύουσιν", "ἐν τῇ ἑορτῇ"],
            "translation": "The maidens dance at the festival.",
        },
        {
            "correct_sentence": ["ὁ κριτής", "δικάζει", "τὴν δίκην"],
            "translation": "The judge judges the case.",
        },
        {
            "correct_sentence": ["οἱ ἔμποροι", "πωλοῦσιν", "τὰ χρήματα"],
            "translation": "The merchants sell the goods.",
        },
        {
            "correct_sentence": ["ἡ σελήνη", "φαίνεται", "ἐν τῷ οὐρανῷ"],
            "translation": "The moon appears in the sky.",
        },
        {
            "correct_sentence": ["οἱ γεωργοί", "σπείρουσιν", "τὸν σῖτον"],
            "translation": "The farmers sow the grain.",
        },
        {
            "correct_sentence": ["ὁ ἱερεύς", "θύει", "τοῖς θεοῖς"],
            "translation": "The priest sacrifices to the gods.",
        },
        {
            "correct_sentence": ["αἱ νύμφαι", "μένουσιν", "παρὰ τὴν κρήνην"],
            "translation": "The nymphs remain by the spring.",
        },
        {
            "correct_sentence": ["ὁ κυβερνήτης", "κυβερνᾷ", "τὴν ναῦν"],
            "translation": "The helmsman steers the ship.",
        },
        {
            "correct_sentence": ["οἱ μαθηταί", "μανθάνουσιν", "τὴν σοφίαν"],
            "translation": "The students learn wisdom.",
        },
        {
            "correct_sentence": ["ἡ ἄμπελος", "φέρει", "τοὺς σταφύλας"],
            "translation": "The vine bears the grapes.",
        },
        {
            "correct_sentence": ["οἱ δικασταί", "ἀκούουσιν", "τοῦ κατηγόρου"],
            "translation": "The jurors listen to the accuser.",
        },
        {
            "correct_sentence": ["ὁ ποιμήν", "βόσκει", "τὰ πρόβατα"],
            "translation": "The shepherd feeds the sheep.",
        },
    ]

    task = rng.choice(reorder_tasks)
    correct_sentence = task["correct_sentence"]

    # Create shuffled version
    indexed_fragments = list(enumerate(correct_sentence))
    rng.shuffle(indexed_fragments)

    shuffled_fragments = [frag for _, frag in indexed_fragments]

    # Build correct_order: for each position in the shuffled list,
    # what index should it have in the final order?
    # The user's reordering will produce indices [0,1,2,...]
    # We need to map those back to the correct sentence order
    position_map = {}  # maps original_idx -> shuffled_position
    for shuffled_pos, (original_idx, _) in enumerate(indexed_fragments):
        position_map[original_idx] = shuffled_pos

    correct_order = [position_map[i] for i in range(len(correct_sentence))]

    return ReorderTask(
        fragments=shuffled_fragments,
        correct_order=correct_order,
        translation=task["translation"],
    )


def _build_dictation_task(language: str, context: LessonContext, rng: random.Random) -> DictationTask:
    # Latin dictation
    if language == "lat":
        phrases = [{"text": "Amo te", "hint": "I love you"}, {"text": "Salve", "hint": "Hello"}]
        phrase = rng.choice(phrases)
        return DictationTask(audio_url=None, target_text=phrase["text"], hint=phrase.get("hint"))

    # Hebrew dictation
    if language == "hbo":
        phrases = [{"text": "שָׁלוֹם", "hint": "Peace"}]
        phrase = rng.choice(phrases)
        return DictationTask(audio_url=None, target_text=phrase["text"], hint=phrase.get("hint"))

    # Sanskrit dictation
    if language == "san":
        phrases = [{"text": "नमस्ते", "hint": "Greetings"}]
        phrase = rng.choice(phrases)
        return DictationTask(audio_url=None, target_text=phrase["text"], hint=phrase.get("hint"))

    # For other non-Greek languages
    if language and not language.startswith("grc"):
        return DictationTask(
            prompt=f"Dictation (Coming soon for {language})",
            answer="placeholder",
            audio_url=None,
        )
    """Write what you hear (spelling practice)"""
    dictation_phrases = [
        {"text": "Χαῖρε, φίλε.", "hint": "A greeting"},
        {"text": "Τί ὄνομά σου;", "hint": "Asking for a name"},
        {"text": "Καλῶς ἔχω.", "hint": "I am well"},
        {"text": "Ἡ σοφία ἐστὶν ἀρετή.", "hint": "Wisdom is virtue"},
        {"text": "Οἱ θεοὶ ἐν τῷ οὐρανῷ.", "hint": "The gods in heaven"},
        {"text": "Μανθάνω τὴν γλῶτταν.", "hint": "I am learning the language"},
    ]

    phrase = rng.choice(dictation_phrases)
    return DictationTask(
        audio_url=None,  # TTS integration pending
        target_text=phrase["text"],
        hint=phrase.get("hint"),
    )


def _build_etymology_task(language: str, context: LessonContext, rng: random.Random) -> EtymologyTask:
    # Latin etymology
    if language == "lat":
        etym = [
            {
                "question": "Which word comes from 'amo' (love)?",
                "word": "amo",
                "options": ["amateur", "armor", "amazing", "ample"],
                "answer_index": 0,
                "explanation": "Amateur comes from Latin amator (lover), from amare (to love)",
            }
        ]
        e = rng.choice(etym)
        return EtymologyTask(
            question=e["question"],
            word=e["word"],
            options=e["options"],
            answer_index=e["answer_index"],
            explanation=e["explanation"],
        )

    # Hebrew etymology
    if language == "hbo":
        etym = [
            {
                "question": "Which word comes from 'שָׁלוֹם' (peace)?",
                "word": "שָׁלוֹם",
                "options": ["shalom", "salami", "slam", "salon"],
                "answer_index": 0,
                "explanation": "Shalom is borrowed directly from Hebrew meaning peace",
            }
        ]
        e = rng.choice(etym)
        return EtymologyTask(
            question=e["question"],
            word=e["word"],
            options=e["options"],
            answer_index=e["answer_index"],
            explanation=e["explanation"],
        )

    # Sanskrit etymology
    if language == "san":
        etym = [
            {
                "question": "Which word comes from 'योग' (yoga)?",
                "word": "योग",
                "options": ["yoga", "yogi", "yoke", "both a and b"],
                "answer_index": 3,
                "explanation": "Both yoga and yogi come from Sanskrit yoga meaning union",
            }
        ]
        e = rng.choice(etym)
        return EtymologyTask(
            question=e["question"],
            word=e["word"],
            options=e["options"],
            answer_index=e["answer_index"],
            explanation=e["explanation"],
        )

    # For other non-Greek languages
    if language and not language.startswith("grc"):
        return EtymologyTask(
            prompt=f"Etymology (Coming soon for {language})",
            ancient_word="placeholder",
            modern_word="placeholder",
            explanation="Placeholder",
        )
    """Learn word origins and relationships"""
    etymology_questions = [
        {
            "question": "Which English word comes from 'φιλοσοφία' (love of wisdom)?",
            "word": "φιλοσοφία",
            "options": ["philosophy", "philanthropy", "philology", "sophistry"],
            "answer_idx": 0,
            "explanation": ("'Philosophy' from φιλοσοφία: φίλος (loving) + σοφία (wisdom)."),
        },
        {
            "question": "What does 'δημο-κρατία' literally mean?",
            "word": "δημοκρατία",
            "options": ["rule of the people", "rule of the king", "rule of the gods", "rule of the wise"],
            "answer_idx": 0,
            "explanation": "'Democracy' comes from δῆμος (demos, people) and κράτος (kratos, power/rule).",
        },
        {
            "question": "Which word comes from 'ψυχή' (soul, life)?",
            "word": "ψυχή",
            "options": ["psychology", "biology", "theology", "mythology"],
            "answer_idx": 0,
            "explanation": "'Psychology' derives from ψυχή (psyche, soul/mind) and λόγος (logos, study).",
        },
        {
            "question": "What is the root meaning of 'ἀνθρωπο-λογία'?",
            "word": "ἀνθρωπολογία",
            "options": ["study of humans", "study of animals", "study of gods", "study of nature"],
            "answer_idx": 0,
            "explanation": "Anthropology comes from ἄνθρωπος (anthropos, human) and λόγος (logos, study).",
        },
        {
            "question": "Which English word comes from 'βίος' (life) and 'λόγος' (study)?",
            "word": "βιολογία",
            "options": ["biology", "biography", "biopsy", "biotechnology"],
            "answer_idx": 0,
            "explanation": ("'Biology' from βίος (life) + λόγος (study)."),
        },
        {
            "question": "What does 'θεο-λογία' mean?",
            "word": "θεολογία",
            "options": ["study of God", "study of nature", "study of earth", "study of stars"],
            "answer_idx": 0,
            "explanation": "'Theology' comes from θεός (theos, god) and λόγος (logos, study).",
        },
        {
            "question": "Which word comes from 'γεω-γραφία' (earth writing)?",
            "word": "γεωγραφία",
            "options": ["geography", "geometry", "geology", "geopolitics"],
            "answer_idx": 0,
            "explanation": "'Geography' comes from γῆ (ge, earth) and γράφω (grapho, write/describe).",
        },
        {
            "question": "What does 'φιλ-ανθρωπία' literally mean?",
            "word": "φιλανθρωπία",
            "options": ["love of humanity", "love of wisdom", "love of nature", "love of god"],
            "answer_idx": 0,
            "explanation": ("'Philanthropy' from φίλος (loving) + ἄνθρωπος (human)."),
        },
        {
            "question": "Which word comes from 'αὐτο-βίο-γραφία' (self-life-writing)?",
            "word": "αὐτοβιογραφία",
            "options": ["autobiography", "biography", "autograph", "bibliograph"],
            "answer_idx": 0,
            "explanation": ("'Autobiography': αὐτός (self) + βίος (life) + γράφω (write)."),
        },
        {
            "question": "What does 'μονο-λόγος' mean?",
            "word": "μονόλογος",
            "options": ["speaking alone", "speaking together", "speaking wisely", "speaking loudly"],
            "answer_idx": 0,
            "explanation": "'Monologue' comes from μόνος (monos, alone) and λόγος (logos, speech).",
        },
        {
            "question": "Which word comes from 'χρόνος' (time) and 'μέτρον' (measure)?",
            "word": "χρονόμετρον",
            "options": ["chronometer", "chronicle", "chronology", "synchronize"],
            "answer_idx": 0,
            "explanation": "'Chronometer' combines χρόνος (chronos, time) and μέτρον (metron, measure).",
        },
        {
            "question": "What does 'τηλε-φωνή' literally mean?",
            "word": "τηλεφωνή",
            "options": ["distant sound", "loud sound", "beautiful sound", "speaking sound"],
            "answer_idx": 0,
            "explanation": "'Telephone' comes from τῆλε (tele, far) and φωνή (phone, sound/voice).",
        },
        {
            "question": "Which word comes from 'μικρο-σκοπέω' (look at small things)?",
            "word": "μικροσκόπιον",
            "options": ["microscope", "telescope", "periscope", "stethoscope"],
            "answer_idx": 0,
            "explanation": "'Microscope' comes from μικρός (mikros, small) and σκοπέω (skopeo, look at).",
        },
        {
            "question": "What does 'σύν-θεσις' mean?",
            "word": "σύνθεσις",
            "options": ["putting together", "taking apart", "standing still", "moving forward"],
            "answer_idx": 0,
            "explanation": "'Synthesis' comes from σύν (syn, together) and τίθημι (tithemi, place/put).",
        },
        {
            "question": "Which word comes from 'νεκρο-πόλις' (city of the dead)?",
            "word": "νεκρόπολις",
            "options": ["necropolis", "metropolis", "acropolis", "megalopolis"],
            "answer_idx": 0,
            "explanation": "'Necropolis' comes from νεκρός (nekros, dead) and πόλις (polis, city).",
        },
        {
            "question": "What does 'ὁμο-γενής' mean?",
            "word": "ὁμογενής",
            "options": ["same kind", "different kind", "many kinds", "no kind"],
            "answer_idx": 0,
            "explanation": "'Homogeneous' comes from ὁμός (homos, same) and γένος (genos, kind/race).",
        },
        {
            "question": "Which word comes from 'μετα-μόρφωσις' (change of form)?",
            "word": "μεταμόρφωσις",
            "options": ["metamorphosis", "metaphor", "metabolism", "metaphysics"],
            "answer_idx": 0,
            "explanation": "'Metamorphosis' comes from μετά (meta, change) and μορφή (morphe, form).",
        },
    ]

    question = rng.choice(etymology_questions)
    return EtymologyTask(
        question=question["question"],
        word=question["word"],
        options=question["options"],
        answer_index=question["answer_idx"],
        explanation=question["explanation"],
    )


def _build_comprehension_task(
    language: str, context: LessonContext, rng: random.Random
) -> ReadingComprehensionTask:
    """Build a reading comprehension exercise with passage and questions."""
    # Get canonical text if available, otherwise use daily line
    passage_text = ""
    ref = None
    source_kind = "daily"

    if context.canonical_lines:
        canon = context.canonical_lines[0]
        passage_text = canon.text
        ref = canon.ref
        source_kind = "canon"
    elif context.daily_lines:
        daily = context.daily_lines[0]
        passage_text = daily.text
        ref = None
        source_kind = "daily"
    else:
        # Fallback Greek passage
        passage_text = "Μῆνιν ἄειδε θεὰ Πηληϊάδεω Ἀχιλῆος οὐλομένην."
        ref = "Il.1.1"
        source_kind = "canon"

    # Create sample comprehension questions
    if language.startswith("grc"):
        questions = [
            ComprehensionQuestion(
                question="What is the main subject being addressed in this passage?",
                options=[
                    "The anger of Achilles",
                    "The wisdom of Athena",
                    "The beauty of Helen",
                    "The strength of Hector",
                ],
                answer_index=0,
            ),
            ComprehensionQuestion(
                question="What type of literary work is this passage from?",
                options=["Epic poetry", "Lyric poetry", "Drama", "Philosophy"],
                answer_index=0,
            ),
        ]
    elif language == "lat":
        questions = [
            ComprehensionQuestion(
                question="What is the primary focus of this text?",
                options=["Historical events", "Philosophical ideas", "Poetic imagery", "Legal procedures"],
                answer_index=0,
            ),
            ComprehensionQuestion(
                question="What literary tradition does this represent?",
                options=["Classical Latin literature", "Medieval Latin", "Church Latin", "Legal Latin"],
                answer_index=0,
            ),
        ]
    else:
        # Generic questions for other languages
        questions = [
            ComprehensionQuestion(
                question="What is the main idea of this passage?",
                options=[
                    "Narrative storytelling",
                    "Descriptive imagery",
                    "Argumentative discourse",
                    "Instructional content",
                ],
                answer_index=0,
            ),
        ]

    # Randomly select 2-3 questions
    selected_questions = rng.sample(questions, min(len(questions), rng.randint(2, 3)))

    return ReadingComprehensionTask(
        source_kind=source_kind,
        ref=ref,
        passage=passage_text,
        translation="Sample translation for beginner mode" if rng.random() < 0.5 else None,
        questions=selected_questions,
    )


async def _populate_audio_urls(
    tasks: Sequence[
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
        | EtymologyTask
    ],
    language: str,
    token: str | None,
) -> list[
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
    | EtymologyTask
]:
    """Populate audio URLs for tasks that require audio (listening, dictation, speaking).

    This function generates and caches TTS audio for tasks that have audio_url fields.
    """
    from app.lesson.audio_cache import get_or_generate_audio_url

    populated = []
    for task in tasks:
        if isinstance(task, ListeningTask):
            # Generate audio for the listening task
            audio_url = await get_or_generate_audio_url(
                text=task.audio_text,
                language=language,
                provider="echo",
                token=token,
            )
            # Create new task with audio URL
            populated.append(
                ListeningTask(
                    audio_url=audio_url,
                    audio_text=task.audio_text,
                    options=task.options,
                    answer=task.answer,
                )
            )
        elif isinstance(task, DictationTask):
            # Generate audio for dictation task
            audio_url = await get_or_generate_audio_url(
                text=task.target_text,
                language=language,
                provider="echo",
                token=token,
            )
            populated.append(
                DictationTask(
                    audio_url=audio_url,
                    target_text=task.target_text,
                    hint=task.hint,
                )
            )
        elif isinstance(task, SpeakingTask):
            # Speaking tasks don't need audio_url in current implementation
            # but could benefit from example pronunciation
            populated.append(task)
        else:
            # Non-audio tasks pass through unchanged
            populated.append(task)

    return populated


_EPI_CACHE: dict[str, epitran.Epitran] = {}


def _generate_phonetic_guide(text: str, system: str) -> str | None:
    """Generate IPA-like phonetic guide using Epitran."""
    if not text.strip():
        return None
    try:
        if system not in _EPI_CACHE:
            _EPI_CACHE[system] = epitran.Epitran(system)
        translit = _EPI_CACHE[system].transliterate(text)
        cleaned = translit.strip()
        return cleaned if cleaned else None
    except Exception as err:  # pragma: no cover - external library
        logger.warning("Failed generating phonetic guide for %s: %s", system, err)
        return None
