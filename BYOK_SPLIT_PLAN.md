# BYOK Branch Split Plan

Source branch: `feat/flutter-reader-byok`

Key commits ahead of `main` (from `git log --oneline --left-right --cherry main...feat/flutter-reader-byok`):

- `d23669d` — CI port alignment for DB integration tests
- `6054d0a` — Request-scoped bring-your-own-key (BYOK) configuration changes in FastAPI
- `7bef4d3` — Flutter reader client addition (web/mobile scaffolding)
- `89d135b` — Normalize accent folding to lowercase NFC

Diffstat overview (`git diff --stat main...feat/flutter-reader-byok`): 149 files changed, 6421 insertions, 8 deletions. The bulk is the Flutter client tree (`client/flutter_reader/**`).

## Proposed salvage path

1. **PR-D-srv – Server BYOK prep**
   - Scope: pull `backend/app/core/config.py`, `backend/app/main.py`, normalization tweak in `backend/app/ingestion/normalize.py`, CI port update (`.github/workflows/ci.yml`), and any config/docs needed to document request-scoped BYOK headers.
   - Checklist:
     - Ensure BYOK remains request-scoped (no persistence/logging).
     - Add unit test or integration stub covering BYOK header propagation.
     - Update docs (README or new doclet) describing BYOK usage.
     - Confirm existing accuracy/bench workflows still pass.
   - Recommendation: **Open PR** (low-risk, matches current architecture).

2. **PR-E-ui – Flutter reader revival (optional)**
   - Scope: resurrect `client/flutter_reader/**`, CI hooks (`.github/workflows/flutter-analyze.yml`), supporting files under `.gitignore`, `.vscode/tasks.json`, README entries, and Flutter-specific assets.
   - Preconditions:
     - Align API client (`lib/api/reader_api.dart`) with current `/reader/analyze` contract and BYOK semantics.
     - Ensure web bundle still mounts under `/app/` when `SERVE_FLUTTER_WEB=1`.
     - Add minimal smoke test (e.g., `flutter test` golden or API roundtrip) and document dev setup.
   - Recommendation: **Open PR only if product wants Flutter client active**; otherwise archive assets and **prune branch after PR-D-srv merges**.

3. **Prune** (if Flutter client not revived)
   - After landing PR-D-srv (and optionally archiving client assets elsewhere), delete `feat/flutter-reader-byok` to avoid drift.

## Next steps

- Branch from latest `main`, cherry-pick commits `d23669d`, `6054d0a`, `89d135b` (adjusting for conflicts) into PR-D-srv.
- Evaluate Flutter client viability with design; if deferred, stash artifacts outside repo and prune.
- Document BYOK header usage alongside accuracy/bench docs for coherence.
