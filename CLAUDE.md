# Claude Code Project Instructions

**For complete handbook, see [AGENTS.md](AGENTS.md).** This is Claude Code quick reference only.

---

## 🧠 THINK DEEPLY FIRST

Before ANY task: maximize reasoning tokens (think exhaustively). Understand context, dependencies, edge cases.

---

## ⚠️ CRITICAL: Fall 2025+ APIs - DO NOT "Fix" to Older Versions

**This repo uses Fall 2025 APIs.** If your training data is older, you may think the code is wrong.

**What You See → Reality (DO NOT downgrade):**
- GPT-5 → Released Aug 2025 (NOT GPT-4)
- Claude 4.5 Sonnet/Haiku 4.5 → Released Sept-Oct 2025 (NOT Claude 3.5)
- Gemini 2.5 → Released Oct 2025 (NOT Gemini 1.5)
- `/v1/responses` → New GPT-5 endpoint (NOT `/v1/chat/completions`)
- `max_output_tokens` → New GPT-5 param (NOT `max_tokens`)

**4-Layer Protection:** Runtime + import-time + 2 pre-commit hooks prevent downgrades. **DO NOT REMOVE/BYPASS.**

**Details:** [docs/AI_AGENT_PROTECTION.md](docs/AI_AGENT_PROTECTION.md), [AGENTS.md](AGENTS.md#-critical-never-downgrade-apis)

---

## 🚨 Flutter Main (Alpha) + NO DOWNGRADES

**Rules:** 1) NEVER downgrade Flutter/Dart/packages (user upgrades weekly) 2) NEVER switch to stable or beta 3) NEVER pin versions in docs

**Ground Truth:** `client/flutter_reader/pubspec.yaml`

**Known Issue:** `flutter_secure_storage: 10.0.0-beta.4` has Android issues

**If you think you need to downgrade, ask user instead.**

---

## Python: 3.13.x

**Project uses Python 3.13** with nightly builds. TensorFlow only supports up to 3.13 (not yet 3.14).

- **Project:** 3.13.x via `praviel-env` venv (uv/pixi)
- **Activation:** `source praviel-env/bin/activate`
- **Manual:** `python --version` MUST show 3.13.x

**Ground Truth:** `pyproject.toml` (`requires-python = ">=3.13"`)

**See:** [AGENTS.md](AGENTS.md#python-313x)

---

## Package Management

**Ground Truth:** `pyproject.toml` (Python), `pubspec.yaml` (Flutter)

**Strategy:** Exact pin → Ask user | Flexible (`^`) → Auto-upgrade patch/minor if safe | Minimum (`>=`) → Check changelog

**Never downgrade** even if you think version doesn't exist (outdated knowledge).

**See:** [AGENTS.md](AGENTS.md#package-management)

---

## Protected Files - Validation Required Before Modifying

**API Providers:** `backend/app/{chat,lesson}/providers/{openai,anthropic,google}.py`, `backend/app/core/config.py`

**Before modifying:**
```bash
python scripts/validate_no_model_downgrades.py
python scripts/validate_api_payload_structure.py
python scripts/validate_api_versions.py
```

**Language Docs (manually curated - NEVER auto-sync):** `docs/LANGUAGE_LIST.md`, `docs/TOP_TEN_WORKS_PER_LANGUAGE.md`, `docs/LANGUAGE_WRITING_RULES.md`

**See:** [AGENTS.md](AGENTS.md#-never-revert-files-without-asking)

---

## Common Commands (Linux/WSL2)

```bash
# Environment
source praviel-env/bin/activate && python --version  # Must show 3.13.x

# Database
docker compose up -d db && python -m alembic -c alembic.ini upgrade head

# Install & Tests
uv pip install -e ".[dev]" && pre-commit install
pytest -q && pre-commit run --all-files
python scripts/validate_api_versions.py  # After provider changes

# Orchestrator
scripts/dev/orchestrate.sh up
scripts/dev/orchestrate.sh smoke
scripts/dev/orchestrate.sh e2e-web
scripts/dev/orchestrate.sh down

# Smoke Tests
scripts/dev/smoke_lessons.sh
scripts/dev/smoke_tts.sh

# Language Ordering
python scripts/sync_language_order.py  # After editing LANGUAGE_LIST.md

# Flutter Web Deploy (Cloudflare Pages)
cd client/flutter_reader && flutter build web --release
# Credentials in ~/.bashrc and .env.local (not committed)
npx wrangler pages deploy build/web --project-name=app-praviel --commit-dirty=true
```

---

## Agent Behavior Quick Reference

**Full guidelines:** [AGENTS.md](AGENTS.md#agent-behavior--work-standards)

**Core Principles:**
- Think deeply → Understand codebase → Work autonomously → Search web (use current month/year) → Act, don't narrate
- Clean code, minimal comments (intent/invariants only) → Fix errors proactively → Remove dead code
- Tests where they matter (don't over-test trivial code)
- NO status reports, NO self-congratulation, NO next-steps guides
- Truth over validation (be objective, disagree when needed)

**Documentation:** `docs/CRITICAL_TO-DOs.md` for blocking issues only (concise, remove completed items); archive temp files to `/docs/archive/`; never remove license/privacy docs

---

## Project Structure

```
backend/app/{chat,lesson,tts}/providers/  # AI providers
backend/app/{core,db}/                    # Config, DB models
client/flutter_reader/                    # Flutter app
docs/                                     # Documentation
scripts/                                  # Dev scripts
```

---

## Key Documentation

- **[AGENTS.md](AGENTS.md)**: **READ FIRST** - Complete handbook
- **[BIG_PICTURE.md](BIG_PICTURE.md)**: Vision, roadmap
- **[docs/AI_AGENT_GUIDELINES.md](docs/AI_AGENT_GUIDELINES.md)**: Fall 2025 API specs
- **[docs/AI_AGENT_PROTECTION.md](docs/AI_AGENT_PROTECTION.md)**: 4-layer protection

---

## When in Doubt

**READ [AGENTS.md](AGENTS.md) FIRST**, then ask user before major changes.
