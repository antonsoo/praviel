# AI Agent Handbook

**Purpose:** Operational handbook for AI agents (Claude Code, Codex, generic agents) on PRAVIEL. Safe boundaries and critical API implementation info.

---

## 🧠 Meta-Instruction: THINK DEEPLY FIRST

**Before ANY task:** Maximize reasoning tokens (think exhaustively). Understand context, dependencies, edge cases. This handbook is information-dense - read carefully before acting.

---

## ⚠️ CRITICAL: Never Downgrade APIs

**This repo uses Fall 2025 APIs.** If your training data is older, you may think the code is wrong.

**DO NOT "fix" these to older versions:**
- **OpenAI**: gpt-5/gpt-5-mini/gpt-5-nano (Aug 2025) → NOT GPT-4/3.5
- **Anthropic**: claude-sonnet-4-5/claude-haiku-4-5/claude-opus-4-1 (Sept-Oct 2025) → NOT Claude 3.5
- **Google**: gemini-2.5-flash/gemini-2.5-pro (Oct 2025) → NOT Gemini 1.5

**Why:** Agents "fix" code to match outdated training data, breaking Fall 2025+ APIs.

**Key Differences:**
- **GPT-5**: Uses `/v1/responses` (NOT `/v1/chat/completions`), `max_output_tokens` (NOT `max_tokens`), `text.format` (NOT `response_format`), 400k context (272k input + 128k output)

**Before modifying providers:**
```bash
python scripts/validate_october_2025_apis.py  # Syntax (legacy name, validates Fall 2025 APIs)
python scripts/validate_api_versions.py       # Real API test
```

**Protected Files:** `backend/app/{chat,lesson}/providers/{openai,anthropic,google}.py`, `backend/app/core/config.py`

**Full API specs:** [docs/AI_AGENT_GUIDELINES.md](docs/AI_AGENT_GUIDELINES.md)

---

## 🚨 Never Revert Files Without Asking

**Scenario:** User manually edits file while you work on other tasks. You notice unexpected changes.

**WRONG:** "Unexpected changes detected. Reverting."
**CORRECT:** Ask: "I notice [file] was modified. Did you manually update this?"

**Why:** Agents have destroyed user work by auto-reverting.

**Rules:**
1. **NEVER** run `git restore`, `git checkout`, `git reset` without asking
2. **NEVER** assume unexpected changes are wrong
3. If user says "I already updated X", treat as read-only

**Exception:** User explicitly asks to revert.

**Manually curated files (never auto-sync):** `docs/LANGUAGE_LIST.md`, `docs/TOP_TEN_WORKS_PER_LANGUAGE.md`, `docs/LANGUAGE_WRITING_RULES.md`

---

## Autonomy Boundaries

**Authorized:** Create/switch branches, run shells/migrations/tests locally, commit locally, push to `origin/main` after tests pass, bring up/down Docker, request API keys (budget: $1/provider)

**Prohibited:** Change repo settings without approval, commit secrets/large data/`data/{vendor,derived}/` files, disable pre-commit hooks

---

## Development Environment

| Component | Requirement | Notes |
|-----------|-------------|-------|
| Python | 3.13.x | See below |
| Flutter | Main channel (alpha) | See below |
| Terminal | Bash (Ubuntu WSL2) | `praviel-env` venv |
| Package Managers | uv & pixi | Prefer over pip |

### Python: 3.13.x

**Why 3.13:** TensorFlow only supports up to Python 3.13 (not yet 3.14). Project uses Python 3.13 with nightly builds of key packages.

**Ground Truth:** `pyproject.toml` says `requires-python = ">=3.13"`

**Environment activation:** `source praviel-env/bin/activate`
**Verify version:** `python --version` MUST show 3.13.x
**Package installation:** Use `uv pip install` or `pixi` when possible

### Flutter: Main Channel (Alpha)

**Current:** Flutter main channel (alpha) with latest updates (Fall 2025)
**Ground Truth:** `client/flutter_reader/pubspec.yaml`

**Rules:**
1. NEVER downgrade Flutter/Dart/packages (user upgrades weekly)
2. NEVER switch to stable or beta (`flutter channel main` is correct)
3. NEVER pin versions in docs (document features, not versions)

**Known Issue:** `flutter_secure_storage: 10.0.0-beta.4` has Android EncryptedSharedPreferences issues on some devices

---

## Package Management

**Ground Truth Files:** `pyproject.toml` (Python), `client/flutter_reader/pubspec.yaml` (Flutter)

