from sqlalchemy import Column, String, Text, Integer, ForeignKey, UniqueConstraint
from sqlalchemy.orm import relationship
# Import JSONB for efficient morphology storage
from sqlalchemy.dialects.postgresql import JSONB
from app.db.base_class import Base, TimestampMixin

# --- Sentence Model ---
class Sentence(TimestampMixin, Base):
    __tablename__ = "sentences"

    id = Column(Integer, primary_key=True, index=True)
    text_id = Column(Integer, ForeignKey("texts.id"), nullable=False, index=True)

    # Sequence within the text
    order_index = Column(Integer, nullable=False, index=True)
    content = Column(Text, nullable=False) # The content of the sentence

    # Relationships
    # Note: The 'text' relationship is handled via backref in the Text model
    word_forms = relationship("WordForm", back_populates="sentence", order_by="WordForm.order_index", cascade="all, delete-orphan")

    # Constraint: Ensure unique order within a text
    __table_args__ = (
        UniqueConstraint('text_id', 'order_index', name='uix_text_sentence_order'),
    )

# --- Lexicon (Dictionary Entry) Model ---
class Lexeme(TimestampMixin, Base):
    __tablename__ = "lexemes"

    id = Column(Integer, primary_key=True, index=True)
    language_id = Column(Integer, ForeignKey("languages.id"), nullable=False)

    # Dictionary headword (e.g., "amo" or "λῡ́ω")
    lemma = Column(String(150), index=True, nullable=False)
    part_of_speech = Column(String(50), index=True, nullable=True)
    definition = Column(Text, nullable=True)
    
    # Relationships
    language = relationship("Language", backref="lexemes")
    word_forms = relationship("WordForm", back_populates="lexeme")

    # Constraint: Ensure unique lemma within a language
    __table_args__ = (
        UniqueConstraint('language_id', 'lemma', name='uix_language_lemma'),
    )

# --- Word Form (Token Occurrence) Model ---
class WordForm(TimestampMixin, Base):
    __tablename__ = "word_forms"

    id = Column(Integer, primary_key=True, index=True)
    sentence_id = Column(Integer, ForeignKey("sentences.id"), nullable=False)
    lexeme_id = Column(Integer, ForeignKey("lexemes.id"), nullable=True) # Optional if unidentified

    # The form as it appears in the sentence (e.g., "amabant")
    surface_form = Column(String(150), index=True, nullable=False)
    
    # Sequence within the sentence
    order_index = Column(Integer, nullable=False, index=True)
    
    # Morphological Analysis (e.g., {"Case": "Nominative", "Number": "Singular"})
    morphology = Column(JSONB, nullable=True)

    # Relationships
    sentence = relationship("Sentence", back_populates="word_forms")
    lexeme = relationship("Lexeme", back_populates="word_forms")

    # Constraint: Ensure unique order within a sentence
    __table_args__ = (
        UniqueConstraint('sentence_id', 'order_index', name='uix_sentence_word_order'),
    )