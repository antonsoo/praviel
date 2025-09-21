# Latency Benchmarks

The reader latency bench uses the same FastAPI instance as local development.

## Local workflow

1. Bring up Postgres and apply migrations via the root `alembic.ini`.
2. Start Uvicorn on `127.0.0.1:8000` (`PYTHONPATH=backend uvicorn app.main:app --reload`).
3. Run the bench script with the desired sample size:
   ```bash
   python scripts/dev/bench_reader.py --runs 150 --warmup 30 --include '{"lsj": true, "smyth": true}' --payload '{"q": "μῆνιν ἄειδε"}'
   ```

`scripts/dev/bench_reader.py` prints a Markdown table (p50/p95/p99/mean in milliseconds) plus the run parameters. Adjust `--payload`, `--include`, or `--base-url` when exploring other cases; `--runs`/`--warmup` trade precision for duration.

## GitHub Actions job

`.github/workflows/bench-latency.yml` runs on:

- `workflow_dispatch` (optional `runs` input, default 150)
- Pull requests labeled `run-bench`

The job provisions Postgres 16, applies migrations, launches Uvicorn, executes the bench (`--runs 150 --warmup 30` unless overridden), uploads `artifacts/bench_output.txt`, and posts/updates a single PR comment marked by `<!-- bench-latency -->`. The job is informational; use it to spot regressions without blocking merges.
