# Sprint 3: Backend Integration & Infrastructure

## Overview

Sprint 2 completed all **user-facing MVP features**:
- ✅ Text-range picker UI (fully functional)
- ✅ Register toggle UI (fully functional)
- ✅ API parameter wiring (complete end-to-end)
- ✅ Auto-generate lessons (working)
- ✅ Chatbot UI (working)
- ✅ Progress tracking (working)
- ✅ History page (working)
- ✅ Settings page (working)
- ✅ Dark mode (working)

Sprint 3 focuses on **backend processing** and **infrastructure fixes**.

---

## Priority 1: Text-Range Backend Processing

### Current State
- **UI:** Complete ✅
- **API:** Parameters wired correctly ✅
- **Backend:** Accepts `text_range` parameter but returns error:
  ```json
  {"detail":"Failed to fetch canonical lines"}
  ```

### Task 1.1: Populate Canonical Text Database
**Estimate:** 4-6 hours

**Requirements:**
1. Download Perseus canonical texts for Iliad
2. Create database schema for canonical text storage
3. Implement text reference parsing (e.g., "Il.1.20" → Book 1, Line 20)
4. Load texts into PostgreSQL
5. Add indexing for fast ref_start/ref_end queries

**Files to modify:**
- `backend/app/canonical/` (new module)
- `backend/app/lesson/providers/canon.py`
- `backend/alembic/versions/` (new migration)

**Test criteria:**
```bash
curl -X POST http://localhost:8000/lesson/generate \
  -d '{"text_range":{"ref_start":"Il.1.20","ref_end":"Il.1.50"},...}'
# Should return: {"tasks":[...]} with vocabulary from lines 20-50
```

### Task 1.2: Vocabulary Extraction from Text Ranges
**Estimate:** 2-3 hours

**Requirements:**
1. Parse Greek text from specified range
2. Extract unique lemmas using CLTK
3. Filter by frequency (focus on high-value words)
4. Generate exercises from extracted vocabulary

**Files to modify:**
- `backend/app/lesson/providers/canon.py`
- `backend/app/lesson/service.py`

---

## Priority 2: Register Mode Backend Effects

### Current State
- **UI:** Complete ✅
- **API:** Parameter sent correctly ✅
- **Backend:** Accepts `register` parameter but doesn't affect output

### Task 2.1: Update Pedagogical Prompts
**Estimate:** 3-4 hours

**Requirements:**
1. Create prompt variants for literary vs. colloquial
2. Update echo provider with register-specific word lists
3. Update OpenAI/Anthropic prompts to specify register
4. Add colloquial Greek phrases to daily drills

**Files to modify:**
- `backend/app/lesson/providers/echo.py`
- `backend/app/lesson/providers/openai.py`
- `backend/app/lesson/providers/anthropic.py`
- `backend/data/prompts/` (new directory)

