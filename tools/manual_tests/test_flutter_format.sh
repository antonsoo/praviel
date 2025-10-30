#!/bin/bash
# Test with exact Flutter app request format
# Requires: OPENAI_API_KEY environment variable or backend/.env file

# Load .env if available
if [ -f backend/.env ]; then
  export $(grep -v '^#' backend/.env | xargs)
fi

if [ -z "$OPENAI_API_KEY" ]; then
  echo "Error: OPENAI_API_KEY not set. Set it in backend/.env or export it."
  exit 1
fi

curl -X POST http://127.0.0.1:8000/chat/converse \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $OPENAI_API_KEY" \
  -d '{
    "message": "Hello warrior",
    "persona": "spartan_warrior",
    "provider": "openai",
    "context": []
  }' \
  --max-time 30
