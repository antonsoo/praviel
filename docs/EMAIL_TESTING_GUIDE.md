# Email System Testing Guide

**Complete guide to testing all email features in PRAVIEL.**

---

## Table of Contents

1. [Setup](#setup)
2. [Testing Transactional Emails](#testing-transactional-emails)
3. [Testing Marketing Emails](#testing-marketing-emails)
4. [Testing Email Preferences](#testing-email-preferences)
5. [Testing Automated Campaigns](#testing-automated-campaigns)
6. [Testing Email Scheduler](#testing-email-scheduler)
7. [Manual Testing Checklist](#manual-testing-checklist)
8. [Troubleshooting](#troubleshooting)

---

## Setup

### 1. Install Dependencies

```bash
cd backend
pip install -e ".[dev]"
pip install apscheduler  # Required for email scheduler
```

### 2. Configure Environment

Ensure your `backend/.env` has:

```bash
# Email Configuration
EMAIL_PROVIDER=resend
EMAIL_FROM_ADDRESS=noreply@praviel.com
EMAIL_FROM_NAME=PRAVIEL
FRONTEND_URL=http://localhost:8080
RESEND_API_KEY=re_your_api_key_here

# Marketing Emails
MARKETING_FROM_ADDRESS=marketing@praviel.com
MARKETING_FROM_NAME=PRAVIEL Team
```

### 3. Run Database Migrations

```bash
# Activate conda environment
conda activate praviel

# Apply email system migrations
cd backend
python -m alembic upgrade head
```

### 4. Start the Server

```bash
uvicorn app.main:app --reload
```

You should see:
```
INFO:     Starting email scheduler...
INFO:     Email scheduler started successfully
INFO:     Registered streak reminder jobs (16:00-21:00)
INFO:     Registered SRS reminder jobs (07:00-11:00)
INFO:     Registered weekly digest job (Mondays 09:00)
INFO:     Registered onboarding job (daily 10:00)
INFO:     Registered re-engagement job (daily 11:00)
```

---

## Testing Transactional Emails

### Test 1: Email Verification

**Test new user registration sends verification email:**

```bash
# Register a new user
curl -X POST http://localhost:8000/api/v1/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "username": "testuser",
    "email": "your-email@example.com",
    "password": "SecurePassword123!"
  }'
```

**Expected:**
- ✅ User created successfully
- ✅ Verification email sent to `your-email@example.com`
- ✅ Email contains verification link
- ✅ Link format: `http://localhost:8080/verify-email?token=...`

**Verify the email:**

1. Check your inbox for verification email
2. Copy the token from the link
3. Verify:

```bash
curl -X POST http://localhost:8000/api/v1/auth/email/verify \
  -H "Content-Type: application/json" \
  -d '{
    "token": "paste-token-here"
  }'
```

**Expected:**
- ✅ Response: `{"message": "Email verified successfully"}`
- ✅ User's `email_verified` field set to `true` in database

**Check verification status:**

```bash
# Get access token first
TOKEN=$(curl -X POST http://localhost:8000/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "username_or_email": "testuser",
    "password": "SecurePassword123!"
  }' | jq -r '.access_token')

# Check status
curl -X GET http://localhost:8000/api/v1/auth/email/status \
  -H "Authorization: Bearer $TOKEN"
```

**Expected:**
```json
{
  "email_verified": true
}
```

---

### Test 2: Password Reset Email

**Test password reset flow:**

```bash
# Request password reset
curl -X POST http://localhost:8000/api/v1/auth/password-reset/request \
  -H "Content-Type: application/json" \
  -d '{
    "email": "your-email@example.com"
  }'
```

**Expected:**
- ✅ Response: `{"message": "If that email exists, a reset link has been sent"}`
- ✅ Password reset email sent
- ✅ Email contains reset link with 15-minute expiration notice

**Complete reset:**

1. Check inbox for reset email
2. Copy token from link
3. Reset password:

```bash
curl -X POST http://localhost:8000/api/v1/auth/password-reset/confirm \
  -H "Content-Type: application/json" \
  -d '{
    "token": "paste-token-here",
    "new_password": "NewSecurePassword123!"
  }'
```

**Expected:**
- ✅ Password changed successfully
- ✅ Can log in with new password

---

### Test 3: Password Changed Notification

**Test password change sends security notification:**

```bash
# Change password (as authenticated user)
curl -X POST http://localhost:8000/api/v1/auth/change-password \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "old_password": "CurrentPassword123!",
    "new_password": "NewPassword456!"
  }'
```

**Expected:**
- ✅ Password changed successfully
- ✅ Security notification email sent
- ✅ Email warns user about password change
- ✅ Email includes support link if change was unauthorized

---

## Testing Marketing Emails

### Test 4: Create Audience and Contacts

**Test marketing service initialization:**

Run the test script:

```bash
cd backend
python scripts/test_email_marketing.py
```

**Follow interactive prompts:**
1. ✅ Service initializes successfully
2. ✅ Lists existing audiences
3. ✅ Creates test audience
4. ✅ Adds test contact (enter your email)
5. ✅ Creates broadcast draft

**Expected output:**
```
✅ Email Marketing Service initialized
✅ Created test audience: 78261eea-...
✅ Added contact: 479e3145-...
✅ Created test broadcast (draft): 49a3999c-...
```

---

### Test 5: Send Test Broadcast

**Send the test broadcast created in Test 4:**

```python
# In Python shell or script
import asyncio
from app.services.email_marketing import create_email_marketing_service
from app.core.config import settings

async def test_broadcast():
    service = create_email_marketing_service(api_key=settings.RESEND_API_KEY)

    # Use broadcast ID from Test 4
    broadcast_id = "49a3999c-..."

    await service.send_broadcast(broadcast_id)
    print(f"Sent broadcast: {broadcast_id}")

asyncio.run(test_broadcast())
```

**Expected:**
- ✅ Broadcast sent successfully
- ✅ Email received at test contact address
- ✅ Personalization works (`{{{FIRST_NAME}}}` replaced)
- ✅ Unsubscribe link present and functional

---

## Testing Email Preferences

### Test 6: Get Email Preferences

**Test getting current preferences:**

```bash
# Get preferences (requires authentication)
curl -X GET http://localhost:8000/api/v1/user/email-preferences \
  -H "Authorization: Bearer $TOKEN"
```

**Expected response:**
```json
{
  "email_streak_reminders": true,
  "email_srs_reminders": true,
  "email_achievement_notifications": true,
  "email_weekly_digest": true,
  "email_onboarding_series": true,
  "email_new_content_alerts": false,
  "email_social_notifications": false,
  "email_re_engagement": true,
  "srs_reminder_time": 9,
  "streak_reminder_time": 18
}
```

---

### Test 7: Update Email Preferences

**Test updating specific preferences:**

```bash
# Disable streak reminders
curl -X PATCH http://localhost:8000/api/v1/user/email-preferences \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "email_streak_reminders": false
  }'
```

**Expected:**
- ✅ Preference updated
- ✅ Response includes updated preferences
- ✅ User will no longer receive streak reminder emails

**Test changing reminder time:**

```bash
# Change SRS reminder to 8 AM
curl -X PATCH http://localhost:8000/api/v1/user/email-preferences \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "srs_reminder_time": 8
  }'
```

**Expected:**
- ✅ Reminder time updated to 8 (08:00 AM)
- ✅ User will receive SRS reminders at 8 AM

---

### Test 8: Bulk Update Preferences

**Test disabling all reminders:**

```bash
curl -X POST http://localhost:8000/api/v1/user/email-preferences/bulk-update \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "category": "reminders",
    "enabled": false
  }'
```

**Expected:**
- ✅ All reminder preferences disabled:
  - `email_streak_reminders`: false
  - `email_srs_reminders`: false

**Test disabling all emails:**

```bash
curl -X POST http://localhost:8000/api/v1/user/email-preferences/disable-all \
  -H "Authorization: Bearer $TOKEN"
```

**Expected:**
- ✅ All optional email preferences disabled
- ✅ Only critical emails (verification, password reset) will be sent

---

## Testing Automated Campaigns

### Test 9: Streak Reminder Email

**Setup:**

1. Create user with active streak
2. Ensure user hasn't met daily XP goal yet
3. Set `streak_reminder_time` to current hour

**Manually trigger:**

```python
import asyncio
from app.jobs.email_jobs import send_streak_reminders

async def test_streak():
    result = await send_streak_reminders(hour=18)  # 6 PM
    print(f"Streak reminders sent: {result}")

asyncio.run(test_streak())
```

**Expected:**
```
{
  "eligible_users": 10,
  "emails_sent": 10,
  "errors": 0
}
```

**Verify email:**
- ✅ Subject: "Don't break your X-day streak!"
- ✅ Contains streak count
- ✅ Contains XP needed to maintain streak
- ✅ Includes CTA to continue learning

---

### Test 10: SRS Review Reminder

**Setup:**

1. Create user with SRS cards due
2. Set `srs_reminder_time` to current hour

**Manually trigger:**

```python
import asyncio
from app.jobs.email_jobs import send_srs_review_reminders

async def test_srs():
    result = await send_srs_review_reminders(hour=9)  # 9 AM
    print(f"SRS reminders sent: {result}")

asyncio.run(test_srs())
```

**Expected:**
```
{
  "eligible_users": 5,
  "emails_sent": 5,
  "errors": 0
}
```

**Verify email:**
- ✅ Subject: "X cards ready for review"
- ✅ Contains number of cards due
- ✅ Estimates review time
- ✅ Includes link to SRS review page

---

### Test 11: Weekly Digest

**Setup:**

1. Create user with activity in past week
2. Wait for Monday 9:00 AM OR manually trigger

**Manually trigger:**

```python
import asyncio
from app.jobs.email_jobs import send_weekly_digest

async def test_digest():
    result = await send_weekly_digest()
    print(f"Weekly digests sent: {result}")

asyncio.run(test_digest())
```

**Expected:**
```
{
  "eligible_users": 20,
  "emails_sent": 20,
  "errors": 0
}
```

**Verify email:**
- ✅ Subject: "Your week in PRAVIEL"
- ✅ Contains weekly stats (XP, lessons, streak)
- ✅ Contains weekly goals for next week
- ✅ Shows top language studied

---

### Test 12: Onboarding Sequence

**Setup:**

1. Register new user
2. Wait 1 day (or adjust `created_at` in database)

**Manually trigger:**

```python
import asyncio
from app.jobs.email_jobs import send_onboarding_emails

async def test_onboarding():
    result = await send_onboarding_emails()
    print(f"Onboarding emails sent: {result}")

asyncio.run(test_onboarding())
```

**Expected:**
- **Day 1**: Welcome email with getting started guide
- **Day 3**: Pro learning tips (SRS, reading techniques)
- **Day 7**: First week complete, celebrate progress

**Verify Day 1 email:**
- ✅ Subject: "Welcome to PRAVIEL!"
- ✅ Contains quick start guide
- ✅ Links to first lesson

---

### Test 13: Re-engagement Campaign

**Setup:**

1. Create user inactive for 7/14/30 days
2. Manually adjust `last_activity_at` in database if needed

**Manually trigger:**

```python
import asyncio
from app.jobs.email_jobs import send_re_engagement_emails

async def test_re_engagement():
    result = await send_re_engagement_emails()
    print(f"Re-engagement emails sent: {result}")

asyncio.run(test_re_engagement())
```

**Expected:**
- **7 days**: "We miss you!" gentle reminder
- **14 days**: "Your progress is waiting" with stats
- **30 days**: "What's new in PRAVIEL" with recent features

---

### Test 14: Achievement Notification

**Test achievement unlock sends email:**

```bash
# Unlock achievement
curl -X POST http://localhost:8000/api/v1/gamification/users/1/achievements/first_lesson/unlock \
  -H "Authorization: Bearer $TOKEN"
```

**Expected:**
- ✅ Achievement unlocked
- ✅ Email sent within seconds
- ✅ Email subject: "Achievement Unlocked: [Achievement Title]"
- ✅ Email contains achievement icon, description, rarity
- ✅ Email includes XP reward

---

## Testing Email Scheduler

### Test 15: Verify Scheduler Status

**Check scheduler jobs:**

```python
from app.jobs.scheduler import email_scheduler

jobs = email_scheduler.get_jobs()
for job in jobs:
    print(f"{job['name']}: Next run at {job['next_run_time']}")
```

**Expected output:**
```
Streak Reminder - Hour 16: 2025-10-25T16:00:00
Streak Reminder - Hour 17: 2025-10-25T17:00:00
...
SRS Review Reminder - Hour 7: 2025-10-26T07:00:00
...
Weekly Progress Digest: 2025-10-27T09:00:00
Onboarding Email Sequence: 2025-10-25T10:00:00
Re-engagement Campaign: 2025-10-25T11:00:00
```

**Verify:**
- ✅ All jobs registered
- ✅ Next run times are correct
- ✅ No duplicate jobs

---

### Test 16: Scheduler Startup/Shutdown

**Test scheduler lifecycle:**

```bash
# Start server
uvicorn app.main:app --reload
```

**Check logs:**
```
INFO:     Starting email scheduler...
INFO:     Registered streak reminder jobs (16:00-21:00)
INFO:     Registered SRS reminder jobs (07:00-11:00)
INFO:     Registered weekly digest job (Mondays 09:00)
INFO:     Registered onboarding job (daily 10:00)
INFO:     Registered re-engagement job (daily 11:00)
INFO:     Email scheduler started successfully
```

**Stop server (Ctrl+C):**
```
INFO:     Stopping email scheduler...
INFO:     Email scheduler stopped
```

**Expected:**
- ✅ Scheduler starts cleanly
- ✅ All jobs registered
- ✅ Scheduler stops cleanly on shutdown

---

## Manual Testing Checklist

### Email Delivery

- [ ] Emails arrive in inbox (not spam)
- [ ] Subject lines are descriptive
- [ ] HTML rendering looks correct
- [ ] Plain text fallback works
- [ ] Links are clickable and work
- [ ] Personalization variables replaced (`{{{FIRST_NAME}}}`)
- [ ] Unsubscribe link works (marketing emails)

### Email Preferences

- [ ] Can view current preferences
- [ ] Can update individual preferences
- [ ] Can bulk disable categories
- [ ] Can disable all emails
- [ ] Preferences are respected (disabled emails not sent)
- [ ] Reminder times are honored

### Transactional Emails

- [ ] Registration sends verification email
- [ ] Verification link works and expires after 24 hours
- [ ] Password reset sends reset email
- [ ] Reset link works and expires after 15 minutes
- [ ] Password change sends security notification

### Marketing Emails

- [ ] Can create audiences
- [ ] Can add contacts to audiences
- [ ] Can create broadcasts
- [ ] Can send broadcasts
- [ ] Unsubscribe link works
- [ ] Personalization works

### Automated Campaigns

- [ ] Streak reminders sent at correct time
- [ ] SRS reminders sent at correct time
- [ ] Weekly digest sent on Mondays
- [ ] Onboarding emails sent on Day 1, 3, 7
- [ ] Re-engagement emails sent at 7, 14, 30 days
- [ ] Achievement notifications sent immediately

### Scheduler

- [ ] Scheduler starts on app startup
- [ ] All jobs registered
- [ ] Jobs run at correct times
- [ ] Scheduler stops cleanly on shutdown

---

## Troubleshooting

### Email Not Sent

**Check logs:**
```bash
# View uvicorn logs
tail -f uvicorn.log | grep -i email
```

**Common issues:**
- ❌ `RESEND_API_KEY` not configured → Check `.env`
- ❌ User email not verified → Reminder emails require verified email
- ❌ Email preferences disabled → Check user preferences
- ❌ Resend API error → Check API key validity

---

### Scheduler Not Running

**Check APScheduler installed:**
```bash
pip show apscheduler
```

**If not installed:**
```bash
pip install apscheduler
```

**Check startup logs:**
```
INFO:     Starting email scheduler...
```

**If missing:**
- ❌ APScheduler import failed → Install dependency
- ❌ Scheduler exception → Check error logs

---

### Verification Email Not Working

**Check token expiration:**
```sql
SELECT * FROM email_verification_token
WHERE user_id = 1
ORDER BY created_at DESC;
```

**If expired:**
- ✅ Request new verification email:
```bash
curl -X POST http://localhost:8000/api/v1/auth/email/send-verification \
  -H "Authorization: Bearer $TOKEN"
```

---

### Marketing Emails Going to Spam

**Check:**
1. ✅ SPF/DKIM/DMARC configured on praviel.com
2. ✅ Sender reputation (check Resend dashboard)
3. ✅ Unsubscribe link present in email
4. ✅ Email content not spammy (avoid ALL CAPS, excessive punctuation)

**Improve deliverability:**
- Use consistent sender address
- Include physical mailing address
- Test subject lines (avoid spam triggers)
- Warm up new sender addresses gradually

---

### Database Migration Errors

**If migration fails:**

```bash
# Rollback one revision
alembic downgrade -1

# Check current revision
alembic current

# Re-apply migration
alembic upgrade head
```

**If tables missing:**
```bash
# Check if tables exist
psql -U postgres -d ancient_languages -c "\dt user*"
```

---

## Testing Automation

### Create Test Script

Create `backend/scripts/test_all_emails.py`:

```python
"""Automated test script for all email features."""

import asyncio
from app.jobs.email_jobs import (
    send_streak_reminders,
    send_srs_review_reminders,
    send_weekly_digest,
    send_onboarding_emails,
    send_re_engagement_emails,
)

async def test_all():
    print("Testing all email campaigns...")

    print("\n1. Streak reminders...")
    result = await send_streak_reminders(hour=18)
    print(f"   ✅ {result}")

    print("\n2. SRS reminders...")
    result = await send_srs_review_reminders(hour=9)
    print(f"   ✅ {result}")

    print("\n3. Weekly digest...")
    result = await send_weekly_digest()
    print(f"   ✅ {result}")

    print("\n4. Onboarding emails...")
    result = await send_onboarding_emails()
    print(f"   ✅ {result}")

    print("\n5. Re-engagement emails...")
    result = await send_re_engagement_emails()
    print(f"   ✅ {result}")

    print("\n✅ All tests complete!")

if __name__ == "__main__":
    asyncio.run(test_all())
```

**Run tests:**
```bash
cd backend
python scripts/test_all_emails.py
```

---

## Next Steps

After testing:

1. ✅ Verify all emails render correctly in multiple clients (Gmail, Outlook, Apple Mail)
2. ✅ Test on mobile devices
3. ✅ Monitor Resend dashboard for delivery rates
4. ✅ Set up email analytics tracking
5. ✅ Create A/B tests for subject lines
6. ✅ Monitor unsubscribe rates
7. ✅ Gather user feedback on email frequency

---

## Resources

- **Email Marketing Guide**: [docs/EMAIL_MARKETING.md](EMAIL_MARKETING.md)
- **Email Services Guide**: [docs/EMAIL_SERVICES_GUIDE.md](EMAIL_SERVICES_GUIDE.md)
- **Email Types Recommendations**: [docs/EMAIL_TYPES_RECOMMENDATIONS.md](EMAIL_TYPES_RECOMMENDATIONS.md)
- **Resend Dashboard**: https://resend.com/emails
- **Resend API Docs**: https://resend.com/docs

---

**Last Updated**: 2025-10-25
**Author**: PRAVIEL Email System
