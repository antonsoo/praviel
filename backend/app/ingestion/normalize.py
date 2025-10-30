from __future__ import annotations

import unicodedata

__all__ = ["nfc", "accent_fold"]


def nfc(value: str) -> str:
    """Return NFC-normalized text."""

    return unicodedata.normalize("NFC", value)


def accent_fold(value: str) -> str:
    """Fold Greek text: remove accents, lowercase, keep NFC for search."""

    decomposed = unicodedata.normalize("NFD", value)
    stripped = "".join(ch for ch in decomposed if unicodedata.category(ch) != "Mn")
    folded = stripped.casefold()
    return unicodedata.normalize("NFC", folded)
