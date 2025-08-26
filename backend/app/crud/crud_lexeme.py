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

    # (get_multi implementation omitted for brevity, follows standard pattern)

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