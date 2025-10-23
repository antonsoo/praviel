"""Language-specific configuration for authentic script and vocabulary.

This module centralizes language-specific data to make it easy to add new languages
without modifying provider code.

OFFICIAL LANGUAGE LIST - DO NOT MODIFY ORDER OR SCRIPTS
This list reflects the authoritative language prioritization, UI menu ordering,
and historically authentic scripts as researched and specified.
"""

from __future__ import annotations

from dataclasses import dataclass
from typing import Any, Literal


@dataclass(frozen=True)
class ScriptConfig:
    """Configuration for historically authentic script rendering."""

    case: Literal["upper", "lower", "mixed"] = "lower"
    """Default case: upper=UPPERCASE, lower=lowercase, mixed=Title Case"""

    has_accents: bool = True
    """Whether to include diacritical marks (accents, breathings, etc)"""

    char_v_for_u: bool = False
    """Use V instead of U (Latin)"""

    direction: Literal["ltr", "rtl", "ttb-rtl", "ttb-ltr"] = "ltr"
    """Writing direction: ltr=left-to-right, rtl=right-to-left, ttb-rtl=top-to-bottom/right-to-left columns, ttb-ltr=top-to-bottom/left-to-right"""

    word_separator: str | None = None
    """Word separator character (None for scriptio continua, '·' for interpunct, ' ' for space, etc)"""

    scriptio_continua_default: bool = False
    """Whether to default to scriptio continua (no word separation)"""

    punctuation_marks: list[str] | None = None
    """List of permitted punctuation marks in authentic texts (None = all modern punctuation forbidden)"""

    numeral_system: str = "spelled"
    """Numeral system: 'spelled'=spell out numbers, 'roman'=Roman numerals, 'greek'=Greek numerals, 'cuneiform'=cuneiform, etc"""

    normalize_chars: dict[str, str] | None = None
    """Character normalizations (e.g., {'J': 'I', 'U': 'V'} for Latin)"""

    special_features: dict[str, Any] | None = None
    """Language-specific special features (e.g., nomina sacra, iota adscript, etc)"""

    notes: str = ""
    """Historical/pedagogical notes about this script choice"""


@dataclass(frozen=True)
class LanguageConfig:
    """Complete language configuration."""

    code: str
    """ISO 639-3 language code"""

    name: str
    """Display name in English"""

    native_name: str
    """Display name in native script"""

    emoji: str
    """Emoji icon for this language"""

    script: ScriptConfig
    """Script rendering rules"""

    alphabet_name: str | None = None
    """Name of alphabet (e.g., 'Greek', 'Latin', 'Hebrew')"""

    is_full_course: bool = True
    """True for full courses, False for partial/inscription-only courses"""

    display_order: int = 9999
    """Display order in UI (synced from docs/LANGUAGE_LIST.md)"""


# ============================================================================
# OFFICIAL LANGUAGE LIST
# Display order synced automatically from docs/LANGUAGE_LIST.md - DO NOT manually edit display_order
# Scripts and names are historically researched - DO NOT MODIFY
# To reorder languages: Edit docs/LANGUAGE_LIST.md, then run: python scripts/sync_language_order.py
# ============================================================================

