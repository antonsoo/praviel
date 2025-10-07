# Docker Deployment Guide

This guide covers containerized deployment of the Ancient Languages API using Docker and Docker Compose.

## Quick Start

### 1. Generate Security Keys

Before deploying, generate secure secrets:

```bash
# Generate JWT secret key
python -c "import secrets; print(secrets.token_urlsafe(32))"

# Generate encryption key (required if BYOK is enabled)
python -c "from cryptography.fernet import Fernet; print(Fernet.generate_key().decode())"
```

### 2. Create Environment File

Copy the example environment file and fill in your secrets:

```bash
cp .env.docker .env
# Edit .env and add your generated secrets and API keys
```

**CRITICAL:** You MUST change `JWT_SECRET_KEY` and `ENCRYPTION_KEY` before deploying to production!

### 3. Start Services

```bash
# Start all services (database, redis, backend)
docker compose up -d

# View logs
docker compose logs -f backend

# Check health
curl http://localhost:8000/health
```

### 4. Initialize Database

The database needs to be initialized on first run:

```bash
# Run migrations
docker compose exec backend alembic upgrade head

# Optional: Seed initial data (creates Greek and Latin language records)
docker compose exec backend python setup_db.py
```

**Note:** The container uses `alembic.docker.ini` which is automatically copied as `alembic.ini` inside the container. This is necessary because the directory structure differs from the development environment.

## Architecture

The Docker setup includes:

- **db**: PostgreSQL 16 with pgvector extension
- **redis**: Redis 7 for caching/sessions
- **backend**: FastAPI application (Python 3.12.11)

## Configuration

### Environment Variables

The backend service is configured via environment variables. See [.env.docker](.env.docker) for a complete example.

**Required for Production:**
- `JWT_SECRET_KEY`: Secure random string for JWT signing
- `ENCRYPTION_KEY`: Fernet key for encrypting user API keys (if BYOK enabled)
- `DATABASE_URL`: PostgreSQL connection string (auto-configured in docker-compose.yml)
- `REDIS_URL`: Redis connection string (auto-configured in docker-compose.yml)

**Optional API Keys (Server-side fallback):**
- `OPENAI_API_KEY`
- `ANTHROPIC_API_KEY`
- `GOOGLE_API_KEY`

### Model Defaults

The application uses **October 2025 API models**:

- **OpenAI**: GPT-5 (gpt-5-mini, gpt-5-nano)
- **Anthropic**: Claude 4.5/4.1 (claude-sonnet-4-5, claude-opus-4-1)
- **Google**: Gemini 2.5 (gemini-2.5-flash, gemini-2.5-pro)

**DO NOT change these to older model names.** These are protected by validation in `backend/app/core/config.py`.

See [AI_AGENT_GUIDELINES.md](AI_AGENT_GUIDELINES.md) for complete API specifications.

## Development vs Production

### Development Mode

For development with hot-reload:

```yaml
# Uncomment in docker-compose.yml
volumes:
  - ./backend:/app
command: uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
```

Then:
```bash
docker compose up backend
```

### Production Mode

Production deployment (default configuration):

```bash
# Build and start
docker compose up -d

# Scale workers
docker compose up -d --scale backend=3
```

## Docker Image Details

The [Dockerfile](../Dockerfile) uses a multi-stage build:

**Stage 1 (builder):**
- Base: `python:3.12.11-slim`
- Installs build dependencies
- Installs Python packages from `pyproject.toml`

**Stage 2 (runtime):**
- Base: `python:3.12.11-slim`
- Copies only runtime dependencies
- Runs as non-root user (`appuser`)
- Includes health check via `/health` endpoint

**Key Features:**
- ✅ Python 3.12.11 (matches development environment)
- ✅ Multi-stage build for smaller image size
- ✅ Non-root user for security
- ✅ Health check for container orchestration
- ✅ Uses `pyproject.toml` for dependency management

## Common Operations

### View Logs

```bash
# All services
docker compose logs -f

# Just backend
docker compose logs -f backend

# Just database
docker compose logs -f db
```

### Database Operations

```bash
# Run migrations
docker compose exec backend alembic upgrade head

# Create new migration
docker compose exec backend alembic revision --autogenerate -m "description"

# Rollback migration
docker compose exec backend alembic downgrade -1

# Connect to database
docker compose exec db psql -U app -d app
```

