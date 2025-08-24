from app.crud.base import CRUDBase
from app.models.language import Script
from app.schemas.script import ScriptCreate, ScriptUpdate

class CRUDScript(CRUDBase[Script, ScriptCreate, ScriptUpdate]):
    pass

# Create a singleton instance
script = CRUDScript(Script)