# LDS v1 — Core Entities (MVP)

Minimal tables exercised by the MVP:

- **language**: `(id PK, code text unique, name text)`
- **source_doc**: `(id PK, language_id FK, source text, title text)`
- **text_work**: `(id PK, language_id FK, source_doc_id FK, ref_scheme text, title text)`
- **text_segment**: `(id PK, work_id FK, idx int, text_raw text, text_nfc text, text_fold text, emb vector?)`

Notes

- Trigram search targets folded fields (e.g., `text_fold`) for robust matching irrespective of accents/case.
- `pg_trgm` and `vector` extensions are expected to be installed; only `pg_trgm` is needed for this demo.
- The MVP ingest stores a few Iliad lines as `text_segment` rows; the search CLI queries them.
