"""Lesson seed validation tests for Phase C."""

from __future__ import annotations

import unicodedata

from app.lesson.seed_loader import load_canonical_refs, load_daily_seeds


def test_daily_seeds_nfc():
    """All daily text must be NFC normalized."""
    seeds = load_daily_seeds("grc")
    for item in seeds:
        text = item["text"]
        assert unicodedata.is_normalized("NFC", text), f"Not NFC: {text}"


def test_daily_seeds_greek_script():
    """Daily text must be Greek script."""
    seeds = load_daily_seeds("grc")
    for item in seeds:
        text = item["text"]
        # Basic check: contains Greek characters (polytonic or monotonic)
        assert any("\u0370" <= c <= "\u03ff" or "\u1f00" <= c <= "\u1fff" for c in text), (
            f"No Greek characters in: {text}"
        )


def test_daily_seeds_structure():
    """Daily seeds must have text and en fields."""
    seeds = load_daily_seeds("grc")
    for item in seeds:
        assert "text" in item, f"Missing text field: {item}"
        assert "en" in item, f"Missing en field: {item}"
        assert isinstance(item["text"], str), f"text must be string: {item}"
        assert isinstance(item["en"], str), f"en must be string: {item}"
        assert len(item["text"]) > 0, f"text cannot be empty: {item}"
        assert len(item["en"]) > 0, f"en cannot be empty: {item}"


def test_canonical_refs_format():
    """Canonical refs must have work abbreviation and reference parts."""
    refs = load_canonical_refs("grc")
    for ref in refs:
        # Check basic format: Work.reference (e.g., "Il.1.1", "Apol.17a", "Pl.Rep.1.327a")
        assert "." in ref, f"Ref must contain at least one period: {ref}"
        parts = ref.split(".")
        assert len(parts) >= 2, f"Expected work.reference format: {ref}"
        # Work abbreviation should not be empty
        assert len(parts[0]) > 0, f"Work abbreviation cannot be empty: {ref}"


def test_canonical_refs_unique():
    """Canonical refs must be unique."""
    refs = load_canonical_refs("grc")
    assert len(refs) == len(set(refs)), "Duplicate refs found"


def test_seed_counts():
    """Verify ~60 daily + ~12 canonical."""
    daily = load_daily_seeds("grc")
    canonical = load_canonical_refs("grc")
    assert len(daily) >= 55, f"Expected ~60 daily, got {len(daily)}"
    assert len(canonical) >= 12, f"Expected ~12 canonical, got {len(canonical)}"


def test_daily_seeds_unique():
    """Daily text values should be mostly unique (allow some duplicates for practice)."""
    seeds = load_daily_seeds("grc")
    texts = [item["text"] for item in seeds]
    unique_ratio = len(set(texts)) / len(texts)
    # Allow up to 5% duplicates for intentional practice repetition
    assert unique_ratio >= 0.95, f"Too many duplicates: {unique_ratio:.1%} unique (expected >= 95%)"
