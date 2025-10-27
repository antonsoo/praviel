# Railway Deployment Checklist

## Critical Pre-Deployment Steps

### 1. Required Services
Link these services in Railway dashboard:
- **PostgreSQL** (Railway will auto-set `DATABASE_URL`)
- **Redis** (Optional but recommended - Railway will auto-set `REDIS_URL`)

### 2. CRITICAL: Security Environment Variables

**The app will CRASH ON STARTUP if these are misconfigured!**

#### JWT_SECRET_KEY (REQUIRED for production)
```bash
# Generate a secure JWT secret:
python -c "import secrets; print(secrets.token_urlsafe(32))"

# Add to Railway environment variables:
# Variable: JWT_SECRET_KEY
# Value: <paste generated secret>
```

**FAILURE MODE**: If `ENVIRONMENT` is set to "production" (or anything except "dev", "development", "local") and `JWT_SECRET_KEY` is still the default value or not set, the app will fail startup validation with:
```
ValueError: JWT_SECRET_KEY must be set to a secure random value in production.
Generate one with: python -c 'import secrets; print(secrets.token_urlsafe(32))'
```

#### ENCRYPTION_KEY (Required if BYOK enabled)
```bash
# Generate an encryption key:
python -c "from cryptography.fernet import Fernet; print(Fernet.generate_key().decode())"

# Add to Railway environment variables:
# Variable: ENCRYPTION_KEY
# Value: <paste generated key>
```

**FAILURE MODE**: If `BYOK_ENABLED=true`, `ENVIRONMENT` is production, and `ENCRYPTION_KEY` is not set, the app will fail startup validation with:
```
ValueError: ENCRYPTION_KEY must be set when BYOK_ENABLED=true in production.
```

### 3. Required Environment Variables

Set these in Railway dashboard:

```bash
# Core Settings
ENVIRONMENT=production  # Options: dev, staging, production

# Feature Flags (optional - defaults to false)
LESSONS_ENABLED=true
TTS_ENABLED=true
COACH_ENABLED=false
BYOK_ENABLED=false  # Set to true only if you want users to store their own API keys
DEMO_ENABLED=true   # Allow demo API access with rate limiting

# Server-Side API Keys (at least ONE required for features to work)
OPENAI_API_KEY=sk-...        # For GPT-5 models
ANTHROPIC_API_KEY=sk-ant-... # For Claude 4.5 models
GOOGLE_API_KEY=...           # For Gemini 2.5 models

# Demo API Keys (optional - for free tier access)
DEMO_OPENAI_API_KEY=sk-...
DEMO_ANTHROPIC_API_KEY=sk-ant-...
DEMO_GOOGLE_API_KEY=...

# Email Service (optional - defaults to console logging)
EMAIL_PROVIDER=console  # Options: console, resend, sendgrid, aws_ses, mailgun, postmark
FRONTEND_URL=https://your-app.railway.app  # For password reset links

# Uvicorn Workers (optional - defaults to 1)
UVICORN_WORKERS=2  # Railway Starter plan can handle 2 workers
```

### 4. Optional Environment Variables

These have safe defaults but can be customized:

```bash
# Database Connection Pool (Railway Hobby: ~20 connection limit)
DB_POOL_SIZE=5           # Permanent connections
DB_MAX_OVERFLOW=5        # Additional connections when pool is full
DB_POOL_RECYCLE=3600     # Recycle connections after 1 hour

# Rate Limiting (requires Redis)
# If REDIS_URL not set, rate limiting is automatically disabled

# Email Provider Keys (based on EMAIL_PROVIDER choice)
RESEND_API_KEY=...
SENDGRID_API_KEY=...
AWS_ACCESS_KEY_ID=...
AWS_SECRET_ACCESS_KEY=...
MAILGUN_API_KEY=...
POSTMARK_SERVER_TOKEN=...
```

## Deployment Process

### Step 1: Verify Railway Services
1. PostgreSQL service is created and running
2. Redis service is created and running (optional)
3. Services are linked to your app (DATABASE_URL and REDIS_URL auto-set)

