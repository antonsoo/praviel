from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.db.session import get_db
from app import crud, schemas

router = APIRouter()

@router.post("/", response_model=schemas.WordForm, status_code=status.HTTP_201_CREATED)
async def create_word_form(
    *,
    db: AsyncSession = Depends(get_db),
    word_form_in: schemas.WordFormCreate,
):
    """Create new word form (token occurrence)."""
    word_form = await crud.word_form.create(db=db, obj_in=word_form_in)
    return word_form

@router.get("/{word_form_id}", response_model=schemas.WordForm)
async def read_word_form_by_id(
    word_form_id: int,
    db: AsyncSession = Depends(get_db),
):
    """Get a specific word form by ID."""
    word_form = await crud.word_form.get(db=db, id=word_form_id)
    if not word_form:
        raise HTTPException(status_code=404, detail="WordForm not found")
    return word_form