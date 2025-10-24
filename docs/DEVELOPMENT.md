# Development Guide

Complete guide for developers working on the Ancient Languages platform.

---

## ⚠️ Critical: October 2025 APIs

This repository uses **October 2025 API implementations** for:
- **OpenAI**: GPT-5 via `/v1/responses` endpoint (NOT `/v1/chat/completions`)
- **Anthropic**: Claude 4.5 Sonnet, Claude 4.1 Opus
- **Google**: Gemini 2.5 Flash, Gemini 2.5 Pro

**If your training data is from before October 2025, DO NOT "fix" code to older API versions.**

### Before Modifying Provider Code

1. Read [AGENTS.md](../AGENTS.md) - Agent autonomy boundaries
2. Read [docs/AI_AGENT_GUIDELINES.md](AI_AGENT_GUIDELINES.md) - October 2025 API specs
3. Run: `python scripts/validate_october_2025_apis.py`
4. Test: `python scripts/validate_api_versions.py`

**Protected files:** [`backend/app/lesson/providers/`](../backend/app/lesson/providers/), [`backend/app/chat/`](../backend/app/chat/), [`backend/app/tts/providers/`](../backend/app/tts/providers/)

See [.github/CODEOWNERS](../.github/CODEOWNERS) for complete list.

---

## Quick Start

**Prerequisites:** Python 3.12, Docker Desktop, Git

```bash
# 1. Start infrastructure
docker compose up -d

# 2. Configure environment
cp backend/.env.example backend/.env
# Edit backend/.env with your API keys (optional)

# 3. Install dependencies
conda create -y -n ancient python=3.12 && conda activate ancient
pip install -e ".[dev]"
python -m alembic -c alembic.ini upgrade head

# 4. Run backend
uvicorn app.main:app --reload

# 5. Verify
curl http://127.0.0.1:8000/health  # Expected: {"status":"ok"}
```

**Windows users:** See [WINDOWS.md](WINDOWS.md) for PYTHONPATH setup and PowerShell-specific commands.

---

## Architecture

### Tech Stack

- **Backend:** Python 3.12, FastAPI, async SQLAlchemy 2.0
- **Database:** PostgreSQL 16 with `pgvector` + `pg_trgm`
- **Queue:** Redis 7
- **Worker:** arq (async job runner)
- **Client:** Flutter 3.35+ (Beta channel), Dart 3.9+

### Data Schema

**Core entities:**
- Language → SourceDoc → TextWork → TextSegment → Token
- Lexeme (lemmas, definitions)
- GrammarTopic (Smyth §, explanations)

**Retrieval:** Hybrid lexical (trigram) + semantic (pgvector) with optional cross-encoder rerank

---

## Project Structure

```
backend/
  app/
    api/                # FastAPI routers
    chat/               # Chat providers (OpenAI, Anthropic, Google)
    core/               # Config, logging, security
    db/                 # SQLAlchemy models, migrations
    ingestion/          # TEI parsers, worker jobs
    lesson/providers/   # Lesson generation (OpenAI, Anthropic, Google)
    retrieval/          # Hybrid search
    tts/providers/      # TTS providers
    tests/              # Unit + accuracy gates

client/flutter_reader/  # Flutter app

data/
  vendor/               # Third-party corpora (not committed)
  derived/              # Pipeline outputs (not committed)

docs/                   # Documentation
scripts/                # Dev scripts
```

---

## Testing

### Unit Tests

```bash
pytest -q
```

### Linting

```bash
pre-commit run --all-files
```

### Flutter Analyzer

```bash
# Windows
.\scripts\dev\analyze_flutter.ps1

# Unix/Mac
./scripts/dev/analyze_flutter.sh
```

### Full Orchestrator (Smoke + E2E)

```bash
# Unix/Mac
./scripts/dev/orchestrate.sh up
./scripts/dev/orchestrate.sh smoke
./scripts/dev/orchestrate.sh e2e-web
./scripts/dev/orchestrate.sh down

# Windows (PowerShell)
.\scripts\dev\orchestrate.ps1 up
.\scripts\dev\orchestrate.ps1 smoke
.\scripts\dev\orchestrate.ps1 e2e-web
.\scripts\dev\orchestrate.ps1 down
```

### API Validation (Required After Provider Changes)

```bash
python scripts/validate_october_2025_apis.py
python scripts/validate_api_versions.py
```

---

## CI/CD

### GitHub Actions Workflows

- **CI / linux:** analyzer → pytest → orchestrator (smoke + E2E web) → artifacts
- **CI / windows:** pytest → pre-commit → artifacts
- **Branch protection:** Both jobs must pass before merge

