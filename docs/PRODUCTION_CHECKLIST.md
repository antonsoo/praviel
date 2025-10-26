# Production Deployment Checklist

Use this checklist before deploying PRAVIEL to production to ensure security, performance, and reliability.

## Security

### Authentication & Secrets

- [ ] **JWT_SECRET_KEY** is set to a secure random value (min 32 characters)
  ```bash
  python -c "import secrets; print(secrets.token_urlsafe(32))"
  ```
  - [ ] NOT using default value `CHANGE_ME_IN_PRODUCTION_USE_RANDOM_STRING`
  - [ ] Stored securely in environment variables (not in code)
  - [ ] Different value for staging and production

- [ ] **ENCRYPTION_KEY** is set (if BYOK_ENABLED=true)
  ```bash
  python -c "from cryptography.fernet import Fernet; print(Fernet.generate_key().decode())"
  ```
  - [ ] Different value for staging and production
  - [ ] Backed up securely (losing this key = users lose their saved API keys)

### Environment Configuration

- [ ] **ENVIRONMENT** is set to `production`
- [ ] **ALLOW_DEV_CORS** is set to `false`
- [ ] **ECHO_FALLBACK_ENABLED** is set to `false` (unless intentionally enabled)

### API Keys

- [ ] Server API keys (if providing) are production keys (not test keys)
  - [ ] OPENAI_API_KEY (if set)
  - [ ] ANTHROPIC_API_KEY (if set)
  - [ ] GOOGLE_API_KEY (if set)
- [ ] API keys are stored in environment variables, not in code
- [ ] API keys have appropriate rate limits configured on provider dashboards
- [ ] Monitor API usage to prevent bill shock

### Email Service

- [ ] EMAIL_PROVIDER is NOT set to `console`
- [ ] Using production email service (resend, sendgrid, aws_ses, etc.)
- [ ] EMAIL_FROM_ADDRESS uses your domain (not @gmail.com)
- [ ] EMAIL_FROM_NAME is user-friendly
- [ ] FRONTEND_URL points to production domain (not localhost)
- [ ] Email provider API key is valid and production-ready
- [ ] Tested password reset flow end-to-end
- [ ] SPF/DKIM/DMARC records configured for email domain

## Database & Infrastructure

### PostgreSQL

- [ ] Using managed PostgreSQL (Railway, AWS RDS, etc.)
- [ ] Database has automatic backups enabled
- [ ] pgvector extension is installed (required for embeddings)
- [ ] Database is NOT publicly accessible (only accessible from app)
- [ ] Connection pooling is configured
  - [ ] DB_POOL_SIZE appropriate for your database plan (5-10 for Railway, 20-50 for dedicated)
  - [ ] DB_MAX_OVERFLOW configured (10 is reasonable)
- [ ] Database has monitoring/alerting enabled

### Redis

- [ ] Using managed Redis (Railway, AWS ElastiCache, etc.)
- [ ] Redis has persistence enabled (AOF or RDB)
- [ ] Redis is NOT publicly accessible
- [ ] Redis password is set (if supported by provider)

### Migrations

- [ ] All migrations have been tested in staging
- [ ] Migrations are run automatically on deployment (via startCommand)
- [ ] Rollback plan exists for breaking migrations

## Performance

### Application Configuration

- [ ] UVICORN_WORKERS set appropriately for your server
  - [ ] 1 worker for Railway free tier
  - [ ] 2-4 workers for Railway hobby/pro
  - [ ] `(2 x CPU cores) + 1` for dedicated servers
- [ ] Connection pools tuned for your load
  - [ ] DB_POOL_SIZE matches expected concurrent requests
  - [ ] Not over-provisioning (wastes database connections)

### Monitoring

- [ ] Health check endpoint is working: `/health`
- [ ] Database health check is working: `/health/db`
- [ ] Provider health checks are working: `/health/providers` (if enabled)
- [ ] Application logs are accessible
- [ ] Error tracking is configured (Sentry, Rollbar, etc.) - optional
- [ ] Performance monitoring is configured (DataDog, New Relic, etc.) - optional

## Deployment

### Railway / Platform Configuration

- [ ] Custom domain configured (if applicable)
- [ ] HTTPS is enabled (should be automatic)
- [ ] Health check path is set to `/health` in Railway config
- [ ] Restart policy is configured (ON_FAILURE)
- [ ] Resource limits are appropriate for your plan

### Build & Deploy

- [ ] Docker build completes successfully (< 15 minutes)
- [ ] Application starts without errors
- [ ] All environment variables are set correctly
- [ ] No secrets in logs (redaction working correctly)
- [ ] Railway build timeout increased if needed (Project Settings → Build Timeout)

