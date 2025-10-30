# Quick Start Guide (Technical)

Get the PRAVIEL platform running in **5 minutes**.

**🎯 New to the project?** See [BIG_PICTURE.md](../BIG_PICTURE.md) for the vision and language roadmap.
**💻 Comprehensive guide?** See [DEVELOPMENT.md](DEVELOPMENT.md) for full technical documentation.

## Prerequisites

- Python 3.13
- uv or pixi (package managers)
- Docker Desktop
- Git

## Setup

### 1. Clone and Enter Directory

```bash
git clone <your-repo-url>
cd praviel
```

### 2. Start Infrastructure

```bash
docker compose up -d
```

### 3. Configure Environment

```bash
cp backend/.env.example backend/.env
```

**Minimum config** (edit `backend/.env`):
```
DATABASE_URL=postgresql+asyncpg://app:app@localhost:5433/app
REDIS_URL=redis://localhost:6379/0
EMBED_DIM=1536
```

**Optional** - Enable AI features by adding your API keys:
```
OPENAI_API_KEY=sk-proj-your-key-here
ANTHROPIC_API_KEY=sk-ant-api03-your-key-here
GOOGLE_API_KEY=your-google-key-here
LESSONS_ENABLED=1
TTS_ENABLED=1
```

### 4. Install and Run

```bash
# Activate the environment (should already exist)
source praviel-env/bin/activate

# Install dependencies
uv pip install -U pip
uv pip install -e ".[dev]"

# Run database migrations
python -m alembic -c alembic.ini upgrade head

# Start the backend
uvicorn app.main:app --reload
```

### 5. Verify

```bash
curl http://127.0.0.1:8000/health
```

Expected response: `{"status":"ok"}`

### 6. Run Tests

```bash
pytest -q
pre-commit install
pre-commit run --all-files
```

## What's Next?

- **Try the Reader**: Start the Flutter client - see [Flutter Setup](FLUTTER.md)
- **Generate Lessons**: Enable `LESSONS_ENABLED=1` and see [LESSONS.md](LESSONS.md)
- **Use TTS**: Enable `TTS_ENABLED=1` and see [TTS.md](TTS.md)
- **Understand the APIs**: Read [AI_AGENT_GUIDELINES.md](AI_AGENT_GUIDELINES.md) for October 2025 API specs

## Troubleshooting

**Database not ready?**
```bash
docker compose logs db  # Check logs
docker compose down -v && docker compose up -d  # Reset
```

**Tests failing?**
```bash
docker compose up -d  # Ensure DB is running
python -m alembic -c alembic.ini upgrade head  # Run migrations
```
