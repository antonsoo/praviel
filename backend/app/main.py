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

# Sentry error tracking (import early for maximum coverage)
try:
    import sentry_sdk
    from sentry_sdk.integrations.fastapi import FastApiIntegration
    from sentry_sdk.integrations.sqlalchemy import SqlalchemyIntegration

    SENTRY_AVAILABLE = True
except ImportError:
    SENTRY_AVAILABLE = False
from fastapi.openapi.docs import get_swagger_ui_html, get_swagger_ui_oauth2_redirect_html
from fastapi.staticfiles import StaticFiles

from app.api.chat import router as chat_router
from app.api.diag import router as diag_router
from app.api.health import router as health_router
from app.api.health_providers import router as health_providers_router
from app.api.languages import router as languages_router
from app.api.reader import router as reader_router
from app.api.routers.api_keys import router as api_keys_router
from app.api.routers.auth import router as auth_router
from app.api.routers.coach import router as coach_router
from app.api.routers.daily_challenges import router as daily_challenges_router
from app.api.routers.demo_usage import router as demo_usage_router
from app.api.routers.email_preferences import router as email_preferences_router
from app.api.routers.email_verification import router as email_verification_router
from app.api.routers.gamification import router as gamification_router
from app.api.routers.password_reset import router as password_reset_router
from app.api.routers.progress import router as progress_router
from app.api.routers.pronunciation import router as pronunciation_router
from app.api.routers.quests import router as quests_router
from app.api.routers.script_preferences import router as script_preferences_router
from app.api.routers.social import router as social_router
from app.api.routers.srs import router as srs_router
from app.api.routers.support import router as support_router
from app.api.routers.users import router as users_router
from app.api.search import router as search_router
from app.core.config import settings
from app.core.logging import setup_logging
from app.db.init_db import initialize_database
from app.db.session import SessionLocal
from app.lesson.router import router as lesson_router
from app.lesson.vocabulary_router import router as vocabulary_router
from app.middleware.csrf import csrf_middleware
from app.middleware.rate_limit import rate_limit_middleware
from app.middleware.security_headers import security_headers_middleware
from app.security.middleware import redact_api_keys_middleware
from app.tasks import task_runner
from app.tts import router as tts_router

# Load .env file explicitly for os.getenv() calls below
_backend_dir = Path(__file__).resolve().parent.parent
load_dotenv(_backend_dir / ".env")

# Setup logging immediately
setup_logging()

# Initialize Sentry for production error tracking
if SENTRY_AVAILABLE and settings.SENTRY_DSN and not settings.is_dev_environment:
    sentry_sdk.init(
        dsn=settings.SENTRY_DSN,
        integrations=[
            FastApiIntegration(),
            SqlalchemyIntegration(),
        ],
        traces_sample_rate=0.1,  # Sample 10% of transactions for performance monitoring
        environment=settings.ENVIRONMENT,
        release=os.getenv("RAILWAY_GIT_COMMIT_SHA", "unknown"),  # Track deployments
        send_default_pii=False,  # Don't send PII by default
    )
    logging.getLogger("app.startup").info("Sentry error tracking initialized")
elif settings.SENTRY_DSN and not SENTRY_AVAILABLE:
    logging.getLogger("app.startup").warning(
        "SENTRY_DSN configured but sentry-sdk not installed. "
        "Install with: pip install sentry-sdk[fastapi,sqlalchemy]"
    )

_LOGGER = logging.getLogger("app.perf")
_default_latency = "1" if settings.is_dev_environment else "0"
_ENABLE_LATENCY = os.getenv("ENABLE_DEV_LATENCY", _default_latency).lower() in {"1", "true", "yes"}
_LATENCY_WINDOW: Dict[str, Deque[float]] = defaultdict(lambda: deque(maxlen=50))
_LATENCY_BINS: tuple[float, ...] = (100.0, 200.0, 400.0, 800.0, 1600.0)