### Quality Gates

- **M1:** ≥99% TEI parse success
- **M2:** Smyth Top-5 ≥85%, LSJ headword ≥90%, p95 latency <800ms
- **Security:** CI fails if API keys appear in logs

---

## Data Management

Third-party corpora (Perseus TEI, LSJ, Smyth) are **not committed**. Fetch locally:

```bash
# Windows
pwsh -File scripts/fetch_data.ps1

# Unix/macOS
bash scripts/fetch_data.sh
```

See [data/DATA_README.md](../data/DATA_README.md) and [docs/licensing-matrix.md](licensing-matrix.md).

---

## Key Features Implementation

### Reader
- Tap-to-analyze Ancient Greek text
- Lemma + morphology via Perseus/CLTK
- LSJ glosses with source attribution
- Smyth grammar references
- Hybrid retrieval (lexical + semantic)

**Endpoints:**
- `GET /reader/analyze` - Analyze a Greek token
- See [API_EXAMPLES.md](API_EXAMPLES.md) for details

### Lessons
- LLM-generated exercises (not template-fill)
- Text-targeted generation (e.g., "Iliad 1.20-1.50")
- Literary vs. colloquial register modes
- Multi-provider BYOK support
- Exercise types: Alphabet, Match, Cloze, Translate

**Endpoints:**
- `POST /lesson/generate` - Generate a lesson
- See [LESSONS.md](LESSONS.md) for API contract

### Progress Dashboard
- Daily streak tracking
- XP and level system
- Recent lesson history
- Glass-morphism UI with smooth animations

### Chat (Experimental)
- Conversational practice with historical personas
- Ancient Greek responses with English grammar notes

**Endpoints:**
- `POST /coach/chat` - Chat with AI coach
- See [COACH.md](COACH.md) for details

### Text-to-Speech
- Offline `echo` provider (deterministic WAV)
- OpenAI TTS via BYOK

**Endpoints:**
- `POST /tts/speak` - Generate audio
- See [TTS.md](TTS.md) for details

---

## Development Workflow

### 1. Create a Feature Branch

```bash
git checkout -b feat/my-feature
```

### 2. Make Changes

Follow these standards:
- **Commits:** Conventional commits (`feat:`, `fix:`, `docs:`, `chore:`)
- **Formatting:** Ruff (`ruff format`)
- **Type hints:** Use where practical
- **Tests:** Required for new features

### 3. Run Tests Locally

```bash
# Unit tests
pytest -q

# Linting
pre-commit run --all-files

# If you modified provider code
python scripts/validate_api_versions.py

# Full smoke test (recommended before pushing)
./scripts/dev/orchestrate.sh up
./scripts/dev/orchestrate.sh smoke
./scripts/dev/orchestrate.sh e2e-web
./scripts/dev/orchestrate.sh down
```

### 4. Commit and Push

```bash
git add .
git commit -m "feat: add new feature"
git push origin feat/my-feature
```

### 5. Create Pull Request

- Ensure CI passes (both linux and windows jobs)
- Request review
- Squash merge when approved

---

## Common Development Tasks

### Add a New Language

1. **Prepare corpus data:**
   - TEI XML files for texts
   - Lexicon data (like LSJ for Greek)
   - Grammar reference (like Smyth for Greek)

2. **Update ingestion pipeline:**
   - Add TEI parser in `backend/app/ingestion/`
   - Add language entry in `backend/app/db/models.py`

3. **Create seed data:**
   - Add `daily_[lang].yaml` in `backend/app/lesson/seed/`
   - Include natural daily speech phrases

4. **Update lesson providers:**
   - Modify prompts in `backend/app/lesson/prompts.py`
   - Add language-specific examples

5. **Test thoroughly:**
   - Run ingestion
   - Generate lessons
   - Verify reader accuracy

### Add a New Exercise Type

1. **Define schema:**
   - Update `backend/app/lesson/schemas.py`

2. **Add prompt:**
   - Create prompt in `backend/app/lesson/prompts.py`

3. **Update providers:**
   - Modify `backend/app/lesson/providers/anthropic.py`, `openai.py`, `google.py`
   - Ensure offline `echo` provider supports it

4. **Add tests:**
   - Update `backend/app/tests/test_lesson_quality.py`

### Modify API Provider

⚠️ **CRITICAL:** Read [AI_AGENT_GUIDELINES.md](AI_AGENT_GUIDELINES.md) first!

1. **Understand October 2025 APIs:**
   - OpenAI GPT-5 uses `/v1/responses`, NOT `/v1/chat/completions`
   - Parameter is `max_output_tokens`, NOT `max_tokens`

