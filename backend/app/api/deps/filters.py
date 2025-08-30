from fastapi import Query
from typing import Optional

# --- Language Filters ---
class LanguageFilters:
    def __init__(
        self,
        name: Optional[str] = Query(None, description="Search by language name (case-insensitive substring match)."),
        iso_code: Optional[str] = Query(None, description="Filter by exact ISO 639-3 code.", pattern=r"^[a-z]{3}$"),
        family: Optional[str] = Query(None, description="Filter by language family (case-insensitive substring match)."),
        is_attested: Optional[bool] = Query(None, description="Filter by attestation status (True for attested, False for reconstructed).")
    ):
        self.name = name
        self.iso_code = iso_code
        self.family = family
        self.is_attested = is_attested

# --- Text Filters ---
class TextFilters:
    def __init__(
        self,
        title: Optional[str] = Query(None, description="Search by text title (case-insensitive substring match)."),
        language_id: Optional[int] = Query(None, description="Filter by specific Language ID."),
        author_id: Optional[int] = Query(None, description="Filter by specific Author ID."),
        text_type: Optional[str] = Query(None, description="Filter by text type (e.g., literary, inscription).")
    ):
        self.title = title
        self.language_id = language_id
        self.author_id = author_id
        self.text_type = text_type

# --- Lexeme Filters ---
class LexemeFilters:
    def __init__(
        self,
        lemma: Optional[str] = Query(None, description="Search by lemma (headword). Case-insensitive substring match."),
        language_id: Optional[int] = Query(None, description="Filter by specific Language ID."),
        pos: Optional[str] = Query(None, description="Filter by Part of Speech.")
    ):
        self.lemma = lemma
        self.language_id = language_id
        self.pos = pos