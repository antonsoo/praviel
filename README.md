# Ancient Languages — Classical Greek MVP

Research‑grade platform for studying ancient languages, beginning with Classical Greek. MVP goal: **Reader v0** for Iliad 1.1–1.10 with tap‑to‑analyze (lemma + morphology), LSJ gloss, Smyth § citation, and RAG‑grounded answers with citations.

## Architecture (MVP)

- Backend: Python 3.12, FastAPI (modular monolith), async SQLAlchemy 2.0
- Worker: Async job runner (e.g., arq) for ingestion/embeddings
- Database: PostgreSQL 16 with `pgvector` + `pg_trgm` (single datastore)
- Queue: Redis 7
- Client: Flutter; BYOK keys stored with `flutter_secure_storage` on mobile/desktop (web keeps keys in-memory for the session) and sent per request only

This pivots from an early SOA design to accelerate iteration for the MVP; extract services later as profiling demands.

## Getting started (development)

Prereqs: Docker Desktop, Python 3.12 (or Conda), Git.

1) Infrastructure

```bash
docker compose up -d
```

2) Environment (`backend/.env`)

```
DATABASE_URL=postgresql+asyncpg://app:app@localhost:5433/app
REDIS_URL=redis://localhost:6379/0
EMBED_DIM=1536
```

3) Install & run
  Unix:

```bash
python -m venv .venv && source .venv/bin/activate
pip install -U pip
pip install fastapi "uvicorn[standard]" "sqlalchemy[asyncio]" asyncpg alembic lxml redis arq "psycopg[binary]" python-dotenv pydantic-settings pgvector
python -m alembic -c alembic.ini upgrade head
uvicorn app.main:app --reload
```

Windows (PowerShell):

```powershell
conda create -y -n ancient python=3.12 && conda activate ancient
pip install -U pip
pip install fastapi "uvicorn[standard]" "sqlalchemy[asyncio]" asyncpg alembic lxml redis arq "psycopg[binary]" python-dotenv pydantic-settings pgvector
python -m alembic -c alembic.ini upgrade head
# Option A: set PYTHONPATH so uvicorn --reload + reloader can import app.main
$env:PYTHONPATH = (Resolve-Path .\backend).Path
uvicorn app.main:app --reload
# Option B: skip PYTHONPATH and point uvicorn at backend/ directly
# uvicorn --app-dir .\backend app.main:app --reload
```

4) Worker

```
arq app.ingestion.worker.WorkerSettings
```

5) Smoke checks

- `GET /health` → `{"status":"ok"}`
- `GET /health/db` → confirms `vector` + `pg_trgm` extensions and seed `Language(grc)`.
- `POST /lesson/generate` (when `LESSONS_ENABLED=1`) returns compact JSON tasks (see `docs/LESSONS.md`).
- UI smoke: run `scripts/dev/smoke_lessons_ui.txt` after enabling `LESSONS_ENABLED=1`.
- Headless smoke (PowerShell): `pwsh -File scripts/dev/smoke_headless.ps1`
- Headless smoke (Bash): `bash scripts/dev/smoke_headless.sh`
Troubleshooting (Windows): if uvicorn reloaders raise `ModuleNotFoundError: app`, set `$env:PYTHONPATH = (Resolve-Path .\backend).Path` before launching or run `uvicorn --app-dir .\backend app.main:app --reload`.

### Lesson v0 (flagged)

### TTS v0 (flagged)
Enable with `TTS_ENABLED=1`. Then call `POST /tts/speak` with: `{"text":"χαῖρε κόσμε","provider":"echo"}`. See [`docs/TTS.md`](docs/TTS.md) for the full runbook and BYOK notes.

- `echo` returns a deterministic ~0.6s mono WAV offline.
- `openai` forwards BYOK `Authorization: Bearer ...` to `https://api.openai.com/v1/audio/speech`; on error the server falls back to `echo` and reports the downgrade in `meta.provider`.
- Smoke locally via `scripts/dev/smoke_tts.ps1` or `scripts/dev/smoke_tts.sh` which save `artifacts/tts_echo.wav`.
Enable with `LESSONS_ENABLED=1`. Then:

```bash
bash scripts/dev/smoke_lessons.sh
```

Or call directly:

```bash
curl -X POST http://127.0.0.1:8000/lesson/generate \
  -H 'Content-Type: application/json' \
  -d '{"language":"grc","profile":"beginner","sources":["daily","canon"],"exercise_types":["alphabet","match","cloze","translate"],"k_canon":2,"include_audio":false,"provider":"echo"}'
```

