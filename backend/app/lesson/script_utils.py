"""Script transformation utilities for authentic ancient language rendering.

This module provides functions to transform text according to historically authentic
script conventions defined in language_config.py.

Features:
- Case transformation (uppercase/lowercase/mixed)
- Accent and diacritic removal
- V-for-U substitution (Latin)
- Scriptio continua (continuous writing without word spaces)
- Interpunct insertion (ancient word separator ·)
- Iota subscript → adscript conversion (Greek ᾳ → ΑΙ)
- Nomina sacra (sacred name abbreviations with overlines for Koine Greek)
"""

from __future__ import annotations

import re
import unicodedata
from typing import TYPE_CHECKING

from app.lesson.language_config import LanguageConfig, get_language_config

if TYPE_CHECKING:
    from app.api.schemas.script_preferences import ScriptDisplayMode


def apply_script_transform(text: str, language_code: str) -> str:
    """Transform text according to language-specific script rules.

    Args:
        text: The text to transform
        language_code: ISO 639-3 language code

    Returns:
        Transformed text following authentic script conventions
    """
    config = get_language_config(language_code)
    return apply_script_transform_with_config(text, config)


def apply_script_transform_with_config(text: str, config: LanguageConfig) -> str:
    """Transform text according to script configuration.

    Args:
        text: The text to transform
        config: Language configuration with script rules

    Returns:
        Transformed text following authentic script conventions
    """
    if not text:
        return text

    result = text

    # Apply character normalizations (e.g., J→I, U→V for Latin)
    if config.script.normalize_chars:
        for old_char, new_char in config.script.normalize_chars.items():
            result = result.replace(old_char, new_char)

    # Strip accents/diacritics if not wanted for this language
    if not config.script.has_accents:
        result = _remove_accents(result)

    # Apply case transformation
    if config.script.case == "upper":
        result = result.upper()
    elif config.script.case == "lower":
        result = result.lower()
    # "mixed" case leaves text as-is

    # Legacy support: Apply V for U transformation (Latin)
    # Note: Modern approach uses normalize_chars instead
    if config.script.char_v_for_u and not config.script.normalize_chars:
        result = result.replace("U", "V").replace("u", "v")

    # Apply scriptio continua if default for this language
    if config.script.scriptio_continua_default and config.script.word_separator is None:
        result = apply_scriptio_continua(result)

    # Apply word separator if configured
    if config.script.word_separator:
        result = _apply_word_separator(result, config.script.word_separator)

    return result


def _remove_accents(text: str) -> str:
    """Remove all diacritical marks from text.

    Uses Unicode normalization to decompose characters into base + combining marks,
    then strips the combining marks. Also handles Greek monotonic uppercase letters
    which are precomposed and don't decompose with NFD.

    Args:
        text: Text potentially containing diacritical marks

    Returns:
        Text with all diacritical marks removed
    """
    # Greek monotonic uppercase letters with tonos/dialytika that don't decompose
    # Map them to their unaccented forms
    greek_monotonic_map = {
        "\u0386": "\u0391",  # Ά → Α (Alpha with tonos)
        "\u0388": "\u0395",  # Έ → Ε (Epsilon with tonos)
        "\u0389": "\u0397",  # Ή → Η (Eta with tonos)
        "\u038a": "\u0399",  # Ί → Ι (Iota with tonos)
        "\u038c": "\u039f",  # Ό → Ο (Omicron with tonos)
        "\u038e": "\u03a5",  # Ύ → Υ (Upsilon with tonos)
        "\u038f": "\u03a9",  # Ώ → Ω (Omega with tonos)
        "\u03aa": "\u0399",  # Ϊ → Ι (Iota with dialytika)
        "\u03ab": "\u03a5",  # Ϋ → Υ (Upsilon with dialytika)
    }

    # Apply Greek monotonic replacements first
    result = text
    for accented, unaccented in greek_monotonic_map.items():
        result = result.replace(accented, unaccented)

    # Normalize to NFD (decomposed form) where accents are separate combining characters
    nfd = unicodedata.normalize("NFD", result)

    # Filter out combining characters (category Mn = Mark, Nonspacing)
    without_accents = "".join(char for char in nfd if unicodedata.category(char) != "Mn")

    # Normalize back to NFC (composed form)
    return unicodedata.normalize("NFC", without_accents)


