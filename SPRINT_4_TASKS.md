# Sprint 4 Task List - Post-Integration Work

**Date**: 2025-10-01
**Previous Sprint**: Session 4 Integration Sprint (Complete)
**Status**: Ready for Sprint 4 Planning

---

## Sprint 3 Completion Status

### ✅ Completed in Session 4
1. ✅ Fixed text-range extraction (database + SQL + provider integration)
2. ✅ Verified register mode working (literary vs colloquial)
3. ✅ Removed "Coming Soon" badges from UI
4. ✅ Verified no regressions (8/8 tests passing)
5. ✅ Pushed integration to main

### ⏸️ Deferred (Infrastructure Issues)
1. ⏸️ CI orchestrator failures (pre-existing, not caused by Session 4)
2. ⏸️ Token table population (vocabulary shows phrases instead of lemmas)
3. ⏸️ Full Iliad ingestion (only lines 1-50 populated)

---

## Sprint 4 Objectives

**Theme**: Infrastructure Stability + Content Expansion

**Goals**:
1. Fix CI orchestrator to enable automated testing
2. Populate token table for lemmatized vocabulary
3. Expand canonical text coverage
4. Improve developer experience

---

## Critical Path Tasks (P0)

### 1. Fix CI Orchestrator - Linux
**Priority**: P0 (Blocking automated testing)
**Estimate**: 30 minutes

**Problem**: Permission denied on `scripts/dev/step.sh`
```
scripts/dev/orchestrate.sh: line 120: /home/runner/work/.../scripts/dev/step.sh: Permission denied
```

**Solution**:
```bash
# Set executable permission
git update-index --chmod=+x scripts/dev/step.sh
git update-index --chmod=+x scripts/dev/orchestrate.sh

# Verify
git ls-files --stage scripts/dev/step.sh
# Should show: 100755 (executable) not 100644 (regular)

# Commit
git commit -m "fix(ci): set executable permission on orchestrator scripts"
git push origin main
```

**Acceptance Criteria**:
- Linux CI job completes "Orchestrate up" step
- No permission errors in CI logs

---

### 2. Fix CI Orchestrator - Windows
**Priority**: P0 (Blocking automated testing)
**Estimate**: 1-2 hours

**Problem**: Database startup fails with exit code 18
```
step 'db_up' failed with exit code 18
```

**Investigation Steps**:
1. Check Docker logs in CI artifacts
2. Verify PostgreSQL port 5432 not in use
3. Check volume mount permissions
4. Review health check timeouts

**Possible Solutions**:
- Add retry logic for container startup
- Increase health check timeout
- Use different port if 5432 conflicts
- Add explicit volume cleanup before startup

**Acceptance Criteria**:
- Windows CI job completes "Orchestrate up" step
- Database container starts successfully
- Health checks pass

---

### 3. Verify CI Green After Fixes
**Priority**: P0 (Proof that CI works)
**Estimate**: 5 minutes (wait time)

**Tasks**:
1. Push orchestrator fixes
2. Monitor CI runs
3. Verify both Linux and Windows pass
4. Confirm smoke tests and e2e tests run

**Acceptance Criteria**:
- ✅ Linux job: All steps green
- ✅ Windows job: All steps green
- ✅ Smoke tests: Pass
- ✅ E2E web tests: Pass

---

## High Priority Tasks (P1)

### 4. Populate Token Table
**Priority**: P1 (Improves vocabulary quality)
**Estimate**: 2-3 hours

**Problem**: Vocabulary extraction returns 0 lemmatized words
**Cause**: Ingestion script populated `text_segment` but not `token`

**Solution**:
1. Review existing tokenization code
   - Check `backend/app/ingestion/jobs.py`
   - Verify tokenization logic exists but wasn't called

2. Run tokenization pass:
   ```python
   # Pseudo-code
   for segment in text_segments:
       tokens = tokenize(segment.text_nfc)
       for token in tokens:
           Token.create(
               segment_id=segment.id,
               idx=token.position,
               surface_nfc=token.surface,
               lemma=token.lemma,
               msd=token.morphology
           )
   ```

