# Quick Start: User Authentication

**Status:** ⚠️ Core logic tested, full integration not verified

This guide helps you set up and verify the authentication system step by step.

---

## Step 1: Verify Core Logic Works (No Database Needed)

Test the authentication cryptography without any setup:

```bash
cd backend
pytest app/tests/test_auth_simple.py -v
```

**Expected output:**
```
test_auth_simple.py::TestPasswordHashing::test_hash_password_creates_different_hashes PASSED
test_auth_simple.py::TestPasswordHashing::test_verify_password_correct PASSED
test_auth_simple.py::TestPasswordHashing::test_verify_password_incorrect PASSED
test_auth_simple.py::TestPasswordHashing::test_verify_password_case_sensitive PASSED
test_auth_simple.py::TestJWTTokens::test_create_access_token PASSED
test_auth_simple.py::TestJWTTokens::test_create_refresh_token PASSED
... (23 more tests)

========================== 27 passed in 1.5s ==========================
```

✅ If all 27 tests pass, the core authentication logic works.

---

## Step 2: Install Dependencies

```bash
# From project root
pip install -e ".[dev]"
```

**What this installs:**
- `python-jose[cryptography]` - JWT tokens
- `passlib[bcrypt]` - Password hashing
- `cryptography` - API key encryption
- `pytest`, `pytest-asyncio`, `httpx` - Testing

---

## Step 3: Generate Secrets

### JWT Secret (Required)

```bash
python -c "import secrets; print(secrets.token_urlsafe(32))"
```

**Copy the output**, it will look like: `xK7vN2pQ9mR8sT1uW3vX5yZ6a0B1c2D3e4F5g6H7i8J9`

### Encryption Key (Required for BYOK)

```bash
python -c "from cryptography.fernet import Fernet; print(Fernet.generate_key().decode())"
```

**Copy the output**, it will look like: `vL8wN9xO0yP1zQ2aR3bS4cT5dU6eV7fW8gX9hY0iZ1j=`

---

## Step 4: Configure Environment

