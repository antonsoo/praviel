from app.api.deps.filters import TextFilters
from typing import List
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
import logging

from app.db.session import get_db
from app import crud, schemas
# Import the new services
from app.services.nlp import async_process_text
from app.services.ingestion import ingest_processed_data, clear_existing_content

logger = logging.getLogger(__name__)
router = APIRouter()

@router.get("/", response_model=List[schemas.Text])
async def read_texts(
    db: AsyncSession = Depends(get_db),
    skip: int = 0,
    limit: int = 100,
    # Inject the filters dependency
    filters: TextFilters = Depends(),
):
    """Retrieve texts (includes nested details). Use query parameters for filtering."""
    # Pass the filters object to the CRUD method
    texts = await crud.text.get_multi(db, skip=skip, limit=limit, filters=filters)
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
    
# Nested route for retrieving analyzed content of a specific text
@router.get("/{text_id}/content/", response_model=List[schemas.Sentence])
async def read_content_for_text(
    text_id: int,
    db: AsyncSession = Depends(get_db),
    skip: int = 0,
    limit: int = 50, # Limit the amount of deeply nested data returned at once
):
    """
    Retrieve the analyzed content (Sentences, WordForms, Lexemes) for a specific text, ordered correctly.
    """
    # First, verify the text exists
    text = await crud.text.get(db=db, id=text_id)
    if not text:
        raise HTTPException(status_code=404, detail="Text not found")

    # Use the specialized CRUD method which handles the deep loading
    sentences = await crud.sentence.get_multi_by_text(
        db, text_id=text_id, skip=skip, limit=limit
    )
    return sentences


# Ingestion Pipeline Trigger
@router.post("/{text_id}/ingest/", response_model=schemas.IngestionResponse)
async def ingest_text(
    text_id: int,
    request: schemas.TextIngestRequest,
    db: AsyncSession = Depends(get_db),
):
    """
    Triggers the NLP ingestion pipeline for the specified text.
    Segments, tokenizes, lemmatizes (using CLTK), and stores the structured data.
    Requires the Text's language to have a valid ISO 639-3 code (e.g., 'lat', 'grc').
    """
    # 1. Validate Text and Language Metadata
    # crud.text.get eagerly loads the language relationship.
    text_obj = await crud.text.get(db=db, id=text_id)
    if not text_obj:
        raise HTTPException(status_code=404, detail="Text not found")

    if not text_obj.language or not text_obj.language.iso_639_3_code:
         raise HTTPException(status_code=422, detail="Text metadata lacks required Language ISO 639-3 code for NLP.")
    
    iso_code = text_obj.language.iso_639_3_code

    # 2. Perform NLP Processing (Asynchronously)
    logger.info(f"Starting async NLP processing for Text ID {text_id} ({iso_code})...")
    processed_data = await async_process_text(iso_code, request.raw_content)
    
    if processed_data is None:
        raise HTTPException(status_code=503, detail=f"NLP service unavailable or failed for language '{iso_code}'. Check server logs.")

    # 3. Ingest Data (Transactionally)
    logger.info(f"Starting bulk ingestion for Text ID {text_id}...")
    try:
        # Use db.begin() to ensure the entire ingestion process is atomic (all or nothing)
        async with db.begin():
            # Handle Overwrite Logic
            if request.overwrite_existing:
                await clear_existing_content(db, text_id)
            
            # Ingest the data using optimized bulk operations
            stats = await ingest_processed_data(
                db, text_id, text_obj.language_id, processed_data
            )
        
        # Transaction commits automatically here
        return schemas.IngestionResponse(
            message="Ingestion successful.",
            text_id=text_id,
            language_code=iso_code,
            stats=stats
        )

    except Exception as e:
        # Transaction rolls back automatically here
        logger.error(f"Ingestion transaction failed for Text ID {text_id}: {e}", exc_info=True)
        raise HTTPException(status_code=500, detail="Ingestion transaction failed.")
