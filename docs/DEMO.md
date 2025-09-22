# Demo Runbook

Reader v0 ships with demo helpers that compile the Flutter web client and serve it alongside the FastAPI app for quick walkthroughs.

## Quickstart (Unix)

```bash
scripts/dev/run_demo.sh
```

The script brings up PostgreSQL via Docker, applies migrations from the root `alembic.ini`, builds the Flutter web bundle, and starts Uvicorn with the bundle mounted at `/app/`.

## Quickstart (Windows PowerShell)

```powershell
scripts/dev/run_demo.ps1
```

This performs the same steps as the Unix script using PowerShell.

## 30-second Smoke Test

Once `uvicorn` reports it is serving on `http://127.0.0.1:8000`, verify the analyzer:

```bash
curl -X POST 'http://127.0.0.1:8000/reader/analyze?include={"lsj":true,"smyth":true}' \
  -H 'Content-Type: application/json' \
  -d '{"q":"Μῆνιν ἄειδε"}'
```

Expect to see tokens with lemma/morph fields and optional LSJ/Smyth sections. Navigate to `http://127.0.0.1:8000/app/` in a browser to load the Flutter web client; BYOK support remains opt-in and request-scoped.

### Optional: Lesson v0 (flag)

Enable the feature and smoke it:

```bash
export LESSONS_ENABLED=1
curl -X POST http://127.0.0.1:8000/lesson/generate \
  -H 'Content-Type: application/json' \
  -d '{"language":"grc","profile":"beginner","sources":["daily","canon"],"exercise_types":["alphabet","match","cloze","translate"],"k_canon":2,"include_audio":false,"provider":"echo"}'
```

This returns a compact JSON lesson containing alphabet, match, cloze (with `ref`), and translate tasks.

## Notes

- The static bundle is only served when `SERVE_FLUTTER_WEB=1`. The demo scripts set this along with `ALLOW_DEV_CORS=1` for local clients.
- Re-run `flutter build web` whenever the Flutter client changes.
- Stop Uvicorn with `Ctrl+C` and run `docker compose down` if you no longer need the database.
- The BYOK-backed coach endpoint stays off by default (`COACH_ENABLED=false`). Enable it manually if you want to demo `/coach/chat`; see `docs/COACH.md` for details.
