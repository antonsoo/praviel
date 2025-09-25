# Demo Runbook

Reader v0 ships with demo helpers that compile the Flutter web client and serve it alongside the FastAPI app for quick walkthroughs.

## Quickstart (Unix)

```bash
scripts/dev/run_demo.sh
```

The script brings up PostgreSQL via Docker, applies migrations from the root `alembic.ini`, builds the Flutter web bundle with `--pwa-strategy none --base-href /app/`, and starts Uvicorn with the bundle mounted at `/app/`.

## Quickstart (Windows PowerShell)

```powershell
scripts/dev/run_demo.ps1
```

This performs the same steps as the Unix script using PowerShell.

Run-only analyzer pass: `scripts/dev/analyze_flutter.sh` (bash) or `scripts/dev/analyze_flutter.ps1` (PowerShell). Both commands run `dart analyze --format=json` and write `artifacts/dart_analyze.json` for quick diffs.

> If you launch uvicorn manually on Windows, run `$env:PYTHONPATH = (Resolve-Path .\backend).Path` first so the reloader imports `app.main`, or use `uvicorn --app-dir .\backend app.main:app --reload`.

## 30-second Smoke Test

Once `uvicorn` reports it is serving on `http://127.0.0.1:8000`, verify the analyzer:

```bash
curl -X POST 'http://127.0.0.1:8000/reader/analyze?include={"lsj":true,"smyth":true}' \
  -H 'Content-Type: application/json' \
  -d '{"q":"Μῆνιν ἄειδε"}'
```

PowerShell headless smoke: `pwsh -File scripts/dev/smoke_headless.ps1`
Bash headless smoke: `bash scripts/dev/smoke_headless.sh`

Expect to see tokens with lemma/morph fields and optional LSJ/Smyth sections. Navigate to `http://127.0.0.1:8000/app/` in a browser to load the Flutter web client; BYOK support remains opt-in and request-scoped.
Windows PowerShell equivalents:

```powershell
# curl.exe uses WinHTTP on Windows and avoids Invoke-WebRequest quirks
curl.exe -sS -X POST "http://127.0.0.1:8000/reader/analyze?include={'lsj':true,'smyth':true}" -H 'Content-Type: application/json' -d '{"q":"Μῆνιν ἄειδε"}'

Invoke-RestMethod -Method Post -Uri 'http://127.0.0.1:8000/reader/analyze?include={"lsj":true,"smyth":true}' -Body '{"q":"Μῆνιν ἄειδε"}' -ContentType 'application/json'
```


### Optional: Lesson v0 (flag)

Enable the feature and smoke it:

```bash
export LESSONS_ENABLED=1
curl -X POST http://127.0.0.1:8000/lesson/generate \
  -H 'Content-Type: application/json' \
  -d '{"language":"grc","profile":"beginner","sources":["daily","canon"],"exercise_types":["alphabet","match","cloze","translate"],"k_canon":2,"include_audio":false,"provider":"echo"}'
```

PowerShell variant (with optional BYOK header):

```powershell
$env:LESSONS_ENABLED = '1'
curl.exe -sS -X POST 'http://127.0.0.1:8000/lesson/generate' -H 'Content-Type: application/json' -H "Authorization: Bearer $env:OPENAI_API_KEY" -d '{"language":"grc","profile":"beginner","sources":["daily","canon"],"exercise_types":["alphabet","match","cloze","translate"],"k_canon":2,"include_audio":false,"provider":"openai"}'

Invoke-RestMethod -Method Post -Uri 'http://127.0.0.1:8000/lesson/generate' -Headers @{ 'Content-Type' = 'application/json'; 'X-Model-Key' = $env:OPENAI_API_KEY } -Body '{"language":"grc","profile":"beginner","sources":["daily","canon"],"exercise_types":["alphabet","match","cloze","translate"],"k_canon":2,"include_audio":false,"provider":"openai"}'
```

A dev-only probe lives at `GET /diag/byok/openai`; supply either BYOK header to confirm connectivity before exercising the OpenAI adapter.

## Run Flutter Lessons

Start the backend with CORS and the lessons flag enabled, then launch the Flutter web client:

Shell 1: `ALLOW_DEV_CORS=1 LESSONS_ENABLED=1 PYTHONPATH=backend uvicorn app.main:app --reload`; Shell 2: `cd client/flutter_reader && flutter pub get && flutter run -d chrome --web-renderer html`

```bash
ALLOW_DEV_CORS=1 LESSONS_ENABLED=1 PYTHONPATH=backend uvicorn app.main:app --reload
cd client/flutter_reader && flutter pub get && flutter run -d chrome --web-renderer html
```

Set `LESSONS_ENABLED=1` alongside `ALLOW_DEV_CORS=1` so the web build can reach the API during development.

This returns a compact JSON lesson containing alphabet, match, cloze (with `ref`), and translate tasks.

### Optional slice ingest

Run `bash scripts/dev/ingest_slice.sh` or `pwsh -File scripts/dev/ingest_slice.ps1` to load the Iliad sample slice before demoing.
## Notes

- The static bundle is only served when `SERVE_FLUTTER_WEB=1`. The demo scripts set this along with `ALLOW_DEV_CORS=1` for local clients.
- When building Flutter web manually, run `flutter build web --pwa-strategy none --base-href /app/` so assets resolve under the `/app/` mount without shipping stale PWA assets.
- Re-run `flutter build web` whenever the Flutter client changes.
- Stop Uvicorn with `Ctrl+C` and run `docker compose down` if you no longer need the database.
- The BYOK-backed coach endpoint stays off by default (`COACH_ENABLED=false`). Enable it manually if you want to demo `/coach/chat`; see `docs/COACH.md` for details.





## TTS v0 (flag)

Enable with `TTS_ENABLED=1` before launching the backend. The smoke scripts
`scripts/dev/smoke_tts.ps1` and `scripts/dev/smoke_tts.sh` spin up the API,
issue `POST /tts/speak` with the echo provider, and save `artifacts/tts_echo.wav`
for quick verification. See [`docs/TTS.md`](TTS.md) for feature flags, BYOK providers, and troubleshooting.

Sample curl (server must be running with the flag):

```bash
curl -sS -X POST http://127.0.0.1:8000/tts/speak   -H 'Content-Type: application/json'   -d '{"text":"χαῖρε κόσμε","provider":"echo"}' | jq '.meta'
```
