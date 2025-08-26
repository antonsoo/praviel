# Import the Base class and Mixin
from app.db.base_class import Base, TimestampMixin

# Import all the models here...
from app.models.language import Language, Script, language_script_association
from app.models.text import Text, Author, TextType
# Add the new linguistic models
from app.models.linguistics import Sentence, Lexeme, WordForm