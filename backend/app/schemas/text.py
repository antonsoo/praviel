from pydantic import BaseModel, Field
from typing import Optional
from datetime import datetime

# Import related schemas and the Enum
from app.models.text import TextType
from app.schemas.author import AuthorNested

# We need a simplified Language schema specifically for nesting inside Text
class LanguageNested(BaseModel):
    id: int
    name: str
    iso_639_3_code: Optional[str]

    class Config:
        from_attributes = True

# Shared properties (Does not include FKs)
class TextBase(BaseModel):
    title: str = Field(..., min_length=2, max_length=255)
    identifier: Optional[str] = Field(None, max_length=100)
    text_type: TextType = TextType.OTHER
    date_composed: Optional[str] = Field(None, max_length=100)
    description: Optional[str] = None

# Properties to receive on creation (Requires IDs)
class TextCreate(TextBase):
    language_id: int
    author_id: Optional[int] = None

# Properties to receive on update (All optional)
class TextUpdate(TextBase):
    title: Optional[str] = Field(None, min_length=2, max_length=255)
    identifier: Optional[str] = Field(None, max_length=100)
    text_type: Optional[TextType] = None
    date_composed: Optional[str] = Field(None, max_length=100)
    description: Optional[str] = None
    language_id: Optional[int] = None
    author_id: Optional[int] = None

# Properties to return to client
class Text(TextBase):
    id: int
    created_at: datetime
    updated_at: datetime

    # Include the nested objects instead of just IDs
    language: LanguageNested
    author: Optional[AuthorNested] = None

    class Config:
        from_attributes = True