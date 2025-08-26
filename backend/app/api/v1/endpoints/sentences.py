from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.db.session import get_db
from app import crud, schemas

router = APIRouter()

@router.post("/", response_model=schemas.Sentence, status_code=status.HTTP_201_CREATED)
async def create_sentence(
    *,
    db: AsyncSession = Depends(get_db),
    sentence_in: schemas.SentenceCreate,
):
    """Create new sentence."""
    sentence = await crud.sentence.create(db=db, obj_in=sentence_in)
    return sentence

@router.get("/{sentence_id}", response_model=schemas.Sentence)
async def read_sentence_by_id(
    sentence_id: int,
    db: AsyncSession = Depends(get_db),
):
    """
    Get a specific sentence by ID. 
    Includes deeply nested WordForms and their associated Lexemes.
    """
    sentence = await crud.sentence.get(db=db, id=sentence_id)
    if not sentence:
        raise HTTPException(status_code=404, detail="Sentence not found")
    return sentence