Edit `backend/.env` (create if doesn't exist):

```env
# Database (update with your credentials)
DATABASE_URL=postgresql+asyncpg://postgres:your_password@localhost:5432/ancient_languages
REDIS_URL=redis://localhost:6379/0

# JWT Secret (REQUIRED - paste from Step 3)
JWT_SECRET_KEY=<paste-your-generated-secret-from-step-3>

# Encryption Key (REQUIRED - paste from Step 3)
ENCRYPTION_KEY=<paste-your-generated-key-from-step-3>

# Optional: Your API keys (server-side fallback)
OPENAI_API_KEY=sk-proj-your-key-here
ANTHROPIC_API_KEY=sk-ant-your-key-here
GOOGLE_API_KEY=your-google-key-here

# Feature flags
LESSONS_ENABLED=true
BYOK_ENABLED=true
ALLOW_DEV_CORS=true
```

**⚠️ Security Warning:** Never commit `.env` file to git. It's already in `.gitignore`.

---

## Step 5: Run Database Migration

```bash
cd backend
alembic upgrade head
```

**Expected output:**
```
INFO  [alembic.runtime.migration] Running upgrade -> 5f7e8d9c0a1b, add_user_authentication_and_gamification_tables
```

**What this creates:**
- 11 user-related tables (user, user_profile, user_progress, etc.)
- Indexes for performance
- Foreign key constraints

**If you get an error:**
- Check DATABASE_URL is correct
- Ensure PostgreSQL is running
- Verify database exists: `psql -c "CREATE DATABASE ancient_languages;"`

---

## Step 6: Start the Server

```bash
cd backend
uvicorn app.main:app --reload
```

**Expected output:**
```
INFO:     Uvicorn running on http://127.0.0.1:8000 (Press CTRL+C to quit)
INFO:     Started reloader process [12345] using StatReload
INFO:     Started server process [12346]
INFO:     Waiting for application startup.
INFO:     Application startup complete.
```

---

## Step 7: Test with API Docs

Open browser: **http://localhost:8000/docs**

You should see Swagger UI with these new endpoint groups:
- **Authentication** (4 endpoints)
- **Users** (5 endpoints)
- **Progress** (5 endpoints)
- **API Keys** (4 endpoints)

---

## Step 8: Manual Test - Register User

In Swagger UI:

1. Find `POST /api/v1/auth/register`
2. Click "Try it out"
3. Enter:
   ```json
   {
     "username": "testuser",
     "email": "test@example.com",
     "password": "TestPassword123"
   }
   ```
4. Click "Execute"

**Expected response (201 Created):**
```json
{
  "id": 1,
  "username": "testuser",
  "email": "test@example.com",
  "is_active": true,
  "created_at": "2025-10-05T12:34:56.789Z",
  "real_name": null,
  "discord_username": null
}
```

✅ User created successfully!

---

## Step 9: Manual Test - Login

1. Find `POST /api/v1/auth/login`
2. Click "Try it out"
3. Enter:
   ```json
   {
     "username_or_email": "testuser",
     "password": "TestPassword123"
   }
   ```
4. Click "Execute"

**Expected response (200 OK):**
```json
{
  "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "refresh_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "token_type": "bearer"
}
```

**Copy the `access_token`** (long string starting with `eyJ...`)

---

## Step 10: Manual Test - Access Protected Endpoint

1. Click the "Authorize" button at the top of Swagger UI
2. Enter: `Bearer <your-access-token>`
   - Example: `Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...`
3. Click "Authorize"
4. Find `GET /api/v1/users/me`
5. Click "Try it out" → "Execute"

**Expected response (200 OK):**
```json
{
  "id": 1,
  "username": "testuser",
  "email": "test@example.com",
  "is_active": true,
  "created_at": "2025-10-05T12:34:56.789Z",
  "real_name": null,
  "discord_username": null
}
```

✅ Authentication working end-to-end!

---

## Step 11: Manual Test - Update Progress

1. Find `POST /api/v1/progress/me/update`
2. Click "Try it out"
3. Enter:
   ```json
   {
     "xp_gained": 50,
     "lesson_id": "test-lesson-1",
     "time_spent_minutes": 15
   }
   ```
4. Click "Execute"

**Expected response (200 OK):**
```json
{
  "xp_total": 50,
  "level": 0,
  "streak_days": 1,
  "max_streak": 1,
  "total_lessons": 1,
  "total_exercises": 0,
  "total_time_minutes": 15,
  "last_lesson_at": "2025-10-05T12:45:00.000Z",
  "xp_for_current_level": 0,
  "xp_for_next_level": 100,
  "xp_to_next_level": 50,
  "progress_to_next_level": 0.5
}
```

✅ Progress tracking working!

---

## Step 12: Manual Test - Store Encrypted API Key

1. Find `POST /api/v1/api-keys/`
2. Click "Try it out"
3. Enter:
   ```json
   {
     "provider": "openai",
     "api_key": "sk-test-fake-key-for-testing"
   }
   ```
4. Click "Execute"

**Expected response (201 Created):**
```json
{
  "provider": "openai",
  "configured": true,
  "created_at": "2025-10-05T12:50:00.000Z",
  "updated_at": "2025-10-05T12:50:00.000Z"
}
```

**Verify encryption:**

1. Find `GET /api/v1/api-keys/openai/test`
2. Click "Try it out" → "Execute"

**Expected response:**
```json
{
  "provider": "openai",
  "configured": true,
  "masked_key": "sk-test-...ting",
  "length": 28
}
```

✅ API key encrypted and stored!

---

## Troubleshooting

### Error: "Could not validate credentials"
- Check you copied the full access_token
- Ensure you included "Bearer " prefix in Authorize dialog
- Token might be expired (7 days for access, 30 for refresh)

### Error: "CHANGE_ME_IN_PRODUCTION_USE_RANDOM_STRING"
- You forgot to set JWT_SECRET_KEY in .env
- Go back to Step 3 and generate a secret

### Error: "Connection refused" when starting server
- DATABASE_URL is wrong
- PostgreSQL not running: `sudo service postgresql start`
- Database doesn't exist: `createdb ancient_languages`

### Error: "No such table: user"
- You skipped Step 5 (migration)
- Run: `cd backend && alembic upgrade head`

### Error: "ImportError: cannot import name 'User'"
- Dependencies not installed
- Run: `pip install -e ".[dev]"`

### Tests fail with "ModuleNotFoundError"
- Not in backend directory
- Run: `cd backend` first

---

## What to Do Next

### Test More Endpoints

- `GET /api/v1/progress/me` - View your progress
- `PATCH /api/v1/users/me` - Update profile (real_name, discord_username)
- `GET /api/v1/api-keys/` - List all configured API keys
- `POST /api/v1/auth/refresh` - Get new access token

### Integrate with Flutter

See `client/flutter_reader/lib/services/auth_service.dart` for example Flutter integration.

### Add More Features

- Email verification flow
- Password reset
- Rate limiting
- Token blacklisting (logout)
- MFA/2FA

---

## Success Criteria

You've successfully set up authentication if:

✅ Simple tests pass (27/27)
✅ Server starts without errors
✅ Can register new user
✅ Can login and get tokens
✅ Can access protected endpoints with token
✅ Progress updates and persists
✅ API keys encrypt properly

---

## Getting Help

**If something doesn't work:**

1. Check the logs in terminal where `uvicorn` is running
2. Look for error details in Swagger UI responses
3. Verify `.env` file has all required settings
4. Read the detailed guides:
   - [USER_AUTHENTICATION.md](USER_AUTHENTICATION.md) - Full documentation
   - [FINAL_HONEST_ASSESSMENT.md](FINAL_HONEST_ASSESSMENT.md) - What works/doesn't

**Common issues:**
- Missing dependencies → `pip install -e ".[dev]"`
- Wrong DATABASE_URL → Check PostgreSQL connection
- Missing secrets → Generate JWT_SECRET_KEY and ENCRYPTION_KEY
- Migration not run → `alembic upgrade head`

---

**Last updated:** 2025-10-05
**Status:** Tested core logic ✅ | Need DB verification ⚠️
