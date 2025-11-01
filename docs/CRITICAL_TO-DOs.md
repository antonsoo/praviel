# Critical TO-DOs

**Last updated:** 2025-11-01 11:10 ET

## ✅ P0 — RESOLVED (Nov 1, 2025 13:00 ET)

**ROOT CAUSE:** Flutter web app deployed in **DEBUG MODE** instead of RELEASE MODE

### Issue Fixed: Flutter Web Build Configuration

The Flutter web app at https://app.praviel.com was built with `flutter build web` (debug mode) instead of `flutter build web --release`. This caused it to load `dev.json` config pointing to `http://127.0.0.1:8002` instead of production API.

**Fix Applied:**
```bash
cd client/flutter_reader
flutter clean
flutter build web --release

# Deploy to Cloudflare Pages
export CLOUDFLARE_API_TOKEN="<token>"
export CLOUDFLARE_ACCOUNT_ID="042db01b93c374acecfbdbc3c1034e25"
npx wrangler pages deploy client/flutter_reader/build/web --project-name=app-praviel --commit-dirty=true
```

**Deployment:** ✅ SUCCESS
**New deployment:** https://d629e866.app-praviel.pages.dev
**Production URL:** https://app.praviel.com (auto-updated)

---

## ✅ BACKEND FIXED (Nov 1, 2025 11:10 ET)

**ROOT CAUSE:** Railway DATABASE_URL contained `channel_binding=require` parameter that asyncpg doesn't support.

### Backend Endpoints - ALL WORKING ✅

**Tested and verified:**
- ✅ Registration: `POST /api/v1/auth/register` → 201 Created
- ✅ Login: `POST /api/v1/auth/login` → 200 OK with tokens
- ✅ User Profile: `GET /api/v1/users/me` → 200 OK
- ✅ User Progress: `GET /api/v1/progress/me` → 200 OK with data
- ✅ Health Check: `GET /health` → 200 OK

**Fix Applied:**
```bash
railway variables --set "DATABASE_URL=postgresql://neondb_owner:...@ep-small-truth-a82ceowt-pooler.eastus2.azure.neon.tech/neondb?sslmode=require"
railway redeploy --yes
```

---

## 🟡 P1 — Post-Launch

### Token/Morphology Data Extraction
Extract `@lemma`/`@ana` from Perseus TEI XML during ingestion.
**File**: `backend/scripts/ingest_perseus_corpus.py`

---

## ✅ Completed Infrastructure (Oct 31)
- Database: Neon Postgres connected (sslmode=require)
- Redis: Connected via Railway internal network
- API Keys: All providers configured (OpenAI, Google, Anthropic)
- Feature Flags: ECHO_FALLBACK_ENABLED=true, LESSONS_ENABLED=true
- Deployment: Railway FastAPI backend + Redis + Neon Postgres
- Health Check: `/health` returns 200 OK