def convert_iota_subscript_to_adscript(text: str) -> str:
    """Convert Greek iota subscripts to adscripts (full iota).

    Historical note: Ancient Greek inscriptions used full iota (adscript) written
    on the line, not subscript. The subscript form is a medieval innovation.

    Args:
        text: Greek text potentially containing iota subscripts

    Returns:
        Text with iota subscripts converted to full iotas

    Examples:
        >>> convert_iota_subscript_to_adscript("ᾳ")
        'ΑΙ'
        >>> convert_iota_subscript_to_adscript("τῷ λόγῳ")
        'ΤΩΙ ΛΟΓΩΙ'
    """
    # Map lowercase iota subscript vowels to vowel + I
    lowercase_map = {
        "ᾀ": "αι",  # alpha with psili and iota subscript
        "ᾁ": "αι",  # alpha with dasia and iota subscript
        "ᾂ": "αι",  # alpha with psili, varia, and iota subscript
        "ᾃ": "αι",  # alpha with dasia, varia, and iota subscript
        "ᾄ": "αι",  # alpha with psili, oxia, and iota subscript
        "ᾅ": "αι",  # alpha with dasia, oxia, and iota subscript
        "ᾆ": "αι",  # alpha with psili, perispomeni, and iota subscript
        "ᾇ": "αι",  # alpha with dasia, perispomeni, and iota subscript
        "ᾰ": "α",  # alpha with vrachy (no iota but sometimes confused)
        "ᾱ": "α",  # alpha with macron (no iota)
        "ᾳ": "αι",  # alpha with iota subscript (MOST COMMON)
        "ᾴ": "αι",  # alpha with oxia and iota subscript
        "ᾶ": "α",  # alpha with perispomeni (no iota)
        "ᾷ": "αι",  # alpha with perispomeni and iota subscript
        "ᾐ": "ηι",  # eta with psili and iota subscript
        "ᾑ": "ηι",  # eta with dasia and iota subscript
        "ᾒ": "ηι",  # eta with psili, varia, and iota subscript
        "ᾓ": "ηι",  # eta with dasia, varia, and iota subscript
        "ᾔ": "ηι",  # eta with psili, oxia, and iota subscript
        "ᾕ": "ηι",  # eta with dasia, oxia, and iota subscript
        "ᾖ": "ηι",  # eta with psili, perispomeni, and iota subscript
        "ᾗ": "ηι",  # eta with dasia, perispomeni, and iota subscript
        "ῃ": "ηι",  # eta with iota subscript (MOST COMMON)
        "ῄ": "ηι",  # eta with oxia and iota subscript
        "ῆ": "η",  # eta with perispomeni (no iota)
        "ῇ": "ηι",  # eta with perispomeni and iota subscript
        "ᾠ": "ωι",  # omega with psili and iota subscript
        "ᾡ": "ωι",  # omega with dasia and iota subscript
        "ᾢ": "ωι",  # omega with psili, varia, and iota subscript
        "ᾣ": "ωι",  # omega with dasia, varia, and iota subscript
        "ᾤ": "ωι",  # omega with psili, oxia, and iota subscript
        "ᾥ": "ωι",  # omega with dasia, oxia, and iota subscript
        "ᾦ": "ωι",  # omega with psili, perispomeni, and iota subscript
        "ᾧ": "ωι",  # omega with dasia, perispomeni, and iota subscript
        "ῳ": "ωι",  # omega with iota subscript (MOST COMMON)
        "ῴ": "ωι",  # omega with oxia and iota subscript
        "ῶ": "ω",  # omega with perispomeni (no iota)
        "ῷ": "ωι",  # omega with perispomeni and iota subscript
    }

    # Map uppercase iota subscript vowels to vowel + Ι
    uppercase_map = {
        "ᾈ": "ΑΙ",  # alpha with psili and prosgegrammeni
        "ᾉ": "ΑΙ",  # alpha with dasia and prosgegrammeni
        "ᾊ": "ΑΙ",  # alpha with psili, varia, and prosgegrammeni
        "ᾋ": "ΑΙ",  # alpha with dasia, varia, and prosgegrammeni
        "ᾌ": "ΑΙ",  # alpha with psili, oxia, and prosgegrammeni
        "ᾍ": "ΑΙ",  # alpha with dasia, oxia, and prosgegrammeni
        "ᾎ": "ΑΙ",  # alpha with psili, perispomeni, and prosgegrammeni
        "ᾏ": "ΑΙ",  # alpha with dasia, perispomeni, and prosgegrammeni
        "ᾼ": "ΑΙ",  # alpha with prosgegrammeni (MOST COMMON)
        "ᾘ": "ΗΙ",  # eta with psili and prosgegrammeni
        "ᾙ": "ΗΙ",  # eta with dasia and prosgegrammeni
        "ᾚ": "ΗΙ",  # eta with psili, varia, and prosgegrammeni
        "ᾛ": "ΗΙ",  # eta with dasia, varia, and prosgegrammeni
        "ᾜ": "ΗΙ",  # eta with psili, oxia, and prosgegrammeni
        "ᾝ": "ΗΙ",  # eta with dasia, oxia, and prosgegrammeni
        "ᾞ": "ΗΙ",  # eta with psili, perispomeni, and prosgegrammeni
        "ᾟ": "ΗΙ",  # eta with dasia, perispomeni, and prosgegrammeni
        "ῌ": "ΗΙ",  # eta with prosgegrammeni (MOST COMMON)
        "ᾨ": "ΩΙ",  # omega with psili and prosgegrammeni
        "ᾩ": "ΩΙ",  # omega with dasia and prosgegrammeni
        "ᾪ": "ΩΙ",  # omega with psili, varia, and prosgegrammeni
        "ᾫ": "ΩΙ",  # omega with dasia, varia, and prosgegrammeni
        "ᾬ": "ΩΙ",  # omega with psili, oxia, and prosgegrammeni
        "ᾭ": "ΩΙ",  # omega with dasia, oxia, and prosgegrammeni
        "ᾮ": "ΩΙ",  # omega with psili, perispomeni, and prosgegrammeni
        "ᾯ": "ΩΙ",  # omega with dasia, perispomeni, and prosgegrammeni
        "ῼ": "ΩΙ",  # omega with prosgegrammeni (MOST COMMON)
    }

    result = text
    for subscript, adscript in lowercase_map.items():
        result = result.replace(subscript, adscript)
    for subscript, adscript in uppercase_map.items():
        result = result.replace(subscript, adscript)

    return result