To test BYOK with OpenAI (example), include a key **per request** (never persisted):

```bash
curl -X POST http://127.0.0.1:8000/lesson/generate \
  -H 'Content-Type: application/json' \
  -H "Authorization: Bearer $OPENAI_API_KEY" \
  -d '{"language":"grc","profile":"beginner","sources":["daily","canon"],"exercise_types":["alphabet","match","cloze","translate"],"k_canon":2,"include_audio":false,"provider":"openai","model":"gpt-5-mini"}'
```

> Keys are request‑scoped only and redacted from logs (BYOK policy unchanged).

## Data (local only)

Third‑party corpora are not stored in this repo. Run:

PowerShell:

```powershell
pwsh -File scripts/fetch_data.ps1
```

Unix:

```bash
bash scripts/fetch_data.sh
```

This populates `data/vendor/**` (Perseus Iliad TEI, LSJ TEI, Smyth HTML) and `data/derived/**` for pipeline outputs. See `data/DATA_README.md` and `docs/licensing-matrix.md`.


## Repository layout (modular monolith)

```
app/
api/                # routers
core/               # config, logging, security
db/                 # models, session, migrations
ingestion/          # parsers, normalizers, worker jobs
retrieval/          # hybrid lexical + vector search
tests/              # unit + accuracy gates
docker/
scripts/
```

## Linguistic Data Schema (LDS v1)

Key entities: Language; SourceDoc; TextWork; TextSegment (text_raw, text_nfc, text_fold, emb); Token (surface/lemma, *_fold, msd); Lexeme; GrammarTopic; (MorphRule reserved).

Normalization: NFC for display; parallel accent‑folded fields for robust search; deterministic chunk IDs.

Indexes:

- `vector` on embeddings (dimension = `EMBED_DIM`)
- GIN `pg_trgm` on `token.surface_fold`, `lexeme.lemma_fold`, `text_segment.text_fold`
- btree on `(language_id, lemma)`

## Reader v0 (M2 target)

- Text: Iliad 1.1–1.10 from TEI
- Tap token → lemma + morphology; LSJ gloss; Smyth § link
- UI shows source attributions and links
- BYOK UI for LLM/TTS keys (request‑scoped server usage; never persisted)

See [docs/BYOK.md](docs/BYOK.md) for header usage, request-scoped policy, and logging guarantees. The optional coach endpoint is documented in [docs/COACH.md](docs/COACH.md).

## Retrieval (hybrid) and RAG

- Lexical: trigram similarity over folded fields with lemma expansion
- Semantic: `pgvector` cosine over segments and grammar topics
- Optional cross‑encoder rerank when latency budget allows
- Mandatory language filter (e.g., `grc`) on every retrieval

## Quality gates (CI)

- M1 Ingestion: ≥99% TEI parse success; searchable by lemma/surface; deterministic chunk IDs; licensing matrix present
- M2 Retrieval: Smyth Top‑5 ≥85% on 100 curated queries; LSJ headword ≥90% on 200 tokens; p95 latency < 800 ms for k=5 (no rerank)
- Security: CI fails if any `*_api_key` appears in captured logs

## Roadmap (tight MVP)

- M1: Infra + LDS + ingestion (Smyth, LSJ, Iliad 1)
- M2: Hybrid retrieval + `/reader/analyze` + accuracy tests
- M3: Flutter Reader v0; polish; BYOK UX
  Post‑MVP (behind feature flags): Socratic dialogue in Greek; phonology/TTS profiles; additional texts/languages.

## Licensing (preliminary)

- Code: intended license is **Apache‑2.0**. Code and data are licensed separately.
- Third‑party data remains under original licenses (see `docs/licensing-matrix.md`). Many Perseus/Scaife TEI and LSJ resources are **CC BY‑SA**; some treebanks are **CC BY‑SA 3.0**; proprietary texts (e.g., *Athenaze*) are **all rights reserved** and excluded.
- Repository layout:
  - `data/vendor/<source>/...` with source `README` and license file or notice
  - `data/derived/` for normalized/chunked output (inherits upstream license where applicable)
  - `docs/licensing-matrix.md` lists each source, license, attribution text, and use constraints
- Attribution: the UI and API responses display source titles and links; exported content includes a consolidated attribution block.
- Restrictions enforcement: runtime checks prevent disallowed actions (e.g., audio/TTS for NC sources).
- This section is non‑legal guidance; contributors should follow the matrix and upstream terms.

