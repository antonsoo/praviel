# Manual Test Scripts

These are quick manual testing scripts for verifying OpenAI API integration during development.

## Scripts

### Shell Scripts (require API key in script)

- **test_openai_final.sh** - Basic chat test with Spartan Warrior persona
- **test_flutter_format.sh** - Test exact Flutter app request format
- **test_lesson_openai.sh** - Test lesson generation endpoint

**Usage:**
```bash
# Edit script to add your API key
nano test_openai_final.sh

# Run test
./test_openai_final.sh
```

### Python Scripts (for debugging)

- **test_chat_endpoint.py** - Detailed chat endpoint testing
- **test_all_openai_endpoints.py** - Test all OpenAI endpoints
- **test_payload_inspection.py** - Inspect API payload structure

**Usage:**
```bash
# Requires server running on port 8000
python tests/manual/test_chat_endpoint.py
```

## Automated Tests

For automated testing, see the main test suite:
```bash
pytest tests/
```

## Validation Scripts

For API validation (pre-commit checks):
```bash
python scripts/validate_no_model_downgrades.py
python scripts/validate_api_payload_structure.py
python scripts/validate_api_versions.py  # Requires API key
```
