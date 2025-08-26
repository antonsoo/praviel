from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select
from sqlalchemy.orm import selectinload
from typing import Optional, Any, List

from app.crud.base import CRUDBase
from app.models.text import Author
from app.schemas.author import AuthorCreate, AuthorUpdate

class CRUDAuthor(CRUDBase[Author, AuthorCreate, AuthorUpdate]):
    # Override methods to ensure async safety
    
    async def get(self, db: AsyncSession, id: Any) -> Optional[Author]:
        stmt = (
            select(self.model)
            # Eagerly load relationships even if not currently used in the schema, for safety
            .options(selectinload(self.model.texts)) 
            .filter(self.model.id == id)
        )
        result = await db.execute(stmt)
        return result.scalars().first()

    async def get_multi(
        self, db: AsyncSession, *, skip: int = 0, limit: int = 100
    ) -> List[Author]:
        stmt = (
            select(self.model)
            .options(selectinload(self.model.texts))
            .order_by(self.model.name).offset(skip).limit(limit) # Order by name
        )
        result = await db.execute(stmt)
        return result.unique().scalars().all()

    async def create(self, db: AsyncSession, *, obj_in: AuthorCreate) -> Author:
        # Use the standard creation process from CRUDBase
        db_obj = await super().create(db, obj_in=obj_in)
        # Re-fetch using the specialized 'get' for async safety
        return await self.get(db, db_obj.id)

# Create a singleton instance
author = CRUDAuthor(Author)