def apply_scriptio_continua(text: str) -> str:
    """Remove all word spaces to create scriptio continua (continuous writing).

    Historical note: Ancient Greek and Latin texts were written in scriptio continua
    without word separation. Word spaces are a medieval innovation.

    Args:
        text: Text with modern word spacing

    Returns:
        Text with all spaces removed (except line breaks)

    Examples:
        >>> apply_scriptio_continua("ΜΗΝΙΝ ΑΕΙΔΕ ΘΕΑ")
        'ΜΗΝΙΝΑΕΙΔΕΘΕΑ'
        >>> apply_scriptio_continua("ARMA VIRVMQVE CANO")
        'ARMAVIRVMQVECANO'
    """
    # Remove all spaces but preserve line breaks
    return re.sub(r"[ \t]+", "", text)


def apply_interpunct(text: str) -> str:
    """Replace word spaces with interpuncts (middle dots ·).

    Historical note: Some ancient inscriptions used interpuncts as word separators,
    though this was not universal. More common than scriptio continua in Latin
    inscriptions, less common in Greek.

    Args:
        text: Text with modern word spacing

    Returns:
        Text with spaces replaced by interpuncts

    Examples:
        >>> apply_interpunct("ARMA VIRVMQVE CANO")
        'ARMA·VIRVMQVE·CANO'
        >>> apply_interpunct("ΜΗΝΙΝ ΑΕΙΔΕ ΘΕΑ")
        'ΜΗΝΙΝ·ΑΕΙΔΕ·ΘΕΑ'
    """
    # Replace spaces with interpunct (U+00B7 MIDDLE DOT)
    return re.sub(r" +", "·", text.strip())


def _apply_word_separator(text: str, separator: str) -> str:
    """Apply a specific word separator character.

    Args:
        text: Text with spaces
        separator: Character to use as word separator

    Returns:
        Text with spaces replaced by separator
    """
    return re.sub(r" +", separator, text.strip())


