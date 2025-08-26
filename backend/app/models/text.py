from sqlalchemy import Column, String, Text, Integer, ForeignKey, Date, Enum
from sqlalchemy.orm import relationship
from app.db.base_class import Base, TimestampMixin
import enum

# Define the type of text. Using (str, enum.Enum) ensures FastAPI serializes the string value correctly.
class TextType(str, enum.Enum):
    LITERARY = "literary"
    INSCRIPTION = "inscription"
    PAPYRUS = "papyrus"
    TABLET = "tablet"
    ADMINISTRATIVE = "administrative"
    LEGAL = "legal"
    RELIGIOUS = "religious"
    OTHER = "other"

class Author(TimestampMixin, Base):
    __tablename__ = "authors"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String(150), unique=True, index=True, nullable=False)
    # Approximate start and end dates of activity (using Date type for historical data)
    start_date = Column(Date, nullable=True)
    end_date = Column(Date, nullable=True)
    description = Column(Text, nullable=True)

    # Relationship (One-to-Many)
    texts = relationship("Text", back_populates="author")

class Text(TimestampMixin, Base):
    __tablename__ = "texts"

    id = Column(Integer, primary_key=True, index=True)
    title = Column(String(255), index=True, nullable=False)
    # A common identifier or abbreviation (e.g., CIL for inscriptions)
    identifier = Column(String(100), index=True, nullable=True)
    text_type = Column(Enum(TextType), default=TextType.OTHER, nullable=False)
    # Approximate date of composition. Storing as string for flexibility (e.g., "c. 50 BCE")
    date_composed = Column(String(100), nullable=True)
    description = Column(Text, nullable=True)

    # Foreign Keys
    language_id = Column(Integer, ForeignKey("languages.id"), nullable=False)
    author_id = Column(Integer, ForeignKey("authors.id"), nullable=True) # Author is optional

    # Relationships
    # Using backref on the Language side for convenience
    language = relationship("Language", backref="texts")
    author = relationship("Author", back_populates="texts")