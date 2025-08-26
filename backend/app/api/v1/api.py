from fastapi import APIRouter

# Import new endpoints
from app.api.v1.endpoints import (
    languages, scripts, authors, texts, 
    lexemes, sentences, word_forms
)

api_router = APIRouter()

# Organize Tags
api_router.include_router(languages.router, prefix="/languages", tags=["Core Metadata"])
api_router.include_router(scripts.router, prefix="/scripts", tags=["Core Metadata"])
api_router.include_router(authors.router, prefix="/authors", tags=["Core Metadata"])
api_router.include_router(texts.router, prefix="/texts", tags=["Corpus Management"])

# Linguistic Data
api_router.include_router(sentences.router, prefix="/sentences", tags=["Linguistic Data"])
api_router.include_router(word_forms.router, prefix="/word_forms", tags=["Linguistic Data"])
api_router.include_router(lexemes.router, prefix="/lexemes", tags=["Lexicon"])