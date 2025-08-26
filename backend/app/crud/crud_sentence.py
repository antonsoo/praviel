from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select
from sqlalchemy.orm import selectinload
from typing import Optional, Any, List

from app.crud.base import CRUDBase
# Import related models for deep loading strategy
from app.models.linguistics import Sentence, WordForm
from app.schemas.sentence import SentenceCreate, SentenceUpdate

class CRUDSentence(CRUDBase[Sentence, SentenceCreate, SentenceUpdate]):

    # Define the deep loading strategy: Sentence -> WordForm -> Lexeme
    def _get_load_strategy(self):
        return [
            # This ensures WordForms are loaded AND their associated Lexemes are loaded in the same query
            selectinload(Sentence.word_forms).selectinload(WordForm.lexeme)
        ]

    async def get(self, db: AsyncSession, id: Any) -> Optional[Sentence]:
        stmt = (
            select(self.model)
            .options(*self._get_load_strategy())
            .filter(self.model.id == id)
        )
        result = await db.execute(stmt)
        # Use unique() when fetching objects that have collections loaded via joins
        return result.unique().scalars().first()

    # Specialized method: Get sentences for a specific text
    async def get_multi_by_text(
        self, db: AsyncSession, *, text_id: int, skip: int = 0, limit: int = 100
    ) -> List[Sentence]:
        stmt = (
            select(self.model)
            .options(*self._get_load_strategy())
            .filter(self.model.text_id == text_id)
            .order_by(self.model.order_index)
            .offset(skip)
            .limit(limit)
        )
        result = await db.execute(stmt)
        return result.unique().scalars().all()

    # Robust Create Implementation
    async def create(self, db: AsyncSession, *, obj_in: SentenceCreate) -> Sentence:
        obj_in_data = obj_in.model_dump(exclude_unset=True)
        db_obj = self.model(**obj_in_data)
        db.add(db_obj)
        await db.commit()
        # Re-fetch using the specialized 'get'
        return await self.get(db, db_obj.id)

sentence = CRUDSentence(Sentence)