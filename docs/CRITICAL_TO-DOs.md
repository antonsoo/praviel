# Critical TO-DOs

**Last Updated:** October 30, 2025
**Purpose:** Blocking issues that must be resolved before production deployment and major launch.

## 📊 Progress Summary

**Completed:** 9 of 13 tasks (69%)
**P0 Critical Blockers:** 2/5 fully resolved, 1/5 partially resolved
**P1 High Priority:** 5/6 resolved
**P2 Medium/Low:** 2/2 verification tasks (cannot auto-complete)

### ✅ Major Accomplishments:
1. Database connection pooling is production-ready
2. CORS security hardened with explicit whitelist
3. Comprehensive endpoint-specific rate limiting verified
4. Sentry error tracking integrated
5. Workbox-based service worker implemented for PWA
6. SEO and Open Graph meta tags added
7. Load testing framework created
8. PWA manifest enhanced

### 🟡 Remaining Tasks:
- Run Flutter Wasm build (`flutter build web --release --wasm`)
- Run full test suite with database (Docker needed)
- Create screenshot images for PWA (home.png, reader.png, lessons.png, og-image.png)
- Verify pgvector indexes in production
- Verify API key redaction in production logs
- Verify CSRF token enforcement

---

## 🚨 Deployment Blockers (P0)

### ✅ 1. Alembic Migrations Directory (RESOLVED)
**Status:** ✅ COMPLETE
**Resolution:** `backend/migrations/versions/` directory exists with 32 migration files tracking full schema history.

---

### ✅ 2. Database Connection Pooling (RESOLVED)
**Status:** ✅ COMPLETE
**Resolution:** Production-ready pooling implemented in `backend/app/db/session.py:backend/app/db/session.py:52`:
- Environment-configurable pool settings (pool_size, max_overflow, pool_recycle)
- pool_pre_ping enabled for connection health checks
- PgBouncer compatibility detection and prepared statement handling
- asyncpg>=0.29 is current version (tested and working with SQLAlchemy 2.0)

---

### ✅ 3. Flutter Web Build Size Optimization (PARTIALLY RESOLVED)
**Status:** 🟡 HIGH PRIORITY - Service worker implemented, Wasm build needs manual execution
**Impact:** Slow initial load, poor UX, high CDN costs

**Completed:**
- ✅ Workbox-based service worker created at `client/flutter_reader/web/service-worker.js`
- ✅ Service worker registration added to `client/flutter_reader/web/index.html`
- ✅ Comprehensive caching strategies for documents, scripts, styles, fonts, images, audio, and API calls
- ✅ Background sync and push notification support scaffolded

**Remaining:**
- Build with Wasm: `cd client/flutter_reader && flutter build web --release --wasm`
- Test PWA installation and caching behavior
- Measure Lighthouse PWA score (target: > 85)

