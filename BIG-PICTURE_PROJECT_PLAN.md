# Big‑Picture Project Plan — Ancient Languages (Classical Greek MVP)

## Purpose
Deliver a credible, research‑grade platform for studying ancient languages, starting with Classical Greek. The MVP centers on **Reader v0** (Iliad 1.1–1.10): tap‑to‑analyze token → lemma & morphology (Perseus), LSJ gloss, Smyth § link, with citations.

## Product pillars
- **Authoritative sources**: Perseus TEI (texts + morphology), LSJ, Smyth.
- **RAG with citations**: Answers are grounded in retrieved passages; UI shows attributions.
- **BYOK**: Users provide LLM/TTS keys; keys are request‑scoped server‑side and never persisted.
- **Dynamic lessons (flagged)**: Lesson generation is provider-pluggable (echo/offline, OpenAI/other via BYOK) and produces only natural daily-speech lines and canonical excerpts—no nonsense prompts. (Daily lines come from team-authored YAML; canonical lines come from our licensed/allowed slices.)  <!-- LESSONS_ENABLED -->
- **Text-targeted lesson generation**: Users select specific text ranges (e.g., "Iliad 1.20-1.50") to extract vocabulary and grammar patterns; LLM generates exercises grounded in that passage's linguistic features.
- **Conversational immersion chatbot**: Roleplay-based language practice (e.g., "Chat with an Athenian merchant in 400 BCE"); BYOK-powered conversational endpoint with system prompts for historical personas, scaffolding in user's native language.
- **Register modes**: Literary vs. colloquial speech toggle; separate seed files (`literary_grc.yaml` vs. `colloquial_grc.yaml`) with LLM prompts adjusted accordingly.
- **Multi-language foundation**: Classical Greek MVP; Latin (Classical + Vulgar) staged for post-MVP expansion with parallel corpus structure.

## Architecture (current)
- **Backend**: Python 3.12, FastAPI modular monolith; async SQLAlchemy 2.0
- **Worker**: Async job runner (arq) for ingestion/embeddings
- **DB**: PostgreSQL 16 + `pgvector` + `pg_trgm` (single datastore)
- **Queues**: Redis 7
- **Client**: Flutter; secure local key storage
(Previous SOA concept is deferred until profiling justifies extraction to services.)

## Linguistic Data Schema (LDS v1)
- **Core entities**: Language, SourceDoc, TextWork, TextSegment (text_raw/nfc/fold, emb), Token (surface/lemma, *_fold, msd), Lexeme, GrammarTopic.
- **Normalization**: NFC display; accent‑folded parallel fields for robust search; deterministic chunk IDs.
- **Indexes**: `vector(EMBED_DIM)` on embeddings; GIN `pg_trgm` on `token.surface_fold`, `lexeme.lemma_fold`, `text_segment.text_fold`; btree on `(language_id, lemma)`.

## Data strategy
- Sources fetched at dev/build time; not committed to the repo.
- Licensing matrix maintained in `docs/licensing-matrix.md`; runtime policy blocks disallowed uses (e.g., TTS for NC sources).
- Reader v0 uses Iliad 1 (Perseus TEI) with strict language filters.

## Roadmap (MVP)
**M1 — Infra + LDS + Ingestion**
- Migrate LDS; enable `pgvector`/`pg_trgm`; fetch & ingest Perseus (Iliad 1) + LSJ + Smyth metadata
- Gate: ≥99% TEI parse success; searchable by lemma/surface; licensing matrix present

**M2 — Retrieval + Reader endpoints**
- Hybrid lexical/semantic retrieval; `/reader/analyze` returns lemma, morphology, LSJ, Smyth §
- Gates: Smyth Top‑5 ≥85% (100 curated queries); LSJ headword ≥90% (200 tokens); p95 < 800 ms (k=5, no rerank)

**M2.5 — Lesson v0 (server, behind flag)**
- Endpoint: `POST /lesson/generate` with `provider` (`echo|openai`), BYOK model selection, and task types (`alphabet|match|cloze|translate`).
- Inputs: `sources=["daily","canon"]`, `k_canon` small. Echo provider is deterministic and works offline.
- Gates: schema validity; offline works with `provider=echo`; canonical tasks carry `ref`; BYOK keys never persisted.

**M3 — Flutter Reader v0**
- Polytonic rendering; tap‑to‑analyze; BYOK UX; visible attributions
- Zero-click lesson generation: auto-generate on tab open with collapsible customization panel (text range picker, exercise types, difficulty slider)
- Text-based entry points: "Learn from Famous Texts" card on home screen with text picker for targeted lesson generation
- Chatbot tab: conversational immersion with chat bubble UI, persona selector, translation help, grammar notes
- Literary/colloquial register toggle integrated into lesson customization
- Professional design system: typography scale, color palette, spacing tokens, smooth animations

Post‑MVP (behind flags): Socratic dialogue in Greek; **TTS/voice via BYOK** (provider-pluggable, NC-licensed sources blocked at runtime); Latin (Classical + Vulgar) with parallel corpus structure.

## Risks & mitigations
- **Low‑resource accuracy** → RAG‑only mode for factual claims; gold test sets in CI
- **Licensing complexity** → fetch scripts + matrix; attribution surfaced; NC guarded at runtime
- **Async complexity** → modular monolith + worker; defer SOA until needed
- **Dependency churn** → two‑tier deps (stable vs experimental) with promotion via benchmarks

## Contributing
Conventional commits; PRs must pass migrations and CI gates (accuracy + security).
