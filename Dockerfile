# syntax=docker/dockerfile:1.4
# Multi-stage build for production deployment
# Uses Python 3.12.11 to match development environment (praviel conda env)
# BuildKit syntax enables advanced features like cache mounts

# Stage 1: Builder - Install dependencies
FROM python:3.12.11-slim AS builder

WORKDIR /build

# Install system dependencies for building Python packages
# Combined in single layer to minimize image size
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    libpq-dev \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Copy only pyproject.toml first for better layer caching
# This layer won't rebuild unless dependencies change
COPY pyproject.toml ./

# Install production dependencies with pip cache mount for faster rebuilds
# BuildKit cache mount persists pip cache across builds
RUN --mount=type=cache,target=/root/.cache/pip \
    pip install --upgrade pip && \
    python -c "import tomllib; deps = tomllib.load(open('pyproject.toml', 'rb'))['project']['dependencies']; [print(d) for d in deps]" | \
    xargs pip install

# Now copy application code (frequently changing layer, but doesn't invalidate dependency cache above)
COPY backend/ ./backend/

# Install the package itself (fast since dependencies already installed)
RUN --mount=type=cache,target=/root/.cache/pip \
    pip install --no-deps -e .

# Stage 2: Runtime - Minimal production image
FROM python:3.12.11-slim

WORKDIR /app

# Install runtime system dependencies only (no build tools)
RUN apt-get update && apt-get install -y --no-install-recommends \
    libpq5 \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Create non-root user for security
RUN useradd -m -u 1000 appuser && \
    chown -R appuser:appuser /app

# Copy installed Python packages from builder
COPY --from=builder /usr/local/lib/python3.12/site-packages /usr/local/lib/python3.12/site-packages
COPY --from=builder /usr/local/bin /usr/local/bin

# Copy application code
COPY --chown=appuser:appuser backend/ ./

# Copy alembic configuration for database migrations
# Use Docker-specific config since directory structure is different in container
COPY --chown=appuser:appuser alembic.docker.ini ./alembic.ini

# Create data directories with correct ownership
# The app expects data/ to be OUTSIDE backend/ (one level up from /app)
# BASE_DIR is /app (backend/), so ../data resolves to /data
# Important: Create as root first, then chown, BEFORE switching to appuser
RUN mkdir -p /data/vendor /data/derived && \
    chown -R appuser:appuser /data

# Switch to non-root user
USER appuser

# Environment variables
# Override data paths to use the container's /data directory
ENV PYTHONPATH=/app \
    PYTHONUNBUFFERED=1 \
    ENVIRONMENT=production \
    DATA_VENDOR_ROOT=/data/vendor \
    DATA_DERIVED_ROOT=/data/derived

# Expose FastAPI port
EXPOSE 8000

# Health check using curl (simpler and more reliable than Python script)
# The /health endpoint is defined in backend/app/api/health.py
HEALTHCHECK --interval=30s --timeout=10s --start-period=40s --retries=3 \
    CMD curl -f http://localhost:8000/health || exit 1

# Run uvicorn server
# Use --host 0.0.0.0 to bind to all interfaces (required for Docker)
# Workers can be controlled via environment variable UVICORN_WORKERS
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
