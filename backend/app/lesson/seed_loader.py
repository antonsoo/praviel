"""Lesson seed data loader for team-authored daily phrases and canonical references."""

from __future__ import annotations

import unicodedata
from functools import lru_cache
from pathlib import Path

import yaml


def load_daily_seeds(language: str) -> list[dict]:
    """Load team-authored daily phrases."""
    seed_file = Path(__file__).parent / "seed" / f"daily_{language}.yaml"
    if not seed_file.exists():
        return []

    with open(seed_file, encoding="utf-8") as f:
        data = yaml.safe_load(f)

    return data.get(f"daily_{language}", [])


def load_canonical_refs(language: str) -> list[str]:
    """Load canonical refs (text fetched from LDS at runtime)."""
    seed_file = Path(__file__).parent / "seed" / f"canonical_{language}.yaml"
    if not seed_file.exists():
        return []

    with open(seed_file, encoding="utf-8") as f:
        data = yaml.safe_load(f)

    return [item["ref"] for item in data.get(f"canonical_{language}", [])]


@lru_cache(maxsize=4)
def load_daily_seeds_normalized(language: str) -> tuple[dict, ...]:
    """Load and normalize daily seeds with NFC normalization."""
    seeds = load_daily_seeds(language)
    normalized = []
    seen: set[str] = set()

    for item in seeds:
        text = _normalize(item.get("text", ""))
        en = (item.get("en") or "").strip()

        if not text or not en or text in seen:
            continue

        normalized.append({"text": text, "en": en})
        seen.add(text)

    return tuple(normalized)


def _normalize(value: str) -> str:
    """Normalize text to NFC form."""
    return unicodedata.normalize("NFC", (value or "").strip())
