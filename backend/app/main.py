from contextlib import asynccontextmanager

from fastapi import FastAPI

from app.api.health import router as health_router
from app.api.reader import router as reader_router
from app.api.search import router as search_router
from app.core.config import settings
from app.core.logging import setup_logging
from app.db.init_db import initialize_database
from app.db.session import SessionLocal
from app.security.middleware import redact_api_keys_middleware

# Setup logging immediately
setup_logging()


# Define the lifespan function for startup initialization
@asynccontextmanager
async def lifespan(app: FastAPI):
    # Startup logic
    async with SessionLocal() as db:
        await initialize_database(db)
    yield
    # Shutdown logic


# Initialize the FastAPI app
app = FastAPI(title=settings.PROJECT_NAME, lifespan=lifespan)

# Register the BYOK redaction middleware
app.middleware("http")(redact_api_keys_middleware)

# Include the health router
app.include_router(health_router, tags=["Health"])
app.include_router(search_router, tags=["Search"])
app.include_router(reader_router, tags=["Reader"])


@app.get("/")
async def read_root():
    return {"message": f"Welcome to the {settings.PROJECT_NAME}! :-)"}
