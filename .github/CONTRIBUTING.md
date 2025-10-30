# Contributing — PRAVIEL

## Prerequisites

- Linux Ubuntu WSL2, Docker Desktop running
- Python 3.13 env: `praviel-env` (uv/pixi)

## Setup

1. **Environment Configuration**
```bash
# Copy the example env file
cp backend/.env.example backend/.env
# Edit backend/.env and add your API keys (see file comments for details)
```

2. **Install Dependencies**
```bash
source praviel-env/bin/activate
uv pip install -e .
pre-commit install -t pre-commit -t pre-push
```

## Database

```bash
# Start DB
docker compose up -d db

# Reset schema and migrate to head
bash scripts/reset_db.sh
```

## Tests & Quality

```bash
cd backend
pytest -q
ruff check . --fix
ruff format .
```

## Migrations

```bash
# From repo root
export DATABASE_URL="postgresql+asyncpg://app:app@localhost:5433/app"
export DATABASE_URL_SYNC="postgresql+psycopg2://app:app@localhost:5433/app"
export PYTHONPATH="$(pwd)/backend"

python -m alembic -c backend/alembic.ini revision --autogenerate -m "explain change"
python -m alembic -c backend/alembic.ini upgrade head
```

## Git Workflow

* Branch from `main`, name like `feat/…`, `fix/…`, `chore/…`.
* Keep commits small, messages conventional (see [https://cbea.ms/git-commit/](https://cbea.ms/git-commit/)).
* Push and open a PR; CI + pre-commit must pass.

## Code Style

* Python 3.13, type hints for public functions, `pathlib` over `os.path` where sensible.
* Comments are minimal and high‑signal (intent, invariants, edge cases).
