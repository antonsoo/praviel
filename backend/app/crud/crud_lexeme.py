from sqlalchemy.sql.selectable import Select
from app.api.deps.filters import LexemeFilters
import sqlalchemy.exc
from fastapi import HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select
from sqlalchemy.orm import selectinload
from typing import Optional, Any, List

from app.crud.base import CRUDBase
from app.models.linguistics import Lexeme
from app.schemas.lexeme import LexemeCreate, LexemeUpdate

class CRUDLexeme(CRUDBase[Lexeme, LexemeCreate, LexemeUpdate]):
    
    async def get(self, db: AsyncSession, id: Any) -> Optional[Lexeme]:
        stmt = (
            select(self.model)
            .options(selectinload(self.model.language)) 
            .filter(self.model.id == id)
        )
        result = await db.execute(stmt)
        return result.scalars().first()

        # Helper method to apply filters
    def _apply_filters(self, stmt: Select, filters: LexemeFilters) -> Select:
        if filters.lemma:
            stmt = stmt.filter(self.model.lemma.ilike(f"%{filters.lemma}%"))
        if filters.language_id:
            stmt = stmt.filter(self.model.language_id == filters.language_id)
        if filters.pos:
            # Search POS using ilike as well
            stmt = stmt.filter(self.model.part_of_speech.ilike(f"%{filters.pos}%"))
        return stmt

    async def get_multi(
        self, db: AsyncSession, *, skip: int = 0, limit: int = 100, filters: LexemeFilters = None
    ) -> List[Lexeme]:
        stmt = (
            select(self.model)
            .options(selectinload(self.model.language))
            .order_by(self.model.lemma)
        )
        
        # Apply filters if provided
        if filters:
            stmt = self._apply_filters(stmt, filters)
            
        stmt = stmt.offset(skip).limit(limit)

        result = await db.execute(stmt)
        return result.scalars().all()

    # Robust Create Implementation with Conflict Handling
    async def create(self, db: AsyncSession, *, obj_in: LexemeCreate) -> Lexeme:
        obj_in_data = obj_in.model_dump(exclude_unset=True)
        db_obj = self.model(**obj_in_data)
        
        db.add(db_obj)
        try:
            await db.commit()
        except sqlalchemy.exc.IntegrityError as e:
            await db.rollback()
            # Handle unique constraint violations (duplicate lemma in the same language)
            if 'uix_language_lemma' in str(e.orig):
                 raise HTTPException(
                    status_code=status.HTTP_409_CONFLICT,
                    detail="A lexeme with this lemma already exists for this language.",
                )
            raise e
        
        # Re-fetch for async safety
        return await self.get(db, db_obj.id)

lexeme = CRUDLexeme(Lexeme)