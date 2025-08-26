from .language import Language, LanguageCreate, LanguageUpdate
from .script import Script, ScriptCreate, ScriptUpdate, ScriptNested
# Add the new schemas
from .author import Author, AuthorCreate, AuthorUpdate, AuthorNested
from .text import Text, TextCreate, TextUpdate, LanguageNested, TextType