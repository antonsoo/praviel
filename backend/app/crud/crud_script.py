from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select
from sqlalchemy.orm import selectinload # Import selectinload
from typing import Optional, Any, List # Import List and others

from app.crud.base import CRUDBase
from app.models.language import Script
from app.schemas.script import ScriptCreate, ScriptUpdate

class CRUDScript(CRUDBase[Script, ScriptCreate, ScriptUpdate]):
    
    # Override 'get' to eagerly load 'languages' relationship.
    # This prevents async errors if Pydantic tries to access the relationship.
    async def get(self, db: AsyncSession, id: Any) -> Optional[Script]:
        stmt = (
            select(self.model)
            .options(selectinload(self.model.languages)) 
            .filter(self.model.id == id)
        )
        result = await db.execute(stmt)
        return result.scalars().first()

    # Override 'get_multi' as well for consistency
    async def get_multi(
        self, db: AsyncSession, *, skip: int = 0, limit: int = 100
    ) -> List[Script]:
        stmt = (
            select(self.model)
            .options(selectinload(self.model.languages))
            .order_by(self.model.id).offset(skip).limit(limit)
        )
        result = await db.execute(stmt)
        # Use unique() when querying lists with joined collections to prevent duplicates
        return result.unique().scalars().all()

    # Override 'create' to use the specialized 'get' after creation
    async def create(self, db: AsyncSession, *, obj_in: ScriptCreate) -> Script:
        obj_in_data = obj_in.model_dump(exclude_unset=True)
        db_obj = self.model(**obj_in_data)
        
        db.add(db_obj)
        await db.commit()
        
        # CRITICAL FIX: Instead of just refreshing (which CRUDBase does), 
        # use the specialized 'get' to ensure everything is loaded correctly 
        # in the async context. This prevents the HTTP 500 error during serialization.
        return await self.get(db, db_obj.id)

# Create a singleton instance
script = CRUDScript(Script)