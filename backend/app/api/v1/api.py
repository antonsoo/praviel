from fastapi import APIRouter

from app.api.v1.endpoints import languages, scripts

api_router = APIRouter()

# Include the routers, assigning prefixes and tags for organization in the docs
api_router.include_router(languages.router, prefix="/languages", tags=["Languages"])
api_router.include_router(scripts.router, prefix="/scripts", tags=["Scripts"])