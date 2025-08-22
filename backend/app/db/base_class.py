from sqlalchemy.orm import DeclarativeBase
from sqlalchemy.ext.asyncio import AsyncAttrs
from sqlalchemy import Column, DateTime
from sqlalchemy.sql import func

# AsyncAttrs allows for asynchronous loading of relationships
class Base(AsyncAttrs, DeclarativeBase):
    """
    Base class for all SQLAlchemy models.
    """
    pass

class TimestampMixin:
    """
    Mixin to add created_at and updated_at timestamps.
    """
    created_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now(), nullable=False)