def apply_nomina_sacra(text: str, language_code: str = "grc-koi") -> str:
    """Apply nomina sacra (sacred name abbreviations with overlines) to Koine Greek.

    Historical note: Early Christian manuscripts abbreviated sacred names (nomina sacra)
    with a line over the abbreviation. This was a distinctively Christian practice.

    Common nomina sacra:
    - ΘΣ (with overline) for ΘΕΟΣ (God)
    - ΚΣ (with overline) for ΚΥΡΙΟΣ (Lord)
    - ΙΣ (with overline) for ΙΗΣΟΥΣ (Jesus)
    - ΧΣ (with overline) for ΧΡΙΣΤΟΣ (Christ)
    - ΠΝΑ (with overline) for ΠΝΕΥΜΑ (Spirit)
    - ΥΣ (with overline) for ΥΙΟΣ (Son)
    - ΠΗΡ (with overline) for ΠΑΤΗΡ (Father)
    - ΜΗΡ (with overline) for ΜΗΤΗΡ (Mother)
    - ΑΝΟΣ (with overline) for ΑΝΘΡΩΠΟΣ (man/human)
    - ΔΑΔ (with overline) for ΔΑΥΙΔ (David)
    - ΙΗΛ (with overline) for ΙΣΡΑΗΛ (Israel)
    - ΙΛΗΜ (with overline) for ΙΕΡΟΥΣΑΛΗΜ (Jerusalem)

    Args:
        text: Koine Greek text
        language_code: Should be "grc-koi" (Koine Greek)

    Returns:
        Text with nomina sacra abbreviated and overlined

    Examples:
        >>> apply_nomina_sacra("ΘΕΟΣ", "grc-koi")
        'Θ͞Σ'
        >>> apply_nomina_sacra("ΚΥΡΙΟΣ ΙΗΣΟΥΣ ΧΡΙΣΤΟΣ", "grc-koi")
        'Κ͞Σ Ι͞Σ Χ͞Σ'
    """
    if language_code != "grc-koi":
        return text  # Only apply to Koine Greek

    # Unicode combining overline: U+035E
    OVERLINE = "\u035e"

    # Nomina sacra mappings (full word → abbreviated form)
    # Format: each letter gets an overline, e.g., ΘΣ → Θ͞Σ͞
    nomina_sacra = {
        # Most common (15 standard nomina sacra)
        "ΘΕΟΣ": f"Θ{OVERLINE}Σ{OVERLINE}",  # God
        "ΘΕΟΥ": f"Θ{OVERLINE}Υ{OVERLINE}",  # of God (genitive)
        "ΘΕΩΝ": f"Θ{OVERLINE}Ν{OVERLINE}",  # of gods (genitive plural)
        "ΚΥΡΙΟΣ": f"Κ{OVERLINE}Σ{OVERLINE}",  # Lord
        "ΚΥΡΙΟΥ": f"Κ{OVERLINE}Υ{OVERLINE}",  # of Lord (genitive)
        "ΚΥΡΙΩΝ": f"Κ{OVERLINE}Ν{OVERLINE}",  # of lords (genitive plural)
        "ΙΗΣΟΥΣ": f"Ι{OVERLINE}Σ{OVERLINE}",  # Jesus
        "ΙΗΣΟΥ": f"Ι{OVERLINE}Υ{OVERLINE}",  # of Jesus (genitive)
        "ΧΡΙΣΤΟΣ": f"Χ{OVERLINE}Σ{OVERLINE}",  # Christ
        "ΧΡΙΣΤΟΥ": f"Χ{OVERLINE}Υ{OVERLINE}",  # of Christ (genitive)
        "ΠΝΕΥΜΑ": f"Π{OVERLINE}Ν{OVERLINE}Α{OVERLINE}",  # Spirit
        "ΠΝΕΥΜΑΤΟΣ": f"Π{OVERLINE}Ν{OVERLINE}Σ{OVERLINE}",  # of Spirit (genitive)
        "ΥΙΟΣ": f"Υ{OVERLINE}Σ{OVERLINE}",  # Son
        "ΥΙΟΥ": f"Υ{OVERLINE}Υ{OVERLINE}",  # of Son (genitive)
        "ΠΑΤΗΡ": f"Π{OVERLINE}Η{OVERLINE}Ρ{OVERLINE}",  # Father
        "ΠΑΤΡΟΣ": f"Π{OVERLINE}Ρ{OVERLINE}Σ{OVERLINE}",  # of Father (genitive)
        "ΜΗΤΗΡ": f"Μ{OVERLINE}Η{OVERLINE}Ρ{OVERLINE}",  # Mother
        "ΜΗΤΡΟΣ": f"Μ{OVERLINE}Ρ{OVERLINE}Σ{OVERLINE}",  # of Mother (genitive)
        "ΑΝΘΡΩΠΟΣ": f"Α{OVERLINE}Ν{OVERLINE}Ο{OVERLINE}Σ{OVERLINE}",  # man/human
        "ΑΝΘΡΩΠΟΥ": f"Α{OVERLINE}Ν{OVERLINE}Ο{OVERLINE}Υ{OVERLINE}",  # of man (genitive)
        "ΟΥΡΑΝΟΣ": f"Ο{OVERLINE}Υ{OVERLINE}Ν{OVERLINE}Σ{OVERLINE}",  # heaven
        "ΟΥΡΑΝΟΥ": f"Ο{OVERLINE}Υ{OVERLINE}Ν{OVERLINE}Υ{OVERLINE}",  # of heaven (genitive)
        "ΙΣΡΑΗΛ": f"Ι{OVERLINE}Η{OVERLINE}Λ{OVERLINE}",  # Israel
        "ΔΑΥΙΔ": f"Δ{OVERLINE}Α{OVERLINE}Δ{OVERLINE}",  # David
        "ΙΕΡΟΥΣΑΛΗΜ": f"Ι{OVERLINE}Λ{OVERLINE}Η{OVERLINE}Μ{OVERLINE}",  # Jerusalem
        "ΣΤΑΥΡΟΣ": f"Σ{OVERLINE}Τ{OVERLINE}Σ{OVERLINE}",  # cross
    }

    result = text
    # Sort by length (longest first) to avoid partial replacements
    for full_word, abbreviated in sorted(nomina_sacra.items(), key=lambda x: -len(x[0])):
        # Use word boundary matching to avoid replacing parts of words
        result = re.sub(rf"\b{full_word}\b", abbreviated, result)

    return result


def remove_modern_punctuation(text: str, language_code: str) -> str:
    """Remove modern punctuation marks not used in ancient manuscripts.

    Historical note: Ancient Greek and Latin manuscripts did not use modern
    punctuation like commas, periods, question marks, or exclamation marks.
    Some ancient texts used high dots (·) for major pauses, but most used
    no punctuation at all.

    Args:
        text: Text potentially containing modern punctuation
        language_code: Language code (e.g., "grc", "lat", "grc-koi")

    Returns:
        Text with modern punctuation removed or replaced

    Examples:
        >>> remove_modern_punctuation("ΧΑΙΡΕ, Ω ΦΙΛΕ!", "grc")
        'ΧΑΙΡΕ Ω ΦΙΛΕ'
        >>> remove_modern_punctuation("SALVE, AMICE.", "lat")
        'SALVE AMICE'
    """
    # Remove modern punctuation marks
    modern_punctuation = {
        "?": "",  # Question mark (not ancient)
        "!": "",  # Exclamation mark (not ancient)
        ",": " ",  # Comma (replace with space)
        ";": " ",  # Semicolon (especially not ancient Greek - this is modern question mark!)
        ":": " ",  # Colon (not ancient)
        ".": " ",  # Period (not ancient in this form)
        '"': "",  # Quotation marks
        "'": "",  # Apostrophe (except in Greek elision)
        "—": " ",  # Em dash
        "–": " ",  # En dash
        "(": "",  # Parentheses
        ")": "",
        "[": "",  # Brackets
        "]": "",
    }

    result = text
    for punct, replacement in modern_punctuation.items():
        result = result.replace(punct, replacement)

    # Clean up multiple spaces
    result = re.sub(r" +", " ", result).strip()

    return result