_SERVE_FLUTTER_WEB = os.getenv("SERVE_FLUTTER_WEB", "0").lower() in {"1", "true", "yes"}
_FLUTTER_WEB_ROOT = Path(__file__).resolve().parents[2] / "client" / "flutter_reader" / "build" / "web"
_SWAGGER_UI_DIR = Path(__file__).resolve().parent / "static" / "swagger-ui"


# Define the lifespan function for startup initialization
@asynccontextmanager
async def lifespan(app: FastAPI):
    # Startup logic
    startup_logger = logging.getLogger("app.startup")
    is_testing = os.getenv("TESTING") == "1"

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

    # Initialize database (wrapped in try/except to prevent startup crashes)
    try:
        async with SessionLocal() as db:
            await initialize_database(db)
    except Exception as exc:
        startup_logger.error(
            "Database connection failed: %s. App will start but database features won't work. "
            "Check DATABASE_URL and ensure PostgreSQL is accessible.",
            exc,
            exc_info=True,
        )

    # Start scheduled tasks only outside of test mode
    if not is_testing:
        startup_logger.info("Starting scheduled tasks...")
        try:
            await task_runner.start()
        except Exception as exc:
            startup_logger.error("Task runner failed to start: %s. Background tasks won't run.", exc)
    else:
        startup_logger.info("Skipping scheduled tasks (TESTING=1)")

    # Start email scheduler
    if not is_testing:
        startup_logger.info("Starting email scheduler...")
        try:
            from app.jobs.scheduler import email_scheduler

            await email_scheduler.start()
        except ImportError:
            startup_logger.warning("APScheduler not installed - email jobs will not run")
        except Exception as exc:
            startup_logger.error(f"Failed to start email scheduler: {exc}")
    else:
        startup_logger.info("Skipping email scheduler (TESTING=1)")

    yield

    # Shutdown logic - stop scheduled tasks
    if not is_testing:
        startup_logger.info("Stopping scheduled tasks...")
        await task_runner.stop()

        startup_logger.info("Stopping email scheduler...")
        try:
            from app.jobs.scheduler import email_scheduler

            await email_scheduler.stop()
        except Exception as exc:
            startup_logger.error(f"Failed to stop email scheduler: {exc}")
    else:
        startup_logger.info("Test mode shutdown; background schedulers were not started")
    # Shutdown logic


# Initialize the FastAPI app
app = FastAPI(title=settings.PROJECT_NAME, lifespan=lifespan, docs_url=None, redoc_url=None)

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

# Mount audio cache directory for serving generated TTS audio
_AUDIO_CACHE_DIR = Path(__file__).resolve().parent.parent / "audio_cache"
_AUDIO_CACHE_DIR.mkdir(parents=True, exist_ok=True)
app.mount("/audio", StaticFiles(directory=str(_AUDIO_CACHE_DIR)), name="audio-cache")
_LOGGER.info("Serving audio cache from %s at /audio/", _AUDIO_CACHE_DIR)

if _SWAGGER_UI_DIR.exists():
    app.mount("/docs/static", StaticFiles(directory=str(_SWAGGER_UI_DIR)), name="swagger-ui-static")
else:
    _LOGGER.warning(
        "Swagger UI assets missing at %s; /docs will fall back to CDN assets.",
        _SWAGGER_UI_DIR,
    )

if settings.dev_cors_enabled:
    app.add_middleware(
        CORSMiddleware,
        allow_origin_regex=r"^https?://(localhost|127\.0\.0\.1)(:\d+)?$",
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["*"],
        expose_headers=["X-CSRF-Token"],
        max_age=3600,
    )
