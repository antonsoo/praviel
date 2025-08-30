from sqlalchemy.sql.selectable import Select
from app.api.deps.filters import LanguageFilters
from typing import List, Optional, Any, Dict, Union
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select
from sqlalchemy.orm import selectinload
from fastapi import HTTPException, status

from app.crud.base import CRUDBase
from app.models.language import Language, Script
from app.schemas.language import LanguageCreate, LanguageUpdate

class CRUDLanguage(CRUDBase[Language, LanguageCreate, LanguageUpdate]):
    
    async def _get_scripts_by_ids(self, db: AsyncSession, script_ids: List[int]) -> List[Script]:
        """Helper method to fetch and validate scripts by ID."""
        if not script_ids:
            return []
        
        stmt = select(Script).filter(Script.id.in_(script_ids))
        result = await db.execute(stmt)
        scripts = result.scalars().all()
        
        # Validate that all requested scripts were found
        if len(scripts) != len(set(script_ids)):
            found_ids = {s.id for s in scripts}
            missing_ids = set(script_ids) - found_ids
            raise HTTPException(
                status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
                detail=f"One or more scripts not found: {missing_ids}",
            )
            
        return scripts

    # Override 'get' and 'get_multi' to eagerly load 'scripts' relationship
    async def get(self, db: AsyncSession, id: Any) -> Optional[Language]:
        stmt = (
            select(self.model)
            .options(selectinload(self.model.scripts)) # Eagerly load
            .filter(self.model.id == id)
        )
        result = await db.execute(stmt)
        return result.scalars().first()

    # Helper method to apply filters to a query
    def _apply_filters(self, stmt: Select, filters: LanguageFilters) -> Select:
        if filters.name:
            # Use ilike for case-insensitive substring search (PostgreSQL specific)
            stmt = stmt.filter(self.model.name.ilike(f"%{filters.name}%"))
        if filters.iso_code:
            stmt = stmt.filter(self.model.iso_639_3_code == filters.iso_code)
        if filters.family:
            stmt = stmt.filter(self.model.family.ilike(f"%{filters.family}%"))
        if filters.is_attested is not None:
            stmt = stmt.filter(self.model.is_attested == filters.is_attested)
        return stmt

    async def get_multi(
        self, db: AsyncSession, *, skip: int = 0, limit: int = 100, filters: LanguageFilters = None
    ) -> List[Language]:
        stmt = (
            select(self.model)
            .options(selectinload(self.model.scripts)) # Eagerly load
            .order_by(self.model.name) # Order by name for better UX
        )
        
        # Apply filters if provided
        if filters:
            stmt = self._apply_filters(stmt, filters)

        stmt = stmt.offset(skip).limit(limit)
        
        result = await db.execute(stmt)
        # Use unique() when querying lists with joined collections
        return result.unique().scalars().all()

    # Override 'create' to handle 'script_ids' input
    async def create(self, db: AsyncSession, *, obj_in: LanguageCreate) -> Language:
        obj_in_data = obj_in.model_dump(exclude_unset=True)
        
        # Pop the script_ids from the input data
        script_ids = obj_in_data.pop("script_ids", [])
        
        db_obj = self.model(**obj_in_data)
        
        # Handle the script associations
        if script_ids:
            scripts = await self._get_scripts_by_ids(db, script_ids)
            db_obj.scripts = scripts
            
        db.add(db_obj)
        await db.commit()
        
        # After commit, re-fetch the object using the specialized 'get' 
        # to ensure relationships are loaded for the response.
        return await self.get(db, db_obj.id)

    # Override 'update' to handle 'script_ids' input
    async def update(
        self,
        db: AsyncSession,
        *,
        db_obj: Language,
        obj_in: Union[LanguageUpdate, Dict[str, Any]]
    ) -> Language:
        if isinstance(obj_in, dict):
            update_data = obj_in
        else:
            update_data = obj_in.model_dump(exclude_unset=True)

        # Handle script associations if the key "script_ids" exists in the input
        if "script_ids" in update_data:
            script_ids = update_data.pop("script_ids")
            # Check if the value is an empty list (meaning remove all associations)
            if script_ids == []:
                db_obj.scripts = []
            else:
                scripts = await self._get_scripts_by_ids(db, script_ids)
                db_obj.scripts = scripts

        # Proceed with the standard update for other fields
        return await super().update(db, db_obj=db_obj, obj_in=update_data)

# Create a singleton instance
language = CRUDLanguage(Language)