def get_alphabet_for_language(language_code: str) -> list[str]:
    """Get the alphabet/script characters for a language.

    Returns the basic character set used in authentic scripts.
    For languages without predefined alphabets, extracts unique characters
    from the language's native name as a fallback.

    Args:
        language_code: ISO 639-3 language code

    Returns:
        List of characters in the script
    """
    config = get_language_config(language_code)

    # Greek alphabet (uppercase without accents)
    if language_code in ("grc", "grc-koi"):
        return list("ΑΒΓΔΕΖΗΘΙΚΛΜΝΞΟΠΡΣΤΥΦΧΨΩ")

    # Latin alphabet (uppercase, with V not U)
    if language_code == "lat":
        return list("ABCDEFGHIKLMNOPQRSTVXYZ")

    # Hebrew alphabet
    if language_code in ("hbo", "hbo-paleo"):
        return list("אבגדהוזחטיכלמנסעפצקרשת")

    # Arabic alphabet (basic forms)
    if language_code == "ara":
        return list("ابتثجحخدذرزسشصضطظعغفقكلمنهوي")

    # Cyrillic (for Old Church Slavonic)
    if language_code == "cu":
        return list("АБВГДЕЖЗИІКЛМНОПРСТОУФХЦЧШЩЪЫЬѢЮѦѪѨѬѮѰѲѴ")

    # Sanskrit Devanagari alphabet
    if language_code in ("san", "san-ved"):
        return list("अआइईउऊऋॠऌॡएऐओऔकखगघङचछजझञटठडढणतथदधनपफबभमयरलवशषसह")

    # Pali (uses various scripts, Devanagari common)
    if language_code == "pli":
        return list("अआइईउऊएओकखगघङचछजझञटठडढणतथदधनपफबभमयरलवशसह")

    # Old Norse (Latin alphabet with additional characters)
    if language_code == "non":
        return list("AÁBDÐEÉFGHIÍJKLMNOPQRSTUÚVXYÝÞÆŒ")

    # Old English (Anglo-Saxon runes or Latin)
    if language_code == "ang":
        return list("ABCDEFGHILMNOPRSTVXYZÆÐÞǷ")

    # Coptic alphabet
    if language_code == "cop":
        return list("ⲀⲂⲄⲆⲈⲌⲎⲐⲒⲔⲖⲘⲚⲜⲞⲠⲢⲤⲦⲨⲪⲬⲮⲰϢϤϦϨϪϬϮ")

    # Armenian alphabet
    if language_code in ("xcl", "hye"):
        return list("ԱԲԳԴԵԶԷԸԹԺԻԼԽԾԿՀՁՂՃՄՅՆՇՈՉՊՋՌՍՎՏՐՑՒՓՔՕՖ")

    # Georgian alphabet
    if language_code == "kat":
        return list("აბგდევზთიკლმნოპჟრსტუფქღყშჩცძწჭხჯჰ")

    # Gothic alphabet
    if language_code == "got":
        return list("𐌰𐌱𐌲𐌳𐌴𐌵𐌶𐌷𐌸𐌹𐌺𐌻𐌼𐌽𐌾𐌿𐍀𐍁𐍂𐍃𐍄𐍅𐍆𐍇𐍈𐍉𐍊")

    # Old Irish (Latin with special characters)
    if language_code == "sga":
        return list("ABCDEFGHILMNOPRSTUVÉÍÓÚ")

    # Syriac alphabet
    if language_code == "syc":
        return list("ܐܒܓܕܗܘܙܚܛܝܟܠܡܢܣܥܦܨܩܪܫܬ")

    # Aramaic (similar to Hebrew/Syriac)
    if language_code == "arc":
        return list("𐡀𐡁𐡂𐡃𐡄𐡅𐡆𐡇𐡈𐡉𐡊𐡋𐡌𐡍𐡎𐡏𐡐𐡑𐡒𐡓𐡔𐡕")

    # Avestan
    if language_code == "ave":
        return list("𐬀𐬁𐬂𐬃𐬄𐬅𐬆𐬇𐬈𐬉𐬊𐬋𐬌𐬍𐬎𐬏𐬐𐬑𐬒𐬓𐬔𐬕𐬖𐬗𐬘𐬙𐬚𐬛𐬜𐬝𐬞")

    # Classical Chinese (sample common radicals/characters)
    if language_code == "lzh":
        return list("一二三四五六七八九十人天地水火木金土日月山川")

    # Classical Japanese (sample Kanji + Kana)
    if language_code == "ojp":
        return list("あいうえおかきくけこさしすせそたちつてとなにぬねの")

    # Classical Tibetan
    if language_code == "bod":
        return list("ཀཁགངཅཆཇཉཏཐདནཔཕབམཙཚཛཝཞཟའཡརལཤསཧཨ")

    # Classical Nahuatl (Latin alphabet)
    if language_code == "nci":
        return list("ACEHILMNOPQTUVXYZ")

    # Classical Quechua (Latin alphabet)
    if language_code == "qwh":
        return list("ACHIKLMNPQRSTUVWY")

    # Akkadian (cuneiform - using transliteration Latin)
    if language_code == "akk":
        return list("ABDEGHIKLMNPQRSŠTUVWYZṢṬ")

    # Sumerian (cuneiform - using transliteration)
    if language_code == "sux":
        return list("ABDEGHIKLMNPRSTUVZ")

    # Hittite (cuneiform - using transliteration)
    if language_code == "hit":
        return list("ABDEGHIKLMNPRSTUVWZ")

    # Middle Persian/Pahlavi (using Pahlavi script sample)
    if language_code == "pal":
        return list("𐭠𐭡𐭢𐭣𐭤𐭥𐭦𐭧𐭨𐭩𐭪𐭫𐭬𐭭𐭮𐭯𐭰𐭱𐭲")

    # Old Egyptian/Middle Egyptian (hieroglyphs - using transliteration)
    if language_code in ("egy-old", "egy"):
        return list("ꜢBDEFGHḤIKMNPQRSŠTVWYZ")

    # For any other language, extract unique characters from native name
    # This ensures alphabet tasks can work for all languages
    unique_chars = []
    for char in config.native_name:
        if char.isalpha() and char not in unique_chars:
            unique_chars.append(char)

    # Need at least 4 characters for alphabet task
    if len(unique_chars) >= 4:
        return unique_chars

    # Ultimate fallback - use English alphabet
    return list("ABCDEFGHIJKLMNOPQRSTUVWXYZ")


