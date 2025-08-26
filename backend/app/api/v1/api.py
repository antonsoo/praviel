from fastapi import APIRouter

# Import new endpoints
from app.api.v1.endpoints import languages, scripts, authors, texts 

api_router = APIRouter()

# Include the routers, assigning prefixes and tags for organization in the docs
api_router.include_router(languages.router, prefix="/languages", tags=["Languages"])
api_router.include_router(scripts.router, prefix="/scripts", tags=["Scripts"])
api_router.include_router(authors.router, prefix="/authors", tags=["Authors"])
api_router.include_router(texts.router, prefix="/texts", tags=["Texts"])