### Step 2: Set Environment Variables
1. Generate JWT_SECRET_KEY (see command above)
2. Generate ENCRYPTION_KEY if using BYOK
3. Add at least one provider API key (OpenAI, Anthropic, or Google)
4. Set ENVIRONMENT=production
5. Configure other settings as needed

### Step 3: Deploy
1. Push code to GitHub
2. Railway will automatically build from Dockerfile
3. Build takes ~3-5 minutes (includes pip install of all dependencies)
4. Migration runs automatically on startup: `python -m alembic upgrade head`
5. App starts with uvicorn

### Step 4: Verify Deployment
1. Check Railway logs for "Database initialization complete"
2. Visit `https://your-app.railway.app/health` - should return `{"status":"ok",...}`
3. Visit `https://your-app.railway.app/health/db` - should return database status
4. Visit `https://your-app.railway.app/` - should return welcome message

## Common Issues

### 1. "failed to parse start command"
**Status**: FIXED in latest commit
- Wrapped start command in `/bin/sh -c` for Railway compatibility

### 2. "extension 'vector' is not available"
**Status**: FIXED in latest commit
- Migrations now gracefully handle missing pgvector extension
- Vector search features disabled but app still works

### 3. "Language 'grc' not supported"
**Status**: FIXED in latest commit
- Updated to use 'grc-cls' (Classical Greek) and 'grc-koi' (Koine Greek)

### 4. App crashes on startup with JWT_SECRET_KEY error
**Solution**: Generate and set JWT_SECRET_KEY environment variable (see above)

### 5. App crashes on startup with ENCRYPTION_KEY error
**Solution**: Either:
- Set BYOK_ENABLED=false (users can't store their own API keys)
- OR generate and set ENCRYPTION_KEY (see above)

### 6. Features don't work / "No API key configured" errors
**Solution**: Set at least one provider API key:
- OPENAI_API_KEY for GPT-5 models
- ANTHROPIC_API_KEY for Claude 4.5 models
- GOOGLE_API_KEY for Gemini 2.5 models

### 7. Build timeout on Railway
**Solution**: Railway Hobby plan has 40-minute build timeout, should be sufficient
- Build includes ~90 seconds of pip dependency installation
- Docker image is ~2.5GB
- If timeout occurs, contact Railway support to increase timeout

## Health Checks

Railway uses `/health` endpoint for health checks (configured in railway.toml):
- Timeout: 300 seconds
- Checks database connectivity, extensions, and seed data
- Returns `{"status": "ok"}` if healthy
- Returns `{"status": "degraded"}` if database issues but app is running

## Database Migrations

Migrations run automatically on every deployment via the start command:
```bash
python -m alembic upgrade head && uvicorn app.main:app ...
```

If migrations fail:
- App will still start (graceful degradation)
- Logs will show migration errors
- Fix migration issues and redeploy

## Performance Tuning

### Railway Hobby Plan
- 512 MB RAM, 1 vCPU
- Recommended: `UVICORN_WORKERS=1` (default)
- DB_POOL_SIZE=5, DB_MAX_OVERFLOW=5

### Railway Starter Plan
- 1 GB RAM, 2 vCPU
- Recommended: `UVICORN_WORKERS=2`
- DB_POOL_SIZE=10, DB_MAX_OVERFLOW=10

### Railway Pro Plan
- 8 GB RAM, 8 vCPU
- Recommended: `UVICORN_WORKERS=4`
- DB_POOL_SIZE=20, DB_MAX_OVERFLOW=20

## Rollback Procedure

If deployment fails:
1. Check Railway logs for specific error
2. Revert to previous GitHub commit
3. Railway will auto-redeploy previous version
4. Fix issues in new branch and redeploy

## Support

For deployment issues:
- Check Railway logs first
- Verify all required environment variables are set
- Test health endpoint: `curl https://your-app.railway.app/health`
- Check Discord: https://discord.gg/fMkF4Yza6B
