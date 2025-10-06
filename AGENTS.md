# AI Agent Handbook

<!--
  This file is automatically read by AI agents (including Codex, generic agents).

  WHEN TO UPDATE THIS FILE:
  - When autonomy boundaries change (what agents may/may not do)
  - When development workflow changes (new CI requirements, testing procedures)
  - When API testing budget limits change

  DO NOT UPDATE THIS FILE FOR:
  - Detailed API specifications → Update docs/AI_AGENT_GUIDELINES.md instead
  - Specific dated model names → Those are in docs/AI_AGENT_GUIDELINES.md
  - Project-specific commands → Those are in CLAUDE.md (for Claude Code)
-->

## Purpose

Operational handbook for AI agents working on the AncientLanguages repository. This document establishes safe boundaries and provides critical information about API implementations.

---

## ⚠️ READ THIS FIRST: API Version Protection

**This repository uses October 2025 API implementations.** If your training data is older, you may incorrectly think the code is wrong.

**MANDATORY: Before modifying any provider code, run:**
```bash
python scripts/validate_october_2025_apis.py
```

This validation script will **FAIL** if you've regressed the APIs to older versions. ALL checks must pass.

**Additional steps:**
1. Read the [API Version Policy](#api-version-policy) section below
2. Run `python validate_api_versions.py` to test with real API calls
3. Read [docs/AI_AGENT_GUIDELINES.md](docs/AI_AGENT_GUIDELINES.md) for complete specifications

**DO NOT** revert to pre-October 2025 API patterns without explicit user approval. If the validation script fails, **DO NOT COMMIT**.

---

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

**This repository uses October 2025 API implementations.**

### Quick Reference

**Critical Differences from Pre-October 2025:**

- **OpenAI GPT-5**: Uses Responses API (`/v1/responses`), NOT Chat Completions
  - Key parameter: `max_output_tokens` (NOT `max_tokens`)
  - Format: `text.format` (NOT `response_format`)

- **Anthropic Claude**: Latest are Claude 4.5 Sonnet and Claude 4.1 Opus

- **Google Gemini**: Latest are Gemini 2.5 Flash and 2.5 Pro

**For complete model names, endpoints, and payload formats:**
→ See [docs/AI_AGENT_GUIDELINES.md](docs/AI_AGENT_GUIDELINES.md)

### Critical Rules

1. **DO NOT** revert to pre-October 2025 API patterns
2. **DO NOT** change `max_output_tokens` to `max_tokens` for GPT-5
3. **DO NOT** change `/v1/responses` to `/v1/chat/completions` for GPT-5
4. **DO** run validation after any provider changes

### Validation

Run these before committing provider changes:

```bash
python scripts/validate_october_2025_apis.py  # Syntax validation
python validate_api_versions.py               # Real API test
```

### Protected Files

These files implement October 2025 APIs and require validation before modification:

- `backend/app/chat/openai_provider.py`
- `backend/app/lesson/providers/openai.py`
- `backend/app/chat/anthropic_provider.py`
- `backend/app/lesson/providers/google.py`
- `backend/app/core/config.py` (model defaults)

See [.github/CODEOWNERS](.github/CODEOWNERS) for complete list.

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
* **If you modified provider code**: Run `python validate_api_versions.py` to verify APIs still work
* Prefer `scripts/dev/orchestrate.sh up && scripts/dev/orchestrate.sh smoke && scripts/dev/orchestrate.sh e2e-web && scripts/dev/orchestrate.sh down` (or the `.ps1` equivalents) before pushing to confirm API + Flutter behave together.
* Verify no data or secrets in staged changes.
* For pushes: only after tests + pre-commit pass; never commit vendor data/secrets; follow the DB runbook for migrations; respect feature flags.

## Push & merge policy (approved)
* You **may** push to `origin/main` once the branch passes tests, lints, and smoke checks. Prefer squash merges when opening PRs for review; tags use `v0.1.0-mX` semantics.
