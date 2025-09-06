# Licensing Matrix (Preliminary)

This matrix governs data and model usage. Code is licensed separately (Apache‑2.0 unless noted). This file is normative for ingestion and UI attributions.

| Source / repo                                   | Type              | License                     | Notes / requirements                                                                 | Allowed in MVP | Attribution (example)                                      |
|-------------------------------------------------|-------------------|-----------------------------|--------------------------------------------------------------------------------------|----------------|------------------------------------------------------------|
| PerseusDL/canonical-greekLit (Scaife)           | TEI texts         | CC BY‑SA 4.0                | Keep license header; share‑alike for adapted material                                 | Yes            | “Text from Perseus Digital Library (Scaife), CC BY‑SA 4.0.” |
| PerseusDL/lexica (LSJ files)                    | Lexicon           | CC BY‑SA 4.0 (repo)         | Some subfolders may vary; retain notices                                             | Yes            | “LSJ data © Perseus DL, CC BY‑SA 4.0.”                     |
| AGLDT / UD Ancient Greek – Perseus              | Treebank          | CC BY‑SA 3.0                | Keep license; share‑alike; credit maintainers                                        | Yes            | “AGLDT/UD data, CC BY‑SA 3.0.”                             |
| Smyth 1920 (print PD; digital variants vary)    | Grammar           | Public Domain (print) / CC BY‑SA if using Perseus transcription | Prefer PD scans if own transcription is produced; else inherit CC BY‑SA               | Yes            | “Smyth (1920), PD; digital transcription per source.”      |
| Morpheus (perseids-tools/morpheus)              | Tool (code)       | MPL‑2.0                     | Dynamic use allowed; modifications to files under MPL must be MPL                     | Yes            | “Morpheus analyzer © Perseus, MPL‑2.0.”                    |
| Athenaze (OUP)                                   | Textbook          | All rights reserved         | Do not ingest; link to publisher; no redistribution                                  | No             | n/a                                                        |

Operational policies
- Data segregation: keep third‑party data under `data/vendor/<source>/` with upstream LICENSE/notice.
- Derived outputs: place normalized/chunked data under `data/derived/<source>/` and preserve upstream license where applicable.
- UI: show source attribution on Reader panels and RAG answers.
- Runtime enforcement: block TTS or redistribution when a source license forbids it (e.g., NC).
