# CRITICAL TODOs — October 2025 Snapshot

**Last Updated:** October 15, 2025 (Codex cleanup)
**Scope:** Highest-risk gaps blocking the multi-language roadmap.

---

## 🚨 Highest Priority (Blockers)
1. **Scale multilingual content** — Expand each target language to ≥500 core vocabulary items, 20+ dialogues, narrative passages, and full conjugation/declension tables. Focus on Classical Greek, Latin, Proto-Hebrew, Vedic Sanskrit, and seed datasets for Old Egyptian & Pali.
   _Sources:_ `backend/app/lesson/seed/*.yaml`, curated text corpora, morphological datasets.
2. **Validate live AI providers** — Run `scripts/validate_api_versions.py` with real BYOK credentials (OpenAI GPT-5 Responses API, Claude 4.5/4.1, Gemini 2.5) and fix any schema drift. Ensure JSON payloads match the expectations in `backend/app/lesson/providers/*.py` and regression tests in `backend/app/tests/test_lessons.py`.
3. **Stand up new language pipelines** — Prepare morphology resources, prompts, and evaluation fixtures for Classical Latin, Old Egyptian, and Pali so they can move from “planned” to “in development” in Q4. Coordinate with `BIG-PICTURE_PROJECT_PLAN.md` milestones.
4. **Unblock automated testing** — `pytest -q` currently crashes with `ValueError: I/O operation on closed file` during capture teardown. Restore a clean test run path so CI can operate again.

---

## 🔥 High Priority
- **Lesson quality & progression** — Implement difficulty tiers, spaced-repetition scheduling, and contextual exercise grouping across providers (`backend/app/lesson/providers/echo.py`, `backend/app/lesson/router.py`, Flutter exercise widgets).
- **UI/UX polish** — Add loading states, celebratory feedback, and user-friendly error handling in the Flutter client (see notes in `client/flutter_reader/lib/widgets/**`). Align with the roadmap in `docs/FUTURE_FEATURES.md`.
- **Audio & speech parity** — Verify TTS playback end-to-end, add microphone capture for speaking drills, and surface pronunciation scoring (`client/flutter_reader/lib/widgets/exercises/*`, backend audio endpoints).
- **Flutter desktop build fix** — Resolve the `flutter_secure_storage_windows` symlink issue documented in `client/flutter_reader/FLUTTER_GUIDE.md` so Windows builds work without manual workarounds.

---

## ⚙️ Medium Priority
- **Performance & caching** — Cache lesson generations, reuse vector search results, and index hot database tables to keep latency acceptable as content scales (`backend/app/lesson/router.py`, `backend/app/db/models.py`, client caching layer).
- **Telemetry & analytics** — Extend progress tracking to cover time-on-task, per-language metrics, and lesson conversion funnels once content depth improves.
- **Developer tooling** — Add CI steps for gitleaks/ruff/pytest once the harness is stable, and document BYOK test budgeting in `docs/AI_AGENT_GUIDELINES.md` addenda if limits change.

---

## ✔️ Stay Focused
- ✅ Prioritise code, content, and testable improvements over new status reports or meta-documents.
- ✅ Do not downgrade October 2025 API implementations (`docs/AI_AGENT_GUIDELINES.md` governs changes).
- ✅ Keep `docs/archive/` for temporary clutter only; remove items before committing.

Need deeper context? Start with `BIG-PICTURE_PROJECT_PLAN.md` and `docs/FUTURE_FEATURES.md`, then sync with the README roadmap.
