from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select
from sqlalchemy.orm import selectinload
from typing import Optional, Any, List

from app.crud.base import CRUDBase
from app.models.text import Text
from app.schemas.text import TextCreate, TextUpdate

class CRUDText(CRUDBase[Text, TextCreate, TextUpdate]):
    # Override methods to eagerly load 'language' and 'author' (crucial for the Text response schema)
    
    async def get(self, db: AsyncSession, id: Any) -> Optional[Text]:
        stmt = (
            select(self.model)
            .options(
                selectinload(self.model.language),
                selectinload(self.model.author)
            )
            .filter(self.model.id == id)
        )
        result = await db.execute(stmt)
        return result.scalars().first()

    async def get_multi(
        self, db: AsyncSession, *, skip: int = 0, limit: int = 100
    ) -> List[Text]:
        stmt = (
            select(self.model)
            .options(
                selectinload(self.model.language),
                selectinload(self.model.author)
            )
            .order_by(self.model.title).offset(skip).limit(limit) # Order by title
        )
        result = await db.execute(stmt)
        # No need for unique() here as these are Many-to-One relationships
        return result.scalars().all()

    async def create(self, db: AsyncSession, *, obj_in: TextCreate) -> Text:
        # Database FK constraints will ensure language_id and author_id (if provided) exist.
        
        # Use the standard creation process
        db_obj = await super().create(db, obj_in=obj_in)
        
        # CRITICAL: Re-fetch using the specialized 'get' to ensure 'language' and 'author' 
        # are loaded before returning to Pydantic.
        return await self.get(db, db_obj.id)

# Create a singleton instance
text = CRUDText(Text)