# Claude Code Project Instructions

<!--
  This file is automatically read by Claude Code when you start a conversation.

  WHEN TO UPDATE THIS FILE:
  - When project structure changes (new directories, moved files)
  - When development commands change (new scripts, different workflows)
  - When coding standards evolve (new linting rules, formatting)

  DO NOT UPDATE THIS FILE FOR:
  - API model changes → Update docs/AI_AGENT_GUIDELINES.md instead
  - Specific model names → Those are in docs/AI_AGENT_GUIDELINES.md
  - Autonomy boundaries → Those are in AGENTS.md
  - Project vision & language roadmap → Those are in BIG_PICTURE.md
-->

## ⚠️ CRITICAL: October 2025 API Implementation

This repository uses **October 2025 API implementations** for OpenAI (GPT-5), Anthropic (Claude 4.5/4.1), and Google (Gemini 2.5).

**If your training data is from before October 2025, DO NOT "fix" code to older API versions.**

### 🚨 ENFORCED BY 4-LAYER PROTECTION SYSTEM 🚨

The codebase has a **4-layer protection system** that will **FAIL THE BUILD** if you try to break October 2025 APIs:

1. **Runtime Validation**: `backend/app/core/config.py` validates model config at startup
2. **Import-Time Validation**: `backend/app/lesson/providers/openai.py` validates model registry
3. **Pre-Commit Hook**: `scripts/validate_no_model_downgrades.py` blocks model downgrades
4. **Pre-Commit Hook**: `scripts/validate_api_payload_structure.py` blocks incorrect API parameters

**Full details**: [docs/AI_AGENT_PROTECTION.md](docs/AI_AGENT_PROTECTION.md)

**DO NOT REMOVE OR BYPASS THESE VALIDATORS.** They exist because AI agents keep trying to "fix" the code by downgrading to GPT-4 or using incorrect API parameters.

## 🚨 CRITICAL: Flutter Beta Channel + NO DOWNGRADES

**This project uses Flutter BETA channel with latest dependencies.**

### ⚠️ ABSOLUTE RULES - DO NOT VIOLATE:

1. **NEVER downgrade Flutter/Dart versions or packages**
   - User upgrades dependencies weekly/daily
   - Breaking the upgrade path wastes hours of work
   - If a package seems "too new", it's intentional

2. **NEVER switch from Beta to Stable channel**
   - Flutter is on **Beta channel** by design
   - `flutter channel beta` is the correct state
   - Do NOT run `flutter channel stable`

3. **NEVER pin specific package versions in docs**
   - User upgrades constantly
   - Document features, not version numbers
   - Let `pubspec.yaml` be the source of truth

4. **Current Package Strategy:**
   - `flutter_secure_storage: 10.0.0-beta.4` (latest beta)
   - `go_router: 16.3.0` (latest stable)
   - All packages on latest resolvable versions
   - SDK-pinned transitives (`characters`, `material_color_utilities`) ignored until Flutter bumps

5. **Platform Requirements (from secure storage beta):**
   - Android: minSdk ≥ 23, Java 17
   - iOS: deployment target ≥ 12.0

**If you think you need to downgrade, you're wrong. Ask the user instead.**

## Before Modifying Provider Code

**MANDATORY STEPS:**

1. Read the full handbook: [AGENTS.md](AGENTS.md)
2. Read detailed API specs: [docs/AI_AGENT_GUIDELINES.md](docs/AI_AGENT_GUIDELINES.md)
3. Read protection system: [docs/AI_AGENT_PROTECTION.md](docs/AI_AGENT_PROTECTION.md)
4. Run validators:
   ```bash
   python scripts/validate_no_model_downgrades.py
   python scripts/validate_api_payload_structure.py
   ```
5. Test real APIs with your API key if making changes

**DO NOT COMMIT** if validation fails.

## Protected Files

These implement October 2025 APIs - **DO NOT revert to older patterns:**

- `/backend/app/lesson/providers/openai.py` - GPT-5 Responses API (`/v1/responses`)
- `/backend/app/chat/openai_provider.py` - GPT-5 Responses API
- `/backend/app/lesson/providers/anthropic.py` - Claude 4.5/4.1
- `/backend/app/lesson/providers/google.py` - Gemini 2.5
- `/backend/app/tts/providers/*.py` - TTS implementations
- `/backend/app/core/config.py` - Model defaults

See [.github/CODEOWNERS](.github/CODEOWNERS) for complete list.

## 🚫 DO NOT MODIFY: Language Documentation Files

**CRITICAL:** These language documentation files are manually curated by the project owner. **NEVER run sync scripts or make automated changes to these files:**

- `/docs/LANGUAGE_LIST.md` - Single source of truth for language order (manually updated by owner)
- `/docs/TOP_TEN_WORKS_PER_LANGUAGE.md` - Curated list of top texts per language (manually maintained)
- `/docs/LANGUAGE_WRITING_RULES.md` - Writing system rules per language (manually maintained)

**When updating language order:**
1. User updates `docs/LANGUAGE_LIST.md` manually FIRST
2. Run `python scripts/sync_language_order.py` to update code ONLY:
   - `backend/app/lesson/language_config.py` (display_order)
   - `client/flutter_reader/lib/models/language.dart` (language list order)
