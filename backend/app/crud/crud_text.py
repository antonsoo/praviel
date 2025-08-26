from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select
from sqlalchemy.orm import selectinload
from typing import Optional, Any, List

from app.crud.base import CRUDBase
from app.models.text import Text
from app.schemas.text import TextCreate, TextUpdate

class CRUDText(CRUDBase[Text, TextCreate, TextUpdate]):
    # Override methods to eagerly load 'language' and 'author'
    
    async def get(self, db: AsyncSession, id: Any) -> Optional[Text]:
        # (Keep this method as is)
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
        # (Keep this method as is)
        stmt = (
            select(self.model)
            .options(
                selectinload(self.model.language),
                selectinload(self.model.author)
            )
            .order_by(self.model.title).offset(skip).limit(limit)
        )
        result = await db.execute(stmt)
        return result.scalars().all()

    # Robust Create Implementation (replaces the previous version)
    async def create(self, db: AsyncSession, *, obj_in: TextCreate) -> Text:
        # Re-implement creation logic instead of calling super().create()
        obj_in_data = obj_in.model_dump(exclude_unset=True)
        db_obj = self.model(**obj_in_data)
        
        db.add(db_obj)
        await db.commit()

        # CRITICAL FIX: Re-fetch using the specialized 'get' immediately after commit.
        return await self.get(db, db_obj.id)

# Create a singleton instance
text = CRUDText(Text)