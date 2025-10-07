# Multi-stage build for production deployment
# Uses Python 3.12.11 to match development environment (ancient-languages-py312 conda env)

# Stage 1: Builder - Install dependencies
FROM python:3.12.11-slim AS builder

WORKDIR /build

# Install system dependencies for building Python packages
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    libpq-dev \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Copy pyproject.toml and install package with dependencies
# This project uses pyproject.toml, not requirements.txt
COPY pyproject.toml ./
COPY backend/ ./backend/

# Install the package and its dependencies
# Use --no-cache-dir to reduce image size
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir .

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