## Contributing

Conventional commits; PRs must pass tests, migrations, and accuracy gates.

## Quickstart

```bash
# Create env (once) and activate
conda create -y -n ancient python=3.12
conda activate ancient

# Install project + dev tools (PEP 621)
pip install --upgrade pip
pip install -e ".[dev]"
pip install ruff pre-commit

# Install pre-commit hooks
pre-commit install

# Start DB and apply migrations
docker compose up -d db
export DATABASE_URL=postgresql+asyncpg://app:app@localhost:5433/app  # PowerShell: $env:DATABASE_URL='postgresql+asyncpg://app:app@localhost:5433/app'
python -m alembic -c alembic.ini upgrade head

# Run tests and lint
pytest -q
pre-commit run --all-files
```

See [docs/DEMO.md](docs/DEMO.md) for the full demo walkthrough and [docs/HOSTING.md](docs/HOSTING.md) for hosting flags (`SERVE_FLUTTER_WEB=1`, `ALLOW_DEV_CORS=1`) and `/app/` serving notes.

## Prerequisites

* Conda (Miniconda/Miniforge) with Python 3.12
* Docker + Docker Compose
* Git

## Database

1. Start Postgres (Docker Compose service `db`):

   ```bash
   docker compose up -d db
   ```
2. Wait until ready (Compose logs will show readiness).
3. Apply migrations:

   ```bash
   python -m alembic -c alembic.ini upgrade head
   ```
4. Verify extensions (optional):

   ```bash
   docker compose exec -T db psql -U postgres -d postgres -c "SELECT extname FROM pg_extension ORDER BY 1;"
   ```

## Reader analyze (dev)

1. Start the API (after `docker compose up -d db` and `alembic upgrade head`):

   ```bash
   PYTHONPATH=backend DATABASE_URL=postgresql+asyncpg://app:app@localhost:5433/app \
   uvicorn app.main:app --reload
   ```

   > Dev-only CORS: export `ALLOW_DEV_CORS=1` (accepted values: `1/true/yes`) before starting Uvicorn if a local Flutter/Web client needs to call the API. The flag defaults off so cross-origin requests stay blocked in prod/test shells.

2. In another shell, call the endpoint with a sample Iliad query:

   ```bash
   curl -X POST http://localhost:8000/reader/analyze \
     -H 'Content-Type: application/json' \
     -d '{"q":"Μῆνιν ἄειδε"}'
   ```

   Tokens now include `lemma` and `morph` fields resolved via Perseus morphology (with CLTK fallback).
   The lexical path still uses `%` + `set_limit(t)` so the session trigram threshold matches the request.

3. Request LSJ glosses and Smyth sections when needed:

   ```bash
   curl -X POST 'http://localhost:8000/reader/analyze?include={"lsj":true,"smyth":true}' \
     -H 'Content-Type: application/json' \
     -d '{"q":"Μῆνιν ἄειδε"}'
   ```

   The response adds `lexicon` (LSJ entries) and `grammar` (Smyth topics filtered to Greek).

4. Perf sanity (dev):

   ```bash
   python scripts/dev/bench_reader.py --runs 150 --warmup 30 --include '{"lsj": true, "smyth": true}'
   ```

   Prints p50/p95/p99/mean latency for `/reader/analyze`; see [docs/BENCHMARKS.md](docs/BENCHMARKS.md) for options and the CI job.

## Accuracy harness (dev/test)

See [docs/ACCURACY.md](docs/ACCURACY.md) for curated datasets, fixture seeding, and the label-triggered CI workflow. Follow those steps to run the harness locally before tagging a PR with `run-accuracy`.


**Reset (destructive):**

```bash
docker compose down -v
docker compose up -d db
python -m alembic -c alembic.ini upgrade head
```

## Flutter Reader (dev)

### First Method of Running the Flutter App (Standard Run):

1. Start the backend stack (database, migrations via root `alembic.ini`, API):

   ```bash
   docker compose up -d db
   python -m alembic -c alembic.ini upgrade head
   PYTHONPATH=backend uvicorn app.main:app --reload
   ```

2. Run the Flutter client (Chrome web shown; pick any supported device):

   ```bash
   cd client/flutter_reader
   flutter pub get
   flutter run -d chrome --web-renderer html
   ```

3. Paste Iliad 1.1–1.10, toggle LSJ/Smyth as needed, then tap **Analyze**. Tokens display lemma + morphology; tapping surfaces LSJ glosses and Smyth anchors with source attributions.