else:
    # Production CORS: Allow praviel.com domains + Cloudflare Pages deployments
    # Use regex to support all *.pages.dev preview URLs for Cloudflare Pages
    allowed_origins = [
        "https://praviel.com",
        "https://app.praviel.com",
        "https://www.praviel.com",
    ]

    # Build regex pattern: praviel.com domains OR *.pages.dev domains
    # This allows all Cloudflare Pages preview deployments (including subdomains with dots)
    origin_regex = r"^https://(praviel\.com|app\.praviel\.com|www\.praviel\.com|[a-zA-Z0-9.-]+\.pages\.dev)$"

    # Log CORS configuration for debugging
    startup_logger = logging.getLogger("app.startup")
    startup_logger.info(
        "CORS configured with regex pattern and allowed origins: %s", ", ".join(allowed_origins)
    )
    startup_logger.info("CORS origin regex: %s", origin_regex)

    app.add_middleware(
        CORSMiddleware,
        allow_origin_regex=origin_regex,  # Regex pattern for praviel.com and *.pages.dev
        allow_credentials=True,
        allow_methods=["GET", "POST", "PUT", "DELETE", "PATCH"],
        allow_headers=["*"],
        expose_headers=["X-CSRF-Token"],
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
app.include_router(email_verification_router, prefix="/api/v1", tags=["Email Verification"])
app.include_router(password_reset_router, prefix="/api/v1", tags=["Password Reset"])
app.include_router(users_router, prefix="/api/v1", tags=["Users"])
app.include_router(email_preferences_router, prefix="/api/v1", tags=["Email Preferences"])
app.include_router(script_preferences_router, prefix="/api/v1", tags=["Script Preferences"])
app.include_router(progress_router, prefix="/api/v1", tags=["Progress"])
app.include_router(quests_router, prefix="/api/v1", tags=["Quests"])
app.include_router(social_router, prefix="/api/v1", tags=["Social"])
app.include_router(gamification_router, prefix="/api/v1", tags=["Gamification"])
app.include_router(daily_challenges_router, prefix="/api/v1", tags=["Daily Challenges"])
app.include_router(srs_router, prefix="/api/v1", tags=["SRS"])
app.include_router(api_keys_router, prefix="/api/v1", tags=["API Keys"])
app.include_router(demo_usage_router, prefix="/api/v1", tags=["Demo Usage"])
app.include_router(pronunciation_router, prefix="/api/v1", tags=["Pronunciation"])
app.include_router(support_router, prefix="/api/v1", tags=["Support"])

app.include_router(search_router, tags=["Search"])
app.include_router(reader_router, tags=["Reader"])
app.include_router(languages_router, prefix="/api/v1", tags=["Languages"])
if settings.is_dev_environment:
    app.include_router(diag_router)
if getattr(settings, "LESSONS_ENABLED", False):
    app.include_router(lesson_router)
    app.include_router(vocabulary_router)  # Vocabulary API under same LESSONS_ENABLED flag
if getattr(settings, "TTS_ENABLED", False):
    app.include_router(tts_router)
if settings.COACH_ENABLED:
    app.include_router(coach_router)
# Chat is always enabled (echo provider works offline)
app.include_router(chat_router, tags=["Chat"])


@app.get("/docs", include_in_schema=False)
async def custom_swagger_ui_html():
    """Serve Swagger UI using local assets when available to avoid CDN blank pages."""
    if _SWAGGER_UI_DIR.exists():
        return get_swagger_ui_html(
            openapi_url=app.openapi_url,
            title=f"{settings.PROJECT_NAME} - Swagger UI",
            swagger_js_url="/docs/static/swagger-ui-bundle.js",
            swagger_css_url="/docs/static/swagger-ui.css",
        )
    return get_swagger_ui_html(
        openapi_url=app.openapi_url,
        title=f"{settings.PROJECT_NAME} - Swagger UI",
    )


@app.get("/docs/oauth2-redirect", include_in_schema=False)
async def swagger_ui_redirect():
    return get_swagger_ui_oauth2_redirect_html()


@app.get("/")
async def read_root():
    return {"message": f"Welcome to the {settings.PROJECT_NAME}! :-)"}