**Examples:**
- **Literary:** χαῖρε (formal greeting), εὖ ἔχω (I am well)
- **Colloquial:** ἀληθῶς; (really?), εἰμὶ οἴκοι (I'm home)

**Test criteria:**
```bash
# Literary should return formal vocabulary
curl -X POST http://localhost:8000/lesson/generate \
  -d '{"register":"literary",...}'

# Colloquial should return everyday phrases
curl -X POST http://localhost:8000/lesson/generate \
  -d '{"register":"colloquial",...}'
```

---

## Priority 3: UI Enhancements

### Task 3.1: Persist Register Preference
**Estimate:** 1 hour

**Requirements:**
1. Save register selection to FlutterSecureStorage
2. Load preference on app start
3. Apply to lessons_page.dart initial state

**Files to modify:**
- `client/flutter_reader/lib/pages/lessons_page.dart`

**Test criteria:**
- User selects "Everyday" → restarts app → still shows "Everyday"

### Task 3.2: Text-Range Error Handling Improvement
**Estimate:** 1 hour

**Requirements:**
1. Show user-friendly message when canonical text unavailable
2. Suggest using daily lessons as alternative
3. Add "Coming Soon" badge to unavailable ranges

**Files to modify:**
- `client/flutter_reader/lib/pages/text_range_picker_page.dart`

---

## Priority 4: Infrastructure Fixes

### Task 4.1: Fix Pre-Commit Hooks on Windows
**Estimate:** 2-3 hours

**Current issue:**
```
ExecutableNotFoundError: Executable `/bin/sh` not found
```

**Requirements:**
1. Update `.pre-commit-config.yaml` to use Windows-compatible shells
2. Test pre-commit hooks on both Linux and Windows
3. Update CI to verify pre-commit hooks work

**Files to modify:**
- `.pre-commit-config.yaml`
- `scripts/hooks/` (ensure Python scripts work on Windows)

### Task 4.2: Fix CI Orchestrator
**Estimate:** 3-4 hours

**Current issue:**
- Orchestrator up step fails on GitHub Actions
- Likely Docker/PostgreSQL connection issues

**Requirements:**
1. Debug orchestrator failure logs
2. Fix Docker Compose configuration for CI
3. Add retry logic for database connection
4. Verify both Linux and Windows CI jobs pass

**Files to modify:**
- `.github/workflows/ci.yml`
- `scripts/dev/orchestrate.sh` / `orchestrate.ps1`
- `docker-compose.yml`

### Task 4.3: Fix Pydantic Warning
**Estimate:** 30 minutes

**Current warning:**
```
Field name "register" in "LessonGenerateRequest" shadows an attribute in parent "BaseModel"
```

**Requirements:**
1. Rename `register` field to `register_mode` or use `Field(alias="register")`
2. Update all references in backend code
3. Verify API still accepts `register` parameter

**Files to modify:**
- `backend/app/lesson/models.py`
- `backend/app/lesson/service.py`

---

## Priority 5: Testing & Documentation

### Task 5.1: Add Integration Tests for Text-Range
**Estimate:** 2 hours

**Requirements:**
1. Create test fixtures for canonical texts
2. Test text-range parsing (ref_start → ref_end)
3. Test vocabulary extraction
4. Test lesson generation from text ranges

**Files to create:**
- `backend/app/tests/test_text_range.py`
- `backend/app/tests/fixtures/canonical.py`

### Task 5.2: Add Integration Tests for Register Mode
**Estimate:** 1 hour

**Requirements:**
1. Test literary vs. colloquial prompt generation
2. Verify output differences between modes
3. Test register mode with different providers

**Files to modify:**
- `backend/app/tests/test_lessons.py`

### Task 5.3: Update Documentation
**Estimate:** 1 hour

**Requirements:**
1. Update README with text-range feature
2. Update API docs with register parameter
3. Add user guide for text-range picker
4. Document register mode behavior

**Files to modify:**
- `README.md`
- `docs/API.md`
- `docs/USER_GUIDE.md`

---

## Total Estimates

| Priority | Task | Hours |
|----------|------|-------|
| P1 | Text-range backend | 6-9 |
| P2 | Register mode | 3-4 |
| P3 | UI enhancements | 2 |
| P4 | Infrastructure | 6-8 |
| P5 | Testing & docs | 4 |
| **Total** | | **21-27 hours** |

---

## Success Criteria for Sprint 3

All criteria must be met before Sprint 3 is complete:

### Backend Processing
- [ ] Text-range picker returns lessons from specified Iliad passages
- [ ] Register mode produces different vocabulary/phrases for literary vs. colloquial
- [ ] Canonical text database populated with at least Iliad Book 1
- [ ] Vocabulary extraction working for custom text ranges

### Infrastructure
- [ ] CI passing on both Linux and Windows (no orchestrator failures)
- [ ] Pre-commit hooks working on Windows
- [ ] No Pydantic warnings in logs
- [ ] All orchestrator smoke tests passing on CI

### User Experience
- [ ] Register preference persists across app restarts
- [ ] Text-range errors show helpful messages
- [ ] All existing features still working (no regressions)

### Testing
- [ ] Integration tests for text-range extraction
- [ ] Integration tests for register mode
- [ ] E2E tests cover new flows
- [ ] Test coverage ≥80% for new code

---

## Out of Scope for Sprint 3

These features are deferred to later sprints:

- Additional canonical texts (Odyssey, tragedies, etc.)
- Advanced text-range features (custom ranges, bookmarks)
- Multi-language support beyond Greek
- Advanced register modes (archaic, koine, modern)
- Audio generation for custom text ranges
- User-created text ranges
- Social features (sharing ranges, collaborative learning)

---

## Notes

### Sprint 2 Achievements
- Delivered 3 commits, 443 lines of code
- Flutter Analyze: 0 issues ✅
- All smoke tests passing ✅
- Professional UI with design system ✅
- Zero breaking changes ✅

### Technical Debt Created
- Text-range backend stub (Priority 1 to complete)
- Register mode stub (Priority 2 to complete)
- Pre-commit hook workarounds (Priority 4.1 to fix)
- CI orchestrator workarounds (Priority 4.2 to fix)

### Dependencies
- Perseus canonical text source
- CLTK Greek lemmatizer (already installed)
- PostgreSQL text search indexes
- Docker Compose fixes for CI

---

**Sprint 3 Start:** After Sprint 2 merge approved
**Estimated Duration:** 3-4 weeks at 7-10 hours/week
**Target Completion:** Mid-October 2025
