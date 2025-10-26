# Railway Deployment Guide

This guide walks you through deploying PRAVIEL to Railway, including database setup, environment variables, and troubleshooting.

## Prerequisites

- GitHub account with PRAVIEL repository
- [Railway account](https://railway.app/) (free tier available)
- API keys for AI providers (OpenAI, Anthropic, or Google - optional but recommended)

## Quick Start

### 1. Create Railway Project

1. Go to [Railway](https://railway.app/) and sign in with GitHub
2. Click **"New Project"**
3. Select **"Deploy from GitHub repo"**
4. Select your PRAVIEL fork/repository
5. Railway will auto-detect the Dockerfile and start building

### 2. Add PostgreSQL Database

1. In your Railway project, click **"+ New"**
2. Select **"Database" → "Add PostgreSQL"**
3. Railway will automatically:
   - Create a PostgreSQL database with pgvector extension
   - Generate a `DATABASE_URL` environment variable
   - Link it to your backend service

### 3. Add Redis (Optional but Recommended)

1. Click **"+ New" → "Database" → "Add Redis"**
2. Railway will automatically generate `REDIS_URL`

### 4. Configure Environment Variables

In your Railway project → Backend Service → **Variables** tab, add:

#### Required Variables

```bash
# Security (CRITICAL - Generate secure values!)
JWT_SECRET_KEY=<generate_with_command_below>
ENCRYPTION_KEY=<generate_with_command_below>

# Environment
ENVIRONMENT=production
ALLOW_DEV_CORS=false

# Feature Flags
BYOK_ENABLED=true
COACH_ENABLED=true
LESSONS_ENABLED=true
TTS_ENABLED=true
ECHO_FALLBACK_ENABLED=false

# AI Provider Keys (at least one required for full functionality)
OPENAI_API_KEY=sk-...
ANTHROPIC_API_KEY=sk-ant-...
GOOGLE_API_KEY=AI...

# Email Service (for password reset emails)
EMAIL_PROVIDER=resend
EMAIL_FROM_ADDRESS=noreply@yourdomain.com
EMAIL_FROM_NAME=PRAVIEL
FRONTEND_URL=https://yourdomain.com
RESEND_API_KEY=re_...
```

#### Generate Secure Keys

Run these commands locally to generate secure values:

```bash
# JWT Secret Key (copy the output to JWT_SECRET_KEY)
python -c "import secrets; print(secrets.token_urlsafe(32))"

# Encryption Key (copy the output to ENCRYPTION_KEY)
python -c "from cryptography.fernet import Fernet; print(Fernet.generate_key().decode())"
```

#### Optional Performance Tuning

```bash
# Database connection pool (defaults are optimized for Railway)
DB_POOL_SIZE=5          # Reduce for free tier, increase for paid plans
DB_MAX_OVERFLOW=5       # Additional connections when pool is full

# Uvicorn workers (defaults to 2, set to 1 for free tier)
UVICORN_WORKERS=2       # More workers = better concurrency (requires more RAM)
```

### 5. Deploy

Railway will automatically:
1. Build your Docker image (~5-10 minutes first time, ~1-2 minutes after)
2. Run database migrations (`alembic upgrade head`)
3. Start the FastAPI server with uvicorn
4. Assign a public URL: `https://your-app.up.railway.app`

## Verify Deployment

### Health Check

Visit: `https://your-app.up.railway.app/health`

Expected response:
```json
{
  "status": "ok",
  "project": "PRAVIEL API (LDSv1)",
  "features": {
    "lessons": true,
    "tts": true
  }
}
```

### Database Health

Visit: `https://your-app.up.railway.app/health/db`

Expected response:
```json
{
  "status": "ok",
  "extensions": {
    "vector": true
  },
  "seed_data": true
}
```

### API Documentation

Visit: `https://your-app.up.railway.app/docs`

You should see the interactive Swagger UI with all available endpoints.

## Common Issues & Solutions

### Build Timeout

**Symptom:** Build fails with "timeout" error after 10 minutes

**Solutions:**
1. **Increase build timeout** (Railway Dashboard):
   - Go to Project Settings → General
   - Increase "Build Timeout" to 15-20 minutes

2. **Check BuildKit is enabled** (it should be automatic):
   - Railway uses BuildKit by default
   - Cache mounts in our Dockerfile speed up rebuilds

3. **Subsequent builds should be much faster** (~1-2 minutes) due to layer caching

### Application Crashes on Startup

**Symptom:** "Health check failed" or service keeps restarting

**Common Causes:**

1. **Missing JWT_SECRET_KEY:**
   ```
   ValueError: JWT_SECRET_KEY must be set to a secure random value in production
   ```
   **Fix:** Add secure `JWT_SECRET_KEY` in Railway environment variables

2. **Database connection failed:**
   ```
   Connection refused to database
   ```
   **Fix:** Ensure PostgreSQL database is created and `DATABASE_URL` is set (Railway does this automatically)

3. **Missing Redis:**
   ```
   Connection refused to Redis
   ```
   **Fix:** Add Redis database in Railway or set `REDIS_URL=redis://localhost:6379` (not recommended for production)

### Slow Performance

**Symptoms:** API responses are slow, timeouts

**Solutions:**

1. **Upgrade Railway plan** - Free tier has CPU/RAM limits
2. **Reduce worker count** - Set `UVICORN_WORKERS=1` for free tier
3. **Optimize database pool** - Set `DB_POOL_SIZE=5` for free tier
4. **Enable caching** - Redis helps with performance (should already be enabled)

### Database Migration Failures

**Symptom:** Startup fails with migration errors

**Solutions:**

1. **Check logs** in Railway dashboard:
   ```bash
   # Look for migration errors
   ERROR: relation "users" already exists
   ```

2. **Reset database** (if safe to do so):
   - Railway Dashboard → PostgreSQL → Data tab
   - Drop all tables and restart deployment

3. **Manual migration** via Railway CLI:
   ```bash
   railway run python -m alembic upgrade head
   ```

## Monitoring & Logs

### View Logs

Railway Dashboard → Your Service → **Logs** tab

Useful filters:
- `ERROR` - See only errors
- `alembic` - See migration logs
- `uvicorn` - See server startup logs

### Monitor Resource Usage

Railway Dashboard → Your Service → **Metrics** tab

Watch for:
- **Memory usage** - If consistently >90%, upgrade plan or reduce workers
- **CPU usage** - High CPU indicates need for more workers or plan upgrade
- **Network I/O** - High indicates good traffic (or potential DDoS)

## Scaling

### Horizontal Scaling (Multiple Instances)

Railway supports horizontal scaling on paid plans:

1. Project Settings → Service → **Replicas**
2. Set desired number of instances (2-10 recommended)
3. Railway load balancer distributes traffic automatically

**Note:** Requires:
- Paid Railway plan
- Stateless application (we are stateless ✅)
- External database (we use Railway PostgreSQL ✅)

### Vertical Scaling (More Resources)

Upgrade your Railway plan for more:
- CPU cores (enables more workers)
- RAM (allows larger connection pools)
- Database size

## Environment Variables Reference

### Required

| Variable | Example | Description |
|----------|---------|-------------|
| `DATABASE_URL` | `postgresql+asyncpg://...` | Auto-set by Railway PostgreSQL |
| `REDIS_URL` | `redis://...` | Auto-set by Railway Redis |
| `JWT_SECRET_KEY` | `abc123...` | **Generate with secure random string** |
| `ENCRYPTION_KEY` | `def456...` | **Generate with Fernet.generate_key()** |

### Feature Flags

| Variable | Default | Description |
|----------|---------|-------------|
| `LESSONS_ENABLED` | `true` | Enable AI-generated lessons |
| `TTS_ENABLED` | `true` | Enable text-to-speech |
| `COACH_ENABLED` | `true` | Enable conversational coach |
| `BYOK_ENABLED` | `true` | Allow users to bring their own API keys |

### Performance Tuning

| Variable | Default | Description |
|----------|---------|-------------|
| `UVICORN_WORKERS` | `2` | Number of worker processes (set to 1 for free tier) |
| `DB_POOL_SIZE` | `10` | Database connection pool size |
| `DB_MAX_OVERFLOW` | `10` | Additional connections when pool is full |

### AI Provider Keys

| Variable | Required? | Description |
|----------|-----------|-------------|
| `OPENAI_API_KEY` | Optional* | OpenAI API key (GPT-5) |
| `ANTHROPIC_API_KEY` | Optional* | Anthropic API key (Claude 4.5) |
| `GOOGLE_API_KEY` | Optional* | Google API key (Gemini 2.5) |

*At least one provider recommended. With `BYOK_ENABLED=true`, users can bring their own keys.

### Email Service

| Variable | Example | Description |
|----------|---------|-------------|
| `EMAIL_PROVIDER` | `resend` | Email service (resend, sendgrid, aws_ses, mailgun, postmark, console) |
| `EMAIL_FROM_ADDRESS` | `noreply@praviel.com` | From email address |
| `RESEND_API_KEY` | `re_...` | Resend API key (if using Resend) |
| `FRONTEND_URL` | `https://praviel.com` | Frontend URL for password reset links |

## Cost Estimation

### Railway Free Tier
- **Included:** $5 credit/month
- **Database:** PostgreSQL + Redis (~$8/month combined)
- **Backend:** Hobby plan (~$5/month)
- **Total:** ~$13/month (requires paid plan after trial)

### Railway Hobby Plan
- **Cost:** $5/month
- **Limits:** 500 hours compute/month
- **Database:** Add PostgreSQL (~$5/month) + Redis (~$3/month)
- **Total:** ~$13/month

### Railway Pro Plan
- **Cost:** $20/month
- **Includes:** More resources, better performance
- **Database:** Included in plan
- **Total:** ~$20/month

## Next Steps

1. ✅ **Configure custom domain** (Railway Dashboard → Domains)
2. ✅ **Set up monitoring** (consider Sentry, LogRocket, or Datadog)
3. ✅ **Configure CI/CD** (automatic deploys on git push - already enabled!)
4. ✅ **Add staging environment** (create second Railway project from `develop` branch)
5. ✅ **Set up backups** (Railway auto-backups databases, but export regularly)

## Support

- **Railway Docs:** https://docs.railway.com
- **PRAVIEL Discord:** https://discord.gg/fMkF4Yza6B
- **Issues:** https://github.com/yourusername/praviel/issues

## Security Checklist

Before going to production:

- [ ] Generated secure `JWT_SECRET_KEY` (not default value)
- [ ] Generated secure `ENCRYPTION_KEY` for BYOK
- [ ] Set `ENVIRONMENT=production`
- [ ] Set `ALLOW_DEV_CORS=false`
- [ ] Configured email service (not `console`)
- [ ] Set `FRONTEND_URL` to actual domain
- [ ] Reviewed all environment variables
- [ ] Tested password reset flow
- [ ] Tested AI provider integrations
- [ ] Configured custom domain with HTTPS
- [ ] Set up database backups
- [ ] Reviewed Railway logs for errors

---

**Last Updated:** October 2025
**Railway API Version:** v2
**PRAVIEL Version:** See [BIG_PICTURE.md](../BIG_PICTURE.md)
