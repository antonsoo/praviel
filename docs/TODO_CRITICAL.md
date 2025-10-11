# Critical TODOs

**Last updated:** 2025-10-11

## 1. Run and verify the end-to-end lesson experience
- Launch the backend with `uvicorn app.main:app --reload` and the Flutter client with `flutter run`.
- Play through at least one full Ancient Greek lesson that exercises all 18 task types (alphabet, match, cloze, translate, grammar, listening, speaking, word bank, true/false, multiple choice, dialogue, conjugation, declension, synonym, context match, reorder, dictation, etymology).
- Confirm drag-and-drop reorder, dialogue chat bubbles, conjugation/declension chips, and dictation audio all render without runtime errors.
- Record and fix any crashes, layout issues, or missing assets uncovered during the run.

## 2. Ship a minimal Classical Latin content pipeline (also make sure that Classic Greek has the 5 minimum texts that I promise in README doc)
- Ingest Latin corpora (Aeneid, Metamorphoses, Gallic War, etc.) into `data/latin/` with clear licensing notes.
- Produce a starter Latin lexicon (subset of Lewis & Short) plus morphology rules so the lesson generator can surface accurate lemmas, paradigms, and audio prompts.
- Implement or extend a lesson provider so every one of the 18 exercise types can render Latin content end-to-end.
- Add regression coverage (unit + integration smoke tests) that exercises at least one Latin lesson to prevent regressions.

## 3. Expand Greek content depth before onboarding more languages
- Grow the handcrafted seed pools: dialogues (target 30+), etymology questions (40+), context match and reorder sentences (30+ each).
- Extend conjugation templates beyond present tense (add aorist, future, imperfect, perfect) and include missing declension cases (vocative, dual where relevant).
- Add automated data validation so newly added items fail fast if required fields are missing or malformed.
- Once Greek coverage is robust, prioritize Old Egyptian and Vedic Sanskrit only after Latin reaches parity.