def apply_script_preferences(
    text: str,
    language_code: str,
    preferences: "ScriptDisplayMode | None" = None,
    authentic_mode: bool = False,
    use_scriptio_continua: bool = False,
    use_interpuncts: bool = False,
    use_iota_adscript: bool = True,
    use_nomina_sacra: bool = False,
    remove_punctuation: bool = False,
) -> str:
    """Apply user script display preferences to text.

    This is the main function for rendering text with user preferences.
    It orchestrates all the transformation functions based on user settings.

    Args:
        text: The text to transform
        language_code: ISO 639-3 language code (e.g., "grc", "lat", "grc-koi")
        preferences: ScriptDisplayMode object with all preferences (if provided, overrides individual params)
        authentic_mode: Apply authentic script transformations (uppercase, no accents, V-for-U)
        use_scriptio_continua: Remove word spaces (continuous writing)
        use_interpuncts: Replace spaces with interpuncts (·)
        use_iota_adscript: Convert Greek iota subscripts to adscripts (ᾳ → ΑΙ)
        use_nomina_sacra: Apply sacred name abbreviations (Koine Greek only)
        remove_punctuation: Remove modern punctuation marks

    Returns:
        Transformed text with all requested transformations applied

    Examples:
        >>> # Modern edition
        >>> apply_script_preferences("χαῖρε, ὦ φίλε", "grc")
        'χαῖρε, ὦ φίλε'

        >>> # Authentic mode
        >>> apply_script_preferences("χαῖρε, ὦ φίλε", "grc", authentic_mode=True)
        'ΧΑΙΡΕ Ω ΦΙΛΕ'

        >>> # Authentic with interpuncts
        >>> apply_script_preferences("χαῖρε, ὦ φίλε", "grc",
        ...                          authentic_mode=True, use_interpuncts=True)
        'ΧΑΙΡΕ·Ω·ΦΙΛΕ'

        >>> # Koine with nomina sacra
        >>> apply_script_preferences("ὁ θεὸς καὶ ὁ κύριος", "grc-koi",
        ...                          authentic_mode=True, use_nomina_sacra=True)
        'Ο Θ͞Σ͞ ΚΑΙ Ο Κ͞Σ͞'
    """
    if not text:
        return text

    # If preferences object provided, extract values from it
    if preferences:
        use_scriptio_continua = preferences.use_scriptio_continua
        use_interpuncts = preferences.use_interpuncts
        use_iota_adscript = preferences.use_iota_adscript
        use_nomina_sacra = preferences.use_nomina_sacra
        remove_punctuation = preferences.remove_modern_punctuation

    result = text

    # Step 1: Apply authentic mode transformations (case, accents, V-for-U)
    if authentic_mode:
        result = apply_script_transform(result, language_code)

    # Step 2: Greek iota subscript → adscript conversion (if requested and Greek)
    if use_iota_adscript and language_code in ("grc", "grc-koi"):
        result = convert_iota_subscript_to_adscript(result)

    # Step 3: Remove modern punctuation (if requested)
    if remove_punctuation:
        result = remove_modern_punctuation(result, language_code)

    # Step 4: Apply nomina sacra (Koine Greek only, if requested)
    if use_nomina_sacra and language_code == "grc-koi":
        result = apply_nomina_sacra(result, language_code)

    # Step 5: Word separation (mutually exclusive: scriptio continua OR interpuncts)
    if use_scriptio_continua:
        result = apply_scriptio_continua(result)
    elif use_interpuncts:
        result = apply_interpunct(result)

    return result


