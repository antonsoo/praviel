from __future__ import annotations

import logging
import os
import time
from collections import defaultdict, deque
from contextlib import asynccontextmanager
from pathlib import Path
from typing import Deque, Dict

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles

from app.api.health import router as health_router
from app.api.reader import router as reader_router
from app.api.routers.coach import router as coach_router
from app.api.search import router as search_router
from app.core.config import settings
from app.core.logging import setup_logging
from app.db.init_db import initialize_database
from app.db.session import SessionLocal
from app.security.middleware import redact_api_keys_middleware

# Setup logging immediately
setup_logging()
_LOGGER = logging.getLogger("app.perf")
_default_latency = "1" if settings.is_dev_environment else "0"
_ENABLE_LATENCY = os.getenv("ENABLE_DEV_LATENCY", _default_latency).lower() in {"1", "true", "yes"}
_LATENCY_WINDOW: Dict[str, Deque[float]] = defaultdict(lambda: deque(maxlen=50))

_SERVE_FLUTTER_WEB = os.getenv("SERVE_FLUTTER_WEB", "0").lower() in {"1", "true", "yes"}
_FLUTTER_WEB_ROOT = Path(__file__).resolve().parents[2] / "client" / "flutter_reader" / "build" / "web"


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

if _SERVE_FLUTTER_WEB:
    if _FLUTTER_WEB_ROOT.exists():
        app.mount("/app", StaticFiles(directory=str(_FLUTTER_WEB_ROOT), html=True), name="flutter-web")
        _LOGGER.info("Serving Flutter web build from %s at /app/", _FLUTTER_WEB_ROOT)
    else:
        _LOGGER.warning(
            "SERVE_FLUTTER_WEB=1 but %s missing; run `flutter build web` first.", _FLUTTER_WEB_ROOT
        )

if settings.dev_cors_enabled:
    app.add_middleware(
        CORSMiddleware,
        allow_origin_regex=r"^https?://(localhost|127\.0\.0\.1)(:\d+)?$",
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["*"],
        max_age=3600,
    )
# Register the BYOK redaction middleware
app.middleware("http")(redact_api_keys_middleware)


async def _latency_middleware(request, call_next):  # pragma: no cover - simple instrumentation
    start = time.perf_counter()
    response = await call_next(request)
    duration_ms = (time.perf_counter() - start) * 1000.0

    key = request.url.path
    window = _LATENCY_WINDOW[key]
    window.append(duration_ms)
    if len(window) >= 10:
        ordered = sorted(window)
        p50 = ordered[int(0.5 * (len(ordered) - 1))]
        p95 = ordered[int(0.95 * (len(ordered) - 1))]
        _LOGGER.info(
            "latency path=%s p50=%.1fms p95=%.1fms window=%d",
            key,
            p50,
            p95,
            len(window),
        )
    return response


if _ENABLE_LATENCY:
    app.middleware("http")(_latency_middleware)

# Include the health router
app.include_router(health_router, tags=["Health"])
app.include_router(search_router, tags=["Search"])
app.include_router(reader_router, tags=["Reader"])
if settings.COACH_ENABLED:
    app.include_router(coach_router)


@app.get("/")
async def read_root():
    return {"message": f"Welcome to the {settings.PROJECT_NAME}! :-)"}
