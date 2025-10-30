# Manual Test Scripts

**Note:** PowerShell scripts (*.ps1) in this directory are **LEGACY** and should not be used. The project has migrated to Linux/Bash. Use the Python scripts directly instead.

Quick API validation scripts. Requires backend running on `localhost:8001`.

## Usage

```bash
# Start backend first
cd backend
uvicorn app.main:app --port 8001

# Run tests
python scripts/test/test_api.py              # Quick API smoke test
python scripts/test/test_comprehensive.py    # All bug fixes validation
python scripts/test/test_streak_freeze.py    # Streak shield feature
python scripts/test/test_weekly_challenges.py # Weekly challenges
python scripts/test/test_lesson_quality.py   # Lesson generation quality
```

## Notes

- These are **manual validation scripts**, not part of automated test suite
- Use `pytest backend/app/tests/` for automated tests
- Scripts create test users with timestamp-based names
