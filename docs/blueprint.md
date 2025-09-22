# Strategic Technical Blueprint v1.1 — Ancient Languages AI Platform

Purpose: deliver a credible Classical Greek MVP centered on **Reader v0** with authoritative sources and RAG with citations, using a **modular monolith + worker** architecture for speed, with clear extraction paths for future services.

## 1) Product scope (MVP)
- Language: Classical Greek (Iliad 1.1–1.10 sample)
- Feature: Reader v0 with tap‑to‑analyze → lemma, morphology, LSJ gloss, Smyth § link
- **Flagged track:** Lesson v0 (server) generating compact tasks from daily-speech seed data and small canonical slices (Iliad 1.1–1.10 now; expandable), with offline echo provider and BYOK providers.
- Guarantees: NFC normalization; accent‑aware lexical search; language‑filtered retrieval; BYOK security; licensing compliance

## 2) Architecture
- Backend: FastAPI app with bounded contexts (api, core, db, ingestion, retrieval, security)
- Worker: async job runner (arq) for ingestion + embeddings
- DB: Postgres 16 with `pgvector` + `pg_trgm` (single datastore for relational + vectors)
- Queue: Redis
- Client: Flutter; BYOK stored locally; server treats keys as request‑scoped secrets only
- **Lesson providers:** `echo` (deterministic, offline) and `openai` (BYOK). Providers are thin, lazily imported adapters; failures fall back to `echo`.
- Extraction plan (post‑MVP, when profiling justifies):
  - Split ingestion worker into a service
  - Split retrieval into a service if latency or independent scaling demands it

## 3) Linguistic Data Schema (LDS v1)
Entities
- Language(code, name)
- SourceDoc(slug, title, license, meta)
- TextWork(language_id, source_id, author, title, ref_scheme)
- TextSegment(work_id, ref, text_raw, text_nfc, text_fold, emb, meta)
- Token(segment_id, idx, surface, surface_nfc, surface_fold, lemma, lemma_fold, msd)
- Lexeme(language_id, lemma, lemma_fold, pos, data)
- GrammarTopic(source_id, anchor, title, body, body_fold, emb)
- MorphRule(paradigm_id, features, language_id) [reserved for later]

Indexes and normalization
- `vector` on `emb` with dimension from `EMBED_DIM` (config)
- GIN `pg_trgm` on folded fields: token.surface_fold, lexeme.lemma_fold, text_segment.text_fold
- btree on `(language_id, lemma)`
- NFC normalization; accent folding for parallel lexical fields; deterministic chunk IDs

## 4) Ingestion v1 (sources and flow)
Sources
- TEI texts + morphology (Perseus/Scaife)
- LSJ (digital lexicon)
- Smyth (grammar topics/sections)

Flow
- acquire → parse (lxml) → normalize (NFC + fold) → segment/chunk → link tokens ↔ lexeme ↔ grammar topics → embed (Vector(`EMBED_DIM`)) → index
- treat Perseus morphology as primary; CLTK as supplemental
- maintain `docs/licensing-matrix.md`; attach license metadata on import

## 5) Retrieval v1 and RAG
- Lexical: trigram similarity on folded fields; lemma expansion
- Semantic: `pgvector` cosine over segments and grammar topics
- Optional cross‑encoder reranking for larger k
- Mandatory language filter (e.g., `grc`) on all queries
- Prompt templates per task; include retrieved snippets + citations; RAG‑only mode for factual queries

## 5.1) Lesson v0 (flag) — API & schema
**Endpoint:** `POST /lesson/generate` (enabled with `LESSONS_ENABLED=1`)
**Request:** `{language, profile, sources, exercise_types, k_canon, include_audio, provider, model}`
**Response:** `{meta, tasks:[Alphabet|Match|Cloze|Translate]}`; canonical tasks include `ref` (e.g., `Il.1.1`).
Providers must not persist or log keys; BYOK is read from headers per request and redacted.

**Acceptance (Lesson v0):**
- Valid schema with ≥3 task types; offline `echo` path works.
- Canonical tasks include `ref` and pass NFC/fold normalization.
- BYOK keys are request-scoped only; failures gracefully fall back to `echo`.

## 6) Security, privacy, observability
- BYOK: keys stored client‑side; on server, request‑scoped only; never persisted; redaction middleware + logger filters
- Observability: basic request metrics and latency histograms; expand after endpoints stabilize
- CI test fails if any `*_api_key` appears in captured logs

## 7) Roadmap and acceptance gates
M1 — Infra + LDS + Ingestion (Smyth, LSJ, Iliad 1)
- `pgvector` + `pg_trgm` enabled; LDSv1 migrated
- ≥99% TEI parse success; deterministic chunk IDs; searchable by lemma/surface
- licensing matrix merged; attributions available via API metadata
Gate: checks pass in CI

M2 — Retrieval + Reader endpoints
- Hybrid retrieval with language filter; `/reader/analyze` returns lemma, morphology, LSJ, Smyth §
- Benchmarks: Smyth Top‑5 ≥85% (100 curated queries); LSJ headword ≥90% (200 tokens); p95 latency < 800 ms (k=5, no rerank)
Gate: metrics enforced in CI

M2.5 — Lesson v0 (server, flag) — **Gate:** schema OK; offline OK; BYOK OK; canonical refs present

M3 — Flutter Reader v0 (Iliad 1.1–1.10)
- Polytonic rendering; tap‑to‑analyze; BYOK UX; visible attributions
Gate: demo build + QA checklist

Post‑MVP (labs/flags): Socratic dialogue in Greek; phonology/TTS; additional texts/languages

## 8) Risks and mitigations
- Low‑resource accuracy → RAG with citations; gold test sets wired into CI; RAG‑only factual mode
- Licensing/attribution → matrix + runtime enforcement; UI attributions
- Async complexity → modular monolith + worker; extract only under load
- Dependency churn → two‑tier deps (stable vs experimental); promotion via passing benchmarks

## 9) Implementation checklist (PR1→PR4)
- PR1: LDSv1 + compose + migrations (extensions + GIN on `text_segment.text_fold`); `/health/db`; `EMBED_DIM` configurable end‑to‑end
- PR2: Ingestion (Perseus, LSJ, Smyth); normalization; deterministic chunk IDs; worker wiring
- PR3: Hybrid retrieval + `/reader/analyze` + accuracy gates in CI
- PR4: Flutter Reader v0; BYOK UX; visible attributions
