from typing import List
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.db.session import get_db
from app import crud, schemas

router = APIRouter()

@router.get("/", response_model=List[schemas.Author])
async def read_authors(
    db: AsyncSession = Depends(get_db),
    skip: int = 0,
    limit: int = 100,
):
    """Retrieve authors."""
    authors = await crud.author.get_multi(db, skip=skip, limit=limit)
    return authors

@router.post("/", response_model=schemas.Author, status_code=status.HTTP_201_CREATED)
async def create_author(
    *,
    db: AsyncSession = Depends(get_db),
    author_in: schemas.AuthorCreate,
):
    """Create new author."""
    author = await crud.author.create(db=db, obj_in=author_in)
    return author

@router.get("/{author_id}", response_model=schemas.Author)
async def read_author_by_id(
    author_id: int,
    db: AsyncSession = Depends(get_db),
):
    """Get a specific author by ID."""
    author = await crud.author.get(db=db, id=author_id)
    if not author:
        raise HTTPException(status_code=404, detail="Author not found")
    return author

@router.put("/{author_id}", response_model=schemas.Author)
async def update_author(
    *,
    db: AsyncSession = Depends(get_db),
    author_id: int,
    author_in: schemas.AuthorUpdate,
):
    """Update an author."""
    author = await crud.author.get(db=db, id=author_id)
    if not author:
        raise HTTPException(status_code=404, detail="Author not found")
    author = await crud.author.update(db=db, db_obj=author, obj_in=author_in)
    return author

@router.delete("/{author_id}", response_model=schemas.Author)
async def delete_author(
    *,
    db: AsyncSession = Depends(get_db),
    author_id: int,
):
    """Delete an author."""
    author = await crud.author.get(db=db, id=author_id)
    if not author:
        raise HTTPException(status_code=404, detail="Author not found")
    # Note: Deletion will fail if the author is still associated with any texts (FK constraint).
    author = await crud.author.remove(db=db, id=author_id)
    return author