3. **DO NOT** let the sync script touch the three docs files above
4. Update other documentation (README.md, BIG_PICTURE.md) manually if needed

**WHY:** The sync script has been known to corrupt these manually-curated files. Owner maintains backups, but breaking these files wastes time and causes frustration.

## Quick API Reference

**Key Gotchas:**

- **OpenAI GPT-5**: Uses `/v1/responses` with `max_output_tokens` and `text.format` (NOT `/v1/chat/completions`, `max_tokens`, or `response_format`)
- **Anthropic Claude**: Latest are Claude 4.5 Sonnet and Claude 4.1 Opus
- **Google Gemini**: Latest are Gemini 2.5 Flash and 2.5 Pro

**For complete model lists, endpoints, and payload formats:**
→ See [docs/AI_AGENT_GUIDELINES.md](docs/AI_AGENT_GUIDELINES.md)

## Python Environment

**CRITICAL**: Always use Python 3.12.11 from the `praviel` conda environment.

- **Global Python**: 3.13.5 (DO NOT USE)
- **Project Python**: 3.12.11 via `praviel` conda env

### For PowerShell Scripts (Automated)

**All PowerShell scripts automatically use the correct Python version** via `scripts\common\python_resolver.ps1`.

When running scripts, they will:
1. Check for `$env:UVICORN_PYTHON` override
2. Find Python 3.12.x in `praviel` conda environment
3. Fall back to any Python 3.12.x in PATH (with warning)
4. Throw an error if no suitable Python is found

**Just run the scripts - they handle Python resolution automatically:**
```powershell
.\scripts\dev\smoke_lessons.ps1  # Automatically uses Python 3.12.11
```

### For Manual Python Commands

**Before running manual Python commands:**
```powershell
# Check current Python version (should be 3.12.11)
python --version

# If wrong version, activate correct environment
conda activate praviel
```

**Common mistake**: Running `python` commands in Git Bash or directly in PowerShell without activating the conda environment will use the wrong Python version (3.13.5).

## Common Commands

### Development Setup
```bash
# Activate environment (PowerShell)
conda activate praviel

# Database
docker compose up -d db
python -m alembic -c alembic.ini upgrade head

# Install dependencies
pip install -e ".[dev]"
pre-commit install

# Run server
uvicorn app.main:app --reload
```

### Testing & Validation
```bash
# Tests
pytest -q

# Linting
pre-commit run --all-files

# API validation (REQUIRED after provider changes)
python scripts/validate_api_versions.py

# Full orchestrator test
scripts/dev/orchestrate.sh up && scripts/dev/orchestrate.sh smoke && scripts/dev/orchestrate.sh e2e-web
# Windows: scripts/dev/orchestrate.ps1 up
```

### Common Development Tasks
```bash
# Smoke test lessons (Unix: .sh, Windows: .ps1)
scripts/dev/smoke_lessons.sh  # or smoke_lessons.ps1

# Smoke test TTS (Unix: .sh, Windows: .ps1)
scripts/dev/smoke_tts.sh      # or smoke_tts.ps1

# Flutter analyzer (Unix: .sh, Windows: .ps1)
scripts/dev/analyze_flutter.sh # or analyze_flutter.ps1

# Demo bundle (Unix: .sh, Windows: .ps1)
scripts/dev/run_demo.sh        # or run_demo.ps1
```

**Note:** User is on Windows. Use PowerShell scripts (.ps1) or run sh scripts via Git Bash.

### Language Ordering
```bash
# Reorder languages by editing docs/LANGUAGE_LIST.md, then sync:
python scripts/sync_language_order.py

# Validate language order is synced (runs in pre-commit hook):
python scripts/sync_language_order.py --check
```

**How it works:**
- `docs/LANGUAGE_LIST.md` is the single source of truth for language ordering
- The sync script updates `backend/app/lesson/language_config.py` (display_order field)
- The sync script also reorders `client/flutter_reader/lib/models/language.dart`
- Pre-commit hook validates files are in sync before allowing commits
- **To reorder languages**: Edit LANGUAGE_LIST.md order, then run the sync script

## Project Structure

```
backend/
  app/
    chat/              # Chat providers (OpenAI, Anthropic, Google)
    lesson/providers/  # Lesson generation providers
    tts/providers/     # TTS providers
    core/              # Config, settings
    db/                # Database models

client/flutter_reader/ # Flutter app
docs/                  # Documentation
scripts/               # Dev scripts
```

## Code Standards

- **Commits**: Conventional commits (`feat:`, `fix:`, `docs:`, `chore:`)
- **Formatting**: Ruff (`ruff format`)
- **Type hints**: Use where practical
- **Tests**: Required for new features

## Safety Checks Before Commit

1. ✅ Run `pytest -q`
2. ✅ Run `pre-commit run --all-files`
3. ✅ If you modified provider code: Run `python scripts/validate_api_versions.py`
4. ✅ Verify no secrets in staged changes

## Key Documentation

- **[BIG_PICTURE.md](BIG_PICTURE.md)**: Project vision, philosophy, and language expansion roadmap
- **[AGENTS.md](AGENTS.md)**: Full agent handbook and autonomy boundaries
- **[docs/AI_AGENT_GUIDELINES.md](docs/AI_AGENT_GUIDELINES.md)**: Complete October 2025 API specifications

## When in Doubt

**ASK THE USER** before making changes to provider implementations.
