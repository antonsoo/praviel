from pydantic import BaseModel, Field
from typing import Optional
from datetime import datetime

# Shared properties
class ScriptBase(BaseModel):
    name: str = Field(..., min_length=2, max_length=100)
    # ISO 15924 codes are 4 letters, first uppercase (e.g., Latn)
    iso_15924_code: Optional[str] = Field(None, pattern=r"^[A-Z][a-z]{3}$") 
    direction: str = Field(default="ltr", pattern=r"^(ltr|rtl|ttb)$")
    description: Optional[str] = None

# Properties to receive on creation
class ScriptCreate(ScriptBase):
    pass

# Properties to receive on update (all optional for partial updates)
class ScriptUpdate(ScriptBase):
    name: Optional[str] = Field(None, min_length=2, max_length=100)
    iso_15924_code: Optional[str] = Field(None, pattern=r"^[A-Z][a-z]{3}$")
    direction: Optional[str] = Field(None, pattern=r"^(ltr|rtl|ttb)$")
    description: Optional[str] = None

# A minimal schema for when a Script is nested within another object
class ScriptNested(BaseModel):
    id: int
    name: str
    iso_15924_code: Optional[str]

    class Config:
        # Enables Pydantic to read data directly from SQLAlchemy models (ORM mode)
        from_attributes = True

# Properties to return to client (The main response model)
class Script(ScriptBase):
    id: int
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True