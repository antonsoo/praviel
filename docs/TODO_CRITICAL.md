# Critical TODOs – reality-driven checklist

**Last reviewed:** October 21, 2025 (Codex session)

---

## Reality Check

- `flutter test` now passes end-to-end (102 passing, 6 skipped) after repairing the reader page structure and adding language picker coverage.
- `flutter analyze` surfaces only existing informational lints (string interpolation hygiene); no remaining syntax errors.
- Prior claims of “0 warnings / 100% tests” were inflated—treat analyzer infos and doc gaps as follow-up work.
- Deployment, premium widget integration, and language QA remain unvalidated—treat them as outstanding work.

## Recently Verified

- Legacy onboarding screen now surfaces the full language catalog via the shared picker (`client/flutter_reader/lib/pages/onboarding_page.dart`), matching `docs/LANGUAGE_LIST.md` order and using `LanguagePickerSheet`.
- Settings and compact selectors already share the same bottom sheet (`client/flutter_reader/lib/widgets/language_picker_sheet.dart`), so language order is consistent across UI entry points.
- BYOK defaults align with October 2025 policy: lesson/chat/TTS providers default to OpenAI with `gpt-5` (`client/flutter_reader/lib/services/byok_controller.dart`).
- OpenAI vocabulary parsing now strips metadata IDs before JSON extraction and is covered by `tests/test_vocabulary_engine.py`; Responses API calls return valid JSON payloads.

## High-Priority Fixes

1. **Browser QA pass** – Run the app (onboarding → lessons → reader) and log any functional gaps not covered by tests.
2. **Deployment dry-run** – Produce a shareable web build (Netlify/Vercel/Cloudflare dev deploy) for investor demo.
3. **Validate vocabulary generation** – Exercise Anthropic and Gemini vocab flows (Echo already local) and extend extraction tests if their payloads diverge.

## Founder Bug Queue (from the latest manual QA)

Status legend: ✅ addressed in code (needs QA), 🔍 still requires investigation.

- ✅ **1.1 Onboarding language list** – now driven by shared catalog; manually verify the UX.
- 🔍 **1.2 Profile language selection UI** – sheet exists; confirm search, ordering, and persistence.
- 🔍 **1.3 App bar language dropdown** – ensure `compact_language_selector.dart` opens the same catalog everywhere.
- ✅ **2 BYOK defaults** – defaults point to OpenAI + GPT‑5; confirm onboarding BYOK modal honours them.
- 🔍 **3 Lesson history** – new store sorts newest-first; test for signed-in/guest behaviour.
- 🔍 **4 Sound palette** – custom assets live under `client/flutter_reader/assets/sounds`; review mix, UX, and licensing.
- 🔍 **5 Vocabulary generation pipeline** – reproduce across all providers and add regression coverage.
- 🔍 **6 Lesson retry rules** – align UI/XP rules with product decision (redo vs auto-advance).
- 🔍 **7 Alphabet / identify lessons** – redesign so the prompt cannot be answered by tapping the displayed glyph.
- 🔍 **8 Writing-rule enforcement** – confirm backend transforms plus frontend rendering respect `docs/LANGUAGE_WRITING_RULES.md`; add tests.
- 🔍 **9 Hint copy** – audit each exercise type for actionable, context-specific hints.
- 🔍 **10 Fun-fact pacing** – facts persist longer now; validate timing and dismissal experience.
- 🔍 **11 Reader fun facts coverage** – ensure curated facts exist for the top 10 languages with localized copy.
- 🔍 **12 Reader loading UX** – port the lesson loading carousel (facts/quotes) to reader generation.
- 🔍 **13 Reader catalog depth** – expand curated works (aim ≥10 per priority language) and improve selection UI (book → chapter/random).

## Next Actions

- Fix `reading_page.dart` and re-run analyzer/tests.
- QA the language selection flow end-to-end (onboarding → settings → app bar).
- Investigate the vocabulary generation error and tighten parsing + logging.
- Update this file after each verified fix; remove items only when confirmed via tests or manual QA.

## Reminders

- Before touching provider code, run `python scripts/validate_october_2025_apis.py` and `python scripts/validate_api_versions.py`.
- Keep GPT-5 calls on `/v1/responses` with `max_output_tokens`; do **not** regress to pre-October-2025 payloads.