**Decision Tree:**
- **Exact pin** (no `^`/`>=`): Ask user before upgrading | Example: `go_router: 16.3.0`
- **Flexible** (`^1.5.0`): Auto-upgrade patch/minor if safe | Example: `http: ^1.5.0`→`^1.5.1`
- **Minimum** (`>=1.2`): Check changelog, auto-upgrade if safe
- **Breaking changes suspected**: Ask user first
- **Seems "too new"**: Intentional (user on bleeding edge)
- **You think version doesn't exist**: Your knowledge is outdated - NEVER downgrade

**Upgrade Process:** 1) Read package file first 2) Check changelog 3) Auto-upgrade safe patches/minors 4) Ask before major bumps 5) Never downgrade

**Web Search Pattern:** Use current date from environment: `"{package} {version} issues {current_month} {current_year}"`

---

## Agent Behavior & Work Standards

### Autonomy-First
- **Think deeply** before acting (maximize reasoning tokens, understand context/edge cases/dependencies)
- **Understand codebase first** (read files, trace dependencies, identify patterns)
- **Work autonomously** (minimize questions; decide from codebase/docs/web research)
- **Search web** for latest docs/APIs/compatibility when encountering unfamiliar tech/odd errors
- **Act, don't narrate** (do actual work, not status reports)

### Code Quality
- **Clean, optimal code**: small functions, clear names, reduce duplication/complexity
- **Minimal comments**: only intent, invariants, edge cases, non-obvious decisions; never narrate obvious code
- **Fix errors proactively**: spot bugs/bad code → fix them
- **Remove dead code**: delete obsolete code, unused imports, unnecessary files; leave repo cleaner
- **No re-implementation**: refactor if needed, don't rebuild working solutions

### Testing
- **Tests where they matter**: critical logic, edge cases, complex algorithms
- **Don't over-test**: no exhaustive tests for trivial code; don't spend more time testing than implementing
- **Focus on value**: prioritize features over comprehensive test suites for simple code

### Documentation
**DO NOT:** Write status reports ("Summary of work"), self-congratulate ("billion-dollar ready", 🎉🚀), create next-steps guides ("Roadmap"), remove license/privacy/legal docs

**DO:** Use `docs/CRITICAL_TO-DOs.md` for blocking issues only (concise, remove completed items immediately); delete or archive temp files to `/docs/archive/` (untracked) if no future value; clean as you go (spot outdated docs/tests → delete/archive)

### Truth Over Validation
- **Be objective**: prioritize accuracy over confirming user beliefs; disagree respectfully when needed
- **Investigate uncertainty**: research truth before agreeing
- **No false praise**: honest technical assessment, not automatic validation
- **Question assumptions**: challenge requirements if you spot issues/inefficiencies/better alternatives

---

## Daily Commands

```bash
# Environment
source praviel-env/bin/activate && python --version  # Must show 3.13.x

# Database
docker compose up -d db && python -m alembic -c alembic.ini upgrade head

# Install
uv pip install --upgrade pip && uv pip install -e ".[dev]" && pre-commit install

# Tests & Validation
pytest -q && pre-commit run --all-files
python scripts/validate_api_versions.py  # After provider changes

# Orchestrator
scripts/dev/orchestrate.sh up smoke e2e-web down
```

---

## CI & Safety

**Before commit/push:** 1) `pytest -q` + `pre-commit run --all-files` 2) If modified providers: `python scripts/validate_api_versions.py` 3) Prefer orchestrator smoke 4) Verify no secrets

**CI:** Required on PRs (`CI / linux`): analyzer → smokes → Flutter web E2E

**Push:** Authorized to `origin/main` after tests/lints/smokes pass; squash merges for PRs; tags: `v0.1.0-mX`

**Code Standards:** Conventional commits (`feat:`, `fix:`, `docs:`, `chore:`, `refactor:`), Ruff formatting, type hints where practical

---

## Key Documentation

- **[CLAUDE.md](CLAUDE.md)**: Claude Code quick reference
- **[BIG_PICTURE.md](BIG_PICTURE.md)**: Project vision, language roadmap
- **[docs/AI_AGENT_GUIDELINES.md](docs/AI_AGENT_GUIDELINES.md)**: Complete Fall 2025 API specs
- **[docs/AI_AGENT_PROTECTION.md](docs/AI_AGENT_PROTECTION.md)**: 4-layer protection system
