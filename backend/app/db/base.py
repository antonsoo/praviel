# Import the Base class and Mixin
from app.db.base_class import Base, TimestampMixin

# Import all the models here, so that Base.metadata is properly registered
# when Alembic runs autogeneration.
from app.models.language import Language, Script, language_script_association