LANGUAGES: dict[str, LanguageConfig] = {
    # ==== FULL COURSES (1-36) ====
    # 2. 🏺 Classical Greek — ΕΛΛΗΝΙΚΗ ΓΛΩΤΤΑ
    "grc-cls": LanguageConfig(
        code="grc-cls",
        name="Classical Greek",
        native_name="ΕΛΛΗΝΙΚΗ ΓΛΩΤΤΑ",
        emoji="🏺",
        alphabet_name="Greek",
        script=ScriptConfig(
            case="upper",
            has_accents=False,
            direction="ltr",
            scriptio_continua_default=True,
            word_separator=None,
            punctuation_marks=["·"],  # Only Greek ano teleia U+0387 when witness-attested
            numeral_system="greek-milesian",  # Milesian/Ionian numerals with stigma/koppa/sampi
            special_features={
                "alphabet": "24-letter-ionian",  # Α–Ω only, no archaic letters
                "sigma_form": "Σ",  # Always Σ, never lunate Ϲ/ϲ
                "iota_adscript": True,  # Drop iota subscript, use adscript ΑΙ/ΩΙ/ΗΙ when attested
                "punctuation_unicode_preserve": [
                    "U+0387"
                ],  # Preserve ano teleia against normalization to U+00B7
                "numeral_letters": ["Ϛ", "ϛ", "Ϟ", "ϟ", "Ϡ", "ϡ"],  # stigma(6), koppa(90), sampi(900)
                "numeral_marks": ["ʹ", "͵"],  # keraia U+0374 (dexia), U+0375 (aristeri for thousands)
                "optional_attic_numerals": True,  # Support U+10140–U+1018F
            },
            notes=(
                "Classical Greek authentic script (5th-4th century BCE): "
                "Encode only 24 Ionian/Eucleidean letters in CAPITALS (Α–Ω). "
                "Always encode sigma as Σ; never lunate sigma (Ϲ/ϲ)—fonts provide lunate/uncial shapes. "
                "Default to scriptio continua (no spaces, hyphens, apostrophes, ligatures). "
                "Strip ALL polytonic marks (accents, breathings); treat iota-subscript as medieval—drop it by default; "
                "expose 'adscript-when-attested' toggle that writes explicit Ι only where witness shows adscript. "
                "Punctuation witness-driven and minimal: if raised dot present, output GREEK ANO TELEIA U+0387 "
                "(preserve U+0387 at render time, not U+00B7); do NOT introduce semicolon-question-mark convention. "
                "Numbers: spell out by default; 'Greek numerals' toggle enables Milesian/Ionian numerals using "
                "keraia marks (dexia U+0374, aristeri U+0375 for thousands) with optional overline U+0305; "
                "include stigma Ϛ/ϛ (6), archaic koppa Ϟ/ϟ (90), sampi Ϡ/ϡ (900). "
                "Optionally support Attic (acrophonic) numerals U+10140–U+1018F. "
                "Guard normalization: U+037E (Greek question mark) ≡ U+003B (semicolon), "
                "U+0387 (ano teleia) ≡ U+00B7 (middle dot), U+0374 has compatibility mapping to U+02B9; "
                "if normalization unavoidable, remap at render so historical punctuation/numeral signs survive; "
                "disable any 'Greek semicolon = question mark' heuristics; rely on fonts for uncial/lunate styling only."
            ),
        ),
        display_order=3,
    ),
    # 1. 🏛️ Classical Latin — LINGVA LATINA
    "lat": LanguageConfig(
        code="lat",
        name="Classical Latin",
        native_name="LINGVA LATINA",
        emoji="🏛️",
        alphabet_name="Latin",
        script=ScriptConfig(
            case="upper",
            has_accents=False,
            char_v_for_u=True,
            direction="ltr",
            scriptio_continua_default=True,
            word_separator=None,  # Default scriptio continua, optional interpunct toggle
            punctuation_marks=["·"],  # Only interpunct U+00B7 as optional epigraphic divider
            numeral_system="roman",  # Roman numerals only
            normalize_chars={
                "J": "I",
                "j": "i",
                "U": "V",
                "u": "v",
                "W": "VV",
                "w": "vv",
                "Æ": "AE",
                "æ": "ae",
                "Œ": "OE",
                "œ": "oe",
            },
            special_features={
                "alphabet": "ABCDEFGHIKLMNOPQRSTVXYZ",  # Y/Z primarily for Greek loans
                "k_usage": "epigraphic-only",  # K only where fixed (KALENDAE, praenomen K.)
                "q_usage": "always-qv",  # Q occurs only as QV
                "greek_loans": ["PH", "TH", "CH", "RH"],  # Initial RH for Greek rho
                "apex_mode": False,  # Optional toggle: combining acute U+0301 for long vowels
                "i_longa": False,  # Optional: LATIN EPIGRAPHIC LETTER I LONGA U+A7FE in capitals
                "roman_numeral_style": "subtractive",  # Toggle: 'additive' (IIII, VIIII) vs 'subtractive' (IV, IX)
                "interpunct_toggle": True,  # Allow interpunct (·) as word divider when enabled
            },
            notes=(
                "Classical Latin authentic script (Roman capitals): "
                "Present text in Roman capitals with classical inventory A B C D E F G H I K L M N O P Q R S T V X Y Z. "
                "Normalize input J→I, U→V, W→VV; map Æ/Œ→AE/OE. "
                "Use Y and Z primarily for Greek loans; Q occurs only as QV; "
                "retain K only where epigraphically fixed (e.g., KALENDAE, praenomen K.). "
                "Default to scriptio continua; optionally expose 'Epigraphic divider' toggle that inserts "
                "interpunct (· U+00B7) as word divider (triangular point is glyphic variant). "
                "Do NOT use macrons/breves; if vowel length must be surfaced, offer 'apex mode' that renders "
                "long-vowel apex (approximate with combining acute U+0301 and/or font feature); "
                "optionally allow epigraphic long I (LATIN EPIGRAPHIC LETTER I LONGA U+A7FE) in capitals. "
                "Greek loans should use PH/TH/CH and initial RH. "
                "Numerals are Roman only; provide style toggle: 'additive/epigraphic' (e.g., IIII, VIIII) "
                "vs 'subtractive/classical' (IV, IX)—both attested. "
                "Prevent typographic ligature synthesis and any re-introduction of J/U/W or modern punctuation; "
                "enforce letter inventory strictly; if dividers shown, use U+00B7 rather than modern punctuation. "
                "As on Trajan's Column, 113 CE."
            ),
        ),
        display_order=1,
    ),
    # 9. 🪲 Old Egyptian (Old Kingdom) — 𓂋𓈖 𓎡𓅓𓏏
    "egy-old": LanguageConfig(
        code="egy-old",
        name="Old Egyptian (Old Kingdom)",
        native_name="𓂋𓈖 𓎡𓅓𓏏",
        emoji="🪲",
        alphabet_name="Hieroglyphic",
        script=ScriptConfig(
            case="mixed",
            has_accents=False,
            direction="rtl",  # Default right-to-left (signs face right)
            scriptio_continua_default=True,
            word_separator=None,
            punctuation_marks=None,  # No punctuation
            numeral_system="egyptian-hieroglyphic",
            special_features={
                "script_type": "monumental-hieroglyphs",
                "reading_direction_default": "rtl",  # Signs oriented to face beginning of line (right)
                "alternative_layout": "ttb-rtl",  # Vertical top-to-bottom, columns right-to-left
                "quadrat_grouping": True,  # Enforce proper quadrat grouping of signs
                "writing_system": "logographic-phonetic-determinative",  # No vowels
                "editorial_markers": False,  # Forbid brackets, dots, etc.
                "numeral_system": "tally-powers-of-ten",  # Hieroglyphic tally system (1, 10, 100, 1000, etc.)
            },
            notes=(
                "Old Kingdom hieroglyphs (c. 2686-2181 BCE): "
                "Display text using monumental Old Kingdom hieroglyphs. "
                "Default reading direction is RIGHT-TO-LEFT, with signs oriented to face the beginning of line (right). "
                "Also support VERTICAL top-to-bottom layout, with columns progressing right to left. "
                "Enforce proper quadrat grouping of signs. "
                "Writing system is purely logographic, phonetic, and determinative; "
                "do NOT insert vowels, modern punctuation, or word spaces. "
                "All editorial markers (brackets, dots) FORBIDDEN. "
                "Numerals rendered using Egyptian hieroglyphic tally system for powers of ten "
                "(1, 10, 100, 1,000, etc.), NOT Arabic digits."
            ),
        ),
        display_order=23,
    ),
    # 5. 🕉️ Vedic Sanskrit — वैदिक संस्कृतम्
    "san-ved": LanguageConfig(
        code="san-ved",
        name="Vedic Sanskrit",
        native_name="वैदिक संस्कृतम्",
        emoji="🕉️",
        alphabet_name="Devanagari",
        script=ScriptConfig(
            case="mixed",
            has_accents=True,  # CRITICAL: Vedic pitch accent marks required
            direction="ltr",
            scriptio_continua_default=True,
            word_separator=None,
            punctuation_marks=["।", "॥"],  # Only danda and double danda
            numeral_system="spelled",
            special_features={
                "script": "devanagari-vedic",
                "pitch_accents": {
                    "anudatta": "U+0952",  # Horizontal bar below syllable
                    "udatta": "unmarked",  # Default, no mark
                    "svarita": "U+0951",  # Vertical stroke above syllable
                },
                "vedic_extensions": "U+1CD0–U+1CFF",  # Complex Vedic marks
                "sandhi": "continuous",  # No hyphens, continuous string
                "avagraha": "witness-only",  # ऽ only if explicit in source, not editorial
                "punctuation": {
                    "danda": "।",  # U+0964 end of verse/section
                    "double_danda": "॥",  # U+0965 end of verse/section
                },
            },
            notes=(
                "Vedic Sanskrit (Devanāgarī, Vedic conventions): "
                "Encode text in Devanāgarī, strictly configured for Vedic conventions, NOT Classical/modern Sanskrit. "
                "CRITICAL: Preserve and accurately render all Vedic pitch accent marks: "
                "anudātta (horizontal bar below syllable, U+0952), udātta (unmarked), "
                "svarita (vertical stroke above syllable, U+0951), plus complex marks from Vedic Extensions (U+1CD0–U+1CFF). "
                "FORBID all Western punctuation. "
                "ONLY valid punctuation: danda (। U+0964) and double danda (॥ U+0965) to mark end of verses/sections, as attested in manuscripts. "
                "Do NOT introduce hyphens; represent sandhi as continuous string of characters. "
                "Avagraha (ऽ) ONLY if explicitly present in source manuscript, not added editorially. "
                "All numbers MUST be spelled out."
            ),
        ),
        display_order=20,
    ),
    # 3. 📖 Koine Greek — ΚΟΙΝΗ ΔΙΑΛΕΚΤΟΣ
    "grc-koi": LanguageConfig(
        code="grc-koi",
        name="Koine Greek",
        native_name="ΚΟΙΝΗ ΔΙΑΛΕΚΤΟΣ",
        emoji="📖",
        alphabet_name="Greek",
        script=ScriptConfig(
            case="upper",
            has_accents=False,
            direction="ltr",
            scriptio_continua_default=True,
            word_separator=None,
            punctuation_marks=["·"],  # Only Greek ano teleia U+0387 when witness-attested
            numeral_system="greek-milesian",  # Milesian/Ionian numerals
            special_features={
                "alphabet": "24-letter",  # Α–Ω only
                "sigma_form": "Σ",  # Encode only as Σ, never Ϲ/ϲ
                "iota_adscript": True,  # Drop iota subscript, use adscript when attested
                "diaeresis": "witness-only",  # Permit Ϊ/Ϋ or combining ◌̈ ONLY where genuine hiatus shown
                "punctuation_unicode_preserve": ["U+0387"],  # Preserve ano teleia
                "numeral_letters": ["Ϛ", "ϛ", "Ϟ", "ϟ", "Ϡ", "ϡ"],  # stigma, koppa, sampi
                "numeral_marks": ["ʹ", "͵"],  # keraia U+0374, U+0375
                "optional_attic_numerals": True,  # U+10140–U+1018F
                "manuscript_mode": {
                    "enabled": False,  # Off by default
                    "nomina_sacra": {
                        "ΙΣ": "Jesus (various cases)",
                        "ΧΣ": "Christ",
                        "ΘΣ": "God",
                        "ΚΣ": "Lord",
                        "ΠΝΑ": "Spirit",
                    },
                    "overline": "U+0305",  # Spanning overbar for nomina sacra contractions
                },
            },
            notes=(
                "Koine Greek authentic script (Septuagint, New Testament uncials): "
                "Same 24 letters in CAPITALS (Α–Ω), uncial look left to fonts; encode sigma only as Σ (never Ϲ/ϲ). "
                "Use scriptio continua; forbid hyphens/apostrophes/ligature synthesis. "
                "Strip accents and breathings entirely; treat iota-subscript as medieval—drop it by default; "
                "expose 'adscript-when-attested' toggle (Ι) per witness. "
                "Punctuation minimal and strictly witness-driven: if raised dot occurs, output U+0387 "
                "(preserve against normalization to U+00B7); do NOT treat semicolon as question mark in this mode. "
                "Permit diaeresis (Ϊ/Ϋ or combining ◌̈) ONLY where genuine hiatus shown in witness "
                "(e.g., initial Ι/Υ in uncial manuscripts). "
                "Numbers: spelled out by default; optional Milesian/Ionian numerals using U+0374/U+0375 "
                "with optional overline U+0305 and numeral letters stigma/koppa/sampi; "
                "optionally support Attic/acrophonic numerals U+10140–U+1018F. "
                "Optional 'Manuscript mode' (off by default) may overline nomina sacra "
                "(curated set: ΙΣ/ΙΗΣ, ΧΣ, ΘΣ, ΚΣ, ΠΝΑ with case endings) "
                "using real overbar spanning contraction (render-level rule or U+0305 across span); "
                "do NOT encode lunate sigma or non-textual ligatures. "
                "Same normalization guards as Classical Greek; rely on fonts for uncial forms; "
                "keep diaeresis strictly witness-based. "
                "As in codices Sinaiticus, Vaticanus."
            ),
        ),
        display_order=2,
    ),
    # 6. 🔆 Ancient Sumerian — 𒅴𒂠
    "sux": LanguageConfig(
        code="sux",
        name="Ancient Sumerian",
        native_name="𒅴𒂠",
        emoji="🔆",
        alphabet_name="Cuneiform",
        script=ScriptConfig(
            case="mixed",
            has_accents=False,
            direction="ltr",  # Left-to-right (shifted from original vertical)
            scriptio_continua_default=True,
            word_separator=None,  # Default continuous, optional DIŠ wedge when attested
            punctuation_marks=None,  # No modern punctuation
            numeral_system="sexagesimal-cuneiform",
            special_features={
                "script_type": "cuneiform-sumerian",
                "period": "ur-iii-old-babylonian",
                "layout": "ltr-horizontal",  # Reflects shift from original vertical
                "word_divider": "𒁹",  # DIŠ (small vertical wedge) only when attested in source tablet
                "word_divider_usage": "witness-only",
                "signs": "determinatives-logograms-phonetic",  # Preserve exactly as in source
                "editorial_markers": False,  # No brackets or superscripts
                "numeral_system": "sexagesimal-base60",  # Proper place-value notation with signs for 1 and 10
            },
            notes=(
                "Sumerian cuneiform (Ur III, Old Babylonian): "
                "Render text using appropriate Sumerian cuneiform sign inventory for the period. "
                "Layout is LEFT-TO-RIGHT in horizontal lines, reflecting shift from original vertical column layout. "
                "PROHIBIT all modern punctuation and spacing. "
                "Determinatives, logograms, and phonetic signs MUST be preserved exactly as in source text, "
                "with NO editorial brackets or superscripts added. "
                "Traditional small vertical wedge (DIŠ, 𒁹) MAY be used as word divider ONLY if attested in source tablet; "
                "otherwise, maintain scriptio continua. "
                "Numerals MUST be displayed using sexagesimal (base-60) cuneiform system, "
                "including proper place-value notation and specific signs for 1 and 10; forbid Arabic digits."
            ),
        ),
        display_order=16,
    ),
    # 7. 🍎 Yehudit (Paleo-Hebrew) — 𐤉𐤄𐤅𐤃𐤉𐤕
    "hbo-paleo": LanguageConfig(
        code="hbo-paleo",
        name="Yehudit (Paleo-Hebrew)",
        native_name="𐤉𐤄𐤅𐤃𐤉𐤕",
        emoji="🍎",
        alphabet_name="Paleo-Hebrew",
        script=ScriptConfig(
            case="mixed",
            has_accents=False,
            direction="rtl",
            scriptio_continua_default=True,
            word_separator=None,  # Default continuous, optional dot/tick when attested
            punctuation_marks=None,  # No Western punctuation
            numeral_system="spelled",
            special_features={
                "script": "paleo-hebrew",
                "variant": "phoenician-derived",
                "alphabet_type": "abjad",  # Pure consonantal
                "matres_lectionis": "source-strict",  # Follow source inscription orthography exactly
                "vowel_marks": False,  # No Masoretic niqqud or cantillation
                "word_division": "witness-only",  # Single dot or short vertical tick if in source artifact
                "script_avoid": "square-aramaic-ashuri",  # Absolutely avoid later square script
            },
            notes=(
                "Paleo-Hebrew script (pre-exilic Yehudit): "
                "Use Paleo-Hebrew alphabet, a variant of Phoenician script. "
                "Writing direction STRICTLY right-to-left. "
                "This is a pure ABJAD (consonantal alphabet); do NOT add any vowel markings, "
                "including Masoretic niqqud or cantillation marks. "
                "Use of matres lectionis (consonants as vowel indicators, e.g., 𐤅 for /o/ or /u/) "
                "MUST strictly follow orthography of source inscription. "
                "FORBID all Western punctuation. "
                "Word division, if present in source artifact, should be represented by single small dot or short vertical tick; "
                "otherwise, all text MUST be rendered in scriptio continua. "
                "Numbers MUST be spelled out. "
                "ABSOLUTELY AVOID the later square Aramaic (Ashuri) script."
            ),
        ),
        display_order=14,
    ),
    # 8. ☦️ Old Church Slavonic — ⰔⰎⰑⰂⰡⰐⰟ ⰟⰸⰟⰽ (or СЛОВѢНЬСКЪ ѨЗЫКЪ)
    "cu": LanguageConfig(
        code="cu",
        name="Old Church Slavonic",
        native_name="ⰔⰎⰑⰂⰡⰐⰟ ⰟⰸⰟⰽ",  # Glagolitic
        emoji="☦️",
        alphabet_name="Glagolitic",
        script=ScriptConfig(
            case="upper",  # No case distinction, only majuscule forms
            has_accents=False,
            direction="ltr",
            word_separator=" ",
            punctuation_marks=["·"],  # Middle or high dot for pauses, decorated paragraph marks
            numeral_system="glagolitic-letters",
            special_features={
                "primary_script": "glagolitic-round",  # Early round Glagolitic most authentic
                "alternative_script": "cyrillic-ustav",  # Early Cyrillic uncial as alternative mode
                "case": "majuscule-only",  # No case distinction
                "titlo": "U+0483",  # Combining overline for abbreviations and numerals
                "nomina_sacra": True,  # Titlo especially for nomina sacra
                "numerals_titlo": True,  # Letters used as numerals marked with titlo
                "punctuation": {
                    "dot": "·",  # Middle or high dot for pauses
                    "paragraph": "decorated-marks",  # Decorated paragraph markers
                },
                "archaic_letters": [
                    "Ъ",
                    "Ь",
                    "Ѧ",
                    "Ѫ",
                    "Ѣ",
                    "Ѵ",
                    "Ѳ",
                ],  # Preserve yers, yuses, yat, izhitsa, fita
                "preserve_orthography": True,  # Do NOT normalize to later Russian/Slavic
            },
            notes=(
                "Old Church Slavonic (СЛОВѢНЬСКЪ ѨЗЫКЪ): "
                "Primary and most authentic script is GLAGOLITIC, specifically early 'round' form. "
                "Alternative mode for early Cyrillic uses USTAV (uncial) script. "
                "In either mode, NO case distinction; use only majuscule forms. "
                "CRITICAL: TITLO (combining overline, U+0483) MUST be placed over letters to indicate "
                "abbreviation (especially for nomina sacra) and to mark letters being used as numerals. "
                "Punctuation restricted to what is found in early manuscripts: "
                "typically middle or high dot (·) for pauses and decorated paragraph marks. "
                "FORBID modern commas, semicolons, quotes. "
                "All numbers MUST be represented by letters with titlo above them. "
                "PRESERVE full archaic letter inventory: yers (Ъ/Ь), yuses (Ѧ/Ѫ), yat (Ѣ), izhitsa (Ѵ), fita (Ѳ); "
                "do NOT normalize to later Russian or other Slavic orthographies."
            ),
        ),
        display_order=8,
    ),
    # 9. 🔥 Avestan — 𐬀𐬬𐬆𐬯𐬙𐬁
    "ave": LanguageConfig(
        code="ave",
        name="Avestan",
        native_name="𐬀𐬬𐬆𐬯𐬙𐬁",
        emoji="🔥",
        alphabet_name="Avestan",
        script=ScriptConfig(
            case="mixed",  # No case distinction
            has_accents=False,
            direction="rtl",
            word_separator="·",  # Avestan word-separator dot (small dot or triangle)
            punctuation_marks=["·"],  # Only word separator dot
            numeral_system="spelled",
            special_features={
                "script": "avestan-alphabet",
                "invented_for_language": True,  # Specifically invented for Avestan
                "full_vowel_representation": True,  # Includes full vowel representation
                "case": "no-distinction",
                "word_separator": "mandatory",  # Dot/triangle mandatory between words
                "word_separator_char": "·",  # Small dot or triangle depending on font
                "ligatures": "preserve",  # Critical to preserve script's complex ligatures
                "conjuncts": "preserve",  # Conjuncts fundamental to orthography
                "no_substitution": True,  # Do NOT substitute Latin or Perso-Arabic characters
            },
            notes=(
                "Avestan script (Zoroastrian texts, 3rd-7th century CE): "
                "Display text using Avestan alphabet, specifically invented for the language with full vowel representation. "
                "Direction is RIGHT-TO-LEFT. "
                "NO case distinction. "
                "Words MUST be separated by Avestan word-separator dot (small dot or triangle, depending on font). "
                "NO other punctuation is historically attested. "
                "CRITICAL: Preserve script's complex LIGATURES and CONJUNCTS as they are fundamental to its orthography. "
                "Do NOT substitute Latin or Perso-Arabic characters. "
                "All numbers MUST be spelled out."
            ),
        ),
        display_order=24,
    ),
    # 10. ☸️ Pali — पाळि (or 𑀧𑀸𑀮𑀺 in Brahmi)
    "pli": LanguageConfig(
        code="pli",
        name="Pali",
        native_name="𑀧𑀸𑀮𑀺",
        emoji="☸️",
        alphabet_name="Brahmi",
        script=ScriptConfig(
            case="mixed",
            has_accents=False,
            direction="ltr",
            scriptio_continua_default=True,
            word_separator=None,  # Default scriptio continua with minimal spacing
            punctuation_marks=["।", "॥"],  # Only danda and double danda
            numeral_system="spelled",
            special_features={
                "script_primary": "brahmi",  # Most ancient choice
                "script_alternatives": [
                    "early-sinhala",
                    "grantha",
                    "burmese",
                ],  # Period-appropriate alternatives
                "manuscript_tradition": "source-dependent",
                "writing_style": "scriptio-continua-minimal-spacing",
                "punctuation": {
                    "danda": "।",  # End of verses/sentences
                    "double_danda": "॥",  # End of verses/sentences
                },
                "no_sanskrit_features": True,  # Do NOT editorially introduce visarga/avagraha
                "visarga": "witness-only",  # Only if explicit in Pali manuscript
                "avagraha": "witness-only",  # Only if explicit in Pali manuscript
                "numerals": "script-native",  # If digits required, use numerals native to chosen script (e.g., Brahmi)
            },
            notes=(
                "Pali (Buddhist Tipitaka, early Indic scripts): "
                "Represent Pali using historically appropriate early Indic script, "
                "with BRAHMI being most ancient choice. "
                "Other valid, period-appropriate scripts: early Sinhala, Grantha, or Burmese, "
                "depending on manuscript tradition being presented. "
                "Default writing style is SCRIPTIO CONTINUA with minimal spacing. "
                "ONLY permitted punctuation: danda (।) and double danda (॥) for marking end of verses/sentences. "
                "PROHIBIT all Western punctuation. "
                "Do NOT editorially introduce Sanskrit-specific features like visarga or avagraha "
                "unless they are explicitly part of the Pali manuscript witness. "
                "Numbers MUST be spelled out; if digits required by source, use numerals native to chosen script "
                "(e.g., Brahmi numerals), NOT Arabic digits."
            ),
        ),
        display_order=7,
    ),
    # 11. 🕎 Biblical Hebrew — עִבְרִית מִקְרָאִית
    "hbo": LanguageConfig(
        code="hbo",
        name="Biblical Hebrew",
        native_name="עברית מקראית",  # Unpointed form as authentic default
        emoji="🕎",
        alphabet_name="Hebrew",
        script=ScriptConfig(
            case="mixed",
            has_accents=False,  # AUTHENTIC: No Masoretic vowel points or cantillation
            direction="rtl",
            word_separator=" ",  # Simple space only
            punctuation_marks=None,  # No maqaf, sof pasuq, or modern punctuation
            numeral_system="spelled",
            special_features={
                "script": "ketav-ashuri-unpointed",  # Square Hebrew script WITHOUT pointing
                "masoretic_additions": False,  # REMOVE all Masoretic additions for authenticity
                "niqqud": False,  # No vowel points
                "cantillation": False,  # No te'amim
                "maqaf": False,  # No hyphen
                "sof_pasuq": False,  # No verse ender
                "modern_punctuation": False,  # No commas, periods, question marks
                "word_separator": "space-only",
                "matres_lectionis": "source-strict",  # Preserve waw/yod exactly as in witness text
                "consonantal_text": "preserve-witness",  # E.g., Leningrad Codex consonantal layer
                "orthography": "no-normalization",
            },
            notes=(
                "Biblical Hebrew authentic script (consonantal text): "
                "Display text using UNPOINTED square Hebrew script (Ketav Ashuri). "
                "Direction MUST be right-to-left. "
                "CORE RULE FOR AUTHENTICITY: REMOVE all Masoretic additions: "
                "this includes ALL vowel points (niqqud) and cantillation marks (te'amim). "
                "Punctuation like maqaf (hyphen), sof pasuq (verse ender), and any modern punctuation "
                "(commas, periods, question marks) MUST be FORBIDDEN. "
                "Words separated by simple space only. "
                "Orthography of consonantal text, including use of matres lectionis (waw/yod), "
                "MUST be preserved exactly as it appears in witness text "
                "(e.g., Leningrad Codex consonantal layer) WITHOUT any normalization. "
                "Numbers MUST be spelled out."
            ),
        ),
        display_order=4,
    ),
    # 12. 🗣️ Ancient Aramaic — 𐡀𐡓𐡌𐡉𐡕
    "arc": LanguageConfig(
        code="arc",
        name="Ancient Aramaic",
        native_name="𐡀𐡓𐡌𐡉𐡕",
        emoji="🗣️",
        alphabet_name="Imperial Aramaic",
        script=ScriptConfig(
            case="mixed",
            has_accents=False,
            direction="rtl",
            scriptio_continua_default=True,
            word_separator=None,  # Only if source shows specific divider (dot/small space)
            punctuation_marks=None,  # No Western punctuation
            numeral_system="spelled",
            special_features={
                "script": "imperial-aramaic-consonantal",
                "alphabet_type": "abjad",  # Consonantal only
                "vowel_points": False,  # No vowel points or later Syriac diacritics
                "matres_lectionis": "source-strict",  # Preserve exactly as attested
                "word_division": "witness-only",  # Dot or small space only if in source manuscript/inscription
                "numerals": "spelled-or-traditional-strokes",  # Spelled out or traditional numerical strokes if in source
            },
            notes=(
                "Ancient Aramaic (Imperial Aramaic script, Achaemenid Empire): "
                "Use Imperial Aramaic consonantal script, with STRICT right-to-left direction. "
                "As an ABJAD, it MUST be displayed WITHOUT any vowel points or later Syriac diacritics. "
                "PROHIBIT all Western punctuation. "
                "Word separation should ONLY occur if source manuscript or inscription shows specific divider, "
                "typically a dot or small space; otherwise, render text continuously. "
                "Use of matres lectionis (consonants as vowel indicators) MUST be preserved exactly as attested in source. "
                "Numbers should be spelled out or, if source uses them, rendered with traditional numerical strokes. "
                "Forbid Arabic digits."
            ),
        ),
        display_order=9,
    ),
    # 13. 🪷 Classical Sanskrit — संस्कृतम्
    "san": LanguageConfig(
        code="san",
        name="Classical Sanskrit",
        native_name="संस्कृतम्",
        emoji="🪷",
        alphabet_name="Devanagari",
        script=ScriptConfig(
            case="mixed",
            has_accents=False,
            direction="ltr",
            scriptio_continua_default=True,
            word_separator=None,  # Default scriptio continua with sandhi
            punctuation_marks=["।", "॥"],  # Only danda and double danda
            numeral_system="spelled",
            special_features={
                "script_primary": "devanagari",
                "script_alternatives": ["nagari", "grantha"],  # Historically appropriate regional scripts
                "sandhi": "continuous",  # Words joined according to sandhi rules
                "writing_mode": "scriptio-continua",  # As written in manuscripts
                "punctuation": {
                    "danda": "।",  # U+0964 terminate half-verses, verses, sentences
                    "double_danda": "॥",  # U+0965 terminate half-verses, verses, sentences
                },
                "avagraha": "witness-only",  # ऽ only when present in source, not editorial
                "conjuncts": "accurate",  # Accurate representation of samyuktākṣara (conjunct consonants)
                "no_editorial": True,  # No hyphens, Western punctuation, quotation marks
            },
            notes=(
                "Classical Sanskrit (Devanāgarī or historically appropriate script): "
                "Render text in Devanāgarī (or historically appropriate regional script like Nāgarī or Grantha). "
                "Default mode MUST be SCRIPTIO CONTINUA, where words are joined according to rules of SANDHI, "
                "reflecting how they are written in manuscripts. "
                "ONLY permitted punctuation: danda (। U+0964) and double danda (॥ U+0965) to terminate "
                "half-verses, verses, or sentences. "
                "FORBID all editorial hyphens, Western punctuation, and quotation marks. "
                "Avagraha (ऽ) should ONLY be displayed when present in source witness, NOT introduced as modern editorial convention. "
                "All numbers MUST be spelled out. "
                "Representation of conjunct consonants (samyuktākṣara) MUST be accurate."
            ),
        ),
        display_order=5,
    ),
    # 14. 🏹 Akkadian — 𒀝𒅗𒁺𒌑
    "akk": LanguageConfig(
        code="akk",
        name="Akkadian",
        native_name="𒀝𒅗𒁺𒌑",
        emoji="🏹",
        alphabet_name="Cuneiform",
        script=ScriptConfig(
            case="mixed",
            has_accents=False,
            direction="ltr",
            scriptio_continua_default=True,
            word_separator=None,  # Small vertical wedge only when explicit in source tablet
            punctuation_marks=None,  # No modern punctuation
            numeral_system="sexagesimal-cuneiform",
            special_features={
                "script": "mesopotamian-cuneiform-akkadian",
                "periods": ["old-babylonian", "neo-assyrian"],  # Adaptations for Akkadian
                "layout": "ltr",
                "word_divider": "small-vertical-wedge",  # Only when present in source tablet
                "word_divider_usage": "witness-only",
                "sumerograms": "preserve",  # Preserve logograms borrowed from Sumerian
                "determinatives": "preserve",  # Preserve exactly as written
                "editorial_glosses": False,  # No modern editorial glosses, brackets, or capitalization changes
                "numeral_system": "sexagesimal-base60",  # Proper place-value notation
            },
            notes=(
                "Akkadian cuneiform (Old Babylonian, Neo-Assyrian styles): "
                "Display text using Mesopotamian cuneiform script adapted for Akkadian language. "
                "Layout is LEFT-TO-RIGHT. "
                "PROHIBIT all modern punctuation. "
                "Small vertical wedge MAY be used as word divider ONLY when explicitly present in source tablet. "
                "Preserve Sumerograms (logograms borrowed from Sumerian) and determinatives exactly as written, "
                "WITHOUT adding modern editorial glosses, brackets, or capitalization changes. "
                "Numerals MUST be rendered using sexagesimal (base-60) cuneiform system with proper place-value notation."
            ),
        ),
        display_order=19,
    ),
    # 15. 🪓 Old Norse (Norrœnt mál) — ᚾᚢᚱᚱᛅᚾᛏ ᛘᛅᛚ
    "non": LanguageConfig(
        code="non",
        name="Old Norse (Norrœnt mál)",
        native_name="ᚾᚢᚱᚱᛅᚾᛏ ᛘᛅᛚ",  # Younger Futhark representation
        emoji="🪓",
        alphabet_name="Medieval Latin",  # For manuscript sources (12th-13th c.)
        script=ScriptConfig(
            case="mixed",  # No case distinction in medieval MSS
            has_accents=False,
            direction="ltr",
            word_separator=" ",  # Minimal spacing approaching scriptio continua, or middle dot
            punctuation_marks=["·"],  # Punctus (middle dot), optionally punctus elevatus/interrogativus
            numeral_system="roman",  # Roman numerals or spelled out per source
            special_features={
                "script_primary": "medieval-latin",  # For manuscript sources (12th-13th c.)
                "case": "no-distinction",
                "norse_characters": ["þ", "ð", "æ", "ǫ", "ꝫ"],  # Thorn, eth, ae, o-caudata/o-ogonek
                "orthography": "manuscript-witness",  # Follow manuscript exactly, no modern normalization
                "ð_þ_usage": "no-regularization",  # Do NOT normalize ð/þ to modern standard
                "punctuation": {
                    "punctus": "·",  # Middle dot for pauses
                    "punctus_elevatus": "optional",  # If in manuscript
                    "punctus_interrogativus": "optional",  # If in manuscript
                },
                "tironian_et": "⁊",  # Tironian note for 'ok' (and) where attested
                "numerals": "roman-or-spelled",  # Following source
            },
            notes=(
                "Old Norse (Norrœnt mál, 12th-13th century manuscripts): "
                "For manuscript sources, use medieval Latin script. NO case distinction. "
                "Alphabet includes specific Norse characters: thorn (þ), eth (ð), æ, and ǫ (often written with o-caudata, ꝫ). "
                "Orthography MUST strictly follow manuscript witness; "
                "do NOT normalize spellings to modern standard (e.g., do NOT regularize use of ð/þ). "
                "Punctuation limited to manuscript practices: punctus (middle dot ·) for pauses, "
                "potentially punctus elevatus or punctus interrogativus. "
                "Tironian note et (⁊) MUST be used for 'and' (ok) where attested. "
                "Numbers either spelled out or written in Roman numerals, following source."
            ),
        ),
        display_order=11,
    ),
    # 16. 👁️ Middle Egyptian — 𓂋𓈖 𓎡𓅓𓏏
    "egy": LanguageConfig(
        code="egy",
        name="Middle Egyptian",
        native_name="𓂋𓈖 𓎡𓅓𓏏",
        emoji="👁️",
        alphabet_name="Hieroglyphic",
        script=ScriptConfig(
            case="mixed",
            has_accents=False,
            direction="rtl",  # Primary right-to-left (signs facing right)
            scriptio_continua_default=True,
            word_separator=None,
            punctuation_marks=None,
            numeral_system="egyptian-hieroglyphic",
            special_features={
                "script_type": "monumental-hieroglyphs-middle-kingdom",
                "period": "middle-kingdom",  # c. 2055-1650 BCE
                "reading_direction_primary": "rtl",  # Signs face right
                "alternative_layout": "ttb-rtl",  # Vertical top-to-bottom, columns right-to-left
                "quadrat_grouping": "canonical",  # Canonical quadrat grouping
                "writing_system": "logosyllabic",  # No vowels
                "editorial_markers": False,  # No brackets or notations
                "hieratic_toggle": True,  # Optional cursive hieratic script for papyrus sources
                "hieratic_usage": "source-specific",  # Only if rendering from hieratic source
                "numeral_system": "hieroglyphic-tally",  # Traditional tally system
            },
            notes=(
                "Middle Egyptian (Middle Kingdom, c. 2055-1650 BCE): "
                "Use Middle Egyptian monumental hieroglyphs with canonical quadrat grouping. "
                "Primary layout is RIGHT-TO-LEFT (with signs facing right), "
                "with alternative VERTICAL top-to-bottom layout. "
                "Writing is logosyllabic; do NOT insert vowels, word spaces, or modern punctuation. "
                "Preserve logograms, phonograms, and determinatives precisely as attested, "
                "WITHOUT any editorial brackets or notations. "
                "Provide toggle to display text in HIERATIC (cursive script) ONLY if rendering text from "
                "specific hieratic source (e.g., papyrus). "
                "Numerals MUST use traditional hieroglyphic tally system."
            ),
        ),
        display_order=12,
    ),
    # 17. 🪢 Old English — ᛖᚾᚷᛚᛁᛋᚳ
    "ang": LanguageConfig(
        code="ang",
        name="Old English",
        native_name="ᛖᚾᚷᛚᛁᛋᚳ",  # Anglo-Saxon runes
        emoji="🪢",
        alphabet_name="Insular Latin",
        script=ScriptConfig(
            case="mixed",  # No u/v or i/j distinction
            has_accents=False,
            direction="ltr",
            scriptio_continua_default=True,  # Minimal spacing approaching scriptio continua
            word_separator="·",  # Simple middle dot as separator if attested
            punctuation_marks=["·"],  # Only punctus (dot) for pauses
            numeral_system="roman-or-spelled",
            special_features={
                "script": "insular-latin",
                "characters": ["þ", "ð", "ƿ", "æ"],  # Thorn, eth, wynn, ash
                "insular_g": True,  # Distinct Insular 'g' glyph (flat-topped 's' with closed loop below)
                "u_v_distinction": False,  # No typographic distinction u/v
                "i_j_distinction": False,  # No i/j distinction
                "wynn_for_w": True,  # 'w' represented by wynn (ƿ)
                "word_spacing": "minimal-or-middle-dot",  # Minimal spacing or middle dot separator
                "punctuation": {
                    "punctus": "·",  # Dot for pauses
                },
                "no_modern": True,  # Forbid modern spellings, punctuation, capitalization
                "numerals": "roman-or-spelled-per-witness",
            },
            notes=(
                "Old English (ᛖᚾᚷᛚᛁᛋᚳ, Insular Latin alphabet): "
                "Render text using Insular Latin alphabet. "
                "Key characters to include: thorn (þ), eth (ð), wynn (ƿ), and ash (æ). "
                "Ensure use of distinct Insular 'g' glyph (looking like flat-topped 's' with closed loop below). "
                "NO typographic distinction between 'u'/'v' or 'i'/'j'. "
                "'w' should be represented by wynn (ƿ). "
                "Writing presented with minimal spacing between words, approaching scriptio continua, "
                "or with simple middle dot as separator if attested. "
                "Punctuation limited to punctus (dot) for pauses. "
                "FORBID all modern spellings, punctuation, and capitalization conventions. "
                "Numbers should be Roman or spelled out per witness."
            ),
        ),
        display_order=13,
    ),
    # 18. 🐉 Classical Chinese — 文言文
    "lzh": LanguageConfig(
        code="lzh",
        name="Classical Chinese",
        native_name="文言文",
        emoji="🐉",
        alphabet_name="Han Characters",
        script=ScriptConfig(
            case="mixed",
            has_accents=False,
            direction="ttb-rtl",  # Vertical top-to-bottom, columns right-to-left
            scriptio_continua_default=True,
            word_separator=None,  # No punctuation or word spacing
            punctuation_marks=None,  # FORBIDDEN
            numeral_system="chinese-characters",
            special_features={
                "script": "traditional-han",  # 繁體字
                "layout_primary": "vertical-rtl",  # Columns top-to-bottom, progressing right-to-left
                "punctuation": False,  # Most authentic: forbid ALL punctuation
                "word_spacing": False,  # No word spacing
                "modern_marks_forbidden": True,  # No commas, periods, quotation marks
                "variant_forms": "preserve",  # Preserve variant character forms (異體字)
                "no_normalization": True,  # Do NOT normalize to modern standardized/simplified forms
                "no_simplified": True,  # Do NOT use simplified characters (简体字)
                "numerals": "chinese-characters",  # 一, 二, 三, 十, 百, etc.
            },
            notes=(
                "Classical Chinese (文言文, traditional characters): "
                "Display text using TRADITIONAL Han characters (繁體字). "
                "Default layout MUST be VERTICAL, with columns running top-to-bottom, "
                "and columns progressing right-to-left. "
                "Most authentic representation FORBIDS all punctuation and word spacing. "
                "Do NOT add modern marks like commas, periods, or quotation marks "
                "unless explicitly reproducing specific, much later punctuated edition. "
                "PRESERVE variant character forms (異體字) as found in source text; "
                "do NOT normalize to modern standardized forms or simplified characters (简体字). "
                "Numbers MUST be rendered using Chinese numeral characters (e.g., 一, 二, 三, 十, 百)."
            ),
        ),
        display_order=6,
    ),
    # 19. ⚖️ Coptic (Sahidic) — ⲧⲙⲛ̄ⲧⲣⲙ̄ⲛ̄ⲕⲏⲙⲉ
    "cop": LanguageConfig(
        code="cop",
        name="Coptic (Sahidic)",
        native_name="ⲧⲙⲛ̄ⲧⲣⲙ̄ⲛ̄ⲕⲏⲙⲉ",
        emoji="⚖️",
        alphabet_name="Coptic",
        script=ScriptConfig(
            case="mixed",  # No case distinction in early manuscripts
            has_accents=False,
            direction="ltr",
            scriptio_continua_default=True,  # Minimal or absent word spacing
            word_separator=None,
            punctuation_marks=["·"],  # Ancient middle/high dot, decorated paragraph markers
            numeral_system="greek-numerals",
            special_features={
                "script": "coptic-alphabet",
                "composition": "greek-derived-plus-demotic",  # Greek letters + 6-7 from Demotic Egyptian
                "case": "no-distinction",  # No case in early manuscripts
                "supralinear_stroke": "U+0305",  # Combining overline
                "supralinear_usage": {
                    "abbreviations": True,  # Indicate abbreviations
                    "nomina_sacra": ["ⲓ̅ⲥ̅"],  # e.g., ⲓ̅ⲥ̅ for Ἰησοῦς
                    "syllabic_consonant": True,  # Syllables with syllabic consonant
                },
                "word_spacing": "minimal-or-absent",
                "punctuation": {
                    "dot": "·",  # Ancient middle or high dot
                    "coronis": "decorated-paragraph-markers",  # Decorated paragraph markers
                },
                "numerals": "greek-numeral-system-with-overline",  # Letters with supralinear stroke
                "dialect_preservation": True,  # Preserve dialect-specific spellings (Sahidic vs. Bohairic)
                "no_normalization": True,
            },
            notes=(
                "Coptic (Sahidic dialect, early Christian texts): "
                "Use Coptic alphabet: Greek-derived letters PLUS six or seven letters from Demotic Egyptian. "
                "NO case distinction in early manuscripts. "
                "CRITICAL feature: SUPRALINEAR STROKE (combining overline) used to indicate abbreviations, "
                "especially NOMINA SACRA (e.g., ⲓ̅ⲥ̅ for Ἰησοῦς) and syllables with syllabic consonant. "
                "Word spacing should be MINIMAL or ABSENT. "
                "Punctuation limited to ancient middle or high dot and decorated paragraph markers (coronis). "
                "FORBID all Western punctuation. "
                "Numbers written using Greek numeral system (letters with supralinear stroke). "
                "PRESERVE dialect-specific spellings (e.g., Sahidic vs. Bohairic) WITHOUT normalization."
            ),
        ),
        display_order=15,
    ),
    # 20. 🐂️ Hittite — 𒉈𒅆𒇷
    "hit": LanguageConfig(
        code="hit",
        name="Hittite",
        native_name="𒉈𒅆𒇷",
        emoji="🐂",
        alphabet_name="Cuneiform",
        script=ScriptConfig(
            case="mixed",
            has_accents=False,
            direction="ltr",
            scriptio_continua_default=True,
            word_separator=None,
            punctuation_marks=None,
            numeral_system="cuneiform",
            special_features={
                "script": "mesopotamian-cuneiform-hittite",
                "syllabary": "hittite-adapted",  # Cuneiform syllabary adapted by Hittites
                "logograms": ["sumerograms", "akkadograms"],  # Both Sumerian and Akkadian
                "word_divider": "small-vertical-tick",  # Cuneiform word-divider wedge
                "word_divider_usage": "witness-only",  # Only when present in source tablet
                "phonetic_complements": "preserve",  # Hittite phonetic complements exactly as in cuneiform
                "editorial_markers": False,  # No brackets or glosses
            },
            notes=(
                "Hittite cuneiform (Anatolian Indo-European): "
                "Display text using Mesopotamian cuneiform script as adapted by Hittites "
                "(syllabary with Sumerian and Akkadian logograms). "
                "Layout is LEFT-TO-RIGHT. "
                "FORBID modern punctuation. "
                "Cuneiform word-divider wedge (small vertical tick) should be used between words "
                "ONLY when present in source tablet. "
                "ESSENTIAL: Retain Sumerograms and Akkadograms (written in capitals in modern transliteration) "
                "and Hittite phonetic complements exactly as they appear in cuneiform, "
                "WITHOUT adding editorial brackets or glosses. "
                "Numerals MUST be rendered in cuneiform."
            ),
        ),
        display_order=22,
    ),
    # 21. 🐆 Classical Nahuatl — Nāhuatlāhtōlli
    "nci": LanguageConfig(
        code="nci",
        name="Classical Nahuatl",
        native_name="Nāhuatlāhtōlli",
        emoji="🐆",
        alphabet_name="Latin",
        script=ScriptConfig(
            case="mixed",
            has_accents=True,  # But only as attested in source, not modern additions
            direction="ltr",
            word_separator=" ",
            punctuation_marks=[".", ":"],  # Sparse, from source only
            numeral_system="roman-or-spelled",
            special_features={
                "orthography": "16th-century-spanish",  # Early colonial sources
                "k_forbidden": True,  # No 'k' letter
                "w_forbidden": True,  # No 'w' letter
                "consonants": {"k_sound": ["c", "qu"], "w_sound": ["hu", "uh"], "sh_sound": "x"},
                "digraphs": ["tz", "tl"],  # Important Nahuatl digraphs
                "saltillo": "source-convention",  # Glottal stop: h, circumflex, or other per source
                "saltillo_inconsistent": True,  # Represented inconsistently in sources
                "no_modern_apostrophe": True,  # Do NOT normalize to modern apostrophe
                "stress_marks": False,  # Do NOT add modern accent marks for stress
                "word_spacing": "minimal",  # Sparse punctuation
                "numerals": "roman-or-spelled-per-witness",
            },
            notes=(
                "Classical Nahuatl (16th-century Spanish orthography): "
                "Use 16th-century Spanish-based orthography found in early colonial sources. "
                "System uses c/qu for /k/, hu/uh for /w/, x for /ʃ/, and digraphs like tz and tl. "
                "NO 'k' or 'w' letters. "
                "Glottal stop (saltillo) was represented inconsistently: often with 'h' or circumflex accent over preceding vowel; "
                "MUST follow convention of source manuscript and NOT normalize to modern apostrophe. "
                "Do NOT add modern accent marks for stress. "
                "Punctuation sparse, typically limited to periods or colons from source; otherwise minimal word spacing. "
                "Numbers spelled out or rendered in Roman numerals if witness uses them."
            ),
        ),
        display_order=25,
    ),
    # 22. 🏔️ Classical Tibetan — ཆོས་སྐད།
    "bod": LanguageConfig(
        code="bod",
        name="Classical Tibetan",
        native_name="ཆོས་སྐད།",
        emoji="🏔️",
        alphabet_name="Tibetan",
        script=ScriptConfig(
            case="mixed",
            has_accents=False,
            direction="ltr",
            word_separator="་",  # tsheg (MANDATORY after every syllable)
            punctuation_marks=["།", "༎"],  # shad and nyis shad
            numeral_system="tibetan-or-spelled",
            special_features={
                "script": "uchen-dbu-can",  # Classical Tibetan script
                "tsheg": "་",  # U+0F0B MANDATORY after every syllable
                "tsheg_usage": "mandatory-after-syllable",
                "shad": "།",  # U+0F0D single vertical bar, terminates clauses/sentences
                "nyis_shad": "༎",  # U+0F0E double vertical bar, end of text/major section
                "no_western_punctuation": True,
                "consonant_stacking": "preserve",  # Complex head-letters, subjoined letters, etc.
                "stacking_precision": "as-in-witness",  # Preserve exactly
                "numerals": {
                    "tibetan_digits": "U+0F20–U+0F29",  # Only when source uses them
                    "default": "spelled-out",
                },
            },
            notes=(
                "Classical Tibetan (Uchen/dbu can script, Buddhist texts): "
                "Render text using Uchen (dbu can) script. "
                "FUNDAMENTAL RULE: Every syllable MUST be followed by tsheg (་), a dot-like mark (syllable divider). "
                "This rule is MANDATORY. "
                "Clauses or sentences terminated by shad (།), a single vertical bar. "
                "End of whole text or major section marked by nyis shad (༎), double vertical bar. "
                "Do NOT use any Western punctuation. "
                "PRESERVE complex consonant stacking system (head-letters, subjoined letters, etc.) "
                "precisely as in witness. "
                "Numbers represented with Tibetan digits (U+0F20–U+0F29) ONLY when source text uses them; "
                "otherwise, spelled out."
            ),
        ),
        display_order=26,
    ),
    # 23. 🗻 Old Japanese — 上代日本語
    "ojp": LanguageConfig(
        code="ojp",
        name="Old Japanese",
        native_name="上代日本語",
        emoji="🗻",
        alphabet_name="Man'yōgana",
        script=ScriptConfig(
            case="mixed",
            has_accents=False,
            direction="ttb-rtl",  # Vertical, columns right-to-left
            scriptio_continua_default=True,
            word_separator=None,
            punctuation_marks=None,  # FORBIDDEN
            numeral_system="chinese-characters",
            special_features={
                "script": "manyogana",  # Chinese characters for phonetic/semantic values
                "layout": "vertical-rtl",  # Columns right-to-left
                "no_hiragana": True,  # No hiragana
                "no_katakana": True,  # No katakana
                "no_punctuation": True,  # Forbid all punctuation
                "no_word_spacing": True,  # No word spacing
                "character_choices": "preserve-witness",  # Preserve specific Man'yōgana char choices exactly
                "stylistic_meaning": True,  # Character choices were often stylistic and meaningful
                "no_normalization": True,  # Do NOT normalize to later kana spellings
                "numerals": "chinese-characters",
            },
            notes=(
                "Old Japanese (Nara period, 8th century, Man'yōgana): "
                "ONLY authentic representation is MAN'YŌGANA, which uses Chinese characters for "
                "their phonetic (and sometimes semantic) values. "
                "Layout MUST be VERTICAL, with columns running right-to-left. "
                "NO hiragana or katakana. "
                "FORBID all punctuation and word spacing. "
                "Specific character choices for phonetic values MUST be preserved exactly as in source text "
                "(e.g., Man'yōshū), as these choices were often stylistic and meaningful. "
                "Do NOT normalize orthography to later kana spellings. "
                "Numbers use Chinese numeral characters when present."
            ),
        ),
        display_order=27,
    ),
    # 24. 🦙 Classical Quechua — Runa Simi
    "qwh": LanguageConfig(
        code="qwh",
        name="Classical Quechua",
        native_name="Runa Simi",
        emoji="🦙",
        alphabet_name="Latin",
        script=ScriptConfig(
            case="mixed",
            has_accents=False,  # Do NOT add modern diacritics
            direction="ltr",
            word_separator=" ",
            punctuation_marks=[".", ":"],  # Sparse, from source only
            numeral_system="roman-or-spelled",
            special_features={
                "orthography": "16th-17th-century-colonial",  # Spanish missionary orthography
                "vowel_system": "3-vowel",  # a, i, u (not modern 5-vowel)
                "consonants": {"k_sound": ["c", "qu"], "w_sound": "hu", "ly_sound": "ll", "ny_sound": "ñ"},
                "ejectives_aspirates": "not-distinguished",  # Often not distinguished from plain stops
                "no_modern_diacritics": True,  # Do NOT add apostrophes or 'h' for ejectives/aspirates
                "diacritics_source_only": True,  # Only if in source
                "punctuation": "sparse",  # Periods/colons from source
                "no_modern_standardization": True,  # Do NOT normalize to modern 5-vowel or standardized Quechua
                "numerals": "roman-or-spelled-per-witness",
            },
            notes=(
                "Classical Quechua (16th/17th-century colonial orthography): "
                "Use 16th/17th-century colonial orthography developed by Spanish missionaries. "
                "System is typically 3-VOWEL (a, i, u) and uses Spanish conventions: "
                "c/qu for /k/, hu for /w/, ll for /ʎ/, ñ for /ɲ/. "
                "Ejective and aspirated stops were often NOT distinguished from plain stops; "
                "do NOT add modern diacritics (like apostrophes or 'h') to represent them unless in source. "
                "Punctuation sparse, limited to what is in source (usually periods/colons). "
                "Numbers spelled out or written as Roman numerals per witness text. "
                "Do NOT normalize spellings to any modern 5-vowel or standardized Quechua orthography."
            ),
        ),
        display_order=28,
    ),
    # 25. 🌙 Classical Arabic — العربية الفصحى
    "ara": LanguageConfig(
        code="ara",
        name="Classical Arabic",
        native_name="العربية الفصحى",
        emoji="🌙",
        alphabet_name="Arabic",
        script=ScriptConfig(
            case="mixed",
            has_accents=False,  # AUTHENTIC: Early Qur'ānic rasm WITHOUT vowel marks
            direction="rtl",
            scriptio_continua_default=False,  # Minimal word spacing
            word_separator=" ",  # Minimal spacing
            punctuation_marks=None,  # No modern punctuation; manuscript-style separators only
            numeral_system="spelled",
            special_features={
                "script": "early-quranic-rasm",  # Consonantal skeleton
                "rasm": "consonantal-only",  # Strip all vowel marks (ḥarakāt)
                "i_jam": False,  # By default, strip consonantal diacritical dots (i'jām)
                "i_jam_toggle": True,  # Toggle to display dots if specific early manuscript tradition includes them
                "harakaat": False,  # No vowel marks (ḥarakāt)
                "tatweel": False,  # Forbid tatweel (kashida) for justification
                "word_spacing": "minimal",
                "modern_punctuation": False,  # Prohibit all modern punctuation
                "verse_separators": "manuscript-style-only",  # Only if present in source
                "orthography": "no-normalization",  # Especially regarding hamza and tā' marbūṭa
                "hamza": "source-exact",  # Do NOT normalize hamza representation
                "ta_marbuta": "source-exact",  # Do NOT normalize form of tā' marbūṭa
                "numerals": "spelled-out",
            },
            notes=(
                "Classical Arabic (early Qur'ānic rasm for maximum authenticity): "
                "For maximum authenticity, display text using early Qur'ānic RASM (consonantal skeleton). "
                "This requires stripping ALL vowel marks (ḥarakāt) and, by default, "
                "all consonantal diacritical dots (i'jām) that distinguish letters like ب, ت, ث. "
                "A toggle MAY allow displaying dots if specific early manuscript tradition (which includes them) is shown. "
                "FORBID use of tatweel (kashida) for justification. "
                "Use minimal word spacing. "
                "PROHIBIT all modern punctuation. "
                "Verse or section ends should ONLY be marked with manuscript-style separators if present in source. "
                "Do NOT normalize orthography, especially regarding representation of hamza or form of tā' marbūṭa. "
                "Numbers MUST be spelled out."
            ),
        ),
        display_order=10,
    ),
    # 26. ✝️ Classical Syriac — ܠܫܢܐ ܣܘܪܝܝܐ
    "syc": LanguageConfig(
        code="syc",
        name="Classical Syriac",
        native_name="ܠܫܢܐ ܣܘܪܝܝܐ",
        emoji="✝️",
        alphabet_name="Syriac",
        script=ScriptConfig(
            case="mixed",
            has_accents=False,  # AUTHENTIC: By default suppress all later vowel pointing
            direction="rtl",
            word_separator=" ",  # Minimal spacing
            punctuation_marks=["·", "܁"],  # Ancient dots at different heights, four-dot arrangement
            numeral_system="spelled-or-letter-numerals",
            special_features={
                "script_primary": "estrangela",  # ܐܣܛܪܢܓܠܐ most authentic for this period
                "script_avoid": [
                    "serto",
                    "east-syriac",
                ],  # Do NOT use later letterforms unless specific witness
                "vowel_pointing": False,  # Suppress both Eastern and Western vowel pointing systems
                "punctuation": {
                    "single_dot": "·",  # High, low, or middle placement for different pause lengths
                    "four_dot": "܁",  # U+0701 four-dot arrangement for end of paragraph
                },
                "combining_overline": "U+0304",  # Mark abbreviations or numerals where attested
                "overline_usage": "abbreviations-and-numerals",
                "numerals": "spelled-or-letter-numerals-with-overline",
            },
            notes=(
                "Classical Syriac (Estrangelā script): "
                "Primary script for this period is ESTRANGELĀ (ܐܣܛܪܢܓܠܐ). "
                "Text direction is RIGHT-TO-LEFT. "
                "By default, SUPPRESS all later vowel pointing systems (both Eastern and Western forms). "
                "Punctuation minimal, limited to what is found in early manuscripts: "
                "single dot placed high, low, or in middle to indicate pauses of different lengths, "
                "and potentially four-dot arrangement (܁) to mark end of paragraph. "
                "Combining overline MAY be used to mark abbreviations or numerals where attested. "
                "Do NOT use later Serto or East Syriac letterforms unless specific witness in that hand is reproduced. "
                "Numbers spelled out or written with letter-numerals using overline."
            ),
        ),
        display_order=18,
    ),
    # 27. 🪙 Middle Persian (Pahlavi) — 𐭯𐭠𐭫𐭮𐭩𐭪
    "pal": LanguageConfig(
        code="pal",
        name="Middle Persian (Pahlavi)",
        native_name="𐭯𐭠𐭫𐭮𐭩𐭪",
        emoji="🪙",
        alphabet_name="Pahlavi",
        script=ScriptConfig(
            case="mixed",
            has_accents=False,
            direction="rtl",
            scriptio_continua_default=False,
            word_separator=None,  # Minimal or non-existent in inscriptions; Book Pahlavi may use dots/strokes
            punctuation_marks=None,  # No Western punctuation
            numeral_system="pahlavi-letters-or-spelled",
            special_features={
                "script_variants": ["inscriptional-pahlavi", "book-pahlavi"],
                "script_type": "abjad-with-ambiguity",  # Inherent ambiguity, mandatory ligatures
                "vowel_marks": False,  # Do NOT add vowel marks
                "ambiguity": "preserve",  # Do NOT attempt to disambiguate letters beyond script
                "ligatures": "mandatory",  # Mandatory ligatures
                "word_separation": "minimal-or-absent-inscriptions",  # Inscriptions: minimal/absent
                "word_separation_book": "dots-or-strokes-when-attested",  # Book Pahlavi: dots/strokes where attested
                "numerals": "pahlavi-letter-numerals-or-spelled",
            },
            notes=(
                "Middle Persian (Pahlavi script, Sassanid Empire): "
                "Use either INSCRIPTIONAL PAHLAVI or BOOK PAHLAVI script, depending on source. "
                "Direction is RIGHT-TO-LEFT. "
                "This script is an ABJAD with inherent ambiguity and mandatory ligatures; "
                "do NOT add vowel marks or attempt to disambiguate letters beyond what script itself provides. "
                "Word separation can be minimal or non-existent in inscriptions; "
                "Book Pahlavi may use dots or short strokes as dividers ONLY where attested. "
                "PROHIBIT Western punctuation. "
                "Numbers represented by Pahlavi letter-based numeral system or spelled out."
            ),
        ),
        display_order=29,
    ),
    # 28. ☘️ Old Irish — ᚛ᚌᚑᚔᚇᚓᚂᚉ᚜
    "sga": LanguageConfig(
        code="sga",
        name="Old Irish",
        native_name="᚛ᚌᚑᚔᚇᚓᚂᚉ᚜",
        emoji="☘️",
        alphabet_name="Ogham",
        script=ScriptConfig(
            case="mixed",
            has_accents=False,
            direction="ttb-ltr",  # Vertical along stemline, bottom-to-top (or left-to-right horizontal)
            word_separator=" ",  # OGHAM SPACE MARK if needed
            punctuation_marks=["᚛", "᚜"],  # OGHAM START MARK and END MARK
            numeral_system="spelled",
            special_features={
                "mode_primary": "epigraphic-ogham",
                "mode_alternative": "manuscript-insular-latin",
                "ogham": {
                    "layout": "vertical-stemline",  # Written vertically along stemline
                    "reading_direction": "bottom-to-top",  # Or left-to-right if horizontal
                    "start_mark": "᚛",  # U+169B OGHAM START MARK - MUST begin text
                    "end_mark": "᚜",  # U+169C OGHAM END MARK - MUST end text
                    "space_mark": " ",  # U+1680 OGHAM SPACE MARK for word division if needed
                    "otherwise": "continuous",
                },
                "manuscript_mode": {
                    "script": "insular-latin",
                    "punctus_delens": "U+0307",  # Combining dot above for lenition
                    "punctus_delens_usage": "manuscript-only",  # Only where MS shows it
                    "no_editorial_h": True,  # Do NOT normalize to following 'h'
                    "punctuation": "middle-dot-punctus-only",
                },
            },
            notes=(
                "Old Irish (᚛ᚌᚑᚔᚇᚓᚂᚉ᚜): "
                "Provide TWO MODES. Primary 'Epigraphic Mode' MUST use OGHAM SCRIPT. "
                "Written vertically along stemline, read bottom-to-top (or left-to-right if horizontal). "
                "MUST begin with OGHAM START MARK (᚛) and end with OGHAM END MARK (᚜). "
                "Use OGHAM SPACE MARK ( ) for word division if needed; otherwise continuous. "
                "For 'Manuscript Mode', use Insular Latin alphabet. "
                "CRITICAL feature: punctus delens (dot placed over letter, using combining dot above U+0307) "
                "to indicate lenition, but ONLY where manuscript shows it "
                "(do NOT editorially add or normalize to following 'h'). "
                "Punctuation limited to middle dot (punctus)."
            ),
        ),
        display_order=30,
    ),
    # 29. ⚔️ Gothic — 𐌲𐌿𐍄𐌹𐍃𐌺𐌰 𐍂𐌰𐌶𐌳𐌰
    "got": LanguageConfig(
        code="got",
        name="Gothic",
        native_name="𐌲𐌿𐍄𐌹𐍃𐌺𐌰 𐍂𐌰𐌶𐌳𐌰",
        emoji="⚔️",
        alphabet_name="Gothic",
        script=ScriptConfig(
            case="mixed",  # No case distinction
            has_accents=False,
            direction="ltr",
            word_separator="·",  # Middle dot (interpunct) mandatory between words
            punctuation_marks=["·", ":"],  # Middle dot for word separation, colon-like double dot for pauses
            numeral_system="gothic-letters-with-overline",
            special_features={
                "script": "gothic-alphabet",
                "case": "no-distinction",  # No case distinction
                "word_separator_mandatory": True,  # Middle dot (· U+00B7) between words per Codex Argenteus
                "major_pause": "colon-double-dot",  # Colon-like double dot for sentence ends
                "diaeresis": "witness-only",  # Trema on 'i' (ï) at word beginning or after vowel, only if MS shows it
                "diaeresis_char": "ï",  # ï where attested
                "supralinear_stroke": "U+0305",  # Overline for numerals or abbreviations
                "no_latin_substitution": True,  # Do NOT substitute Latin letters for Gothic (e.g., 'g' for 𐌲)
            },
            notes=(
                "Gothic (𐌲𐌿𐍄𐌹𐍃𐌺𐌰 𐍂𐌰𐌶𐌳𐌰, Wulfila's alphabet): "
                "Display text using Gothic alphabet. NO case distinction. "
                "Words MUST be separated by MIDDLE DOT (interpunct · U+00B7), "
                "following convention of Codex Argenteus. "
                "Major pauses or sentence ends marked with COLON-LIKE DOUBLE DOT. "
                "PROHIBIT all other Western punctuation. "
                "Use of DIAERESIS (trema) on letter 'i' (e.g., ï) at beginning of word or after vowel "
                "should be preserved ONLY where manuscript witness shows it. "
                "SUPRALINEAR STROKE (overline) indicates numerals or abbreviations. "
                "Do NOT substitute Latin letters for Gothic ones (e.g., 'g' for 𐌲)."
            ),
        ),
        display_order=31,
    ),
    # 30. 🦁 Geʽez — ግዕዝ
    "gez": LanguageConfig(
        code="gez",
        name="Geʽez",
        native_name="ግዕዝ",
        emoji="🦁",
        alphabet_name="Geʽez",
        script=ScriptConfig(
            case="mixed",  # No case distinction
            has_accents=False,
            direction="ltr",
            word_separator="፡",  # Ethiopic wordspace (looks like colon) - MANDATORY
            punctuation_marks=["።", "፤", "፣", "፥"],  # Ethiopic full stop and clause separators
            numeral_system="ethiopic-numerals",
            special_features={
                "script": "ethiopic-fidel",  # Syllabary (each char = consonant+vowel pair)
                "case": "no-distinction",
                "wordspace_mandatory": True,  # Ethiopic wordspace ፡ (U+1361) MANDATORY between words
                "full_stop": "።",  # U+1362 MANDATORY at end of sentences
                "clause_separators": {
                    "comma": "፣",  # U+1363
                    "semicolon": "፤",  # U+1364
                    "colon": "፥",  # U+1365
                },
                "clause_separator_usage": "as-attested-in-source",
                "no_latin_punctuation": True,  # Forbid all Latin punctuation
                "numerals": "ethiopic-numeral-system",  # U+1369–U+137C
            },
            notes=(
                "Geʽez (ግዕዝ, Ethiopic/Eritrean classical language): "
                "Render text using Ethiopic FIDEL (syllabary), where each character represents consonant+vowel pair. "
                "NO case distinction. "
                "MANDATORY word separator is ETHIOPIC WORDSPACE, which looks like colon (፡ U+1361). "
                "Sentences MUST end with ETHIOPIC FULL STOP (። U+1362). "
                "Other traditional clause separators (፤, ፣, ፥) should be used ONLY as attested in source text. "
                "FORBID all Latin punctuation. "
                "Numbers MUST be rendered using ETHIOPIC NUMERAL SYSTEM (U+1369–U+137C)."
            ),
        ),
        display_order=32,
    ),
    # 31. 🪔 Classical Tamil — சங்கத் தமிழ்
    "tam-old": LanguageConfig(
        code="tam-old",
        name="Classical Tamil",
        native_name="செந்தமிழ்",  # More authentic form
        emoji="🪔",
        alphabet_name="Tamil-Brahmi",
        script=ScriptConfig(
            case="mixed",
            has_accents=False,
            direction="ltr",
            scriptio_continua_default=True,
            word_separator=None,  # Nearly continuous writing
            punctuation_marks=None,  # No Western punctuation
            numeral_system="spelled-or-tamil-digits",
            special_features={
                "script": "tamil-script",
                "period": "sangam-period",  # c. 300 BCE-300 CE
                "writing_style": "nearly-continuous",
                "pulli": "U+0BCD",  # Dot above letter (virama) to suppress inherent /a/
                "pulli_usage": "preserve-accurately",  # Preserve its usage accurately
                "aytam": "ஃ",  # U+0B83 - use ONLY where explicitly attested
                "aytam_usage": "witness-only",
                "no_western_punctuation": True,
                "no_modern_word_spacing": True,  # Do NOT introduce modern conventions
                "numerals": "spelled-or-tamil-digits",  # Tamil digits U+0BE6–U+0BEF when in witness
                "grantha_letters": "witness-only",  # Do NOT introduce unless source (quoting Sanskrit) uses them
            },
            notes=(
                "Classical Tamil (செந்தமிழ், Sangam period c. 300 BCE-300 CE): "
                "Use Tamil script. Writing should be NEARLY CONTINUOUS. "
                "PUḶḶI (dot above letter, corresponding to virama U+0BCD) used to suppress inherent /a/ vowel "
                "and create pure consonants; its usage MUST be preserved accurately. "
                "Special character ĀYTAM (ஃ U+0B83) MUST be used ONLY where explicitly attested. "
                "FORBID all Western punctuation and do NOT introduce modern word spacing conventions. "
                "Numbers should be spelled out or, if witness contains them, "
                "rendered using TAMIL DIGITS (U+0BE6–U+0BEF). "
                "Do NOT introduce GRANTHA LETTERS unless source text (which might be quoting Sanskrit) explicitly uses them."
            ),
        ),
        display_order=17,
    ),
    # 32. 🦅 Classical Armenian — ԳՐԱԲԱՐ
    "xcl": LanguageConfig(
        code="xcl",
        name="Classical Armenian",
        native_name="ԳՐԱԲԱՐ",
        emoji="🦅",
        alphabet_name="Armenian",
        script=ScriptConfig(
            case="upper",  # Original uncial (majuscule) form
            has_accents=False,
            direction="ltr",
            word_separator=" ",
            punctuation_marks=["։", "՝", "՞"],  # Armenian punctuation only
            numeral_system="armenian-letter-numerals",
            special_features={
                "script": "erkatagir",  # երկաթագիր original uncial/majuscule form
                "case": "uppercase-majuscule-only",  # NO lowercase
                "punctuation": {
                    "full_stop": "։",  # U+0589 VERJAKET (looks like colon)
                    "comma": "՝",  # U+055D BOWT'
                    "question_mark": "՞",  # U+055E HARTSAKAN NSHAN - placed OVER stressed vowel of key word
                },
                "question_mark_placement": "over-stressed-vowel",  # NOT at end of sentence!
                "no_latin_punctuation": True,
                "numerals": "armenian-letter-numerals-with-overline",  # Ա=1, Բ=2, etc., with overline
                "orthography": "original-pre-reform",  # Preserve pre-reform distinctions (e.g., յ/հ)
            },
            notes=(
                "Classical Armenian (ԳՐԱԲԱՐ, Grabar): "
                "Use Armenian alphabet, rendered in original UNCIAL (MAJUSCULE) form known as ERKAT'AGIR (երկաթագիր). "
                "NO lowercase. "
                "Punctuation MUST be strictly Armenian: "
                "full stop is VERJAKET (։ U+0589), which looks like colon. "
                "Other period-appropriate marks: comma-like BOWT' (՝ U+055D) and "
                "question mark HARTSAKAN NSHAN (՞ U+055E), which is placed OVER the stressed vowel "
                "of question's key word, NOT at end of sentence. "
                "PROHIBIT Latin punctuation. "
                "Numbers MUST be written using ARMENIAN LETTER-NUMERAL SYSTEM (e.g., Ա=1, Բ=2), "
                "often marked with overline. "
                "PRESERVE original orthography (e.g., pre-reform distinction between յ/հ)."
            ),
        ),
        display_order=21,
    ),
    # 33. 🌌 Sogdian — 𐼼𐼴𐼶𐼹𐼷𐼸
    "sog": LanguageConfig(
        code="sog",
        name="Sogdian",
        native_name="𐼼𐼴𐼶𐼹𐼷𐼸",
        emoji="🌌",
        alphabet_name="Sogdian",
        script=ScriptConfig(
            case="mixed",
            has_accents=False,
            direction="rtl",
            scriptio_continua_default=False,
            word_separator=None,  # Minimal or marked with small/double dot if attested
            punctuation_marks=None,  # No Western punctuation
            numeral_system="spelled-or-letter-values",
            special_features={
                "script": "sogdian-formal-sutra",  # "Formal" or "sutra" script
                "cursive": True,  # Cursive script where many letters connect
                "word_separation": "minimal-or-dot-marks",  # Small dot or double dot only if attested
                "vowel_diacritics": False,  # Do NOT add beyond inherent matres lectionis
                "matres_lectionis": ["aleph", "yodh", "waw"],  # Inherent only
                "no_western_punctuation": True,
                "numerals": "spelled-or-letter-values-per-manuscript",
            },
            notes=(
                "Sogdian (𐼼𐼴𐼶𐼹𐼷𐼸, Silk Road trade language): "
                "Use Sogdian alphabet (the 'formal' or 'sutra' script) in RIGHT-TO-LEFT direction. "
                "This is a CURSIVE SCRIPT where many letters connect. "
                "Word separation should be MINIMAL or marked with small dot or double dot ONLY if attested in manuscript. "
                "Do NOT add vowel diacritics beyond inherent MATRES LECTIONIS (aleph, yodh, waw). "
                "FORBID all Western punctuation. "
                "Numbers spelled out or rendered with their letter values per manuscript convention."
            ),
        ),
        display_order=33,
    ),
    # 34. 🌄 Ugaritic — 𐎜𐎂𐎗𐎚
    "uga": LanguageConfig(
        code="uga",
        name="Ugaritic",
        native_name="𐎜𐎂𐎗𐎚",
        emoji="🌄",
        alphabet_name="Ugaritic",
        script=ScriptConfig(
            case="mixed",
            has_accents=False,
            direction="ltr",
            word_separator="𐎟",  # Ugaritic word divider - MANDATORY between every word
            punctuation_marks=["𐎟"],  # Only word divider
            numeral_system="spelled",
            special_features={
                "script": "ugaritic-cuneiform-alphabet",
                "alphabet_type": "alphabetic-cuneiform",  # Unique: alphabetic (NOT syllabic)
                "signs": 30,  # 30 alphabetic signs
                "word_divider": "𐎟",  # U+1039F small vertical wedge
                "word_divider_mandatory": True,  # MUST be placed between EVERY word
                "no_other_punctuation": True,
            },
            notes=(
                "Ugaritic (𐎜𐎂𐎗𐎚, earliest alphabetic cuneiform): "
                "Use UGARITIC CUNEIFORM ALPHABET, a unique ALPHABETIC (not syllabic) cuneiform script. "
                "Direction MUST be LEFT-TO-RIGHT. "
                "ONLY valid separator is UGARITIC WORD DIVIDER (𐎟 U+1039F), a small vertical wedge, "
                "which MUST be placed between EVERY word. "
                "NO other punctuation is used. "
                "Preserve the 30 alphabetic signs exactly as written."
            ),
        ),
        display_order=34,
    ),
    # 35. 🐫 Tocharian A (Ārśi) — Ārśi
    "xto": LanguageConfig(
        code="xto",
        name="Tocharian A (Ārśi)",
        native_name="Ārśi",
        emoji="🐫",
        alphabet_name="Brahmi",
        script=ScriptConfig(
            case="mixed",
            has_accents=True,  # Macrons for long vowels
            direction="ltr",
            scriptio_continua_default=True,
            word_separator=None,
            punctuation_marks=["।", "॥"],  # Only danda and double danda if attested
            numeral_system="spelled-or-brahmi-numerals",
            special_features={
                "script": "north-turkestan-brahmi",  # "Slanting Brahmi"
                "also_called": "slanting-brahmi",
                "writing_style": "scriptio-continua",
                "punctuation": {
                    "danda": "।",  # U+0964 end of sentences/verses if attested
                    "double_danda": "॥",  # U+0965 end of sentences/verses if attested
                },
                "punctuation_usage": "if-attested",
                "conjunct_forms": "preserve-exactly",  # Preserve script's specific conjuncts
                "vowel_diacritics": "preserve-exactly",  # Preserve exactly as in witness
                "numerals": "spelled-or-brahmi-digits",
            },
            notes=(
                "Tocharian A (Ārśi, Tarim Basin Indo-European): "
                "Render text using NORTH TURKESTAN BRAHMI SCRIPT (sometimes called 'slanting Brahmi'). "
                "Direction is LEFT-TO-RIGHT. "
                "Default writing style is SCRIPTIO CONTINUA. "
                "ONLY permitted punctuation: DANDA (।) and DOUBLE DANDA (॥) at end of sentences or verses, "
                "IF attested. "
                "PRESERVE script's specific CONJUNCT FORMS and VOWEL DIACRITICS exactly as in witness. "
                "Numbers spelled out or rendered with BRAHMI NUMERALS."
            ),
        ),
        display_order=35,
    ),
    # 36. 🛕 Tocharian B (Kuśiññe) — Kuśiññe
    "txb": LanguageConfig(
        code="txb",
        name="Tocharian B (Kuśiññe)",
        native_name="Kuśiññe",
        emoji="🛕",
        alphabet_name="Brahmi",
        script=ScriptConfig(
            case="mixed",
            has_accents=True,  # Macrons for long vowels
            direction="ltr",
            scriptio_continua_default=True,
            word_separator=None,
            punctuation_marks=["।", "॥"],  # Only danda and double danda if attested
            numeral_system="spelled-or-brahmi-numerals",
            special_features={
                "script": "north-turkestan-brahmi",  # Same as Tocharian A
                "also_called": "slanting-brahmi",
                "writing_style": "scriptio-continua",
                "punctuation": {
                    "danda": "।",  # U+0964 if in manuscript
                    "double_danda": "॥",  # U+0965 if in manuscript
                },
                "punctuation_usage": "when-present-in-manuscript",
                "orthographic_conventions": "tocharian-b-specific",  # Differ slightly from A
                "preserve_orthography": True,
                "numerals": "spelled-or-brahmi-digits-as-attested",
            },
            notes=(
                "Tocharian B (Kuśiññe, Tarim Basin Indo-European): "
                "Render text using same NORTH TURKESTAN BRAHMI SCRIPT conventions as Tocharian A. "
                "Direction is LEFT-TO-RIGHT and default is SCRIPTIO CONTINUA. "
                "ONLY allowed punctuation: Indic DANDA (।) and DOUBLE DANDA (॥) when present in manuscript. "
                "PRESERVE specific ORTHOGRAPHIC CONVENTIONS of Tocharian B, which differ slightly from A. "
                "Numerals MUST be spelled out or rendered in BRAHMI DIGITS as attested."
            ),
        ),
        display_order=36,
    ),
    # ==== PARTIAL COURSES / FUTURE MODULES ====
    # Reconstructed and/or sparsely attested - inscription/script modules only
    # 1. ⚱️ Etruscan — 𐌛𐌀𐌔𐌍𐌀
    "ett": LanguageConfig(
        code="ett",
        name="Etruscan",
        native_name="𐌛𐌀𐌔𐌍𐌀",
        emoji="⚱️",
        alphabet_name="Etruscan",
        is_full_course=False,
        script=ScriptConfig(
            case="mixed",
            has_accents=False,
            notes="Etruscan alphabet inscriptions (pre-Roman Italian civilization)",
        ),
        display_order=38,
    ),
    # 2. 🏞 Proto-Norse (Elder Futhark) — ᚾᛟᚱᚦᚱ ᛗᚨᛚᛟ
    "gmq-pro": LanguageConfig(
        code="gmq-pro",
        name="Proto-Norse (Elder Futhark)",
        native_name="ᚾᛟᚱᚦᚱ ᛗᚨᛚᛟ",
        emoji="🏞",
        alphabet_name="Elder Futhark",
        is_full_course=False,
        script=ScriptConfig(
            case="mixed",
            has_accents=False,
            notes="Proto-Norse in Elder Futhark (inscriptions only, c. 2nd-8th century CE)",
        ),
        display_order=39,
    ),
    # 3. 🐍 Elamite — 𒄬𒆷𒁶𒋾
    "elx": LanguageConfig(
        code="elx",
        name="Elamite",
        native_name="𒄬𒆷𒁶𒋾",
        emoji="🐍",
        alphabet_name="Cuneiform",
        is_full_course=False,
        script=ScriptConfig(
            case="mixed",
            has_accents=False,
            notes="Elamite cuneiform (inscriptions from ancient Iran)",
        ),
        display_order=42,
    ),
    # 4. ⛈️ Runic Old Norse (Younger Futhark) — ᚾᚢᚱᚱᚯᚾᛏ ᛘᛅᛚ
    "non-rune": LanguageConfig(
        code="non-rune",
        name="Runic Old Norse (Younger Futhark)",
        native_name="ᚾᚢᚱᚱᚯᚾᛏ ᛘᛅᛚ",
        emoji="⛈️",
        alphabet_name="Younger Futhark",
        is_full_course=False,
        script=ScriptConfig(
            case="mixed",
            has_accents=False,
            notes="Runic Old Norse inscriptions in Younger Futhark (Viking Age runestones)",
        ),
        display_order=40,
    ),
    # 5. 👑 Old Persian (Ariya) — 𐎠𐎼𐎡𐎹
    "peo": LanguageConfig(
        code="peo",
        name="Old Persian (Ariya)",
        native_name="𐎠𐎼𐎡𐎹",
        emoji="👑",
        alphabet_name="Old Persian Cuneiform",
        is_full_course=False,
        script=ScriptConfig(
            case="mixed",
            has_accents=False,
            notes="Old Persian cuneiform (Achaemenid royal inscriptions)",
        ),
        display_order=41,
    ),
    # 6. 🌽 Classic Maya (Chʼoltiʼ) — Chʼoltiʼ
    "myn": LanguageConfig(
        code="myn",
        name="Classic Maya (Chʼoltiʼ)",
        native_name="Chʼoltiʼ",
        emoji="🌽",
        alphabet_name="Maya Glyphs",
        is_full_course=False,
        script=ScriptConfig(
            case="mixed",
            has_accents=True,
            notes="Classic Maya hieroglyphic inscriptions (Chʼoltiʼ language)",
        ),
        display_order=43,
    ),
    # 7. 🐺 Old Turkic (Orkhon) — 𐱅𐰇𐰼𐰰
    "otk": LanguageConfig(
        code="otk",
        name="Old Turkic (Orkhon)",
        native_name="𐱅𐰇𐰼𐰰",
        emoji="🐺",
        alphabet_name="Old Turkic",
        is_full_course=False,
        script=ScriptConfig(
            case="mixed",
            has_accents=False,
            notes="Old Turkic in Orkhon script (Göktürk inscriptions)",
        ),
        display_order=37,
    ),
    # 8. ⛵ Phoenician (Canaanite) — 𐤊𐤍𐤏𐤍𐤉
    "phn": LanguageConfig(
        code="phn",
        name="Phoenician (Canaanite)",
        native_name="𐤊𐤍𐤏𐤍𐤉",
        emoji="⛵",
        alphabet_name="Phoenician",
        is_full_course=False,
        script=ScriptConfig(
            case="mixed",
            has_accents=False,
            notes="Phoenician alphabet inscriptions (mother of many alphabets)",
        ),
        display_order=44,
    ),
    # 9. 🐏 Moabite — 𐤌𐤀𐤁𐤉
    "obm": LanguageConfig(
        code="obm",
        name="Moabite",
        native_name="𐤌𐤀𐤁𐤉",
        emoji="🐏",
        alphabet_name="Phoenician",
        is_full_course=False,
        script=ScriptConfig(
            case="mixed",
            has_accents=False,
            notes="Moabite in Phoenician script (Mesha Stele inscription)",
        ),
        display_order=45,
    ),
    # 10. ⚓ Punic (Carthaginian) — 𐤊𐤍𐤏𐤍𐤉
    "xpu": LanguageConfig(
        code="xpu",
        name="Punic (Carthaginian)",
        native_name="𐤊𐤍𐤏𐤍𐤉",
        emoji="⚓",
        alphabet_name="Phoenician",
        is_full_course=False,
        script=ScriptConfig(
            case="mixed",
            has_accents=False,
            notes="Punic (late Phoenician) inscriptions from Carthage",
        ),
        display_order=46,
    ),
}


