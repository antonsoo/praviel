import unicodedata


def nfc(s: str) -> str:
    return "" if not isinstance(s, str) else unicodedata.normalize("NFC", s)


def accent_fold(s: str) -> str:
    if not isinstance(s, str):
        return ""
    s = unicodedata.normalize("NFD", s)
    s = "".join(ch for ch in s if unicodedata.category(ch) != "Mn")
    return unicodedata.normalize("NFC", s)
