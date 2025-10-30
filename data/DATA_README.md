# Data setup

This repository does not include third‑party corpora. Use the provided scripts to fetch sources locally.

## Directories

- `data/vendor/`  – unmodified upstream data (by source)
- `data/derived/` – normalized/chunked outputs produced by the pipeline

## Fetch

```bash
bash scripts/fetch_data.sh
```

**Note:** PowerShell scripts are legacy and should not be used. The project has migrated to Linux/Bash.

## Sources and licenses (summary)

* **Perseus canonical‑greekLit (Iliad TEI)** — CC BY‑SA 4.0. Attribution required; adaptations must remain CC BY‑SA. Source: PerseusDL/canonical-greekLit.
* **LSJ TEI (PerseusDL/lexica)** — CC BY‑SA 4.0. Attribution + ShareAlike.
* **Smyth’s Greek Grammar (Alpheios)** — CC BY‑NC‑SA 3.0 US (non‑commercial). Fetched for local use; not redistributed here.
* **AGLDT treebank (optional)** — CC BY‑SA 3.0 US.

See `docs/licensing-matrix.md` for full details and attribution strings.

## Attribution (examples)

* “Text from Perseus Digital Library (Scaife) — CC BY‑SA 4.0.”
* “LSJ data © Perseus Digital Library — CC BY‑SA 4.0.”
* “Smyth (Alpheios) — CC BY‑NC‑SA 3.0 (not redistributed).”

## Policy

* Do not commit files under `data/vendor/` or `data/derived/`.
* The application surfaces source attributions in UI/API responses.
