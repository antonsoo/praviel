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
  - Project vision & language roadmap → Those are in BIG_PICTURE.md
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
2. Run `python scripts/validate_api_versions.py` to test with real API calls
3. Read [docs/AI_AGENT_GUIDELINES.md](docs/AI_AGENT_GUIDELINES.md) for complete specifications

**DO NOT** revert to pre-October 2025 API patterns without explicit user approval. If the validation script fails, **DO NOT COMMIT**.

---

## 🚨 CRITICAL: NEVER Revert Files Without Asking

**SCENARIO:** You're working on a task. The user manually edits a file while you're working on other things. Later, you notice the file has changes you didn't make.

**WRONG RESPONSE:** "Oh, this file has unexpected changes. Let me revert it to the version I expect."

**CORRECT RESPONSE:** Ask the user: "I notice [filename] has been modified since I last saw it. Did you manually update this file, or should I investigate why it changed?"

### Why This Matters

**Example disaster scenario:**
1. Agent starts working, modifies README.md, then moves on to 200 other tasks
2. User manually updates README.md during task #150 with important changes
3. Agent reaches task #250 and thinks "Wait, README.md doesn't look like I left it"
4. Agent runs `git restore README.md` or similar, **destroying user's manual work**

### Protected Files - NEVER Auto-Revert

These files are **manually curated by the project owner** and may be updated independently:

- `/docs/LANGUAGE_LIST.md` - Single source of truth for language order (user updates first)
- `/docs/TOP_TEN_WORKS_PER_LANGUAGE.md` - Curated texts per language (user maintains)
- `/docs/LANGUAGE_WRITING_RULES.md` - Writing system rules (user maintains)
- Any file the user explicitly says they've manually updated

### Rules

1. **NEVER run `git restore`, `git checkout`, or `git reset` on files without asking first**
2. **NEVER assume a file change you didn't make is wrong**
3. **If a file looks different than you expect, ASK before reverting**
4. **If user says "I already updated X", treat it as read-only**
5. **Trust that files ahead of what you expect may be intentional user updates**

### Exception

The ONE exception is if the user explicitly asks you to revert a file: "Please restore [filename] to the last commit version."

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

**IDE**: VSCode Insiders with Claude Code and Codex extensions
**Terminal**: Anaconda PowerShell with `ancient-languages-py312` conda env
**Python Version**: 3.12.11 (via conda env) - **DO NOT use global Python 3.13.5**
**Git**: Commits are authorized and encouraged for completed work
**Web Access**: Available for researching latest API documentation

### Python Environment Rules

**CRITICAL**: The project requires Python 3.12.11. Python resolution is handled automatically for PowerShell scripts.

#### Automated Python Resolution (PowerShell Scripts)

**All PowerShell scripts in `scripts/` automatically use the correct Python version** via the centralized resolver at `scripts\common\python_resolver.ps1`.

The resolver:
1. Checks `$env:UVICORN_PYTHON` for manual override
2. Searches for Python 3.12.x in `ancient-languages-py312` conda environment
3. Falls back to any Python 3.12.x in PATH (with warning)
4. Throws an error if no suitable Python found

**When running PowerShell scripts, Python version is handled automatically:**
```powershell
.\scripts\dev\smoke_lessons.ps1  # Uses Python 3.12.11 automatically
.\scripts\dev\serve_uvicorn.ps1 start  # Uses Python 3.12.11 automatically
```

#### Manual Python Commands

**For direct `python` commands, verify version first:**
```powershell
# Check current Python version (MUST be 3.12.11)
python --version

# If wrong version (e.g., 3.13.5), activate correct environment
conda activate ancient-languages-py312
```

**Common Pitfalls**:
- Running `python` in Git Bash may use global Python 3.13.5
- Running `python` without activating conda environment uses wrong version
- PowerShell scripts handle this automatically; manual commands don't

**Environment Location**: `C:\ProgramData\anaconda3\envs\ancient-languages-py312`

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
python scripts/validate_api_versions.py               # Real API test
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
* **If you modified provider code**: Run `python scripts/validate_api_versions.py` to verify APIs still work
* Prefer `scripts/dev/orchestrate.sh up && scripts/dev/orchestrate.sh smoke && scripts/dev/orchestrate.sh e2e-web && scripts/dev/orchestrate.sh down` (or the `.ps1` equivalents) before pushing to confirm API + Flutter behave together.
* Verify no data or secrets in staged changes.
* For pushes: only after tests + pre-commit pass; never commit vendor data/secrets; follow the DB runbook for migrations; respect feature flags.

## Push & merge policy (approved)
* You **may** push to `origin/main` once the branch passes tests, lints, and smoke checks. Prefer squash merges when opening PRs for review; tags use `v0.1.0-mX` semantics.

## Key Documentation

For project understanding and context:
- **[BIG_PICTURE.md](BIG_PICTURE.md)**: Project vision, philosophy, and language expansion roadmap (Classical Greek → Latin → Hebrew → Egyptian, etc.)
- **[README.md](README.md)**: Technical quick-start and feature overview
- **[CLAUDE.md](CLAUDE.md)**: Project-specific instructions for Claude Code
- **[docs/AI_AGENT_GUIDELINES.md](docs/AI_AGENT_GUIDELINES.md)**: Complete October 2025 API specifications