**References:**
- [Flutter web optimization guide 2025](https://cleancodestack.com/choosing-flutter-web-in-2025-top-8-issues/)
- [Workbox caching strategies](https://mohanrajmuthukumaran.hashnode.dev/flutter-pwa-workbox-caching)

---

### ✅ 4. CORS Configuration (RESOLVED)
**Status:** ✅ COMPLETE
**Resolution:** Updated `backend/app/main.py:185` to use explicit whitelist instead of regex:
- Explicit origins: praviel.com, app.praviel.com, www.praviel.com
- ADDITIONAL_CORS_ORIGINS environment variable for staging/preview
- Explicit HTTP methods instead of wildcard
- Eliminates subdomain attack vector

---

### 5. 145 Tests Being Skipped
**Status:** 🟡 HIGH PRIORITY
**Impact:** Unknown test coverage, potential bugs in production

**Problem:**
```
212 tests collected
67 passed, 145 skipped
```

**Root cause:** Tests skip when PostgreSQL is not running (connection error)

**Solution:**
```bash
# Start PostgreSQL
docker compose up -d db

# Wait for DB to be ready
sleep 5

# Run full test suite
source praviel-env/bin/activate
pytest -v --tb=short

# Expected: All 212 tests should pass
```

If any tests fail, fix them before deploying.

---

## ⚠️ Performance & Scalability (P1)

### 6. pgvector Index Optimization
**Status:** 🟡 MEDIUM PRIORITY
**Impact:** Slow vector search, poor reader performance at scale

**Problem:**
- No HNSW indexes on embedding columns (using slower IVFFlat or no index)
- Missing `ANALYZE` after bulk inserts
- No index parameter tuning

**Solution:**

Add HNSW indexes (faster than IVFFlat for most workloads):
```sql
-- On Neon PostgreSQL
CREATE INDEX ON text_segments USING hnsw (embedding vector_cosine_ops);
CREATE INDEX ON lexicon_entries USING hnsw (embedding vector_cosine_ops);

-- After bulk inserts or updates:
ANALYZE text_segments;
ANALYZE lexicon_entries;
```

**Index tuning:**
- For < 1M rows: `lists = rows / 1000`, `probes = lists / 10`
- For > 1M rows: `lists = sqrt(rows)`, `probes = sqrt(lists)`
- Monitor index size - ensure it fits in RAM for best performance

**References:**
- [pgvector performance optimization](https://www.crunchydata.com/blog/pgvector-performance-for-developers)
- [Neon pgvector guide](https://neon.com/blog/optimizing-vector-search-performance-with-pgvector)

---

### ✅ 7. Endpoint-Specific Rate Limiting (RESOLVED)
**Status:** ✅ COMPLETE
**Resolution:** Comprehensive endpoint-specific rate limiting already implemented in `backend/app/middleware/rate_limit.py:106`:
- Password reset: 3 per hour
- API key operations: 5 per hour
- Lesson generation: 10 per hour
- Registration: 5 per hour
- Login: 10 per minute
- Auth endpoints: 10 per minute
- Chat: 20 per minute
- TTS: 15 per minute
- Standard write: 30 per minute
- Read operations: 100 per minute
- Redis-backed token bucket algorithm with graceful fallback

---

### ✅ 8. Production Logging/Monitoring (RESOLVED)
**Status:** ✅ COMPLETE
**Resolution:** Sentry error tracking integrated:
- Added `SENTRY_DSN` to `backend/app/core/config.py:104`
- Sentry initialization in `backend/app/main.py:70` with FastAPI and SQLAlchemy integrations
- 10% transaction sampling for performance monitoring
- Automatic release tracking via RAILWAY_GIT_COMMIT_SHA
- PII protection enabled
- Graceful fallback if sentry-sdk not installed

**Next steps:**
- Add SENTRY_DSN to Railway environment variables
- Install sentry-sdk: `pip install sentry-sdk[fastapi,sqlalchemy]`

---

### ✅ 9. Load Testing Script (RESOLVED)
**Status:** ✅ COMPLETE
**Resolution:** Comprehensive Locust load testing script created at `scripts/load_test.py`:
- Three user types: PravielUser (general), HeavyUser (lessons), ReadOnlyUser (reader)
- Realistic task distribution and wait times
- Custom DailyLoadShape for simulating traffic patterns
- Support for multiple ancient languages (Greek, Latin, Hebrew)
- Detailed usage examples and target benchmarks documented

**Usage:**
```bash
locust -f scripts/load_test.py --host https://api.praviel.com
```

---

## 📱 Flutter Web Deployment Issues (P1)

### ✅ 10. Flutter Web Manifest (RESOLVED)
**Status:** ✅ COMPLETE
**Resolution:** Updated `client/flutter_reader/web/manifest.json` with PWA enhancements:
- ✅ Categories: education, productivity, books
- ✅ Screenshots structure added (home.png, reader.png, lessons.png) with form factors
- ✅ Share target configured for sharing content to app
- ✅ Enhanced name and description
- ✅ Proper icon purposes defined (any/maskable)

**Remaining:**
- Create actual screenshot images in `client/flutter_reader/web/screenshots/` directory
- Create og-image.png (1200x630px) for social sharing

---

### ✅ 11. Flutter Web SEO (RESOLVED)
**Status:** ✅ COMPLETE
**Resolution:** Comprehensive SEO meta tags added to `client/flutter_reader/web/index.html`:
- ✅ SEO meta tags: description, keywords, author
- ✅ Open Graph tags for Facebook sharing
- ✅ Twitter Card tags
- ✅ Enhanced page title
- ✅ Viewport meta tag

**Remaining:**
- Create og-image.png (1200x630px) for social sharing previews

**Long-term recommendation:**
- Create separate marketing landing page (HTML/CSS) for SEO at `praviel.com`
- Use Flutter web for the app itself at `app.praviel.com`

---

## 🔒 Security Hardening (P2)

### 12. API Keys Potentially Visible in Logs
**Status:** 🟠 LOW PRIORITY
**Impact:** Accidental key leakage

**Problem:**
- Redaction middleware exists (`backend/app/security/middleware.py`)
- But need to verify it's working correctly

**Verification:**
```bash
# In production, check logs for leaked keys
grep -r "sk-" backend/logs/  # Should return nothing
grep -r "x-goog-api-key" backend/logs/  # Should return nothing
grep -r "claude-" backend/logs/  # Should return nothing
```

If any keys found, update redaction patterns in `backend/app/security/middleware.py`.

---

### 13. CSRF Token Implementation Incomplete
**Status:** 🟠 LOW PRIORITY
**Impact:** CSRF vulnerability on state-changing endpoints

**Problem:**
- CSRF middleware exists (`backend/app/middleware/csrf.py`)
- But need to verify it's enforced on all POST/PUT/DELETE endpoints

**Solution:**

Add CSRF token to all forms in Flutter:
```dart
// In http_client or API service
final headers = {
  'Content-Type': 'application/json',
  'X-CSRF-Token': await getCsrfToken(),  // Fetch from /api/v1/csrf-token
};
```

Verify all state-changing endpoints require CSRF token.

---

## ✅ Completed / Non-Issues

### ✅ Fall 2025 API Protection
**Status:** ✅ COMPLETE
All 4 protection layers are in place and working correctly.

### ✅ Python 3.13 Environment
**Status:** ✅ COMPLETE
Python 3.13.9 confirmed working with `praviel-env` venv.

### ✅ Flutter Stable Channel
**Status:** ✅ COMPLETE
Flutter 3.35.7 (stable) confirmed working.

### ✅ Package Management Strategy
**Status:** ✅ COMPLETE
Clear strategy documented in AGENTS.md and CLAUDE.md.

### ✅ BYOK Architecture
**Status:** ✅ COMPLETE
Bring Your Own Key system is implemented and working.

### ✅ Docker Configuration
**Status:** ✅ COMPLETE
Multi-stage Dockerfile with Python 3.13, proper security (non-root user), health checks.

### ✅ CI/CD Workflows Exist
**Status:** ✅ COMPLETE
GitHub Actions workflows exist in `.github/workflows/` and appear well-structured.

### ✅ Railway Environment Variables Configured
**Status:** ✅ COMPLETE
45 environment variables including JWT_SECRET_KEY, ENCRYPTION_KEY, ENVIRONMENT, and ALLOW_DEV_CORS are already configured in Railway production environment.

---

## 📋 Quick Action Items (Can Do Now)

```bash
# 1. Create missing alembic migrations
mkdir -p alembic/versions
cd /home/antonsoloviev/work/projects/praviel_files/praviel
source praviel-env/bin/activate
alembic revision --autogenerate -m "Initial schema"
alembic upgrade head

# 2. Run full test suite
docker compose up -d db
pytest -v

# 3. Optimize Flutter web build
cd client/flutter_reader
flutter build web --release --wasm

# 4. Add asyncpg version pin to pyproject.toml
# Edit: dependencies = ["asyncpg>=0.28.0,<0.29.0", ...]
```

---

## Priority Legend

- 🔴 **P0 (CRITICAL):** Blocks deployment, must fix before production
- 🟡 **P1 (HIGH):** Significant impact, fix before public launch
- 🟠 **P2 (MEDIUM):** Important for stability/scale, fix within 1-2 months
- ⚪ **P3 (LOW):** Nice-to-have, address opportunistically

---

## Maintenance Notes

- **Remove items immediately when completed** - this doc should always reflect current blockers
- **Keep this doc under 400 lines** - anything longer means too many blockers (prioritize!)
- **Archive old TO-DOs** to `docs/archive/OLD_TODOS_[DATE].md` if historical context needed
- **Review before every deployment** to ensure all blockers are resolved

---

**Last Review:** October 30, 2025
**Next Review:** Before next deployment to production
