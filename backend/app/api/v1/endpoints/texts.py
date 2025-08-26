from typing import List
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.db.session import get_db
from app import crud, schemas

router = APIRouter()

@router.get("/", response_model=List[schemas.Text])
async def read_texts(
    db: AsyncSession = Depends(get_db),
    skip: int = 0,
    limit: int = 100,
):
    """Retrieve texts (includes nested language and author details due to eager loading)."""
    texts = await crud.text.get_multi(db, skip=skip, limit=limit)
    return texts

@router.post("/", response_model=schemas.Text, status_code=status.HTTP_201_CREATED)
async def create_text(
    *,
    db: AsyncSession = Depends(get_db),
    text_in: schemas.TextCreate,
):
    """
    Create new text. 
    Requires a valid language_id. author_id is optional.
    """
    # The specialized crud.text.create handles loading the relationships for the response
    text = await crud.text.create(db=db, obj_in=text_in)
    return text

@router.get("/{text_id}", response_model=schemas.Text)
async def read_text_by_id(
    text_id: int,
    db: AsyncSession = Depends(get_db),
):
    """Get a specific text by ID."""
    text = await crud.text.get(db=db, id=text_id)
    if not text:
        raise HTTPException(status_code=404, detail="Text not found")
    return text

@router.put("/{text_id}", response_model=schemas.Text)
async def update_text(
    *,
    db: AsyncSession = Depends(get_db),
    text_id: int,
    text_in: schemas.TextUpdate,
):
    """Update a text."""
    text_db_obj = await crud.text.get(db=db, id=text_id)
    if not text_db_obj:
        raise HTTPException(status_code=404, detail="Text not found")
    
    await crud.text.update(db=db, db_obj=text_db_obj, obj_in=text_in)
    # After update, we must re-fetch to ensure relationships reflect potential changes (e.g., if author_id changed)
    return await crud.text.get(db=db, id=text_id)

@router.delete("/{text_id}", response_model=schemas.Text)
async def delete_text(
    *,
    db: AsyncSession = Depends(get_db),
    text_id: int,
):
    """Delete a text."""
    text = await crud.text.get(db=db, id=text_id)
    if not text:
        raise HTTPException(status_code=404, detail="Text not found")
    text = await crud.text.remove(db=db, id=text_id)
    return text