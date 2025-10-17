"""Language-specific configuration for authentic script and vocabulary.

This module centralizes language-specific data to make it easy to add new languages
without modifying provider code.
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
    """Display name"""

    script: ScriptConfig
    """Script rendering rules"""

    alphabet_name: str | None = None
    """Name of alphabet (e.g., 'Greek', 'Latin', 'Hebrew')"""


# Language configurations - edit this to add new languages or change script rules
LANGUAGES: dict[str, LanguageConfig] = {
    "grc": LanguageConfig(
        code="grc",
        name="Classical Greek",
        alphabet_name="Greek",
        script=ScriptConfig(
            case="lower",
            has_accents=True,
            notes="Using polytonic lowercase for modern pedagogical clarity. "
            "Authentic epigraphy was UPPERCASE without accents, but polytonic "
            "aids learning pronunciation and morphology.",
        ),
    ),
    "lat": LanguageConfig(
        code="lat",
        name="Latin",
        alphabet_name="Latin",
        script=ScriptConfig(
            case="upper",
            has_accents=False,
            char_v_for_u=True,
            notes="Classical Latin used UPPERCASE with V (no U). Example: AVGVSTVS not AUGUSTUS",
        ),
    ),
    "hbo": LanguageConfig(
        code="hbo",
        name="Biblical Hebrew",
        alphabet_name="Hebrew",
        script=ScriptConfig(
            case="mixed",  # Hebrew has no case distinction
            has_accents=True,  # Includes niqqud (vowel points)
            notes="Hebrew script with niqqud (vowel pointing) for clarity",
        ),
    ),
    "san": LanguageConfig(
        code="san",
        name="Sanskrit",
        alphabet_name="Devanagari",
        script=ScriptConfig(
            case="mixed",
            has_accents=False,  # Devanagari vowels are built into characters
            notes="Devanagari script - vowels are diacritics on consonants",
        ),
    ),
    "cop": LanguageConfig(
        code="cop",
        name="Coptic",
        alphabet_name="Coptic",
        script=ScriptConfig(
            case="mixed",
            has_accents=False,
            notes="Coptic alphabet derived from Greek + demotic Egyptian",
        ),
    ),
    "egy": LanguageConfig(
        code="egy",
        name="Egyptian",
        alphabet_name="Egyptian",
        script=ScriptConfig(
            case="mixed",
            has_accents=False,
            notes="Hieroglyphic transliteration",
        ),
    ),
    "akk": LanguageConfig(
        code="akk",
        name="Akkadian",
        alphabet_name="Cuneiform",
        script=ScriptConfig(
            case="mixed",
            has_accents=False,
            notes="Cuneiform transliteration",
        ),
    ),
    "pli": LanguageConfig(
        code="pli",
        name="Pali",
        alphabet_name="Devanagari",
        script=ScriptConfig(
            case="mixed",
            has_accents=False,
            notes="Usually written in Devanagari or Latin transliteration",
        ),
    ),
    "gem-pro": LanguageConfig(
        code="gem-pro",
        name="Proto-Germanic",
        alphabet_name="Latin",
        script=ScriptConfig(
            case="lower",
            has_accents=False,
            notes="Reconstructed language, usually in Latin transcription",
        ),
    ),
    "non-pro": LanguageConfig(
        code="non-pro",
        name="Proto-Norse",
        alphabet_name="Elder Futhark",
        script=ScriptConfig(
            case="mixed",
            has_accents=False,
            notes="Runic script (Elder Futhark)",
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
        guidelines.append(f"Note: {config.script.notes}")

    return ". ".join(guidelines) + "."


def get_supported_languages() -> list[str]:
    """Get list of supported language codes."""
    return list(LANGUAGES.keys())
