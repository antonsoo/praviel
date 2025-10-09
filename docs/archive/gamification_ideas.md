Assumptions: MVP is Classical Greek with text-targeted lessons, LSJ/Smyth, register toggle, chat personas, BYOK; Flutter client + FastAPI/Postgres.

Radar charts (pick 1–2 now; add others later)

1. Reader Proficiency (per work/author)
   Axes: Lemma coverage% (weighted by token freq in selected text), Morph accuracy (F1 over case/tense/person/gender), Grammar topics mastery% (Smyth-mapped quiz accuracy), Comprehension% (cloze/translate), Diacritics accuracy% (accents/breathings), Reading fluency (wpm @ ≥90% comp).
   Compute: coverage = Σfreq(known_lemma)/Σfreq(all_lemmas); known if SRS P(recall) ≥ 0.9.

2. Morphosyntax Focus
   Axes: Noun cases, Verb tenses, Voices, Moods, Particles, Clause types.
   Compute: per-axis rolling accuracy (last 50 items), IRT/Rasch-weighted if available.

3. Vocabulary Acquisition
   Axes: Core lemma retention P(recall), Proper names P(recall), Formulae/epithets P(recall), Hapax handling (first-seen recall%), False-friends error rate↓, Semantic confusability↓.
   Compute: SRS model P(recall) by tag; confusability = errors among semantically close lemmas.

4. Engagement/Habits (separate chart; don’t mix with skill)
   Axes: Streak days, Daily active minutes, Reviews cleared/day, New items stabilized/week, Due backlog health↓, Session regularity (stddev of start time↓).

5. Persona/Conversation (chat mode)
   Axes: Turn length in target language, Register control (literary/colloquial), Error-free turns%, Repair success after hint, Topic breadth (domains hit), Latency to respond (p50).
   Compute from chat transcripts + rubric prompts.

Profile metrics to track (for gamification & coaching)

* XP, Level, Streak (already planned).
* Lemma coverage% per text/work/genre (Homeric vs Attic); top unknown lemmas list.
* Stable items (count with P(recall) ≥ threshold); learning velocity = Δstable/week.
* SRS load: due today, projected week load, backlog health score (capped).
* Morph topic mastery% (per Smyth section group); decay if no exposure for N days.
* Hintless-run length (max consecutive sentences read without hints).
* Diacritics accuracy% and common accent errors.
* Comprehension@speed: wpm at ≥90% comprehension.
* “Lines read” (canonical refs completed), “Smyth §§ collected,” “LSJ headwords unlocked.”
* Confusion pairs (e.g., εἶμι/εἰμί) error rate↓; surface similar lemma collisions.
* Session regularity (days/week ≥ target); time-of-day consistency.
* Quests: “Master genitive absolute,” “Scan 10 hexameter lines,” “Zero-hint Iliad 1.1–1.10.”
* Social: weekly ladder by lemma coverage gain, streak hall, “first to master X” ribbons.

Instrumentation (minimal, implementable now)

* Events: lesson_start/complete, exercise_result{topic, tags[], msd, correct, time_ms, hint_used}, reader_tap{token_id, lemma, msd}, chat_turn{chars, errors, hint_used, register}, srs_review{card_id, q(0–5), next_ivl_d, p_recall}.
* Entities: user_skill(topic_id, elo), user_srs(card_id, params, p_recall), user_text_stats(work_id, coverage, wpm, comp).
* Scoring:
  • P(recall): FSRS/SSP baseline; default SM-2 if offline.
  • Topic ability: simple Elo→0–100 per topic; dampen with recency.
  • Radar scaling: min–max clip per axis; show deltas vs last week.

UX hooks that drive “obsession”

* Per-text radar appears after each session; show +/- deltas and one “most valuable next step.”
* “Coach” nudge cards: “+8% coverage of Iliad 1 if you master these 12 lemmas.”
* Collections: Smyth-badge sets, epithet sets, meter sets; visible on profile.
* Anti-grind: cap daily XP from easy items; reward stable-item growth and hard-topic wins.

Notes to align with your stack

* Use your text-targeted lessons and register toggle to feed topic/genre axes; BYOK stays request-scoped.
* Store per-axis snapshots daily to render trend sparklines under each radar spoke.
