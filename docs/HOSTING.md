# Hosting Notes

Reader v0 ships with demo scripts that orchestrate the full stack locally: Dockerized Postgres, Alembic migrations (root `alembic.ini`), the FastAPI app, and the Flutter web bundle mounted under `/app/`. Keep the demo flags unchanged—`SERVE_FLUTTER_WEB=1` enables the static bundle and `ALLOW_DEV_CORS=1` relaxes CORS for local clients.

## Flags
- `SERVE_FLUTTER_WEB=1` — serve the compiled Flutter web bundle at `/app/`.
- `ALLOW_DEV_CORS=1` — relax CORS for local web clients.
- `LESSONS_ENABLED=1` — mount `POST /lesson/generate` (Lesson v0). Keep off in prod until the feature stabilizes.
- `COACH_ENABLED=true` — optional coach endpoint; BYOK required for non-echo providers (see docs/COACH.md).

## One-command demo

Unix:

```bash
scripts/dev/run_demo.sh
```

Windows (PowerShell):

```powershell
scripts/dev/run_demo.ps1
```

Both scripts perform the following:

1. `docker compose up -d db`
2. `python -m alembic -c alembic.ini upgrade head`
3. Build the Flutter web bundle and serve it at `/app/`
4. Start Uvicorn with `SERVE_FLUTTER_WEB=1` and `ALLOW_DEV_CORS=1`

When Uvicorn reports `127.0.0.1:8000`, navigate to `http://127.0.0.1:8000/app/` for the Flutter UI and use `/reader/analyze` for API checks. BYOK remains request-scoped; never persist user-provided keys.

## Deploy quickstart (stub)

For production you will need to provide your own process manager and HTTPS termination. Recommended next steps:

- Provision Postgres 16 with the same extensions as the demo (see `docs/DEMO.md`).
- Run migrations with `python -m alembic -c alembic.ini upgrade head` during deploys.
- Configure FastAPI (e.g., uvicorn/gunicorn) to set `SERVE_FLUTTER_WEB=1` only when the static bundle should be exposed under `/app/`.
- Keep `ALLOW_DEV_CORS` disabled unless a trusted frontend requires it.
- Optionally enable the Greek coach endpoint (`COACH_ENABLED=true`) when BYOK providers are configured; see `docs/COACH.md`.

See [docs/DEMO.md](docs/DEMO.md) for the full demo flow and smoke tests.
