from fastapi import FastAPI
from app.core.config import settings
# Import the API router
from app.api.v1.api import api_router

# Initialize the FastAPI app
app = FastAPI(
    title=settings.PROJECT_NAME,
    # The OpenAPI schema location is tied to the API version prefix
    openapi_url=f"{settings.API_V1_STR}/openapi.json"
)

# Include the aggregated API router with the version prefix (e.g., /api/v1)
app.include_router(api_router, prefix=settings.API_V1_STR)

@app.get("/")
async def read_root():
    # Provide a link to the docs for convenience
    return {"message": f"Welcome to the {settings.PROJECT_NAME}!", "docs_url": "/docs"}