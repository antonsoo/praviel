"""Language-specific configuration for lesson generation."""

LANGUAGE_CONFIGS = {
    "grc": {
        "name": "Classical Greek (Koine)",
        "native_field": "grc",
        "script_instruction": """**CRITICAL - Historical Script Authenticity:**
- Use CAPITAL LETTERS ONLY for all Greek text (e.g., ΧΑΙΡΕ, not χαῖρε)
- Classical Greek was written in scriptio continua with capitals only
- Lowercase (minuscule) letters were a medieval innovation (9th century CE)
- Keep polytonic accents and breathing marks (they ARE ancient)
- Use capital sigma Σ everywhere, including word-final (no ς)
- Examples: ΜΗΝΙΝ ΑΕΙΔΕ ΘΕΑ, ΧΑΙΡΕ, ΝΑΙ, ΟΥ""",
        "text_format": "polytonic Greek (NFC normalized Unicode)",
        "example_match": '{"grc": "ΧΑΙΡΕ", "en": "Hello"}',
        "example_translate": '"direction": "grc->en", "text": "ΧΑΙΡΕ· ΤΙ ΚΑΝΕΙΣ;"',
    },
    "lat": {
        "name": "Classical Latin",
        "native_field": "lat",
        "script_instruction": """**CRITICAL - Historical Script Authenticity:**
- Use CAPITAL LETTERS ONLY with V (not U) for all Latin text
- Examples: SALVÉ, QVID AGIS?, BONVS, VIRTVS (not salve, quid agis?, bonus, virtus)
- Classical Latin inscriptions used capitals only (as seen on Trajan's Column)
- Replace all U with V (both vowel and consonant uses)
- May use macrons for pedagogical clarity: Á, É, Í, Ó, Ú""",
        "text_format": "Classical Latin with capitals and V",
        "example_match": '{"lat": "SALVÉ", "en": "Hello"}',
        "example_translate": '"direction": "lat->en", "text": "SALVÉ· QVID AGIS?"',
    },
    "hbo": {
        "name": "Biblical Hebrew",
        "native_field": "hbo",
        "script_instruction": """**CRITICAL - Historical Script Authenticity:**
- Use Hebrew script (right-to-left)
- Include pointing (nikud) for learners: עִבְרִית
- No romanization - always use native Hebrew script""",
        "text_format": "Hebrew script with nikud (right-to-left)",
        "example_match": '{"hbo": "שָׁלוֹם", "en": "Peace/Hello"}',
        "example_translate": '"direction": "hbo->en", "text": "שָׁלוֹם"',
    },
    "san": {
        "name": "Sanskrit",
        "native_field": "san",
        "script_instruction": """**CRITICAL - Historical Script Authenticity:**
- Use Devanagari script only: संस्कृतम्
- No romanization - always use native Devanagari
- Include all diacriticals (anusvara, visarga, etc.)""",
        "text_format": "Devanagari script",
        "example_match": '{"san": "नमस्ते", "en": "Greetings"}',
        "example_translate": '"direction": "san->en", "text": "नमस्ते"',
    },
}


def get_system_prompt(language: str = "grc") -> str:
    """Get language-specific system prompt for lesson generation."""
    config = LANGUAGE_CONFIGS.get(language, LANGUAGE_CONFIGS["grc"])
    return (
        f"You are an expert pedagogue designing {config['name']} lessons. "
        "Generate exercises that match the requested types. "
        'Output ONLY valid JSON with structure: {"tasks": [...]}\n'
        "Each task must follow the exact JSON schema specified in the prompts. "
        f"Use proper {config['text_format']}. "
        f"\n\n{config['script_instruction']}"  # Include full script instructions
    )


def get_pedagogy_core(language: str = "grc") -> str:
    """Get language-specific pedagogy instructions."""
    config = LANGUAGE_CONFIGS.get(language, LANGUAGE_CONFIGS["grc"])
    return f"""
You are an expert pedagogue teaching {config["name"]}.

**Pedagogical Principles:**
- Beginner students need simple vocabulary, clear patterns, repetition
- Intermediate students can handle complex syntax, compound sentences, nuance
- Always use proper {config["text_format"]}
- Distractors should be morphologically plausible but semantically wrong
- Provide scaffolding: easier exercises build skills for harder ones

{config["script_instruction"]}
"""