## Testing

### Functionality

- [ ] Can create a new user account
- [ ] Can verify email (if email service configured)
- [ ] Can log in with username/password
- [ ] Can reset password (if email service configured)
- [ ] Can refresh JWT token
- [ ] Can access protected endpoints with valid token
- [ ] Cannot access protected endpoints without token (403/401)

### AI Features

- [ ] Lessons API works (if LESSONS_ENABLED=true)
  - [ ] OpenAI provider works
  - [ ] Anthropic provider works
  - [ ] Google provider works
- [ ] Chat API works
- [ ] Coach API works (if COACH_ENABLED=true)
- [ ] TTS API works (if TTS_ENABLED=true)

### BYOK (Bring Your Own Key)

- [ ] Users can save API keys (if BYOK_ENABLED=true)
- [ ] API keys are encrypted in database
- [ ] User's API key is used for their requests
- [ ] Can delete saved API keys

### Reader & Search

- [ ] Can search for texts
- [ ] Can view text reader
- [ ] Morphological analysis works
- [ ] Vocabulary lookups work

## Documentation

- [ ] README.md is up to date
- [ ] API documentation is accessible at `/docs`
- [ ] Environment variables are documented
- [ ] Deployment guide exists (RAILWAY_DEPLOYMENT.md)

## Compliance & Legal

- [ ] Privacy policy exists (if collecting user data)
- [ ] Terms of service exists
- [ ] GDPR compliance (if serving EU users)
  - [ ] Can export user data
  - [ ] Can delete user data
- [ ] License file is present (LICENSE.md)

## Post-Deployment

### Monitoring (First 24 Hours)

- [ ] Monitor error logs for unexpected errors
- [ ] Monitor resource usage (CPU, memory, database connections)
- [ ] Monitor API response times
- [ ] Monitor database query performance
- [ ] Check health endpoints every hour

### Verification

- [ ] Smoke test all critical features
- [ ] Check email delivery (send test password reset)
- [ ] Verify AI providers are responding
- [ ] Check database seed data is present
- [ ] Verify authentication flow works end-to-end

### Backup & Recovery

- [ ] Database backup is working (automatic or manual)
- [ ] Backup restoration has been tested
- [ ] Environment variables are backed up securely
- [ ] Secrets are stored in password manager or vault

## Rollback Plan

If deployment fails or critical issues arise:

1. [ ] Know how to rollback deployment in Railway (Deployments → Previous deployment → Redeploy)
2. [ ] Have previous environment variables backed up
3. [ ] Can restore database from backup
4. [ ] Have communication plan for users (status page, email, Discord)

## Scaling Preparation

- [ ] Understand current resource limits
- [ ] Know how to scale horizontally (add more instances)
- [ ] Know how to scale vertically (upgrade server tier)
- [ ] Have cost estimates for different scale levels
- [ ] Database can handle expected load

## Support & Incident Response

- [ ] Discord server is active (for user support)
- [ ] GitHub issues are monitored
- [ ] On-call rotation exists (for critical bugs)
- [ ] Have monitoring alerts configured

## Cost Management

- [ ] Understand current costs:
  - [ ] Railway/hosting platform
  - [ ] Database
  - [ ] Redis
  - [ ] AI API usage (OpenAI, Anthropic, Google)
  - [ ] Email service
- [ ] Set up billing alerts
- [ ] Have budget for unexpected spikes
- [ ] API usage limits configured on provider dashboards

---

## Final Verification Command

Run this command before going live (requires Railway CLI):

```bash
# Check all environment variables are set
railway run python -c "from app.core.config import settings; print('✅ Config loaded successfully')"

# Run health checks
curl https://your-app.up.railway.app/health
curl https://your-app.up.railway.app/health/db

# Test authentication
curl -X POST https://your-app.up.railway.app/api/v1/auth/register \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"TestPassword123!","username":"testuser"}'
```

## Checklist Summary

Total items: ~80+

Before going live:
- [ ] All **Security** items (14 items)
- [ ] All **Database & Infrastructure** items (11 items)
- [ ] All **Performance** items (6 items)
- [ ] All **Deployment** items (8 items)
- [ ] All **Testing** items (16 items)

---

**Last Updated:** October 2025
**PRAVIEL Version:** See [BIG_PICTURE.md](../BIG_PICTURE.md)

**Need Help?**
- Discord: https://discord.gg/fMkF4Yza6B
- GitHub Issues: https://github.com/yourusername/praviel/issues
