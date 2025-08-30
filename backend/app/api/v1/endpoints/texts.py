# backend/app/api/v1/endpoints/texts.py

# Ensure all necessary imports are present at the top of the file
from typing import List
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
import logging

from app.db.session import get_db
from app import crud, schemas
# Import the new services
from app.services.nlp import async_process_text
from app.services.ingestion import ingest_processed_data, clear_existing_content

# Initialize logger if not already present
logger = logging.getLogger(__name__)
router = APIRouter()

# ... (Keep all existing endpoints: read_texts, create_text, read_text_by_id, update_text, delete_text) ...

# New Endpoint: Ingestion Pipeline Trigger
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


# Keep the existing read_content_for_text endpoint
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