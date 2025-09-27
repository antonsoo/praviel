# Iota Agent Handbook

## Purpose

Operational handbook for **Iota** to work autonomously on the AncientLanguages repo within safe boundaries.

## Autonomy boundaries

**May:**

* Create/switch local branches, run shells, update code/docs/tests, run migrations locally, commit locally.
* Bring up/down Docker services locally, run database migrations, run pytest and pre-commit.

**Must not:**

* Change repo settings without explicit approval.
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
python -m alembic -c alembic.ini upgrade head

# Tests and lint
pytest -q
pre-commit run --all-files

# Orchestrator (preferred demo + smoke)
scripts/dev/orchestrate.sh up
scripts/dev/orchestrate.sh smoke
scripts/dev/orchestrate.sh e2e-web
scripts/dev/orchestrate.sh down
```
PowerShell: run the matching `.ps1` commands (separate statements) for smoke + E2E.

## Code standards

* Conventional Commits (`feat:`, `fix:`, `docs:`, `chore:`, `refactor:`…)
* Ruff lint + `ruff format` controls formatting
* Docstrings and type annotations where practical

## CI expectations

* The GitHub Actions workflow `CI` (jobs `CI / linux` and `CI / windows`) must pass before pushing or merging to `main`.
* Reproduce the green path locally with `scripts/dev/orchestrate.sh up --flutter`, `smoke`, `e2e-web --require-flutter`, then `down` prior to tagging or pushing.

## Safety checks before commit/push

* Run tests (`pytest -q`) and `pre-commit run --all-files`.
* Prefer `scripts/dev/orchestrate.sh up && scripts/dev/orchestrate.sh smoke && scripts/dev/orchestrate.sh e2e-web && scripts/dev/orchestrate.sh down` (or the `.ps1` equivalents) before pushing to confirm API + Flutter behave together.
* Verify no data or secrets in staged changes.
* For pushes: only after tests + pre-commit pass; never commit vendor data/secrets; follow the DB runbook for migrations; respect feature flags.

## Push & merge policy (approved)
* You **may** push to `origin/main` once the branch passes tests, lints, and smoke checks. Prefer squash merges when opening PRs for review; tags use `v0.1.0-mX` semantics.