def convert_lunate_sigma_to_regular(text: str) -> str:
    """Convert lunate sigma (Ϲ/ϲ) to regular sigma (Σ/σ).

    Historical note: While lunate sigma was used in some later manuscripts,
    classical Greek inscriptions used only the regular sigma form.
    For authentic classical/Koine display, encode all sigmas as Σ.

    Args:
        text: Greek text potentially containing lunate sigma

    Returns:
        Text with lunate sigma converted to regular sigma

    Examples:
        >>> convert_lunate_sigma_to_regular("ΚΥΡΙΟϹ")
        'ΚΥΡΙΟΣ'
        >>> convert_lunate_sigma_to_regular("ϲοφία")
        'σοφία'
    """
    # U+03F9 GREEK CAPITAL LUNATE SIGMA SYMBOL → Σ
    # U+03F2 GREEK LUNATE SIGMA SYMBOL → σ
    # U+03FD GREEK CAPITAL REVERSED LUNATE SIGMA SYMBOL → Σ
    # U+037C GREEK SMALL DOTTED LUNATE SIGMA SYMBOL → σ
    # U+037D GREEK SMALL REVERSED DOTTED LUNATE SIGMA SYMBOL → σ
    replacements = {
        "\u03f9": "Σ",  # GREEK CAPITAL LUNATE SIGMA SYMBOL (Ϲ)
        "\u03f2": "σ",  # GREEK LUNATE SIGMA SYMBOL (ϲ)
        "\u03fd": "Σ",  # GREEK CAPITAL REVERSED LUNATE SIGMA SYMBOL
        "\u037c": "σ",  # GREEK SMALL DOTTED LUNATE SIGMA SYMBOL
        "\u037d": "σ",  # GREEK SMALL REVERSED DOTTED LUNATE SIGMA SYMBOL
    }
    result = text
    for lunate, regular in replacements.items():
        result = result.replace(lunate, regular)
    return result


def preserve_greek_punctuation_unicode(text: str) -> str:
    """Preserve Greek-specific punctuation Unicode code points.

    Important: Some Greek punctuation marks are canonically equivalent to
    Latin punctuation, but should be preserved as distinct code points
    for historical authenticity.

    Args:
        text: Text with potential Greek punctuation

    Returns:
        Text with Greek punctuation Unicode preserved
    """
    # This function would be used AFTER any Unicode normalization
    # to remap back to the Greek-specific code points
    # U+037E (Greek question mark) ≡ U+003B (semicolon) - preserve U+037E
    # U+0387 (ano teleia) ≡ U+00B7 (middle dot) - preserve U+0387
    # In practice, we ensure these are NEVER normalized away in the first place
    return text


def remove_hebrew_vowel_points(text: str) -> str:
    """Remove Masoretic vowel points (niqqud) and cantillation marks from Hebrew text.

    For authentic Biblical Hebrew display (consonantal text only),
    this removes all later Masoretic additions.

    Args:
        text: Hebrew text potentially with niqqud and te'amim

    Returns:
        Hebrew text with only consonants (and matres lectionis)

    Examples:
        >>> remove_hebrew_vowel_points("בְּרֵאשִׁית")
        'בראשית'
    """
    # Niqqud (vowel points): U+05B0–U+05BD, U+05BF, U+05C1–U+05C2, U+05C4–U+05C5, U+05C7
    # Cantillation marks (te'amim): U+0591–U+05AF, U+05BD, U+05BF, U+05C0, U+05C3, U+05C6
    # Also remove other Masoretic marks
    result = text
    # Use NFD to decompose characters
    result = unicodedata.normalize("NFD", result)
    # Remove all combining marks in the Hebrew vowel and cantillation ranges
    result = re.sub(r"[\u0591-\u05C7]", "", result)
    # Normalize back to NFC
    result = unicodedata.normalize("NFC", result)
    return result


def remove_syriac_vowel_points(text: str) -> str:
    """Remove Syriac vowel pointing systems (both Eastern and Western).

    For authentic Classical Syriac (Estrangelā), suppress all later
    vowel pointing additions.

    Args:
        text: Syriac text potentially with vowel points

    Returns:
        Syriac text without vowel points

    Examples:
        >>> remove_syriac_vowel_points("ܡܰܠܟܳܐ")
        'ܡܠܟܐ'
    """
    # Syriac vowel points and diacritics: U+0730–U+074A
    result = text
    result = unicodedata.normalize("NFD", result)
    result = re.sub(r"[\u0730-\u074A]", "", result)
    result = unicodedata.normalize("NFC", result)
    return result


