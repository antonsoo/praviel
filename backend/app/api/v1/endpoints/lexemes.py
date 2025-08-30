from app.api.deps.filters import LexemeFilters
from typing import List
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.db.session import get_db
from app import crud, schemas

router = APIRouter()

# Add the GET list endpoint
@router.get("/", response_model=List[schemas.Lexeme])
async def read_lexemes(
    db: AsyncSession = Depends(get_db),
    skip: int = 0,
    limit: int = 100,
    # Inject the filters dependency
    filters: LexemeFilters = Depends(),
):
    """Retrieve lexemes. Use query parameters for filtering (e.g., search by lemma)."""
    # Pass the filters object to the CRUD method
    lexemes = await crud.lexeme.get_multi(db, skip=skip, limit=limit, filters=filters)
    return lexemes

@router.post("/", response_model=schemas.Lexeme, status_code=status.HTTP_201_CREATED)
async def create_lexeme(
    *,
    db: AsyncSession = Depends(get_db),
    lexeme_in: schemas.LexemeCreate,
):
    """Create new lexeme (dictionary entry). Returns 409 Conflict if lemma exists for language."""
    # The CRUD create handles validation and potential conflicts.
    lexeme = await crud.lexeme.create(db=db, obj_in=lexeme_in)
    return lexeme

@router.get("/{lexeme_id}", response_model=schemas.Lexeme)
async def read_lexeme_by_id(
    lexeme_id: int,
    db: AsyncSession = Depends(get_db),
):
    """Get a specific lexeme by ID."""
    lexeme = await crud.lexeme.get(db=db, id=lexeme_id)
    if not lexeme:
        raise HTTPException(status_code=404, detail="Lexeme not found")
    return lexeme