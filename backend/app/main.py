from fastapi import FastAPI
from app.core.config import settings

# Initialize the FastAPI app using the settings
app = FastAPI(
    title=settings.PROJECT_NAME,
    openapi_url=f"{settings.API_V1_STR}/openapi.json"
)

@app.get("/")
async def read_root():
    return {"message": f"Welcome to the {settings.PROJECT_NAME}!", "api_version": settings.API_V1_STR}

# Later, we will include routers here
# from app.api import api_router
# app.include_router(api_router, prefix=settings.API_V1_STR)