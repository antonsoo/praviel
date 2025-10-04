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

## Development Environment

**IDE**: VSCode with Claude Code extension
**Terminal**: Anaconda PowerShell with `ancient-languages-py312` conda env (default)
**Git**: Commits are authorized and encouraged for completed work
**Web Access**: Available for researching latest API documentation

**Current API landscape (Fall 2025)**:
- GPT-5 released (August 2025)
- Claude 4.5 Sonnet released (September 2025)
- Gemini 2.5 Flash released (October 2025)

When researching APIs, verify against official vendor documentation published after these dates.

## API Testing Authorization

The agent is authorized to request and use API keys for autonomous testing and verification.

**Budget limits**: Each provider (OpenAI, Anthropic, Google) has $1 spending limit
**Usage**: Request keys when needed for end-to-end verification
**Security**: Keys are request-scoped only; never commit to repo; redact from logs

To request keys: "I'm ready to test [feature]. Please provide API keys for [providers]."

## API Version Policy

**Current specifications (October 2025)**:

### OpenAI
- **GPT-5 models**: Use Responses API (`POST /v1/responses`)
- **GPT-4 models**: Use Chat Completions API (`POST /v1/chat/completions`)
- **Reasoning field**: Only include for `gpt-5*` models
- **Response format**: `output[].content[].text` (Responses), `choices[].message.content` (Chat)

### Anthropic
- **Endpoint**: `POST /v1/messages`
- **Required headers**: `x-api-key: {token}`, `anthropic-version: 2023-06-01`
- **Models**: `claude-sonnet-4-5-20250929`, `claude-opus-4-1-20250805`, etc.

### Google Gemini
- **Endpoint**: `POST /v1/models/{model}:generateContent`
- **Required header**: `x-goog-api-key: {token}` (NOT query param)
- **Models**: `gemini-2.5-flash`, `gemini-2.5-flash-lite`, preview variants
- **Note**: v1 endpoint (NOT v1beta)

**CRITICAL**: Do not revert to older API versions without explicit user instruction. These specifications were verified working in October 2025.

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
* `CI` is required on PRs; it runs analyzer -> contract smokes -> Flutter web e2e and stores artifacts (dart_analyze.json, e2e_web_report.json, e2e_web_console.log, uvicorn logs, orchestrate state).
* Reproduce the green path locally with `scripts/dev/orchestrate.sh up --flutter`, `smoke`, `e2e-web --require-flutter`, then `down` prior to tagging or pushing.

## Safety checks before commit/push

* Run tests (`pytest -q`) and `pre-commit run --all-files`.
* Prefer `scripts/dev/orchestrate.sh up && scripts/dev/orchestrate.sh smoke && scripts/dev/orchestrate.sh e2e-web && scripts/dev/orchestrate.sh down` (or the `.ps1` equivalents) before pushing to confirm API + Flutter behave together.
* Verify no data or secrets in staged changes.
* For pushes: only after tests + pre-commit pass; never commit vendor data/secrets; follow the DB runbook for migrations; respect feature flags.

## Push & merge policy (approved)
* You **may** push to `origin/main` once the branch passes tests, lints, and smoke checks. Prefer squash merges when opening PRs for review; tags use `v0.1.0-mX` semantics.
