from pydantic import BaseModel, Field
from typing import Optional
from datetime import datetime, date

# Shared properties
class AuthorBase(BaseModel):
    name: str = Field(..., min_length=2, max_length=150)
    start_date: Optional[date] = None
    end_date: Optional[date] = None
    description: Optional[str] = None

# Properties to receive on creation
class AuthorCreate(AuthorBase):
    pass

# Properties to receive on update (all optional)
class AuthorUpdate(AuthorBase):
    name: Optional[str] = Field(None, min_length=2, max_length=150)
    start_date: Optional[date] = None
    end_date: Optional[date] = None
    description: Optional[str] = None

# A minimal schema for when an Author is nested within another object (like Text)
class AuthorNested(BaseModel):
    id: int
    name: str

    class Config:
        from_attributes = True

# Properties to return to client
class Author(AuthorBase):
    id: int
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True