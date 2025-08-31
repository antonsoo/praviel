# Strategic Technical Blueprint v1.1 — Ancient Languages AI Platform

This version pivots from an early SOA design to a **modular monolith + worker** to accelerate the Classical Greek MVP while preserving clear extraction paths for future services. The MVP centers on **Reader v0** with authoritative sources (Perseus TEI, LSJ, Smyth) and RAG with citations. :contentReference[oaicite:14]{index=14}

## 1) Product scope (MVP)
- Language: Classical Greek (Homeric sample: Iliad 1.1–1.10)
- Core feature: Reader v0 (tap‑to‑analyze morphology + LSJ + Smyth § with citations)
- Guarantees: NFC normalization, accent‑aware lexical search, language‑filtered retrieval, BYOK security, licensing compliance. :contentReference[oaicite:15]{index=15}

## 2) Architecture
- **Backend:** FastAPI app (bounded contexts: api, db, ingestion, retrieval, security)  
- **Worker:** Async job runner (arq) for ingestion and embedding jobs  
- **DB:** PostgreSQL 16 with `pgvector` + `pg_trgm` (single datastore)  
- **Queues:** Redis 7  
- **Client:** Flutter; BYOK stored with `flutter_secure_storage` and only sent per request; never persisted server‑side. :contentReference[oaicite:16]{index=16}

Extraction plan (when needed):  
- Ingestion worker → separate service when throughput requires it  
- Retrieval service → separate when latency SLOs or independent scaling justify it

## 3) Linguistic Data Schema (LDSv1)
**Entities:**  
Language(code, name)  
SourceDoc(slug, title, license, meta)  
TextWork(language_id, source_id, author, title, ref_scheme)  
TextSegment(work_id, ref, text_raw, text_nfc, text_fold, emb, meta)  
Token(segment_id, idx, surface, surface_nfc, surface_fold, lemma, lemma_fold, msd)  
Lexeme(language_id, lemma, lemma_fold, pos, data)  
GrammarTopic(source_id, anchor, title, body, body_fold, emb)  
MorphRule(paradigm_id, features, language_id) — optional in MVP table, defined in schema for future use

**Indexes:**  
- `GIN (pg_trgm)` on `token.surface_fold`, `lexeme.lemma_fold`, `text_segment.text_fold`  
- `btree` on `(language_id, lemma)`  
- `vector` on embeddings (dimension = `EMBED_DIM` from settings)

**Normalization:**  
- NFC for display; parallel accent‑folded fields for robust search; deterministic chunk IDs by source/anchor/line. :contentReference[oaicite:17]{index=17}

## 4) Ingestion v1 (sources and flow)
**Sources:** Perseus TEI (texts + morphology), LSJ, Smyth. Treat Perseus morphology as primary ground truth; CLTK only supplemental. :contentReference[oaicite:18]{index=18}

**Pipeline:** acquire → parse (lxml) → normalize (NFC + fold) → segment/chunk → link tokens ↔ lexeme ↔ grammar topics → embed (Vector(`EMBED_DIM`)) → index.

**Licensing:** complete and enforce `docs/licensing-matrix.md` (allowed uses, attribution text, audio restrictions). Block actions (e.g., TTS) that violate source terms. :contentReference[oaicite:19]{index=19}

## 5) Retrieval v1 (hybrid + RAG)
- Lexical: `pg_trgm` similarity over folded fields; lemma expansion  
- Semantic: `pgvector` cosine over segment and grammar embeddings  
- Rerank: optional cross‑encoder when `k>8` or latency budget allows  
- Mandatory filters: language code (`grc`) on all queries to avoid cross‑language bleed.  
- Prompts: strict templates; include retrieved snippets + citations; RAG‑only mode for factual queries. :contentReference[oaicite:20]{index=20}

## 6) Security (BYOK) and observability
- Keys live only client‑side; on server they are request‑scoped, not persisted, and scrubbed from logs/traces.  
- Redaction middleware + logger filters; CI test fails if any key pattern appears in logs.  
- Minimal tracing/metrics initially; expand once endpoints stabilize. :contentReference[oaicite:21]{index=21}

## 7) Roadmap & acceptance gates
**M1 — Infra + LDS + Ingestion (Smyth, LSJ, Iliad 1)**  
- `pgvector` + `pg_trgm` enabled; LDSv1 migrated  
- ≥99% TEI parse success on selected sources  
- Deterministic chunk IDs; searchable by lemma and surface  
- Licensing matrix merged; attributions displayed in API responses as metadata  
**Gate:** above checks pass in CI

**M2 — Retrieval + Reader endpoints**  
- Hybrid lexical/semantic retrieval with language filter; `/reader/analyze` returns lemma + morphology + LSJ + Smyth §  
- Benchmarks: Smyth Top‑5 ≥85% on 100 curated queries; LSJ headword ≥90% on 200 tokens; p95 latency < 800 ms (k=5, no rerank)  
**Gate:** metrics automated in CI

**M3 — Flutter Reader v0 (Iliad 1.1–1.10)**  
- Polytonic rendering; tap‑to‑analyze; BYOK UX with clear quota/error handling  
**Gate:** demo build + manual QA checklist

**Post‑MVP (labs/flags):** Socratic dialogue in Greek; phonology/TTS profiles and audio; additional texts/languages. :contentReference[oaicite:22]{index=22}

## 8) Risks & mitigations
- **Accuracy in low‑resource domain:** RAG with citations; gold test sets wired into CI; RAG‑only mode for factual claims.  
- **Licensing/attribution:** matrix + runtime enforcement; show attributions in UI.  
- **Async stack complexity:** modular monolith + worker; extract only under load.  
- **Dependency churn (nightlies):** two‑tier deps (stable vs. experimental), promotion via passing benchmarks. :contentReference[oaicite:23]{index=23}

## 9) Implementation checklist (PR1→PR4)
- PR1: LDSv1 + compose + migrations (+ `EMBED_DIM` config, `text_segment.text_fold` GIN index, `/health/db`)  
- PR2: Ingestion (Perseus, LSJ, Smyth), normalization, deterministic chunk IDs, worker wiring  
- PR3: Hybrid retrieval + `/reader/analyze` + accuracy gates in CI  
- PR4: Flutter Reader v0 (Iliad 1.1–1.10), BYOK UX, attributions in UI