3. Verify extraction works:
   ```bash
   curl http://127.0.0.1:8000/lesson/generate \
     -d '{"text_range": {"ref_start": "1.20", "ref_end": "1.30"}, ...}'

   # Should return vocabulary items with lemmas
   # "grc": "παῖδα", "en": "παῖς (appears 2x)"
   ```

**Acceptance Criteria**:
- Token table has records for Iliad 1.1-1.50
- Text-range extraction returns lemmatized vocabulary
- Match tasks show "lemma (appears Nx)" instead of phrases

---

### 5. Ingest Full Iliad Book 1
**Priority**: P1 (Expands content coverage)
**Estimate**: 1 hour

**Current State**: Only lines 1-50 ingested
**Target**: Full Book 1 (lines 1-611)

**Tasks**:
1. Run ingestion script for full book:
   ```bash
   python scripts/ingest_iliad_sample.py --slice 1.1-1.611
   ```

2. Verify database:
   ```sql
   SELECT COUNT(*) FROM text_segment WHERE ref LIKE '1.%';
   -- Expected: 611
   ```

3. Test text-range picker with later ranges:
   - "Iliad 1.100-1.200 (Assembly)"
   - "Iliad Book 1 (Complete)"

**Acceptance Criteria**:
- Database has 611 segments for Book 1
- All predefined ranges in UI work
- No errors when selecting any range

---

## Medium Priority Tasks (P2)

### 6. Add More Canonical Texts
**Priority**: P2 (Content expansion)
**Estimate**: 3-4 hours per text

**Candidates**:
1. **Odyssey Book 1** (Similar to Iliad ingestion)
2. **Euripides - Medea** (Tragedy, different register)
3. **Plato - Apology** (Philosophical prose)
4. **New Testament - Gospel of John** (Koine Greek)

**Tasks per text**:
1. Acquire TEI XML file (Perseus Digital Library)
2. Create ingestion script (similar to `ingest_iliad_sample.py`)
3. Run ingestion
4. Add ranges to UI text-range picker
5. Test extraction

**Acceptance Criteria per text**:
- Text fully ingested in database
- Tokenization complete
- UI picker has 3-5 ranges defined
- Text-range lessons work

---

### 7. Improve Pre-Commit Hook Compatibility
**Priority**: P2 (Developer experience)
**Estimate**: 1 hour

**Problem**: Pre-commit hook requires `/bin/sh` on Windows

**Solutions**:
1. **Option A**: Make hook shell-agnostic
   - Detect OS and use appropriate shell
   - Use Python scripts instead of shell scripts

2. **Option B**: Document requirement
   - Update README: "Pre-commit hooks require Git Bash or WSL on Windows"
   - Add `--no-verify` instructions for Windows users

3. **Option C**: Disable hooks on Windows
   - Add `.pre-commit-config.yaml` with OS detection
   - Skip certain hooks on Windows

**Acceptance Criteria**:
- Pre-commit hook works on Windows OR
- Documentation clearly explains Windows workflow

---

### 8. Add Integration Tests for Text-Range
**Priority**: P2 (Test coverage)
**Estimate**: 2 hours

**Current State**: Manual curl testing only
**Target**: Automated integration tests

**Tasks**:
1. Create `test_text_range_integration.py`:
   ```python
   async def test_text_range_extracts_vocabulary():
       response = await client.post("/lesson/generate", json={
           "text_range": {"ref_start": "1.20", "ref_end": "1.30"},
           "exercise_types": ["match"],
           "provider": "echo"
       })
       assert response.status_code == 200
       pairs = response.json()["tasks"][0]["pairs"]
       # Verify pairs contain Greek from specified range
       assert any("from 1.20-1.30" in pair["en"] for pair in pairs)
   ```

2. Add tests for:
   - Empty range (no segments)
   - Invalid range (end < start)
   - Large range (100+ segments)
   - Register mode with text-range

**Acceptance Criteria**:
- Test file created with 5+ test cases
- All tests passing
- Tests run in CI orchestrator

---

### 9. Add Register Mode to Text-Range UI
**Priority**: P2 (UX improvement)
**Estimate**: 1 hour

**Current State**: Text-range picker doesn't show register toggle
**Target**: Allow users to combine text-range + register

