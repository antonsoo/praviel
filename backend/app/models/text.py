# backend/app/models/text.py
from sqlalchemy import Column, String, Text, Integer, ForeignKey, Date, Enum
from sqlalchemy.orm import relationship
from app.db.base_class import Base, TimestampMixin
import enum

# (Keep TextType and Author definitions as they are)
class TextType(str, enum.Enum):
    # ... (existing enum values) ...
    LITERARY = "literary"
    INSCRIPTION = "inscription"
    PAPYRUS = "papyrus"
    TABLET = "tablet"
    ADMINISTRATIVE = "administrative"
    LEGAL = "legal"
    RELIGIOUS = "religious"
    OTHER = "other"

class Author(TimestampMixin, Base):
    # ... (existing Author definition) ...
    __tablename__ = "authors"
    id = Column(Integer, primary_key=True, index=True)
    name = Column(String(150), unique=True, index=True, nullable=False)
    start_date = Column(Date, nullable=True)
    end_date = Column(Date, nullable=True)
    description = Column(Text, nullable=True)
    texts = relationship("Text", back_populates="author")


class Text(TimestampMixin, Base):
    __tablename__ = "texts"

    # ... (Keep existing columns) ...
    id = Column(Integer, primary_key=True, index=True)
    title = Column(String(255), index=True, nullable=False)
    identifier = Column(String(100), index=True, nullable=True)
    text_type = Column(Enum(TextType), default=TextType.OTHER, nullable=False)
    date_composed = Column(String(100), nullable=True)
    description = Column(Text, nullable=True)

    # Foreign Keys
    language_id = Column(Integer, ForeignKey("languages.id"), nullable=False)
    author_id = Column(Integer, ForeignKey("authors.id"), nullable=True)

    # Relationships
    language = relationship("Language", backref="texts")
    author = relationship("Author", back_populates="texts")
    
    # New Relationship (One-to-Many with Sentence)
    # cascade="all, delete-orphan" ensures Sentences (and their WordForms) are deleted if the Text is deleted.
    sentences = relationship(
        "Sentence", 
        backref="text", 
        order_by="Sentence.order_index",
        cascade="all, delete-orphan"
    )