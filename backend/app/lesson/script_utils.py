"""Script transformation utilities for authentic ancient language rendering.

This module provides functions to transform text according to historically authentic
script conventions defined in language_config.py.
"""

import unicodedata

from app.lesson.language_config import LanguageConfig, get_language_config


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

    # Strip accents/diacritics if not wanted for this language
    if not config.script.has_accents:
        result = _remove_accents(result)

    # Apply case transformation
    if config.script.case == "upper":
        result = result.upper()
    elif config.script.case == "lower":
        result = result.lower()
    # "mixed" case leaves text as-is

    # Apply V for U transformation (Latin)
    if config.script.char_v_for_u:
        result = result.replace("U", "V").replace("u", "v")

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
