# Contributing — AncientLanguages

## Prerequisites

- Windows 11, Docker Desktop running
- VS Code (Insiders), PowerShell 7
- Conda env: `ancient-languages-py312` (Python 3.12)

## Setup

```powershell
conda activate ancient-languages-py312
pip install -e .
pre-commit install -t pre-commit -t pre-push
```

## Database

```powershell
# Start DB
pwsh -NoProfile -File .\scripts\db_up.ps1

# Reset schema and migrate to head
pwsh -NoProfile -File .\scripts\reset_db.ps1 `
  -Database app -DbUser app -DbPass "app" -DbHost localhost -DbPort 5433
```

## Tests & Quality

```powershell
cd backend
pytest -q
ruff check . --fix
ruff format .
```

## Migrations

```powershell
# From repo root
$env:DATABASE_URL      = "postgresql+asyncpg://app:app@localhost:5433/app"
$env:DATABASE_URL_SYNC = "postgresql+psycopg2://app:app@localhost:5433/app"
$env:PYTHONPATH        = (Resolve-Path .\backend).Path

python -m alembic -c backend\alembic.ini revision --autogenerate -m "explain change"
python -m alembic -c backend\alembic.ini upgrade head
```

## Git Workflow

* Branch from `main`, name like `feat/…`, `fix/…`, `chore/…`.
* Keep commits small, messages conventional (see [https://cbea.ms/git-commit/](https://cbea.ms/git-commit/)).
* Push and open a PR; CI + pre-commit must pass.

## Code Style

* Python 3.12, type hints for public functions, `pathlib` over `os.path` where sensible.
* Comments are minimal and high‑signal (intent, invariants, edge cases).