def remove_arabic_diacritics_full(text: str) -> str:
    """Remove all Arabic diacritics (ḥarakāt, šadda, tanwīn, etc.).

    For authentic early Quranic rasm (consonantal skeleton), remove all
    vowel marks and diacritical points.

    Args:
        text: Arabic text with diacritics

    Returns:
        Arabic text as consonantal skeleton (rasm)

    Examples:
        >>> remove_arabic_diacritics_full("بِسْمِ اللَّهِ")
        'بسم الله'
    """
    # Arabic diacritics: U+064B–U+065F (ḥarakāt, tanwīn, šadda, sukūn, etc.)
    # Optional: Also remove consonantal diacritical dots for full rasm authenticity
    # (This would be a separate toggle)
    result = text
    result = unicodedata.normalize("NFD", result)
    # Remove all Arabic diacritical marks
    result = re.sub(r"[\u064B-\u065F]", "", result)
    result = unicodedata.normalize("NFC", result)
    return result


def apply_latin_character_normalization(text: str) -> str:
    """Apply Latin character normalizations for Classical Latin.

    Normalizations:
    - J → I
    - U → V
    - W → VV
    - Æ → AE
    - Œ → OE

    Args:
        text: Latin text with modern characters

    Returns:
        Latin text with classical character inventory

    Examples:
        >>> apply_latin_character_normalization("IVLIVS")
        'IVLIVS'
        >>> apply_latin_character_normalization("JULIUS")
        'IULIUS'
        >>> apply_latin_character_normalization("CÆSAR")
        'CAESAR'
    """
    normalizations = {
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
    }
    result = text
    for old, new in normalizations.items():
        result = result.replace(old, new)
    return result


def apply_ethiopic_word_separator(text: str) -> str:
    """Apply Ethiopic wordspace (፡) between words for Geʽez.

    Args:
        text: Ethiopic text with spaces

    Returns:
        Text with spaces replaced by Ethiopic wordspace

    Examples:
        >>> apply_ethiopic_word_separator("ግዕዝ ቋንቋ")
        'ግዕዝ፡ቋንቋ'
    """
    # Replace spaces with ETHIOPIC WORDSPACE U+1361
    return re.sub(r" +", "፡", text.strip())


def apply_tibetan_tsheg(text: str) -> str:
    """Apply Tibetan tsheg (་) after each syllable.

    Args:
        text: Tibetan text

    Returns:
        Text with tsheg properly placed

    Note:
        This is a simplified version. In practice, proper tsheg placement
        requires understanding Tibetan syllable structure.
    """
    # Simplified: add tsheg after spaces if not already present
    # Full implementation would require Tibetan syllable analysis
    result = text
    if "་" not in result:
        result = re.sub(r" +", "་", result)
    return result


def apply_ugaritic_word_divider(text: str) -> str:
    """Apply Ugaritic word divider (𐎟) between every word.

    Args:
        text: Ugaritic text with spaces

    Returns:
        Text with Ugaritic word divider between words

    Examples:
        >>> apply_ugaritic_word_divider("𐎜𐎂𐎗𐎚 𐎛𐎐")
        '𐎜𐎂𐎗𐎚𐎟𐎛𐎐'
    """
    # Replace spaces with UGARITIC WORD DIVIDER U+1039F
    return re.sub(r" +", "𐎟", text.strip())


def apply_gothic_interpunct(text: str) -> str:
    """Apply Gothic mandatory interpunct (·) between words.

    Args:
        text: Gothic text with spaces

    Returns:
        Text with interpunct between words

    Examples:
        >>> apply_gothic_interpunct("𐌲𐌿𐍄𐌹𐍃𐌺 𐍂𐌰𐌶𐌳𐌰")
        '𐌲𐌿𐍄𐌹𐍃𐌺·𐍂𐌰𐌶𐌳𐌰'
    """
    # Gothic uses middle dot (U+00B7) between words per Codex Argenteus
    return re.sub(r" +", "·", text.strip())


def apply_ogham_markers(text: str) -> str:
    """Add Ogham start and end marks to text.

    Args:
        text: Ogham text

    Returns:
        Text wrapped with Ogham start (᚛) and end (᚜) marks

    Examples:
        >>> apply_ogham_markers("ᚌᚑᚔᚇᚓᚂᚉ")
        '᚛ᚌᚑᚔᚇᚓᚂᚉ᚜'
    """
    # Add OGHAM START MARK U+169B and END MARK U+169C
    if not text.startswith("᚛"):
        text = "᚛" + text
    if not text.endswith("᚜"):
        text = text + "᚜"
    return text


def validate_script_authenticity(text: str, language_code: str) -> bool:
    """Check if text follows authentic script conventions for the language.

    Args:
        text: Text to validate
        language_code: ISO 639-3 language code

    Returns:
        True if text appears to follow script conventions
    """
    if not text:
        return True

    config = get_language_config(language_code)

    # Check case conventions
    if config.script.case == "upper":
        # Should be mostly uppercase
        upper_ratio = sum(1 for c in text if c.isupper()) / max(1, sum(1 for c in text if c.isalpha()))
        if upper_ratio < 0.8:  # Allow some flexibility
            return False

    # Check for U in Latin text when V should be used
    if config.script.char_v_for_u:
        if "U" in text or "u" in text:
            return False

    return True
