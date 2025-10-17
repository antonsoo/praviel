"""Language-specific configuration for authentic script and vocabulary.

This module centralizes language-specific data to make it easy to add new languages
without modifying provider code.

OFFICIAL LANGUAGE LIST - DO NOT MODIFY ORDER OR SCRIPTS
This list reflects the authoritative language prioritization, UI menu ordering,
and historically authentic scripts as researched and specified.
"""

from __future__ import annotations

from dataclasses import dataclass
from typing import Literal


@dataclass(frozen=True)
class ScriptConfig:
    """Configuration for historically authentic script rendering."""

    case: Literal["upper", "lower", "mixed"] = "lower"
    """Default case: upper=UPPERCASE, lower=lowercase, mixed=Title Case"""

    has_accents: bool = True
    """Whether to include diacritical marks (accents, breathings, etc)"""

    char_v_for_u: bool = False
    """Use V instead of U (Latin)"""

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


# ============================================================================
# OFFICIAL LANGUAGE LIST
# Order reflects prioritization and UI menu ordering - DO NOT REORDER
# Scripts and names are historically researched - DO NOT MODIFY
# ============================================================================

LANGUAGES: dict[str, LanguageConfig] = {
    # ==== FULL COURSES (1-36) ====
    # 1. 🏺 Classical Greek — ΕΛΛΗΝΙΚΗ ΓΛΩΤΤΑ
    "grc": LanguageConfig(
        code="grc",
        name="Classical Greek",
        native_name="ΕΛΛΗΝΙΚΗ ΓΛΩΤΤΑ",
        emoji="🏺",
        alphabet_name="Greek",
        script=ScriptConfig(
            case="upper",
            has_accents=False,
            notes=(
                "Classical Greek inscriptions used UPPERCASE without "
                "accents/breathings. Authentic epigraphic form."
            ),
        ),
    ),
    # 2. 🏛️ Classical Latin — LINGVA LATINA
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
            notes="Classical Latin used UPPERCASE with V (no U). Example: AVGVSTVS not AUGUSTUS",
        ),
    ),
    # 3. 🪲 Old Egyptian (Old Kingdom) — 𓂋𓈖 𓎡𓅓𓏏
    "egy-old": LanguageConfig(
        code="egy-old",
        name="Old Egyptian (Old Kingdom)",
        native_name="𓂋𓈖 𓎡𓅓𓏏",
        emoji="🪲",
        alphabet_name="Hieroglyphic",
        script=ScriptConfig(
            case="mixed",
            has_accents=False,
            notes="Old Kingdom hieroglyphic script (c. 2686-2181 BCE)",
        ),
    ),
    # 4. 🕉️ Vedic Sanskrit — 𑀯𑁃𑀤𑀺𑀓 𑀲𑀁𑀲𑁆𑀓𑀾𑀢𑀫𑁆
    "san-ved": LanguageConfig(
        code="san-ved",
        name="Vedic Sanskrit",
        native_name="𑀯𑁃𑀤𑀺𑀓 𑀲𑀁𑀲𑁆𑀓𑀾𑀢𑀫𑁆",
        emoji="🕉️",
        alphabet_name="Brahmi",
        script=ScriptConfig(
            case="mixed",
            has_accents=True,
            notes="Vedic Sanskrit in Brahmi script with accent marks for proper pronunciation",
        ),
    ),
    # 5. 📖 Koine Greek — ΚΟΙΝΗ ΔΙΑΛΕΚΤΟΣ
    "grc-koi": LanguageConfig(
        code="grc-koi",
        name="Koine Greek",
        native_name="ΚΟΙΝΗ ΔΙΑΛΕΚΤΟΣ",
        emoji="📖",
        alphabet_name="Greek",
        script=ScriptConfig(
            case="upper",
            has_accents=False,
            notes="Koine Greek (common Greek of Hellenistic period) in uppercase",
        ),
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
            notes="Sumerian cuneiform script",
        ),
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
            notes="Paleo-Hebrew script (pre-exilic period)",
        ),
    ),
    # 8. ☦️ Old Church Slavonic — ⰔⰎⰑⰂⰡⰐⰟ ⰟⰸⰟⰽ
    "cu": LanguageConfig(
        code="cu",
        name="Old Church Slavonic",
        native_name="ⰔⰎⰑⰂⰡⰐⰟ ⰟⰸⰟⰽ",
        emoji="☦️",
        alphabet_name="Glagolitic",
        script=ScriptConfig(
            case="mixed",
            has_accents=False,
            notes="Glagolitic script (original OCS alphabet created by Saints Cyril and Methodius)",
        ),
    ),
    # 9. 🔥 Avestan — 𐬀𐬬𐬆𐬯𐬙𐬁
    "ave": LanguageConfig(
        code="ave",
        name="Avestan",
        native_name="𐬀𐬬𐬆𐬯𐬙𐬁",
        emoji="🔥",
        alphabet_name="Avestan",
        script=ScriptConfig(
            case="mixed",
            has_accents=False,
            notes="Avestan script for Zoroastrian texts (developed c. 3rd-7th century CE)",
        ),
    ),
    # 10. ☸️ Pali — 𑀧𑀸𑀮𑀺
    "pli": LanguageConfig(
        code="pli",
        name="Pali",
        native_name="𑀧𑀸𑀮𑀺",
        emoji="☸️",
        alphabet_name="Brahmi",
        script=ScriptConfig(
            case="mixed",
            has_accents=False,
            notes="Pali in Brahmi script (Buddhist Tipitaka texts)",
        ),
    ),
    # 11. 🕎 Biblical Hebrew — יהודית
    "hbo": LanguageConfig(
        code="hbo",
        name="Biblical Hebrew",
        native_name="יהודית",
        emoji="🕎",
        alphabet_name="Hebrew",
        script=ScriptConfig(
            case="mixed",
            has_accents=True,
            notes="Biblical Hebrew with niqqud (vowel points) for pronunciation",
        ),
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
            notes="Imperial Aramaic script (official script of Achaemenid Empire)",
        ),
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
            notes="Classical Sanskrit in Devanagari script (standard for classical texts)",
        ),
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
            notes="Akkadian cuneiform (Mesopotamian empire language)",
        ),
    ),
    # 15. 🪓 Old Norse (Norrœnt mál) — ᛏᚢᚾᛋᚴ ᛏᚢᚾᚴᛅ
    "non": LanguageConfig(
        code="non",
        name="Old Norse (Norrœnt mál)",
        native_name="ᛏᚢᚾᛋᚴ ᛏᚢᚾᚴᛅ",
        emoji="🪓",
        alphabet_name="Younger Futhark",
        script=ScriptConfig(
            case="mixed",
            has_accents=False,
            notes="Old Norse in Younger Futhark runes (Viking Age script)",
        ),
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
            notes="Middle Kingdom hieroglyphic script (c. 2055-1650 BCE) - classical literary form",
        ),
    ),
    # 17. 🪢 Old English — ᚫᛝᛚᛁᛋᚳ
    "ang": LanguageConfig(
        code="ang",
        name="Old English",
        native_name="ᚫᛝᛚᛁᛋᚳ",
        emoji="🪢",
        alphabet_name="Anglo-Saxon Runes",
        script=ScriptConfig(
            case="mixed",
            has_accents=False,
            notes="Old English in Anglo-Saxon runes (futhorc) for inscriptions",
        ),
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
            notes="Literary Chinese (Classical Chinese characters) - formal written form",
        ),
    ),
    # 19. ⚖️ Coptic (Sahidic) — ⲧⲙⲛ̄ⲧⲣⲙ̄ⲛ̄ⲕⲏⲙⲉ
    "cop": LanguageConfig(
        code="cop",
        name="Coptic (Sahidic)",
        native_name="ⲧⲙⲛ̄ⲧⲣⲙ̄ⲛ̄ⲕⲏⲙⲉ",
        emoji="⚖️",
        alphabet_name="Coptic",
        script=ScriptConfig(
            case="mixed",
            has_accents=False,
            notes="Sahidic Coptic dialect (most common for early Christian texts)",
        ),
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
            notes="Hittite cuneiform (Anatolian Indo-European language)",
        ),
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
            has_accents=True,
            notes="Classical Nahuatl with macrons for long vowels (Aztec language)",
        ),
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
            notes="Classical Tibetan script (dharma language of Buddhist texts)",
        ),
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
            notes="Old Japanese (Nara period, 8th century) in Man'yōgana",
        ),
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
            has_accents=False,
            notes="Classical Quechua (Cusco-Collao dialect, Inca language)",
        ),
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
            has_accents=True,
            notes="Classical Arabic with tashkeel (diacritics for proper pronunciation)",
        ),
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
            has_accents=True,
            notes="Classical Syriac with vowel points (Eastern Christian liturgical language)",
        ),
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
            notes="Middle Persian in Pahlavi script (Sassanid Empire language)",
        ),
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
            notes="Old Irish in Ogham script (ancient Celtic inscriptions)",
        ),
    ),
    # 29. ⚔️ Gothic — 𐌲𐌿𐍄𐌹𐍃𐌺𐌰 𐍂𐌰𐌶𐌳𐌰
    "got": LanguageConfig(
        code="got",
        name="Gothic",
        native_name="𐌲𐌿𐍄𐌹𐍃𐌺𐌰 𐍂𐌰𐌶𐌳𐌰",
        emoji="⚔️",
        alphabet_name="Gothic",
        script=ScriptConfig(
            case="mixed",
            has_accents=False,
            notes="Gothic alphabet (Wulfila's script for Gothic Bible)",
        ),
    ),
    # 30. 🦁 Geʽez — ግዕዝ
    "gez": LanguageConfig(
        code="gez",
        name="Geʽez",
        native_name="ግዕዝ",
        emoji="🦁",
        alphabet_name="Geʽez",
        script=ScriptConfig(
            case="mixed",
            has_accents=False,
            notes="Geʽez script (Ethiopic/Eritrean classical language)",
        ),
    ),
    # 31. 🪔 Classical Tamil — சங்கத் தமிழ்
    "tam-old": LanguageConfig(
        code="tam-old",
        name="Classical Tamil",
        native_name="சங்கத் தமிழ்",
        emoji="🪔",
        alphabet_name="Tamil-Brahmi",
        script=ScriptConfig(
            case="mixed",
            has_accents=False,
            notes="Classical Tamil (Sangam period, c. 300 BCE-300 CE)",
        ),
    ),
    # 32. 🦅 Classical Armenian — ԳՐԱԲԱՐ
    "xcl": LanguageConfig(
        code="xcl",
        name="Classical Armenian",
        native_name="ԳՐԱԲԱՐ",
        emoji="🦅",
        alphabet_name="Armenian",
        script=ScriptConfig(
            case="upper",
            has_accents=False,
            notes="Classical Armenian (Grabar) in uppercase - ancient literary form",
        ),
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
            notes="Sogdian script (Silk Road trade language)",
        ),
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
            notes="Ugaritic cuneiform alphabet (earliest alphabetic cuneiform)",
        ),
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
            has_accents=True,
            notes="Tocharian A in Brahmi script with macrons (Tarim Basin Indo-European)",
        ),
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
            has_accents=True,
            notes="Tocharian B in Brahmi script with macrons (Tarim Basin Indo-European)",
        ),
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
    guidelines = []

    # Script form (native name shows authentic script)
    guidelines.append(f"Use script form: {config.native_name}")

    if config.script.case == "upper":
        guidelines.append("Use UPPERCASE letters only")
    elif config.script.case == "lower":
        guidelines.append("Use lowercase letters")
    else:
        guidelines.append("Use standard case conventions for this script")

    if config.script.has_accents:
        guidelines.append("Include all diacritical marks (accents, breathings, etc)")
    else:
        guidelines.append("Omit accents and diacritical marks")

    if config.script.char_v_for_u:
        guidelines.append("Use V instead of U (e.g., AVGVSTVS not AUGUSTUS)")

    if config.script.notes:
        guidelines.append(f"Historical note: {config.script.notes}")

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
