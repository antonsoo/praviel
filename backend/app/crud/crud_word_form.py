from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select
from sqlalchemy.orm import selectinload
from typing import Optional, Any

from app.crud.base import CRUDBase
from app.models.linguistics import WordForm
from app.schemas.word_form import WordFormCreate, WordFormUpdate

class CRUDWordForm(CRUDBase[WordForm, WordFormCreate, WordFormUpdate]):
    
    async def get(self, db: AsyncSession, id: Any) -> Optional[WordForm]:
        stmt = (
            select(self.model)
            .options(
                selectinload(self.model.lexeme),
                selectinload(self.model.sentence)
            )
            .filter(self.model.id == id)
        )
        result = await db.execute(stmt)
        return result.scalars().first()

    # (get_multi implementation omitted for brevity)

    # Robust Create Implementation
    async def create(self, db: AsyncSession, *, obj_in: WordFormCreate) -> WordForm:
        obj_in_data = obj_in.model_dump(exclude_unset=True)
        db_obj = self.model(**obj_in_data)
        db.add(db_obj)
        await db.commit()
        # Re-fetch for async safety
        return await self.get(db, db_obj.id)

word_form = CRUDWordForm(WordForm)