### Rebuild After Code Changes

```bash
# Rebuild backend image
docker compose build backend

# Restart with new image
docker compose up -d backend
```

### Clean Up

```bash
# Stop and remove containers
docker compose down

# Also remove volumes (WARNING: deletes data!)
docker compose down -v

# Remove images
docker rmi ancient-languages-backend
```

## Production Deployment Checklist

- [ ] Generate secure `JWT_SECRET_KEY` (≥32 characters)
- [ ] Generate secure `ENCRYPTION_KEY` (Fernet key)
- [ ] Set `ENVIRONMENT=production`
- [ ] Set `ALLOW_DEV_CORS=false`
- [ ] Configure API keys (if not using BYOK)
- [ ] Review and adjust token expiration times
- [ ] Configure firewall rules (expose port 8000 or use reverse proxy)
- [ ] Set up SSL/TLS termination (nginx, Traefik, etc.)
- [ ] Configure log aggregation
- [ ] Set up monitoring (health checks, metrics)
- [ ] Configure database backups
- [ ] Test rollback procedure
- [ ] Review security settings in `backend/app/core/config.py`

## Troubleshooting

### Container won't start

```bash
# Check logs
docker compose logs backend

# Check if ports are already in use
docker compose ps
netstat -an | grep 8000
```

### Database connection errors

```bash
# Verify database is healthy
docker compose ps db

# Check database logs
docker compose logs db

# Verify connection from backend
docker compose exec backend python -c "from app.db.session import SessionLocal; SessionLocal()"
```

### Health check failing

```bash
# Check health endpoint manually
docker compose exec backend curl http://localhost:8000/health

# Check if app is running
docker compose exec backend ps aux | grep uvicorn
```

### "Module not found" errors

This usually means dependencies weren't installed correctly:

```bash
# Rebuild from scratch
docker compose build --no-cache backend
docker compose up -d backend
```

## Security Notes

1. **Never commit `.env` files** containing real secrets to git
2. **Use Docker secrets** or external secret management in production
3. **Limit container capabilities** if deploying to orchestration platform
4. **Regularly update base images** for security patches
5. **Use read-only root filesystem** if possible (requires volume mounts for data)
6. **Scan images for vulnerabilities**: `docker scan ancient-languages-backend`

## Performance Tuning

### Worker Processes

Control uvicorn workers via environment variable:

```yaml
environment:
  UVICORN_WORKERS: 4
```

Or override the command:

```yaml
command: uvicorn app.main:app --host 0.0.0.0 --port 8000 --workers 4
```

### Database Connection Pool

Configure in `.env`:

```bash
# SQLAlchemy pool settings
SQLALCHEMY_POOL_SIZE=20
SQLALCHEMY_MAX_OVERFLOW=10
```

### Resource Limits

Set in `docker-compose.yml`:

```yaml
deploy:
  resources:
    limits:
      cpus: '2.0'
      memory: 2G
    reservations:
      cpus: '1.0'
      memory: 1G
```

## Integration with Orchestration Platforms

### Kubernetes

The Docker image can be deployed to Kubernetes. You'll need to:

1. Push image to container registry
2. Create Kubernetes manifests (Deployment, Service, Ingress)
3. Configure secrets via Kubernetes Secrets
4. Set up persistent volumes for data
5. Configure health checks and probes

### AWS ECS/Fargate

1. Push image to ECR
2. Create ECS task definition
3. Configure environment variables
4. Set up Application Load Balancer
5. Configure auto-scaling

### Google Cloud Run

```bash
# Build and push
gcloud builds submit --tag gcr.io/PROJECT-ID/ancient-languages-backend

# Deploy
gcloud run deploy ancient-languages-api \
  --image gcr.io/PROJECT-ID/ancient-languages-backend \
  --platform managed \
  --allow-unauthenticated
```

## Next Steps

- Review [CLAUDE.md](../CLAUDE.md) for project structure
- Review [AI_AGENT_GUIDELINES.md](AI_AGENT_GUIDELINES.md) for API specifications
- Review [QUICKSTART_AUTH.md](../QUICKSTART_AUTH.md) for authentication setup
- Review [CONTRIBUTING.md](../CONTRIBUTING.md) for development guidelines
