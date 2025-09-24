# Text-to-Speech v0

`POST /tts/speak` streams lesson lines into short audio clips. The endpoint is **disabled by default** and guarded by `TTS_ENABLED=1`.

## Enabling

Set the flag alongside the existing demo toggles:

```bash
export TTS_ENABLED=1 ALLOW_DEV_CORS=1 SERVE_FLUTTER_WEB=1
python -m uvicorn app.main:app --app-dir backend --reload
```

PowerShell:

```powershell
$env:TTS_ENABLED = '1'
$env:ALLOW_DEV_CORS = '1'
$env:SERVE_FLUTTER_WEB = '1'
python -m uvicorn app.main:app --app-dir backend --reload
```

## Request schema

```json
{
  "text": "χαῖρε κόσμε",
  "provider": "echo",
  "model": "gpt-4o-mini-tts",
  "voice": "alloy"
}
```

- `provider` — `echo` (offline, deterministic) or `openai` (BYOK via `Authorization: Bearer …`).
- `model` / `voice` — optional override; defaults are provider-specific.
- `format` — currently fixed to `wav`.

Response:

```json
{
  "audio": {
    "mime": "audio/wav",
    "b64": "…"
  },
  "meta": {
    "provider": "echo",
    "model": "echo:v0",
    "sample_rate": 22050
  }
}
```

Errors from BYOK providers fall back to the echo adapter so lesson playback keeps working even if OpenAI is unreachable.

## Smoke tests

- PowerShell: `pwsh -File scripts/dev/smoke_tts.ps1`
- Bash: `bash scripts/dev/smoke_tts.sh`

Both scripts spin up the API (with `TTS_ENABLED=1`), call `/tts/speak`, and save:

- `artifacts/tts_echo.json` — normalized JSON response
- `artifacts/tts_echo.wav` — decoded audio sample

## Notes

- Keys stay request-scoped. The server never persists BYOK credentials and request logs redact `Authorization` headers.
- Use the BYOK sheet in the Flutter client to pick lesson/TTS providers and optional model overrides; offline `echo` stays the default.
- `echo` outputs a ~0.6 s mono WAV at 22.05 kHz derived from the input text hash; it has no external dependencies.
- `openai` uses `POST https://api.openai.com/v1/audio/speech` with tight timeouts and downgrades to `echo` on error.
- `TTS_LICENSE_GUARD=1` blocks canonical segments with non-commercial or restricted licenses; daily YAML content continues to pass.
- On 403 responses the payload includes `reason`, `ref`, and the source license string so callers can surface a helpful message.
