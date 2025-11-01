# Critical TO-DOs

**Last updated:** 2025-11-01 18:53 ET

## 🚧 P0 — IN TESTING (Nov 1, 2025 18:53 ET)

### Home/Profile/Lessons Black Screens - Flutter 3.35+ Compiler Bug

**Status:** FIX DEPLOYED - Awaiting User Testing

**ROOT CAUSE:** Flutter 3.35+ has known compiler bug (GitHub Issues #175116, #162868) causing "Null check operator used on a null value" crashes on web even when null checks are present.

**Fix Applied:**
Replaced all `!` null assertion operators with local non-nullable variables in critical paths:
- `daily_goal_service.dart`: Lines 51-58, 114-116
- `backend_progress_service.dart`: Lines 131-138, 600-602

Pattern:
```dart
// BEFORE (triggers compiler bug):
if (_lastCheck == null) return;
final day = DateTime(_lastCheck!.year, ...);

// AFTER (workaround):
final lastCheck = _lastCheck;
if (lastCheck == null) return;
final day = DateTime(lastCheck.year, ...);
```

**Deployment:**
- Frontend: https://b082000c.app-praviel.pages.dev (Nov 1 18:53 ET)
- Backend: Auto-deployed via Railway from main branch
- Git: Commit 5536e6c pushed to main

---

## ✅ P0 — FIXED (Nov 1, 2025 16:15 ET)

### Home/Profile/Lessons Pages Black Screens ✅ RESOLVED

**Status:** FIXED - Root cause identified and resolved

**ROOT CAUSE IDENTIFIED:**
The null check error was in `client/flutter_reader/lib/services/backend_progress_service.dart:419`:
```dart
_queueBox = await Hive.openBox<Map<String, dynamic>>(_queueBoxName);
_pendingUpdates = _queueBox!.values  // ← NULL CHECK OPERATOR ON POTENTIALLY NULL VALUE
```

**Why This Failed:**
- Hive uses IndexedDB for web storage, which can fail due to:
  - Browser privacy/security settings
  - Incognito mode
  - Storage quota exceeded
  - Browser incompatibility
- When `Hive.openBox()` failed silently, `_queueBox` remained null
- The `!` operator on line 419 threw "Null check operator used on a null value"
- This error propagated through `progressServiceProvider` initialization
- All three tabs (Home, Profile, Lessons) depend on `progressServiceProvider`, causing them all to fail

**Fix Applied:**
Added null safety check in `_loadQueue()` method:
```dart
if (_queueBox != null) {
  _pendingUpdates = _queueBox!.values
      .map(_QueuedProgressUpdate.fromMap)
      .toList()
    ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
} else {
  debugPrint('[BackendProgressService] Hive box was null after opening, using empty queue');
  _pendingUpdates = [];
}
```

**Backend SQL Fix (Bonus):**
Also fixed `/search` endpoint SQL ambiguous parameter errors by adding explicit type casts:
- `CAST(:language AS TEXT)` in all three search queries
- `CAST(:work_id AS INTEGER)` in text search query
- Location: `backend/app/api/search.py:70-133`

**Latest Deployment:** https://b9bf7f3b.app-praviel.pages.dev (Nov 1 16:12 ET)

---

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