2. **Make changes:**
   - Edit provider file (e.g., `backend/app/lesson/providers/openai.py`)

3. **Validate:**
   ```bash
   python scripts/validate_october_2025_apis.py  # Syntax check
   python scripts/validate_api_versions.py               # Real API test
   ```

4. **Commit only if validation passes**

---

## Troubleshooting

### Database not ready

```bash
docker compose logs db  # Check logs
docker compose down -v && docker compose up -d  # Reset
```

### Windows `ModuleNotFoundError: app`

```powershell
$env:PYTHONPATH = (Resolve-Path .\backend).Path
uvicorn app.main:app --reload
```

### Tests failing

```bash
docker compose up -d  # Ensure DB running
python -m alembic -c alembic.ini upgrade head
pytest -q
```

### Git line endings (Windows)

```powershell
git config core.autocrlf false
git config core.eol lf
```

### Pre-commit hooks failing

```bash
pre-commit run --all-files
git add -u  # Re-stage fixed files
```

**More:** See [WINDOWS.md](WINDOWS.md) or [QUICKSTART.md](QUICKSTART.md#troubleshooting)

---

## Code Standards

- **Commits:** Use conventional commits (`feat:`, `fix:`, `docs:`, `chore:`)
- **Formatting:** Ruff (`ruff format`)
- **Type hints:** Use where practical
- **Tests:** Required for new features
- **Documentation:** Update docs when adding features

---

## Release Process

1. **Ensure all tests pass:**
   ```bash
   pytest -q
   pre-commit run --all-files
   ./scripts/dev/orchestrate.sh up && \
   ./scripts/dev/orchestrate.sh smoke && \
   ./scripts/dev/orchestrate.sh e2e-web && \
   ./scripts/dev/orchestrate.sh down
   ```

2. **Tag release:**
   ```bash
   git tag v0.1.0-m3
   git push origin v0.1.0-m3
   ```

3. **Update CHANGELOG (if exists)**

---

## Environment Variables

### Required

```bash
DATABASE_URL=postgresql+asyncpg://app:app@localhost:5433/app
REDIS_URL=redis://localhost:6379/0
EMBED_DIM=1536
```

### Optional (for AI features)

```bash
OPENAI_API_KEY=sk-proj-your-key-here
ANTHROPIC_API_KEY=sk-ant-api03-your-key-here
GOOGLE_API_KEY=your-google-key-here
LESSONS_ENABLED=1
TTS_ENABLED=1
COACH_ENABLED=1
BYOK_ENABLED=1
```

### Development

```bash
ALLOW_DEV_CORS=1
SERVE_FLUTTER_WEB=1
LOG_LEVEL=DEBUG
```

See [backend/.env.example](../backend/.env.example) for complete list.

---

## Resources

### Documentation
- [API Examples](API_EXAMPLES.md) - Complete curl examples
- [BYOK Guide](BYOK.md) - Bring Your Own Key policy
- [Lessons API](LESSONS.md) - Lesson generation contract
- [TTS Guide](TTS.md) - Text-to-speech runbook
- [Chat API](COACH.md) - Conversational coach endpoint

### For AI Agents
- [CLAUDE.md](../CLAUDE.md) - Project instructions for Claude Code
- [AGENTS.md](../AGENTS.md) - Agent handbook and autonomy boundaries
- [AI Agent Guidelines](AI_AGENT_GUIDELINES.md) - October 2025 API specifications

### External Resources
- [FastAPI Documentation](https://fastapi.tiangolo.com/)
- [SQLAlchemy 2.0 Documentation](https://docs.sqlalchemy.org/en/20/)
- [Flutter Documentation](https://docs.flutter.dev/)
- [Perseus Digital Library](http://www.perseus.tufts.edu/)

---

## License

- **Code:** Elastic License 2.0 (ELv2) — [View full license](../LICENSE.md)
- **Data:** Remains under original licenses (Perseus/LSJ: CC BY-SA, etc.)

The Elastic License 2.0 allows you to freely use, copy, distribute, and modify this software with three simple limitations:
- Cannot provide as a hosted/managed service
- Cannot circumvent license key functionality
- Must preserve copyright notices

- **Full details:** [docs/licensing-matrix.md](licensing-matrix.md)

---

## Questions?

- **Technical questions:** [GitHub Discussions](https://github.com/antonsoo/praviel/discussions)
- **Bug reports:** [GitHub Issues](https://github.com/antonsoo/praviel/issues)
- **Contributing:** [CONTRIBUTING.md](../CONTRIBUTING.md)
