# Web Deployment Checklist - Get Users ASAP

**Last Updated:** October 21, 2025
**Goal:** Deploy Ancient Languages as a web app with one-click access for users (zero setup required)
**Urgency:** HIGH - Investor meeting approaching, need to demonstrate userbase growth and traction

---

## Executive Summary

**Current Status:** 95% production-ready
- Backend: 173+ tests passing, all 3 AI providers verified
- Frontend: 0 analyzer warnings, 100% test pass rate, successful web build
- Infrastructure: Docker-ready, database migrations complete

**Critical Path to Launch:** 3-7 days
1. Choose deployment strategy (Day 1)
2. Set up infrastructure (Day 1-2)
3. Configure environment & deploy (Day 2-3)
4. Browser testing & bug fixes (Day 3-5)
5. Domain setup & SSL (Day 1-2, can run in parallel)
6. Launch & monitor (Day 7+)

**Estimated Costs:**
- **Option A (Free Tier):** $0-15/month (self-hosted or free services + domain)
- **Option B (Budget Cloud):** $15-35/month (managed services, zero maintenance)
- **Option C (Production Scale):** $50-100/month (when userbase grows)

---

## Table of Contents

1. [Deployment Strategy Options](#deployment-strategy-options)
2. [Minimum Requirements Checklist](#minimum-requirements-checklist)
3. [Free Tier Implementation (Rate Limiting)](#free-tier-implementation-rate-limiting)
4. [Option A: Self-Hosted from Home PC (FREE)](#option-a-self-hosted-from-home-pc-free)
5. [Option B: Hybrid (Free Services + Budget Cloud)](#option-b-hybrid-free-services--budget-cloud)
6. [Option C: Full Cloud (Scalable, Investor-Ready)](#option-c-full-cloud-scalable-investor-ready)
7. [Frontend Deployment (All Options)](#frontend-deployment-all-options)
8. [Domain & SSL Setup](#domain--ssl-setup)
9. [Pre-Launch Testing Checklist](#pre-launch-testing-checklist)
10. [Launch Day Checklist](#launch-day-checklist)
11. [Post-Launch Monitoring](#post-launch-monitoring)
12. [Recommended Path for Your Situation](#recommended-path-for-your-situation)

---

## Deployment Strategy Options

### Quick Comparison

| Component | Option A: Self-Hosted | Option B: Hybrid | Option C: Full Cloud |
|-----------|---------------------|-----------------|---------------------|
| **Backend** | Home PC + Cloudflare Tunnel | Railway/Render | DigitalOcean/AWS |
| **Database** | Docker on PC | Neon (free) / Aiven (free) | Managed PostgreSQL |
| **Frontend** | Firebase Hosting (free) | Netlify (free) | Vercel (free) / CDN |
| **Monthly Cost** | $0-15 (domain only) | $15-25 | $50-100 |
| **Setup Time** | 2-3 days | 1-2 days | 1-2 days |
| **Maintenance** | Medium (restart PC issues) | Low | Very Low |
| **Scalability** | Limited (your PC/internet) | Medium (free tier limits) | High |
| **Investor Appeal** | Low (not "real" infra) | Medium | High |
| **Best For** | MVP testing, friends/family | Small beta (50-200 users) | Public launch, growth |

**Recommendation:** Start with **Option B (Hybrid)** to balance cost and credibility. Migrate to Option C when you have 200+ active users or secure funding.

---

## Minimum Requirements Checklist

### What You MUST Have (No Shortcuts)

#### 1. Production Secrets (Security)
```bash
# Generate these BEFORE deploying
python -c "import secrets; print(secrets.token_urlsafe(32))"  # JWT_SECRET_KEY
python -c "from cryptography.fernet import Fernet; print(Fernet.generate_key().decode())"  # ENCRYPTION_KEY
```

**Store in:**
- `.env` file (local testing)
- Cloud provider's environment variable settings (production)
- **NEVER commit to git**

#### 2. Database with pgvector Extension
- PostgreSQL 14+
- `pgvector` extension installed
- Minimum: 1GB RAM, 10GB storage
- Connection URL format: `postgresql+asyncpg://user:pass@host:5432/dbname`

#### 3. Redis Instance
- Redis 7+
- Minimum: 256MB RAM
- Connection URL format: `redis://user:pass@host:6379`

#### 4. AI Provider API Key (Choose ONE minimum)
- **Google Gemini** (RECOMMENDED for free tier): 2M tokens/day free
- OpenAI GPT-5: Pay-as-you-go
- Anthropic Claude 4.5: Pay-as-you-go

**For Free Tier Users:**
- Set `GOOGLE_API_KEY` with YOUR key (users won't need their own)
- Implement rate limiting (see section below)

#### 5. Domain Name
- **Recommended:** yourapp.com, learn-ancient.com, etc.
- **Budget option:** Namecheap ($8-12/year), Porkbun ($7-10/year)
- **Free subdomain option:** Provided by hosting platforms (e.g., yourapp.netlify.app)

#### 6. Email Service (For Password Resets)
- **Free tier options:**
  - Resend: 3,000 emails/month free
  - SendGrid: 100 emails/day free
  - Mailgun: 1,000 emails/month free (first 3 months)
- Set `EMAIL_PROVIDER`, `RESEND_API_KEY`, `EMAIL_FROM_ADDRESS`

---

## Free Tier Implementation (Rate Limiting)

**Why:** You're providing free credits initially. Without rate limiting, one user could burn through your entire API budget.

### Backend Implementation Required

#### 1. Add Daily Quota Tracking to Database

**File:** `backend/app/db/models/user_quota.py` (NEW)

```python
from sqlalchemy import Column, Integer, String, Date
from app.db.base import Base

class UserDailyQuota(Base):
    __tablename__ = "user_daily_quotas"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, index=True, nullable=False)
    date = Column(Date, nullable=False, index=True)

    # Quota counters
    lessons_generated = Column(Integer, default=0)
    chat_messages_sent = Column(Integer, default=0)
    tts_requests = Column(Integer, default=0)

    # Limits (can vary per user tier)
    lessons_limit = Column(Integer, default=10)  # 10 lessons/day for free tier
    chat_messages_limit = Column(Integer, default=50)  # 50 messages/day
    tts_requests_limit = Column(Integer, default=20)  # 20 TTS requests/day
```

**Migration:** Run `alembic revision --autogenerate -m "Add user daily quotas"`

#### 2. Add Rate Limiting Middleware

**File:** `backend/app/middleware/rate_limit.py` (NEW)

```python
from datetime import date
from fastapi import HTTPException, status, Depends
from sqlalchemy.ext.asyncio import AsyncSession
from app.db.session import get_db
from app.db.models.user_quota import UserDailyQuota
from app.security.auth import get_current_user

async def check_lesson_quota(
    user = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Check if user has remaining lesson quota for today."""
    today = date.today()

    # Get or create today's quota record
    quota = await db.query(UserDailyQuota).filter(
        UserDailyQuota.user_id == user.id,
        UserDailyQuota.date == today
    ).first()

    if not quota:
        quota = UserDailyQuota(user_id=user.id, date=today)
        db.add(quota)
        await db.commit()

    # Check limit
    if quota.lessons_generated >= quota.lessons_limit:
        raise HTTPException(
            status_code=status.HTTP_429_TOO_MANY_REQUESTS,
            detail=f"Daily lesson limit reached ({quota.lessons_limit}/day). Upgrade to premium for unlimited lessons, or use BYOK mode."
        )

    # Increment counter
    quota.lessons_generated += 1
    await db.commit()

    return quota
```

#### 3. Apply Rate Limiting to Endpoints

**File:** `backend/app/api/routes/lessons.py`

```python
from app.middleware.rate_limit import check_lesson_quota

@router.post("/generate")
async def generate_lesson(
    request: LessonRequest,
    user = Depends(get_current_user),
    quota = Depends(check_lesson_quota),  # ADD THIS
    db: AsyncSession = Depends(get_db)
):
    # Existing lesson generation logic...
```

#### 4. Frontend: Display Quota to Users

**File:** `client/flutter_reader/lib/pages/pro_lessons_page.dart`

Add quota display widget at top of page:

```dart
// Fetch quota from backend
final quota = await ApiService.getUserQuota();

// Display banner
if (quota.lessonsRemaining <= 3) {
  return Card(
    color: Colors.orange.shade100,
    child: Padding(
      padding: EdgeInsets.all(12),
      child: Row(
        children: [
          Icon(Icons.warning_amber, color: Colors.orange.shade900),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'You have ${quota.lessonsRemaining} free lessons remaining today. '
              'Resets at midnight UTC. Upgrade to Premium for unlimited lessons!',
            ),
          ),
        ],
      ),
    ),
  );
}
```

### Estimated API Costs with Rate Limiting

**Google Gemini 2.5 Flash (FREE tier: 2M tokens/day)**
- Average lesson: ~2,000 tokens (1,500 input + 500 output)
- Capacity: ~1,000 lessons/day FREE
- Cost if exceeded: $0.075 per 1M input tokens, $0.30 per 1M output tokens

**Your daily limits:**
- 10 lessons/user/day × 50 users = 500 lessons/day = ~1M tokens = FREE
- 10 lessons/user/day × 200 users = 2,000 lessons/day = ~4M tokens = $0.15-0.30/day = $5-10/month

**Conclusion:** With rate limiting, you can support 50-100 free users per day at ZERO cost using Google Gemini free tier.

---

## Option A: Self-Hosted from Home PC (FREE)

**Best For:** Initial testing with friends/family (10-50 users), budget is $0

**Pros:**
- Completely free (except domain ~$10/year)
- Full control over infrastructure
- Good for learning/testing

**Cons:**
- Your PC must stay on 24/7
- Limited by your internet upload speed
- Power outages = downtime
- Not professional for investors

### Architecture

```
User Browser
    ↓ HTTPS
Cloudflare Tunnel (free)
    ↓ Encrypted tunnel
Your Gaming PC (Windows)
├── Docker: PostgreSQL + Redis + Backend
└── Already running: Fast internet, 24/7 uptime

Frontend: Firebase Hosting (free CDN)
```

### Setup Checklist

#### Step 1: Prepare Your PC (30 minutes)

- [ ] Ensure PC will stay on 24/7
- [ ] Configure Windows power settings: Never sleep/hibernate
- [ ] Check upload speed: Run speedtest.net (need 10+ Mbps upload)
- [ ] Disable Windows auto-restart for updates
- [ ] Set up port forwarding exemption (NOT needed with Cloudflare Tunnel)

#### Step 2: Install Cloudflare Tunnel (30 minutes)

**Cloudflare Tunnel (formerly Argo Tunnel)** exposes your local backend to the internet without opening firewall ports.

```powershell
# Download cloudflared
# Visit: https://developers.cloudflare.com/cloudflare-one/connections/connect-apps/install-and-setup/installation/

# Windows: Download and install cloudflared.exe
Invoke-WebRequest -Uri https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-windows-amd64.exe -OutFile cloudflared.exe

# Authenticate with Cloudflare
.\cloudflared.exe tunnel login

# Create a tunnel
.\cloudflared.exe tunnel create ancient-languages-backend

# Create config file: C:\Users\YourName\.cloudflared\config.yml
tunnel: <TUNNEL_ID_FROM_ABOVE>
credentials-file: C:\Users\YourName\.cloudflared\<TUNNEL_ID>.json

ingress:
  - hostname: api.yourapp.com
    service: http://localhost:8000
  - service: http_status:404
```

#### Step 3: Start Backend on Your PC (20 minutes)

```powershell
# Navigate to project
cd C:\Dev\AI_Projects\AncientLanguagesAppDirs\Current-working-dirs\AncientLanguages

# Create production .env file
# File: backend/.env
@"
# Security (GENERATE NEW SECRETS!)
JWT_SECRET_KEY=your-secret-here
ENCRYPTION_KEY=your-fernet-key-here

# Database (Docker on localhost)
DATABASE_URL=postgresql+asyncpg://app:app@localhost:5433/app
REDIS_URL=redis://localhost:6379/0

# AI Provider (use Google Gemini for free tier)
GOOGLE_API_KEY=your-google-api-key

# Features
BYOK_ENABLED=true
LESSONS_ENABLED=true
TTS_ENABLED=true
COACH_ENABLED=true
ECHO_FALLBACK_ENABLED=false

# Email (get Resend API key)
EMAIL_PROVIDER=resend
RESEND_API_KEY=re_your_key_here
EMAIL_FROM_ADDRESS=noreply@yourapp.com
FRONTEND_URL=https://yourapp.netlify.app
"@ | Out-File -FilePath backend\.env -Encoding utf8

# Start database and Redis
docker compose up -d db redis

# Wait for database to be ready (check health)
docker ps  # Should show db as "healthy"

# Run migrations
conda activate ancient-languages-py312
cd backend
python -m alembic upgrade head

# Start backend
uvicorn app.main:app --host 0.0.0.0 --port 8000
```

#### Step 4: Run Cloudflare Tunnel

```powershell
# In a separate PowerShell window
.\cloudflared.exe tunnel run ancient-languages-backend
```

#### Step 5: Configure DNS in Cloudflare

1. Go to Cloudflare dashboard → DNS
2. Add CNAME record:
   - Name: `api` (or `backend`)
   - Target: `<TUNNEL_ID>.cfargotunnel.com`
   - Proxy status: Proxied (orange cloud)

**Result:** Your backend is now accessible at `https://api.yourapp.com`

#### Step 6: Deploy Frontend (See "Frontend Deployment" section)

---

## Option B: Hybrid (Free Services + Budget Cloud)

**Best For:** Public beta launch (50-200 users), credible for investors, minimal cost

**Pros:**
- Professional infrastructure
- Free database (Neon or Aiven)
- Low cost ($15-25/month)
- Automatic SSL, scaling, backups
- No need to keep PC on 24/7

**Cons:**
- Free tier limits (e.g., Neon: 3GB storage, shared compute)
- May need to upgrade as you grow

### Architecture

```
User Browser
    ↓ HTTPS
Netlify CDN (free) → Flutter Web App
    ↓ API calls
Railway/Render ($5-20/mo) → FastAPI Backend
    ↓ Database connection
Neon/Aiven (free) → PostgreSQL + pgvector
Railway Redis (included) → Cache
```

### Setup Checklist

#### Step 1: Set Up Free PostgreSQL (30 minutes)

**Option 1: Neon (Recommended)**

1. Go to [neon.tech](https://neon.tech)
2. Sign up (GitHub auth)
3. Create new project: "ancient-languages"
4. Select region closest to your backend (e.g., US East)
5. Copy connection string: `postgresql://user:pass@ep-xyz.us-east-2.aws.neon.tech/neondb`
6. Enable pgvector extension:
   ```sql
   CREATE EXTENSION IF NOT EXISTS vector;
   ```

**Free tier limits:**
- 3 GB storage
- Shared compute (1 GB RAM)
- Unlimited queries
- Auto-sleep after 5 minutes inactivity (wakes instantly on query)

**Option 2: Aiven**

1. Go to [aiven.io](https://aiven.io)
2. Sign up for free PostgreSQL plan
3. Select cloud provider + region
4. Enable pgvector in Extensions tab

#### Step 2: Deploy Backend to Railway (30 minutes)

**Railway** offers generous free tier and simple Docker deployment.

1. Go to [railway.app](https://railway.app)
2. Sign up (GitHub auth)
3. Click "New Project" → "Deploy from GitHub repo"
4. Connect your GitHub repo (you'll need to push your code to GitHub)
5. Railway auto-detects Dockerfile
6. Set environment variables in Railway dashboard:

```env
# Security
JWT_SECRET_KEY=<your-secret>
ENCRYPTION_KEY=<your-fernet-key>

# Database (from Neon)
DATABASE_URL=postgresql+asyncpg://user:pass@ep-xyz.us-east-2.aws.neon.tech/neondb

# Redis (Railway provides this automatically)
REDIS_URL=${{Redis.REDIS_URL}}

# AI Provider
GOOGLE_API_KEY=<your-google-key>

# Features
BYOK_ENABLED=true
LESSONS_ENABLED=true
TTS_ENABLED=true
COACH_ENABLED=true

# Email
EMAIL_PROVIDER=resend
RESEND_API_KEY=<your-resend-key>
EMAIL_FROM_ADDRESS=noreply@yourapp.com
FRONTEND_URL=https://yourapp.netlify.app

# Environment
ENVIRONMENT=production
```

7. Add Redis service: Click "New" → "Database" → "Add Redis"
8. Railway will auto-deploy on git push

**Alternative: Render**

1. Go to [render.com](https://render.com)
2. Similar setup to Railway
3. Free tier: 512MB RAM, auto-sleep after inactivity
4. Wakes on incoming requests (adds ~30s delay)

#### Step 3: Run Database Migrations

**From Railway dashboard:**

1. Go to your backend service
2. Click "Settings" → "Deploy"
3. Add custom start command:
   ```bash
   alembic upgrade head && uvicorn app.main:app --host 0.0.0.0 --port $PORT
   ```

**Or run manually:**

```bash
# Install Railway CLI
npm i -g @railway/cli

# Login
railway login

# Link project
railway link

# Run migration
railway run alembic upgrade head
```

#### Step 4: Deploy Frontend (See "Frontend Deployment" section)

### Cost Breakdown

| Service | Cost |
|---------|------|
| Neon PostgreSQL | FREE (3GB limit) |
| Railway Backend | $5-10/month (512MB RAM) |
| Railway Redis | Included |
| Netlify Frontend | FREE |
| Domain (Namecheap) | $10/year |
| Resend Email | FREE (3,000/month) |
| **TOTAL** | **$15-20/month** |

---

## Option C: Full Cloud (Scalable, Investor-Ready)

**Best For:** Post-funding, 200+ users, serious growth trajectory

**Pros:**
- Battle-tested infrastructure
- High availability (99.9% uptime SLAs)
- Auto-scaling
- Professional monitoring
- Investor credibility

**Cons:**
- Higher cost ($50-100/month minimum)
- More complex setup

### Architecture

```
User Browser
    ↓ HTTPS
Cloudflare CDN / Vercel
    ↓ API Gateway
DigitalOcean App Platform / AWS ECS
    ├── FastAPI Backend (autoscaling)
    ├── PostgreSQL Managed Database
    └── Redis Managed Cache
```

### Recommended Stack

**Option 1: DigitalOcean (Simplest)**

- App Platform: $12/month (1 GB RAM)
- Managed PostgreSQL: $15/month (1 GB RAM, 10 GB storage)
- Managed Redis: $15/month (256 MB)
- Total: ~$42/month

**Option 2: AWS (Most Scalable)**

- ECS Fargate: $20-30/month (0.5 vCPU, 1 GB RAM)
- RDS PostgreSQL: $30-40/month (db.t3.micro with pgvector)
- ElastiCache Redis: $15/month (cache.t3.micro)
- Total: ~$65-85/month

**Setup similar to Option B but with managed services from major cloud provider.**

---

## Frontend Deployment (All Options)

Your Flutter web build is already compiled at `client/flutter_reader/build/web/`. You just need to host static files.

### Option 1: Firebase Hosting (Recommended - FREE)

**Pros:** Fast CDN, free SSL, custom domain, 10GB/month free

**Steps:**

```bash
# Install Firebase CLI
npm install -g firebase-tools

# Login
firebase login

# Initialize Firebase in project root
cd c:/Dev/AI_Projects/AncientLanguagesAppDirs/Current-working-dirs/AncientLanguages
firebase init hosting

# When prompted:
# - Choose "Use existing project" or "Create new project"
# - Public directory: client/flutter_reader/build/web
# - Configure as single-page app: Yes
# - Set up automatic builds with GitHub: No (manual deploy for now)

# Deploy
firebase deploy --only hosting

# Get your URL: https://your-project.web.app
```

**Configure API endpoint in Flutter:**

File: `client/flutter_reader/lib/config/api_config.dart`

```dart
class ApiConfig {
  static const String baseUrl =
    kReleaseMode
      ? 'https://api.yourapp.com'  // Production backend URL
      : 'http://localhost:8000';    // Local development
}
```

**Rebuild after changing API config:**

```bash
cd client/flutter_reader
flutter build web --release
firebase deploy --only hosting
```

### Option 2: Netlify (Also FREE)

```bash
# Install Netlify CLI
npm install -g netlify-cli

# Login
netlify login

# Deploy
cd client/flutter_reader/build/web
netlify deploy --prod

# Follow prompts to create new site
# Get your URL: https://your-site.netlify.app
```

### Option 3: Vercel (Also FREE)

```bash
# Install Vercel CLI
npm install -g vercel

# Deploy
cd client/flutter_reader/build/web
vercel --prod
```

### Configure Custom Domain

**For Firebase Hosting:**

1. Firebase Console → Hosting → Add custom domain
2. Follow DNS setup instructions (add TXT record for verification, A/CNAME for routing)

**For Netlify:**

1. Netlify dashboard → Domain settings → Add custom domain
2. Update DNS to point to Netlify

**For Vercel:**

1. Vercel dashboard → Domains → Add domain
2. Update DNS

---

## Domain & SSL Setup

### Buy Domain (If you don't have one)

**Recommended registrars (cheapest):**
- [Porkbun](https://porkbun.com): $7-10/year (.com)
- [Namecheap](https://namecheap.com): $8-12/year (.com)
- [Cloudflare Registrar](https://cloudflare.com): At-cost pricing (~$9/year)

**Choose domain:**
- Short, memorable
- Easy to spell
- Examples: `ancientlang.app`, `learn-ancient.com`, `polyglossai.com`

### DNS Configuration

**Assuming you have:**
- Domain: `yourapp.com`
- Backend: Railway/Render/DigitalOcean
- Frontend: Firebase Hosting

**DNS Records:**

| Type | Name | Value | TTL |
|------|------|-------|-----|
| CNAME | `www` | `yourapp.web.app` (Firebase) | 3600 |
| CNAME | `api` | `yourapp.up.railway.app` (Backend) | 3600 |
| A | `@` | Redirect to `www` | 3600 |

**SSL:** Automatic via hosting platforms (Firebase, Netlify, Railway all provide free SSL)

---

## Pre-Launch Testing Checklist

### 1. Local Browser Testing (CRITICAL - Not Done Yet!)

**Start backend:**
```powershell
cd C:\Dev\AI_Projects\AncientLanguagesAppDirs\Current-working-dirs\AncientLanguages
conda activate ancient-languages-py312
docker compose up -d
cd backend
uvicorn app.main:app --reload
```

**Start frontend:**
```powershell
cd client/flutter_reader
flutter run -d web-server --web-port=3000
```

**Open:** http://localhost:3000

**Test ALL features:**

- [ ] User registration works
- [ ] Login works
- [ ] Logout works
- [ ] Lesson generation works (test 3+ languages)
- [ ] Text reader works (tap words, see morphology)
- [ ] Chat/Coach works
- [ ] TTS works (pronunciation audio)
- [ ] Gamification (XP, streaks, achievements)
- [ ] Settings page (API key input, preferences)
- [ ] Vocabulary review (SRS flashcards)
- [ ] Progress charts display correctly
- [ ] Mobile responsive (resize browser to phone width)

**Fix bugs found BEFORE deploying!**

### 2. Production Environment Testing

After deploying to cloud:

- [ ] Test from different devices (phone, tablet, desktop)
- [ ] Test from different browsers (Chrome, Firefox, Safari, Edge)
- [ ] Test from different networks (home WiFi, mobile data, coffee shop)
- [ ] Check page load speed (should be <3 seconds)
- [ ] Verify SSL certificate (HTTPS with green lock)
- [ ] Test API endpoints directly (use Postman or curl)

### 3. Load Testing (Optional but Recommended)

**Simulate 10-50 concurrent users:**

```bash
# Install k6
# Windows: choco install k6
# Or download from https://k6.io

# Create load test script: load_test.js
cat > load_test.js << 'EOF'
import http from 'k6/http';
import { check, sleep } from 'k6';

export let options = {
  vus: 10,  // 10 virtual users
  duration: '30s',
};

export default function() {
  let res = http.get('https://api.yourapp.com/health');
  check(res, { 'status is 200': (r) => r.status === 200 });
  sleep(1);
}
EOF

# Run test
k6 run load_test.js
```

**Expected results:**
- <200ms response time for /health endpoint
- 0% error rate
- Backend stays responsive

---

## Launch Day Checklist

### 24 Hours Before Launch

- [ ] All tests passing locally
- [ ] Production deployment successful
- [ ] DNS propagated (check with `nslookup yourapp.com`)
- [ ] SSL certificate working (visit `https://yourapp.com`)
- [ ] Monitoring set up (Sentry, LogRocket, or similar)
- [ ] Backup database (even if empty, test backup process)
- [ ] Email sending works (test password reset flow)
- [ ] Rate limiting active and tested
- [ ] Prepared launch message for Discord, social media

### Launch Hour

- [ ] Final smoke test (register, login, generate lesson, logout)
- [ ] Monitor logs in real-time (`railway logs -f` or equivalent)
- [ ] Have rollback plan ready (previous Docker image tagged)
- [ ] Share link with initial users
- [ ] Watch error monitoring dashboard

### First 24 Hours

- [ ] Monitor user registrations
- [ ] Watch for error spikes
- [ ] Check API costs (Google Cloud Console → Gemini usage)
- [ ] Respond to user feedback in Discord
- [ ] Fix critical bugs immediately, defer non-critical to sprint

---

## Post-Launch Monitoring

### Error Tracking (Set Up BEFORE Launch)

**Option 1: Sentry (Recommended - Free tier: 5k events/month)**

```bash
# Backend: Add to requirements
pip install sentry-sdk[fastapi]
```

File: `backend/app/main.py`

```python
import sentry_sdk

sentry_sdk.init(
    dsn="https://your-dsn@sentry.io/your-project",
    environment="production",
)
```

**Option 2: LogRocket (Session replay for debugging)**

Free tier: 1,000 sessions/month

### Monitoring Checklist

**Daily (First Week):**
- [ ] Check error rate (Sentry dashboard)
- [ ] Check API costs (Google Cloud Console)
- [ ] Check database size (Neon dashboard)
- [ ] Review user feedback
- [ ] Check uptime (UptimeRobot or similar)

**Weekly:**
- [ ] Review most common errors
- [ ] Analyze user retention (how many return?)
- [ ] Check quota usage (are users hitting limits?)
- [ ] Database performance (query slow logs)

**Metrics to Track:**
- Daily Active Users (DAU)
- Lesson generation count
- Average session duration
- API error rate (target: <1%)
- API response time (target: <500ms p95)
- User retention (Day 1, Day 7, Day 30)

---

## Recommended Path for Your Situation

**Given your constraints:**
- Investor meeting soon (need credible infrastructure)
- Limited budget (but willing to spend if needed)
- Have powerful PC and good internet
- Need to build userbase ASAP

### My Recommendation: **Hybrid Approach (Option B) with Fast Migration Path**

**Phase 1: Immediate Launch (Week 1)**

1. **Backend:** Railway ($5-10/month)
   - Professional URL (`api.yourapp.com`)
   - Auto-deploy on git push
   - Easy for demos

2. **Database:** Neon (FREE)
   - 3GB storage (enough for 500+ users)
   - pgvector supported
   - Auto-scaling

3. **Frontend:** Firebase Hosting (FREE)
   - Global CDN
   - Fast load times
   - Custom domain support

4. **Total Cost:** $15-20/month + $10/year domain = **~$17/month**

**Phase 2: After Securing Users (Week 2-4)**

If you hit 100+ daily active users or 50% of free tier limits:

1. Upgrade Neon to paid ($25/month for 10GB)
2. OR migrate to managed PostgreSQL (DigitalOcean: $15/month)

**Phase 3: After Funding (Month 2+)**

Migrate to full cloud (Option C):
- DigitalOcean App Platform (~$42/month)
- OR AWS with RDS (~$65/month)
- Add monitoring, backups, staging environment

### Timeline Estimate

**Day 1:**
- Set up Neon database (30 min)
- Deploy to Railway (1 hour)
- Run migrations (15 min)
- **Total: 2 hours**

**Day 2:**
- Deploy frontend to Firebase (30 min)
- Configure custom domain (30 min)
- Test all features in production (2 hours)
- **Total: 3 hours**

**Day 3-4:**
- Fix bugs found in testing (4-8 hours)
- Implement rate limiting (2-4 hours)
- **Total: 6-12 hours**

**Day 5:**
- Final smoke test (1 hour)
- Prepare launch materials (1 hour)
- **LAUNCH**

**Total: 3-5 days to production web app**

---

## Quick Start Commands

### Deploy to Railway (Fastest Path)

```bash
# 1. Push code to GitHub
cd C:\Dev\AI_Projects\AncientLanguagesAppDirs\Current-working-dirs\AncientLanguages
git add .
git commit -m "feat: Prepare for Railway deployment"
git push origin main

# 2. Go to railway.app → New Project → Deploy from GitHub
# 3. Select your repo
# 4. Railway auto-detects Dockerfile
# 5. Set environment variables (see Option B checklist)
# 6. Deploy!
```

### Deploy Frontend to Firebase (Fastest Path)

```bash
# 1. Install Firebase CLI
npm install -g firebase-tools

# 2. Login
firebase login

# 3. Initialize
cd C:\Dev\AI_Projects\AncientLanguagesAppDirs\Current-working-dirs\AncientLanguages
firebase init hosting
# Public directory: client/flutter_reader/build/web
# Single-page app: Yes

# 4. Deploy
firebase deploy --only hosting

# Done! Your app is live at https://your-project.web.app
```

---

## Cost Summary (First 3 Months)

### Option B (Recommended)

| Month | Backend (Railway) | Database (Neon) | Frontend (Firebase) | Domain | Email (Resend) | **Total** |
|-------|------------------|-----------------|---------------------|--------|----------------|-----------|
| 1 | $10 | FREE | FREE | $10/year ≈ $1 | FREE | **$11** |
| 2 | $10 | FREE | FREE | - | FREE | **$10** |
| 3 | $10 | FREE | FREE | - | FREE | **$10** |

**3-Month Total: $31** (less than one month of Netflix!)

### When to Upgrade

**Upgrade to paid database when:**
- 3GB storage used (Neon limit)
- 50+ concurrent users regularly
- Database queries slow (need dedicated compute)

**Upgrade to Option C when:**
- 200+ daily active users
- $500+ monthly revenue
- Secured funding
- Need SLA guarantees

---

## Red Flags to Avoid

### DON'T:

1. **Don't deploy without HTTPS** (users won't trust your app)
2. **Don't use default JWT_SECRET_KEY** (critical security risk)
3. **Don't skip rate limiting** (one user could cost you $100s in API fees)
4. **Don't deploy without testing in browser first** (you'll find bugs in production)
5. **Don't use your personal email for `EMAIL_FROM_ADDRESS`** (will go to spam)
6. **Don't commit API keys to git** (they'll be scraped by bots)
7. **Don't skip database backups** (Neon auto-backups, but test restore process)

### DO:

1. **Test locally first** (catch 90% of bugs before deployment)
2. **Set up error monitoring** (Sentry) before launch
3. **Monitor API costs daily** (first week)
4. **Have a rollback plan** (previous Docker image)
5. **Prepare user communication** (Discord, email)
6. **Document deployment process** (for future you)

---

## Next Steps

1. **Decide on deployment strategy** (Recommendation: Option B - Hybrid)
2. **Create accounts:**
   - [ ] Neon (database)
   - [ ] Railway (backend)
   - [ ] Firebase (frontend)
   - [ ] Resend (email)
   - [ ] Namecheap (domain)
3. **Generate production secrets** (JWT, encryption key)
4. **Test app locally in browser** (fix bugs found)
5. **Deploy backend to Railway**
6. **Deploy frontend to Firebase**
7. **Configure custom domain**
8. **Implement rate limiting**
9. **Final production testing**
10. **LAUNCH!**

---

## Questions? Concerns?

**If you're stuck on:**
- **Which option to choose:** Option B (Hybrid) - best balance for your situation
- **Database setup:** Use Neon (free, pgvector supported, 3GB enough for beta)
- **Backend hosting:** Use Railway ($5-10/month, easy Docker deploy)
- **Frontend hosting:** Use Firebase (free, fast CDN, custom domain)
- **Cost concerns:** Total is ~$15-20/month for 50-200 users

**Your Next Message Should Be:**
"Let's start with Option B. Set up Neon database and deploy to Railway."

**And I'll guide you through each step with exact commands!**

---

**Last Updated:** October 21, 2025
**Author:** Claude (with human review)
**Status:** READY FOR IMPLEMENTATION
