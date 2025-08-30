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
            .order_by(self.model.name).offset(skip).limit(limit)
        )
        result = await db.execute(stmt)
        return result.unique().scalars().all()

    # Robust Create Implementation (replaces the previous version)
    async def create(self, db: AsyncSession, *, obj_in: AuthorCreate) -> Author:
        # Re-implement creation logic instead of calling super().create()
        obj_in_data = obj_in.model_dump(exclude_unset=True)
        db_obj = self.model(**obj_in_data)
        
        db.add(db_obj)
        await db.commit()
        
        # CRITICAL FIX: Re-fetch using the specialized 'get' immediately after commit.
        # This ensures async safety and prevents 500 errors during serialization.
        return await self.get(db, db_obj.id)

# Create a singleton instance
author = CRUDAuthor(Author)