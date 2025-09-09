# Ancient Languages — Classical Greek MVP

Research‑grade platform for studying ancient languages, beginning with Classical Greek. MVP goal: **Reader v0** for Iliad 1.1–1.10 with tap‑to‑analyze (lemma + morphology), LSJ gloss, Smyth § citation, and RAG‑grounded answers with citations.

## Architecture (MVP)
- Backend: Python 3.12, FastAPI (modular monolith), async SQLAlchemy 2.0
- Worker: Async job runner (e.g., arq) for ingestion/embeddings
- Database: PostgreSQL 16 with `pgvector` + `pg_trgm` (single datastore)
- Queue: Redis 7
- Client: Flutter; BYOK keys stored with `flutter_secure_storage` and sent per request only

This pivots from an early SOA design to accelerate iteration for the MVP; extract services later as profiling demands.

## Getting started (development)
Prereqs: Docker Desktop, Python 3.12 (or Conda), Git.

1) Infrastructure
```bash
docker compose up -d
```

2) Environment (`backend/.env`)
```
DATABASE\_URL=postgresql+asyncpg://app\:app\@localhost:5433/app
REDIS\_URL=redis\://localhost:6379/0
EMBED\_DIM=1536
```

3) Install & run
Unix:
```bash
python -m venv .venv && source .venv/bin/activate
pip install -U pip
pip install fastapi "uvicorn\[standard]" "sqlalchemy\[asyncio]" asyncpg alembic lxml redis arq "psycopg\[binary]" python-dotenv pydantic-settings pgvector
alembic upgrade head
uvicorn app.main\:app --reload
```

Windows (Anaconda PowerShell):
```powershell
conda create -y -n ancient python=3.12 && conda activate ancient
pip install -U pip
pip install fastapi "uvicorn\[standard]" "sqlalchemy\[asyncio]" asyncpg alembic lxml redis arq "psycopg\[binary]" python-dotenv pydantic-settings pgvector
alembic upgrade head
uvicorn app.main\:app --reload
```

4) Worker
```
arq app.ingestion.worker.WorkerSettings
```

5) Smoke checks
- `GET /health` → `{"status":"ok"}`
- `GET /health/db` → confirms `vector` + `pg_trgm` extensions and seed `Language(grc)`.

## Data (local only)
Third‑party corpora are not stored in this repo. Run:

PowerShell:
```powershell
pwsh -File scripts/fetch\_data.ps1
```

Unix:
```bash
bash scripts/fetch\_data.sh
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
