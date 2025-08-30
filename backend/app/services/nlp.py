import asyncio
import logging
from typing import Dict, Optional, List, Any
from cltk import NLP
from cltk.core.exceptions import UnknownLanguageError, CLTKException

logger = logging.getLogger(__name__)

# Cache for initialized NLP pipelines
PIPELINE_CACHE: Dict[str, NLP] = {}

def _initialize_pipeline(language_code: str) -> Optional[NLP]:
    """
    Synchronously initializes the CLTK pipeline. Downloads models if necessary.
    """
    if language_code in PIPELINE_CACHE:
        return PIPELINE_CACHE[language_code]

    logger.info(f"Initializing CLTK pipeline for '{language_code}'. This may involve downloading models (e.g., Stanza).")
    try:
        # Initialize NLP. Use 'stanza' backend for robust morphology/lemmatization if available.
        nlp = NLP(language=language_code, suppress_banner=True, backend="stanza")
        
        if not nlp.pipeline:
             # Fallback if Stanza isn't available
             logger.warning(f"Stanza backend not available for {language_code}. Trying default.")
             nlp = NLP(language=language_code, suppress_banner=True)

        if not nlp.pipeline:
            logger.error(f"Failed to initialize any NLP pipeline for '{language_code}'.")
            return None

        PIPELINE_CACHE[language_code] = nlp
        return nlp
    except (UnknownLanguageError, CLTKException) as e:
        logger.error(f"CLTK error for '{language_code}': {e}")
        return None
    except Exception as e:
        logger.error(f"Unexpected error (e.g., network issue) during CLTK initialization: {e}")
        return None

def _sync_process_text(language_code: str, content: str) -> Optional[List[Dict[str, Any]]]:
    """
    The synchronous function that performs the actual NLP processing and structuring.
    """
    # 1. Initialize/Retrieve the pipeline
    nlp = _initialize_pipeline(language_code)
    if not nlp:
        return None

    # 2. Process the text
    try:
        doc = nlp.analyze(content)
    except Exception as e:
        logger.error(f"Error during CLTK analysis for '{language_code}': {e}")
        return None

    # 3. Structure the output for the ingestion service
    structured_data = []
    for sent_idx, sentence in enumerate(doc.sentences):
        sentence_data = {
            "order_index": sent_idx,
            "content": sentence.string,
            "words": []
        }
        for word_idx, word in enumerate(sentence.words):
            # Extract morphology
            morph_dict = {}
            if hasattr(word, 'features') and word.features:
                try:
                    # Attempt to convert CLTK features to a dictionary
                    if isinstance(word.features, dict):
                        morph_dict = word.features
                    elif hasattr(word.features, 'to_dict'):
                         morph_dict = word.features.to_dict()
                except Exception:
                    pass # If conversion fails, proceed with empty dict

            # Ensure POS is included if available
            if word.pos:
                morph_dict["POS"] = word.pos

            sentence_data["words"].append({
                "order_index": word_idx,
                "surface_form": word.string,
                "lemma": word.lemma,
                "part_of_speech": word.pos,
                "morphology": morph_dict if morph_dict else None
            })
        structured_data.append(sentence_data)
        
    return structured_data

async def async_process_text(language_code: str, content: str) -> Optional[List[Dict[str, Any]]]:
    """
    Asynchronously processes text using CLTK by running the synchronous code in a thread pool.
    """
    # Run the synchronous function without blocking the event loop
    response = await asyncio.to_thread(
        _sync_process_text, 
        language_code, 
        content
    )
    return response