def get_language_config(language_code: str) -> LanguageConfig:
    """Get configuration for a language, with fallback to default.

    Args:
        language_code: ISO 639-3 code (e.g., 'grc', 'lat')

    Returns:
        LanguageConfig for the language
    """
    return LANGUAGES.get(
        language_code,
        LanguageConfig(
            code=language_code,
            name=language_code.upper(),
            native_name=language_code.upper(),
            emoji="🌐",
            script=ScriptConfig(case="mixed", has_accents=True),
        ),
    )


def get_script_guidelines(language_code: str) -> str:
    """Get script guidelines for AI prompts.

    Args:
        language_code: ISO 639-3 code

    Returns:
        Human-readable script guidelines for inclusion in AI prompts
    """
    config = get_language_config(language_code)

    # For detailed configurations with comprehensive notes, use them directly
    if config.script.notes and len(config.script.notes) > 200:
        # Comprehensive notes are formatted for direct use in AI prompts
        return f"**{config.name} ({config.code}) Authentic Script Guidelines:**\n\n{config.script.notes}"

    # Otherwise, build guidelines from config fields (legacy/simple configs)
    guidelines = []
    guidelines.append(f"Use script form: {config.native_name}")

    if config.script.case == "upper":
        guidelines.append("Use UPPERCASE letters only")
    elif config.script.case == "lower":
        guidelines.append("Use lowercase letters")

    if config.script.has_accents:
        guidelines.append("Include all diacritical marks")
    else:
        guidelines.append("Omit accents and diacritical marks")

    if config.script.char_v_for_u:
        guidelines.append("Use V instead of U (e.g., AVGVSTVS not AUGUSTUS)")

    if config.script.notes:
        guidelines.append(f"Note: {config.script.notes}")

    return ". ".join(guidelines) + "."


def get_supported_languages() -> list[str]:
    """Get list of supported language codes in priority order."""
    return list(LANGUAGES.keys())


def get_full_course_languages() -> list[str]:
    """Get list of language codes for full courses only."""
    return [code for code, config in LANGUAGES.items() if config.is_full_course]


def get_partial_course_languages() -> list[str]:
    """Get list of language codes for partial/inscription courses only."""
    return [code for code, config in LANGUAGES.items() if not config.is_full_course]
