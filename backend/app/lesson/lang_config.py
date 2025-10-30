"""Language-specific configuration for lesson generation.

This module provides language-specific prompts and script instructions
for AI-powered lesson generation, dynamically pulling from the comprehensive
language configuration system.
"""


def get_system_prompt(language: str = "grc-cls") -> str:
    """Get language-specific system prompt for lesson generation.

    Args:
        language: ISO 639-3 language code

    Returns:
        System prompt with script instructions for AI
    """
    from app.lesson.language_config import get_language_config, get_script_guidelines

    try:
        lang_config = get_language_config(language)
    except ValueError:
        # Fallback to Classical Greek if language not found
        lang_config = get_language_config("grc-cls")

    # Get comprehensive script guidelines
    script_guidelines = get_script_guidelines(language)

    return (
        f"You are an expert pedagogue designing {lang_config.name} lessons. "
        "Generate exercises that match the requested types. "
        'Output ONLY valid JSON with structure: {"tasks": [...]}\n'
        "Each task must follow the exact JSON schema specified in the prompts. "
        f"Use proper {lang_config.native_name} script. "
        f"\n\n{script_guidelines}"  # Include comprehensive script guidelines
    )


def get_pedagogy_core(language: str = "grc-cls") -> str:
    """Get language-specific pedagogy instructions.

    Args:
        language: ISO 639-3 language code

    Returns:
        Pedagogical instructions with script guidelines
    """
    from app.lesson.language_config import get_language_config, get_script_guidelines

    try:
        lang_config = get_language_config(language)
    except ValueError:
        lang_config = get_language_config("grc-cls")

    script_guidelines = get_script_guidelines(language)

    return f"""
You are an expert pedagogue teaching {lang_config.name}.

**Pedagogical Principles:**
- Beginner students need simple vocabulary, clear patterns, repetition
- Intermediate students can handle complex syntax, compound sentences, nuance
- Always use proper {lang_config.native_name} script
- Distractors should be morphologically plausible but semantically wrong
- Provide scaffolding: easier exercises build skills for harder ones

**CRITICAL - Authentic Script Guidelines:**
{script_guidelines}
"""
