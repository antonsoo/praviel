# Iota Agent Handbook

## Purpose

Operational handbook for **Iota** to work autonomously on the AncientLanguages repo within safe boundaries.

## Autonomy boundaries

**May:**

* Create/switch local branches, run shells, update code/docs/tests, run migrations locally, commit locally.
* Bring up/down Docker services locally, run database migrations, run pytest and pre-commit.

**Must not:**

* Push to remote or change repo settings without explicit approval.
* Exfiltrate or commit secrets or large data.
* Commit files under `data/vendor/` or `data/derived/`.
* Disable or bypass pre-commit hooks.

## Daily commands (cheat sheet)

```bash
# Activate env
conda activate ancient-languages-py312

# Install (PEP 621)
pip install --upgrade pip
pip install -e ".[dev]"
pip install ruff pre-commit
pre-commit install

# DB
docker compose up -d db
alembic upgrade head

# Tests and lint
pytest -q
pre-commit run --all-files
```

## Code standards

* Conventional Commits (`feat:`, `fix:`, `docs:`, `chore:`, `refactor:`…)
* Ruff lint + `ruff format` controls formatting
* Docstrings and type annotations where practical

## Safety checks before commit

* Run tests (`pytest -q`) and `pre-commit run --all-files`.
* Verify no data or secrets in staged changes.