**UI Change**:
```dart
// Add to text_range_picker_page.dart
Row(
  children: [
    Text("Register: "),
    SegmentedButton(
      segments: [
        ButtonSegment(value: "literary", label: Text("Literary")),
        ButtonSegment(value: "colloquial", label: Text("Everyday")),
      ],
      selected: {selectedRegister},
      onSelectionChanged: (Set<String> selection) {
        setState(() {
          selectedRegister = selection.first;
        });
      },
    ),
  ],
)
```

**Acceptance Criteria**:
- Register toggle visible on text-range picker page
- Selected register passed to lesson generation
- User can get colloquial lessons from Iliad text

---

## Low Priority Tasks (P3)

### 10. Performance Optimization for Large Ranges
**Priority**: P3 (Nice to have)
**Estimate**: 2-3 hours

**Problem**: Large text ranges (200+ segments) may be slow
**Solution**: Add pagination or sampling

**Investigation**:
1. Benchmark extraction with 50, 100, 200, 500 segments
2. Identify bottlenecks (DB query? tokenization? LLM?)
3. Implement optimization (pagination, caching, sampling)

---

### 11. Add Text-Range Preview
**Priority**: P3 (UX enhancement)
**Estimate**: 2 hours

**Feature**: Show first few lines of text when user hovers over range

**UI Change**:
- Tooltip on text-range card showing first 50 characters
- "Preview" button that opens modal with full text

---

### 12. Export Vocabulary List
**Priority**: P3 (Study tool)
**Estimate**: 2-3 hours

**Feature**: Allow users to export vocabulary from text range as CSV/PDF

**Implementation**:
- Add "Export Vocabulary" button to lesson page
- Generate CSV: lemma, frequency, forms, definition
- Optional: Generate printable PDF flashcards

---

## Dependencies & Blockers

### Unblocked (Can Start Now)
- ✅ Task 1: Fix Linux permissions
- ✅ Task 2: Fix Windows DB startup
- ✅ Task 5: Ingest full Iliad
- ✅ Task 7: Improve pre-commit hooks

### Blocked By Task 1+2 (CI Green)
- ⏸️ Task 3: Verify CI green
- ⏸️ Task 8: Integration tests (need CI to run)

### Blocked By Task 4 (Token Table)
- ⏸️ Task 6: Add more texts (tokenization pipeline needed)

---

## Success Metrics

### Sprint 4 Goals
1. **CI Green**: Both Linux and Windows orchestrator passing ✅
2. **Token Table**: Populated for all ingested text ✅
3. **Content Expansion**: At least 611 lines of Greek text available ✅
4. **Test Coverage**: Integration tests for text-range feature ✅

### Nice-to-Have
- 2+ canonical texts added
- Register mode in text-range picker
- Pre-commit hook Windows-compatible

---

## Estimated Timeline

**Week 1** (P0 Tasks):
- Day 1: Fix CI Linux permissions (Task 1)
- Day 2: Fix CI Windows DB startup (Task 2)
- Day 3: Verify CI green, celebrate (Task 3)

**Week 2** (P1 Tasks):
- Day 1-2: Populate token table (Task 4)
- Day 3: Ingest full Iliad Book 1 (Task 5)
- Day 4: Integration tests (Task 8)

**Week 3** (P2 Tasks):
- Day 1-2: Add Odyssey Book 1 (Task 6)
- Day 3: Register mode in text-range UI (Task 9)
- Day 4: Pre-commit hook fix (Task 7)

**Total Estimate**: 2-3 weeks for P0-P2 tasks

---

## Notes

### From Session 4 Learnings
1. **Always verify end-to-end**: Don't just build UI, test the full flow
2. **Database matters**: Check schema matches code expectations
3. **Local tests first**: Prove functionality before pushing to CI
4. **Document limitations**: Be explicit about what doesn't work yet

### From Frontisterion Feedback
1. **Working > Polished**: User wants functional features, not pretty broken UI
2. **Integration > Layers**: Complete vertical slices, not horizontal layers
3. **Prove it works**: Curl tests, screenshots, evidence of functionality

---

**Sprint 4 Owner**: TBD
**Previous Sprint Owner**: Prakteros-Gamma (Session 4)
**Status**: Ready for planning meeting
