from pydantic import BaseModel, Field
from typing import Optional, Dict
from datetime import datetime
from app.schemas.lexeme import LexemeNested

# Shared properties
class WordFormBase(BaseModel):
    surface_form: str = Field(..., min_length=1, max_length=150)
    order_index: int = Field(..., ge=0)
    # Morphology is a dictionary mapping to JSONB
    morphology: Optional[Dict[str, str]] = None

class WordFormCreate(WordFormBase):
    sentence_id: int
    lexeme_id: Optional[int] = None

class WordFormUpdate(BaseModel):
    # (All fields optional for partial update)
    surface_form: Optional[str] = Field(None, min_length=1, max_length=150)
    order_index: Optional[int] = Field(None, ge=0)
    morphology: Optional[Dict[str, str]] = None
    sentence_id: Optional[int] = None
    lexeme_id: Optional[int] = None

# Nested schema for use within Sentence
class WordFormNested(WordFormBase):
    id: int
    lexeme: Optional[LexemeNested] = None
    class Config:
        from_attributes = True

class WordForm(WordFormBase):
    id: int
    sentence_id: int
    lexeme_id: Optional[int]
    created_at: datetime
    updated_at: datetime
    lexeme: Optional[LexemeNested] = None
    class Config:
        from_attributes = True