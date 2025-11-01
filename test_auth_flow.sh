#!/usr/bin/env bash
# Test complete auth flow including progress endpoint

API="https://api.praviel.com"

echo "=== Testing Complete Auth Flow ==="
echo

# 1. Register a new user
echo "1. Registering new test user..."
REGISTER_RESPONSE=$(curl -s -X POST "$API/api/v1/auth/register" \
  -H "Content-Type: application/json" \
  -d '{"username":"test_auth_flow","email":"test_auth_flow@example.com","password":"TestPassword123@"}')

echo "$REGISTER_RESPONSE" | python -m json.tool
echo

# 2. Login
echo "2. Logging in..."
LOGIN_RESPONSE=$(curl -s -X POST "$API/api/v1/auth/login" \
  -H "Content-Type: application/json" \
  -d '{"username_or_email":"test_auth_flow","password":"TestPassword123@"}')

echo "$LOGIN_RESPONSE" | python -m json.tool
TOKEN=$(echo "$LOGIN_RESPONSE" | python -c "import sys, json; print(json.load(sys.stdin)['access_token'])" 2>/dev/null)
echo

if [ -z "$TOKEN" ]; then
  echo "❌ Failed to get access token"
  exit 1
fi

echo "✅ Got access token"
echo

# 3. Test /api/v1/users/me
echo "3. Testing /api/v1/users/me..."
curl -s "$API/api/v1/users/me" \
  -H "Authorization: Bearer $TOKEN" | python -m json.tool
echo

# 4. Test /api/v1/progress/me
echo "4. Testing /api/v1/progress/me..."
PROGRESS_RESPONSE=$(curl -s "$API/api/v1/progress/me" \
  -H "Authorization: Bearer $TOKEN")
echo "$PROGRESS_RESPONSE" | python -m json.tool
echo

# 5. Check HTTP status
echo "5. Checking HTTP status code..."
STATUS=$(curl -s -o /dev/null -w "%{http_code}" "$API/api/v1/progress/me" \
  -H "Authorization: Bearer $TOKEN")
echo "Status: $STATUS"
echo

if [ "$STATUS" = "200" ]; then
  echo "✅ Progress endpoint working!"
else
  echo "❌ Progress endpoint returned $STATUS"
fi
