from __future__ import annotations

import logging
import os
import time
from collections import defaultdict, deque
from contextlib import asynccontextmanager
from pathlib import Path
from typing import Deque, Dict, Iterable, List

from dotenv import load_dotenv
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles

from app.api.chat import router as chat_router
from app.api.diag import router as diag_router
from app.api.health import router as health_router
from app.api.health_providers import router as health_providers_router
from app.api.reader import router as reader_router
from app.api.routers.api_keys import router as api_keys_router
from app.api.routers.auth import router as auth_router
from app.api.routers.coach import router as coach_router
from app.api.routers.password_reset import router as password_reset_router
from app.api.routers.progress import router as progress_router
from app.api.routers.users import router as users_router
from app.api.search import router as search_router
from app.core.config import settings
from app.core.logging import setup_logging
from app.db.init_db import initialize_database
from app.db.session import SessionLocal
from app.lesson.router import router as lesson_router
from app.middleware.csrf import csrf_middleware
from app.middleware.rate_limit import rate_limit_middleware
from app.middleware.security_headers import security_headers_middleware
from app.security.middleware import redact_api_keys_middleware
from app.tts import router as tts_router

# Load .env file explicitly for os.getenv() calls below
_backend_dir = Path(__file__).resolve().parent.parent
load_dotenv(_backend_dir / ".env")

# Setup logging immediately
setup_logging()
_LOGGER = logging.getLogger("app.perf")
_default_latency = "1" if settings.is_dev_environment else "0"
_ENABLE_LATENCY = os.getenv("ENABLE_DEV_LATENCY", _default_latency).lower() in {"1", "true", "yes"}
_LATENCY_WINDOW: Dict[str, Deque[float]] = defaultdict(lambda: deque(maxlen=50))
_LATENCY_BINS: tuple[float, ...] = (100.0, 200.0, 400.0, 800.0, 1600.0)

_SERVE_FLUTTER_WEB = os.getenv("SERVE_FLUTTER_WEB", "0").lower() in {"1", "true", "yes"}
_FLUTTER_WEB_ROOT = Path(__file__).resolve().parents[2] / "client" / "flutter_reader" / "build" / "web"


# Define the lifespan function for startup initialization
@asynccontextmanager
async def lifespan(app: FastAPI):
    # Startup logic
    startup_logger = logging.getLogger("app.startup")

    # Log API key availability
    startup_logger.info("Checking vendor API keys...")
    if settings.OPENAI_API_KEY:
        startup_logger.info("OpenAI API key loaded (length: %d)", len(settings.OPENAI_API_KEY))
    else:
        startup_logger.warning("OpenAI API key not configured")

    if settings.ANTHROPIC_API_KEY:
        startup_logger.info("Anthropic API key loaded (length: %d)", len(settings.ANTHROPIC_API_KEY))
    else:
        startup_logger.warning("Anthropic API key not configured")

    if settings.GOOGLE_API_KEY:
        startup_logger.info("Google API key loaded (length: %d)", len(settings.GOOGLE_API_KEY))
    else:
        startup_logger.warning("Google API key not configured")

    startup_logger.info("Echo fallback enabled: %s", settings.ECHO_FALLBACK_ENABLED)

    async with SessionLocal() as db:
        await initialize_database(db)
    yield
    # Shutdown logic


# Initialize the FastAPI app
app = FastAPI(title=settings.PROJECT_NAME, lifespan=lifespan)

# Add rate limiting middleware
app.middleware("http")(rate_limit_middleware)
app.middleware("http")(security_headers_middleware)

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

# Register CSRF protection middleware (only in production by default)
app.middleware("http")(csrf_middleware)


def _histogram_counts(samples: Iterable[float]) -> List[int]:
    counts = [0] * (len(_LATENCY_BINS) + 1)
    for value in samples:
        for idx, threshold in enumerate(_LATENCY_BINS):
            if value <= threshold:
                counts[idx] += 1
                break
        else:
            counts[-1] += 1
    return counts


def _format_histogram(counts: List[int]) -> str:
    labels = [f"<= {int(threshold)}" for threshold in _LATENCY_BINS]
    labels.append(f"> {int(_LATENCY_BINS[-1])}")
    parts = [f"{label}:{count}" for label, count in zip(labels, counts) if count]
    return ", ".join(parts)


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
        log_extra = ""
        if key == "/reader/analyze":
            hist = _format_histogram(_histogram_counts(window))
            if hist:
                log_extra = f" hist=[{hist}]"
        _LOGGER.info(
            "latency path=%s p50=%.1fms p95=%.1fms window=%d%s",
            key,
            p50,
            p95,
            len(window),
            log_extra,
        )
    return response


if _ENABLE_LATENCY:
    app.middleware("http")(_latency_middleware)

# Include the health router
app.include_router(health_router, tags=["Health"])
app.include_router(health_providers_router, tags=["Health"])

# User authentication and profile management (always enabled)
app.include_router(auth_router, prefix="/api/v1", tags=["Authentication"])
app.include_router(password_reset_router, prefix="/api/v1", tags=["Password Reset"])
app.include_router(users_router, prefix="/api/v1", tags=["Users"])
app.include_router(progress_router, prefix="/api/v1", tags=["Progress"])
app.include_router(api_keys_router, prefix="/api/v1", tags=["API Keys"])

app.include_router(search_router, tags=["Search"])
app.include_router(reader_router, tags=["Reader"])
if settings.is_dev_environment:
    app.include_router(diag_router)
if getattr(settings, "LESSONS_ENABLED", False):
    app.include_router(lesson_router)
if getattr(settings, "TTS_ENABLED", False):
    app.include_router(tts_router)
if settings.COACH_ENABLED:
    app.include_router(coach_router)
# Chat is always enabled (echo provider works offline)
app.include_router(chat_router, tags=["Chat"])


@app.get("/")
async def read_root():
    return {"message": f"Welcome to the {settings.PROJECT_NAME}! :-)"}
