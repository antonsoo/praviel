"""Historical persona system prompts for conversational immersion"""

from __future__ import annotations

from pathlib import Path

# Load persona prompts from external text files
_PROMPTS_DIR = Path(__file__).parent / "persona_prompts"


def _load_persona_prompt(filename: str) -> str:
    """Load persona system prompt from external file."""
    file_path = _PROMPTS_DIR / filename
    return file_path.read_text(encoding="utf-8")


PERSONAS: dict[str, dict[str, str]] = {
    "athenian_merchant": {
        "name": "Kleisthenes",
        "era": "400 BCE, Classical Athens",
        "context": "Athenian agora merchant selling olive oil, wine, pottery",
        "system_prompt": _load_persona_prompt("athenian_merchant.txt"),
    },
    "spartan_warrior": {
        "name": "Brasidas",
        "era": "420 BCE, Sparta",
        "context": "Spartan hoplite discussing military training and philosophy",
        "system_prompt": _load_persona_prompt("spartan_warrior.txt"),
    },
    "athenian_philosopher": {
        "name": "Sokrates",
        "era": "410 BCE, Classical Athens",
        "context": "Philosopher engaging in Socratic dialogue",
        "system_prompt": _load_persona_prompt("athenian_philosopher.txt"),
    },
    "roman_senator": {
        "name": "Marcus Tullius",
        "era": "50 BCE, Late Roman Republic",
        "context": "Roman senator discussing politics and law",
        "system_prompt": _load_persona_prompt("roman_senator.txt"),
    },
}


def get_persona_prompt(persona: str) -> str:
    """Get system prompt for a persona"""
    if persona not in PERSONAS:
        # Default to athenian_merchant
        persona = "athenian_merchant"
    return PERSONAS[persona]["system_prompt"]


def list_personas() -> list[str]:
    """List available persona IDs"""
    return list(PERSONAS.keys())
