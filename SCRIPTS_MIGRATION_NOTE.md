# Scripts Migration Note

## Status: Migrated to Linux/Bash

This project has been fully migrated to Linux (Ubuntu WSL2) and now uses bash scripts exclusively.

## PowerShell Scripts (.ps1)

All PowerShell scripts in this repository are **LEGACY** and should **NOT** be used. They are kept temporarily for reference only and may be removed in the future.

**DO NOT USE:**
- `scripts/**/*.ps1`
- `client/flutter_reader/**/*.ps1`
- `backend/scripts/**/*.ps1`
- `tools/**/*.ps1`

## Bash Scripts (.sh)

All active development uses bash scripts. Key scripts:

**Development:**
- `scripts/dev/orchestrate.sh` - Main orchestrator (up, smoke, e2e-web, down)
- `scripts/dev/analyze_flutter.sh` - Flutter analysis
- `scripts/dev/smoke_lessons.sh` - Smoke test lessons
- `scripts/dev/smoke_tts.sh` - Smoke test TTS
- `scripts/dev/serve_uvicorn.sh` - Start backend server

**Data:**
- `scripts/fetch_data.sh` - Fetch third-party corpora

**Testing:**
- Bash equivalents exist for all critical functionality

## Environment

- **Python:** 3.13.x via `praviel-env` venv
- **Activation:** `source praviel-env/bin/activate`
- **Package Manager:** uv or pixi (prefer over pip)
- **Platform:** Linux Ubuntu WSL2 with Bash

## If You Need a Script

1. Check if bash equivalent exists in same directory
2. All documentation now references bash scripts only
3. See `AGENTS.md` or `CLAUDE.md` for current command reference

---

*This note can be deleted after all PowerShell scripts are removed from the repository.*
