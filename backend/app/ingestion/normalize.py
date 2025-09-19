from __future__ import annotations

import unicodedata

__all__ = ["nfc", "accent_fold"]


def nfc(value: str) -> str:
    """Return NFC-normalized text."""

    return unicodedata.normalize("NFC", value)


def accent_fold(value: str) -> str:
    """Strip combining marks and lowercase for consistent trigram comparisons."""

    decomposed = unicodedata.normalize("NFD", value)
    base = "".join(ch for ch in decomposed if unicodedata.category(ch) != "Mn")
    return unicodedata.normalize("NFC", base).casefold()
