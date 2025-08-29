from pydantic import BaseModel, Field
# Add Optional to the imports
from typing import List, Optional 
from datetime import datetime
# Import the nested WordForm schema
from app.schemas.word_form import WordFormNested

# Shared properties
class SentenceBase(BaseModel):
    order_index: int = Field(..., ge=0)
    content: str = Field(..., min_length=1)

class SentenceCreate(SentenceBase):
    text_id: int

class SentenceUpdate(BaseModel):
    # (All fields optional for partial update)
    # The 'Optional' type hint is now correctly recognized
    order_index: Optional[int] = Field(None, ge=0)
    content: Optional[str] = Field(None, min_length=1)
    text_id: Optional[int] = None

# Properties to return to client
class Sentence(SentenceBase):
    id: int
    text_id: int
    created_at: datetime
    updated_at: datetime
    # Include nested word forms, which in turn include nested lexemes
    word_forms: List[WordFormNested] = []

    class Config:
        from_attributes = True