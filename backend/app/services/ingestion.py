import logging
from typing import List, Dict, Any
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select
# Import PostgreSQL specific dialect for bulk operations
from sqlalchemy.dialects.postgresql import insert

from app.models.linguistics import Lexeme, Sentence, WordForm
from app.models.text import Text

logger = logging.getLogger(__name__)

async def get_or_create_lexemes_bulk(db: AsyncSession, language_id: int, processed_data: List[Dict[str, Any]]) -> Dict[str, int]:
    """
    Efficiently handles Lexeme creation using INSERT ... ON CONFLICT DO NOTHING.
    Returns a mapping of lemma strings to their database IDs.
    """
    lemmas_to_process = set()
    # Extract unique lemmas from the processed data
    for sentence in processed_data:
        for word in sentence.get("words", []):
            if word["lemma"]:
                # Store lemma and POS (if available)
                lemmas_to_process.add((word["lemma"], word.get("part_of_speech")))

    if not lemmas_to_process:
        return {}

    # Prepare data for bulk insertion
    values = [
        {"language_id": language_id, "lemma": lemma, "part_of_speech": pos}
        for lemma, pos in lemmas_to_process
    ]

    # 1. Bulk Insert with ON CONFLICT DO NOTHING
    # This inserts new lexemes and ignores those that already exist based on the 'uix_language_lemma' constraint.
    stmt = insert(Lexeme).values(values).on_conflict_do_nothing(index_elements=['language_id', 'lemma'])
    await db.execute(stmt)
    # Note: We do not commit here; the parent transaction handles it.

    # 2. Fetch all relevant Lexeme IDs (both new and existing)
    lemma_strings = [lemma for lemma, pos in lemmas_to_process]
    fetch_stmt = select(Lexeme.lemma, Lexeme.id).filter(
        Lexeme.language_id == language_id,
        Lexeme.lemma.in_(lemma_strings)
    )
    result = await db.execute(fetch_stmt)
    
    # Create the mapping {lemma: id}
    # Note: This assumes (language_id, lemma) is unique. If (language_id, lemma, pos) is the intended key, 
    # the model constraint and this mapping logic need adjustment.
    lexeme_map = {row.lemma: row.id for row in result}
    return lexeme_map

async def ingest_processed_data(db: AsyncSession, text_id: int, language_id: int, processed_data: List[Dict[str, Any]]) -> Dict[str, int]:
    """Ingests the structured NLP data into the database using optimized bulk operations."""
    if not processed_data:
        return {"sentences": 0, "words": 0, "lexemes": 0}

    # This function assumes it is running within an active transaction (db.begin())

    # 1. Handle Lexemes (Get or Create)
    lexeme_map = await get_or_create_lexemes_bulk(db, language_id, processed_data)

    # 2. Bulk Insert Sentences using INSERT...RETURNING
    sentence_values = [
        {"text_id": text_id, "order_index": s["order_index"], "content": s["content"]}
        for s in processed_data
    ]
    # 'returning' gets the IDs of the newly inserted sentences efficiently
    insert_sent_stmt = insert(Sentence).values(sentence_values).returning(Sentence.id, Sentence.order_index)
    sent_result = await db.execute(insert_sent_stmt)
    
    # Map sentence order_index to the new database ID
    sentence_id_map = {row.order_index: row.id for row in sent_result}

    # 3. Prepare and Bulk Insert WordForms
    word_form_values = []
    for sentence in processed_data:
        sentence_db_id = sentence_id_map.get(sentence["order_index"])
        if not sentence_db_id:
            continue

        for word in sentence.get("words", []):
            # Map using the lemma string key
            lexeme_id = lexeme_map.get(word["lemma"])
            
            word_form_values.append({
                "sentence_id": sentence_db_id,
                "order_index": word["order_index"],
                "surface_form": word["surface_form"],
                "lexeme_id": lexeme_id,
                "morphology": word["morphology"]
            })

    if word_form_values:
        await db.execute(insert(WordForm).values(word_form_values))

    return {
        "sentences": len(sentence_values),
        "words": len(word_form_values),
        "lexemes": len(lexeme_map)
    }

async def clear_existing_content(db: AsyncSession, text_id: int):
    """Deletes existing sentences (and cascaded WordForms) for a text."""
    # SQLAlchemy cascade configuration handles the deletion of WordForms automatically
    # We use a direct delete statement for efficiency.
    delete_stmt = Sentence.__table__.delete().where(Sentence.text_id == text_id)
    await db.execute(delete_stmt)
    logger.info(f"Cleared existing content for Text ID {text_id}.")