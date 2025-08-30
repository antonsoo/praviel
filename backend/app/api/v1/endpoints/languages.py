from app.api.deps.filters import LanguageFilters
from typing import List
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.db.session import get_db
from app import crud, schemas

router = APIRouter()

@router.get("/", response_model=List[schemas.Language])
async def read_languages(
    db: AsyncSession = Depends(get_db),
    skip: int = 0,
    limit: int = 100,
    # Inject the filters dependency
    filters: LanguageFilters = Depends(),
):
    """Retrieve languages (includes associated scripts). Use query parameters for filtering."""
    # Pass the filters object to the CRUD method
    languages = await crud.language.get_multi(db, skip=skip, limit=limit, filters=filters)
    return languages

@router.post("/", response_model=schemas.Language, status_code=status.HTTP_201_CREATED)
async def create_language(
    *,
    db: AsyncSession = Depends(get_db),
    language_in: schemas.LanguageCreate,
):
    """
    Create new language. 
    Optionally provide 'script_ids' list to associate existing scripts.
    """
    # The specialized crud.language.create handles the association logic
    language = await crud.language.create(db=db, obj_in=language_in)
    return language

@router.get("/{language_id}", response_model=schemas.Language)
async def read_language_by_id(
    language_id: int,
    db: AsyncSession = Depends(get_db),
):
    """Get a specific language by ID (includes associated scripts)."""
    language = await crud.language.get(db=db, id=language_id)
    if not language:
        raise HTTPException(status_code=404, detail="Language not found")
    return language

@router.put("/{language_id}", response_model=schemas.Language)
async def update_language(
    *,
    db: AsyncSession = Depends(get_db),
    language_id: int,
    language_in: schemas.LanguageUpdate,
):
    """
    Update a language. 
    If 'script_ids' is provided in the payload, it replaces the existing associations.
    To remove all scripts, provide an empty list [] for 'script_ids'.
    """
    language = await crud.language.get(db=db, id=language_id)
    if not language:
        raise HTTPException(status_code=404, detail="Language not found")
    
    # The specialized crud.language.update handles the association changes
    language = await crud.language.update(db=db, db_obj=language, obj_in=language_in)
    return language

@router.delete("/{language_id}", response_model=schemas.Language)
async def delete_language(
    *,
    db: AsyncSession = Depends(get_db),
    language_id: int,
):
    """Delete a language."""
    language = await crud.language.get(db=db, id=language_id)
    if not language:
        raise HTTPException(status_code=404, detail="Language not found")
    language = await crud.language.remove(db=db, id=language_id)
    return language