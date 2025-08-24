from pydantic import BaseModel, Field
from typing import Optional, List
from datetime import datetime
# Import the nested script schema
from app.schemas.script import ScriptNested

# Shared properties
class LanguageBase(BaseModel):
    name: str = Field(..., min_length=2, max_length=100)
    # ISO 639-3 codes are 3 lowercase letters (e.g., lat)
    iso_639_3_code: Optional[str] = Field(None, pattern=r"^[a-z]{3}$")
    family: Optional[str] = Field(None, max_length=100)
    description: Optional[str] = None
    is_attested: bool = True

# Properties to receive on creation
class LanguageCreate(LanguageBase):
    # When creating a language, we can associate existing scripts by ID
    script_ids: List[int] = Field(default_factory=list)

# Properties to receive on update (all optional for partial updates)
class LanguageUpdate(LanguageBase):
    name: Optional[str] = Field(None, min_length=2, max_length=100)
    iso_639_3_code: Optional[str] = Field(None, pattern=r"^[a-z]{3}$")
    family: Optional[str] = Field(None, max_length=100)
    description: Optional[str] = None
    is_attested: Optional[bool] = None
    # If provided, this list replaces the existing script associations
    script_ids: Optional[List[int]] = None

# Properties to return to client (The main response model)
class Language(LanguageBase):
    id: int
    created_at: datetime
    updated_at: datetime
    # Include related scripts in the response using the nested schema
    scripts: List[ScriptNested] = []

    class Config:
        from_attributes = True