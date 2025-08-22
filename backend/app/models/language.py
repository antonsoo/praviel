from sqlalchemy import Column, String, Text, Boolean, ForeignKey, Table, Integer
from sqlalchemy.orm import relationship
from app.db.base_class import Base, TimestampMixin

# Association table for the many-to-many relationship.
# A language might use multiple scripts, and a script is used by many languages.
language_script_association = Table(
    'language_script_association',
    Base.metadata,
    Column('language_id', ForeignKey('languages.id'), primary_key=True),
    Column('script_id', ForeignKey('scripts.id'), primary_key=True)
)

class Language(TimestampMixin, Base):
    __tablename__ = "languages"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String(100), unique=True, index=True, nullable=False)
    iso_639_3_code = Column(String(3), unique=True, index=True, nullable=True) # e.g., lat (Latin), grc (Ancient Greek)
    family = Column(String(100), index=True, nullable=True)
    description = Column(Text, nullable=True)
    is_attested = Column(Boolean, default=True, nullable=False) # True if attested, False if reconstructed

    # Relationships
    scripts = relationship("Script", secondary=language_script_association, back_populates="languages")

class Script(TimestampMixin, Base):
    __tablename__ = "scripts"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String(100), unique=True, index=True, nullable=False)
    iso_15924_code = Column(String(4), unique=True, index=True, nullable=True) # e.g., Latn (Latin), Linb (Linear B)
    direction = Column(String(3), default="ltr", nullable=False) # ltr, rtl, ttb
    description = Column(Text, nullable=True)

    # Relationships
    languages = relationship("Language", secondary=language_script_association, back_populates="scripts")