from pydantic import BaseModel, Field
from typing import Optional
from datetime import datetime

# Shared properties
class LexemeBase(BaseModel):
    lemma: str = Field(..., min_length=1, max_length=150)
    part_of_speech: Optional[str] = Field(None, max_length=50)
    definition: Optional[str] = None

class LexemeCreate(LexemeBase):
    language_id: int

class LexemeUpdate(BaseModel):
    # (All fields optional for partial update)
    lemma: Optional[str] = Field(None, min_length=1, max_length=150)
    part_of_speech: Optional[str] = Field(None, max_length=50)
    definition: Optional[str] = None
    language_id: Optional[int] = None

# Nested schema for use within WordForm
class LexemeNested(LexemeBase):
    id: int
    class Config:
        from_attributes = True

class Lexeme(LexemeBase):
    id: int
    language_id: int
    created_at: datetime
    updated_at: datetime
    class Config:
        from_attributes = True