Open the **Lessons** tab to generate daily + canonical drills; requires backend `LESSONS_ENABLED=1`.

For quick screenshots during demos hit `http://127.0.0.1:8000/app/?tab=lessons&autogen=1` to preload the generator.

Sample API checks (optional, run after the server is live):

```bash
curl -X POST http://127.0.0.1:8000/reader/analyze \
  -H "Content-Type: application/json" \
  -d '{"q":"Μῆνιν ἄειδε"}'

curl -X POST "http://127.0.0.1:8000/reader/analyze?include={"lsj":true,"smyth":true}" \
  -H "Content-Type: application/json" \
  -d '{"q":"Μῆνιν ἄειδε"}'
```

See [docs/DEMO.md](docs/DEMO.md) for a one-command demo runbook.

### Second Method of Running the Flutter App

Tested on Flutter 3.35.4 stable (Dart 3.9.2). See `flutter --version`.

#### Prereqs (Windows)

- Install Flutter stable (3.35.x) somewhere like `C:\tools\flutter`.
- Add `C:\tools\flutter\bin` to your **User PATH**.
- Install Chrome or use Edge. If Chrome isn't in default location, set:
```
  setx CHROME_EXECUTABLE "C:\Program Files\Google\Chrome\Application\chrome.exe"
  # Open a NEW terminal after this so the env var is available.
```

Or point to any other Chrome path, if you prefer (note: for web dev you can also use the generic `web-server` device).

- Android (optional): install SDK via Android Studio or `sdkmanager`; accept licenses:
```
  flutter config --android-sdk "%LOCALAPPDATA%\Android\sdk"
  sdkmanager --licenses
```

#### First run
```powershell
  flutter --version
  flutter doctor -v
  cd client\flutter_reader
  flutter pub get
  flutter run -d chrome          # or: flutter run -d edge

  # If browsers won’t auto-launch on your system:
  flutter run -d web-server --web-hostname 127.0.0.1 --web-port 0
```

### BYOK (dev only)

- Tap the key icon in the app bar to open the BYOK sheet (debug builds only; persisted with `flutter_secure_storage` on mobile/desktop and kept in-memory for the session on web builds).
- Paste an OpenAI API key and choose **Save**; the key stays local and is sent only for BYOK providers such as `provider=openai` lesson requests.
- Pick lesson/TTS providers and optional model overrides from the same sheet; the app falls back to the offline `echo` provider if a BYOK call fails.
- Use **Clear** to wipe the stored key when switching providers or rotating credentials.

The reader loads `assets/config/dev.json` for `apiBaseUrl`—copy/adjust per environment instead of hardcoding URLs.

## Tests & Lint

* Run test suite:

  ```bash
  pytest -q
  ```
* A pre-commit hook runs `ruff` and formatting; run:

  ```bash
  pre-commit run --all-files
  ```

## API search (dev)

```bash
PYTHONPATH=backend python -m uvicorn app.main:app --reload
curl 'http://127.0.0.1:8000/search?q=Μῆνιν&l=grc&k=3&t=0.05'
```

## Data directories policy

* `data/vendor/` and `data/derived/` are **not** committed; hooks block accidental commits.
* Do not commit secrets; a hook checks for obvious keys in staged diffs.

## Troubleshooting

* **Commit fails with auto-fixes**: run `pre-commit run --all-files` and re-stage, or use the normalization steps in this repo’s `.gitattributes`/`.editorconfig`.
* **Windows CRLF/LF**: this repo enforces LF. Git config is set per-repo to `core.eol=lf`, `core.autocrlf=false`.
* **DB not ready**: check `docker compose logs db` and ensure port 5433 on host is free.

## MVP demo: Classical Greek (Perseus TEI)

Use the tiny TEI sample to run the end-to-end slice (ingest → normalize → store → query):

**Bash**
    scripts/dev/run_mvp.sh

**PowerShell**
    scripts/dev/run_mvp.ps1

These scripts will: (1) docker compose up -d db, (2) run python -m alembic -c alembic.ini upgrade head, and (3) ingest the sample via python -m pipeline.perseus_ingest --ensure-table, then print a one-line summary.

Tip: For CI or non-default ports, set DATABASE_URL (for example: postgresql+asyncpg://postgres:postgres@localhost:5432/postgres). If you need a synchronous driver for tooling, set `DATABASE_URL_SYNC` separately (e.g., `postgresql+psycopg://...`).
