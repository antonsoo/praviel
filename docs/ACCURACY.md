# Accuracy Harness

Reader accuracy checks live under `tests/accuracy/` and back the label-triggered CI comment job. Two curated JSONL datasets exercise `/reader/analyze`:

- `smyth_top5.jsonl` — each row contains `{"q": "…", "expected_anchors": ["smyth-accuracy-…"]}` and asserts that the expected Smyth anchor appears within the top five grammar hits.
- `lsj_headword.jsonl` — each row contains `{"q": "…", "expected_lemma": "…"}` and asserts that the LSJ lexicon block includes the requested lemma.

The current gates are informational at 0.85 (Smyth@5) and 0.90 (LSJ headword); CI fails only when accuracy dips below 0.70 / 0.80 respectively.

## Official curated sets (for CI and local runs)
Two datasets live under `tests/accuracy/official/`:

- `smyth_top5.off.jsonl` — ≥100 rows with `{"q": "accusative of respect", "expected_anchors": ["smyth-##"]}`
- `lsj_headword.off.jsonl` — ≥200 rows with `{"q": "ἄειδε", "expected_lemma": "ἀείδω"}`

Strings must be NFC; anchors/lemmas must exist in the DB after ingesting our small Iliad slice. CI keeps the current informational gates (0.85/0.90) and only hard-fails <0.70/<0.80.

### Running locally
```bash
python scripts/accuracy/run_accuracy.py --datasets tests/accuracy/official/smyth_top5.off.jsonl tests/accuracy/official/lsj_headword.off.jsonl --limit 20
```

The harness prints per-set rows and writes `artifacts/accuracy_summary.json`. Label `run-accuracy` on a PR to refresh the comment.

## Local workflow

1. Start Postgres and apply migrations via the root `alembic.ini`.
2. Seed deterministic fixtures (grammar topics, lexeme rows, and lookup tokens):
   ```bash
   python scripts/accuracy/seed_accuracy_fixtures.py
   ```
   Windows (Anaconda PowerShell):
   ```powershell
   python scripts/accuracy/seed_accuracy_fixtures.py
   ```
3. Run the harness against the FastAPI service (ensure `uvicorn` is running on `127.0.0.1:8000`):
   ```bash
   python scripts/accuracy/run_accuracy.py --datasets tests/accuracy/smyth_top5.jsonl tests/accuracy/lsj_headword.jsonl
   ```
   Windows (Anaconda PowerShell):
   ```powershell
   python scripts/accuracy/run_accuracy.py --datasets tests\accuracy\smyth_top5.jsonl tests\accuracy\lsj_headword.jsonl
   ```

Optional flags:

- `--limit N` samples the first `N` rows from each dataset (useful for spot checks).
- `--bench` appends latency percentiles to the Markdown table.
- `--base-url` overrides the default `http://127.0.0.1:8000` target.

The script prints a Markdown table and summary line, then writes `artifacts/accuracy_summary.json` (ignored by Git) for downstream tooling.

## GitHub Actions job

The workflow `.github/workflows/accuracy-comment.yml` runs when either:

- A PR carries the `run-accuracy` label, or
- `workflow_dispatch` is invoked manually (optionally with a `limit` input).

It provisions Postgres 16, applies migrations, seeds the fixtures, boots Uvicorn, runs the harness, uploads `artifacts/accuracy_summary.json` + `artifacts/accuracy_output.txt`, and posts a PR comment containing the Markdown table. Re-running the workflow updates the existing bot comment (marked by `<!-- accuracy-comment -->`).

Keep the datasets and the seeding script (`scripts/accuracy/seed_accuracy_fixtures.py`) in sync—add new anchors/lemmas there whenever the gold sets grow.
