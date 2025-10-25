# Email Address Setup Guide

**Complete guide for setting up and managing PRAVIEL email forwarding addresses on Resend.**

---

## Overview

PRAVIEL uses multiple email addresses for different purposes. This guide explains which addresses to create and how to configure them on Resend.com.

---

## Required Email Addresses

### High Priority (Create Immediately)

These addresses are actively used by the application:

#### 1. `noreply@praviel.com`
- **Purpose**: Transactional emails (verification, password resets)
- **Used by**: `EmailService`
- **Volume**: Medium (triggered by user actions)
- **Forward to**: No forwarding needed (send-only)
- **Status**: ✅ Already created

#### 2. `admin@praviel.com`
- **Purpose**: System administrator contact
- **Used by**: Documentation, error reports
- **Volume**: Low
- **Forward to**: Your primary email
- **Status**: ✅ Already created

#### 3. `support@praviel.com`
- **Purpose**: User support inquiries
- **Used by**: Help links, documentation
- **Volume**: Medium
- **Forward to**: Your support inbox
- **Status**: ✅ Already created

#### 4. `verify@praviel.com` 🆕
- **Purpose**: Email verification emails
- **Used by**: User registration flow
- **Volume**: High (every new user)
- **Forward to**: No forwarding needed (send-only)
- **Configuration**: Update `.env` to use this for verification emails

#### 5. `reminders@praviel.com` 🆕
- **Purpose**: Streak and SRS reminder emails
- **Used by**: Automated cron jobs
- **Volume**: Very high (daily reminders)
- **Forward to**: No forwarding needed (send-only)
- **Configuration**: Use for automated reminder campaigns

#### 6. `achievements@praviel.com` 🆕
- **Purpose**: Achievement unlock notifications
- **Used by**: Gamification system
- **Volume**: Medium (triggered by achievements)
- **Forward to**: No forwarding needed (send-only)
- **Configuration**: Use for achievement emails

---

### Medium Priority (Create Soon)

These addresses enhance the user experience:

#### 7. `progress@praviel.com` 🆕
- **Purpose**: Weekly progress digest emails
- **Used by**: Weekly digest cron job
- **Volume**: Medium (weekly sends)
- **Forward to**: No forwarding needed (send-only)

#### 8. `welcome@praviel.com` 🆕
- **Purpose**: Onboarding email sequence
- **Used by**: Onboarding cron job
- **Volume**: Medium (new users)
- **Forward to**: No forwarding needed (send-only)

#### 9. `community@praviel.com` 🆕
- **Purpose**: Social features, friend requests, onboarding
- **Used by**: Social notifications
- **Volume**: Low-Medium
- **Forward to**: Your community manager email (if any)

#### 10. `marketing@praviel.com`
- **Purpose**: Marketing campaigns, newsletters
- **Used by**: `EmailMarketingService` broadcasts
- **Volume**: Low (manual campaigns)
- **Forward to**: Your marketing inbox
- **Status**: Should be created for marketing emails

---

### Lower Priority (Optional)

These addresses are used in documentation but don't send automated emails:

#### 11. `business@praviel.com`
- **Purpose**: Business inquiries, partnerships
- **Used by**: Documentation, terms of service
- **Volume**: Very low
- **Forward to**: Your business email
- **Status**: ✅ Already created

#### 12. `billing@praviel.com`
- **Purpose**: Billing and payment inquiries
- **Used by**: Terms documentation
- **Volume**: Very low
- **Forward to**: Your billing email
- **Status**: ✅ Already created

#### 13. `help@praviel.com`
- **Purpose**: General help inquiries
- **Used by**: Documentation
- **Volume**: Low
- **Forward to**: Same as `support@praviel.com`
- **Status**: ✅ Already created

#### 14. `antonsoloviev@praviel.com`
- **Purpose**: Personal contact for Anton
- **Used by**: Documentation
- **Volume**: Very low
- **Forward to**: Your personal email
- **Status**: ✅ Already created

#### 15. `anton@praviel.com`
- **Purpose**: Short alias for Anton
- **Used by**: Quick contact
- **Volume**: Very low
- **Forward to**: Same as `antonsoloviev@praviel.com`
- **Status**: ✅ Already created

---

## How to Create Email Addresses on Resend

### Step 1: Access Resend Dashboard

1. Go to https://resend.com/emails
2. Log in to your account
3. Navigate to **Domains** → **praviel.com**

### Step 2: Add Email Address

1. Click **Add Email Address** or **Configure**
2. Choose **Forwarding Address** option
3. Enter the local part (e.g., `reminders`)
4. Select domain: `praviel.com`
5. Configure forwarding (if needed):
   - For send-only addresses: Leave forwarding blank
   - For forwarded addresses: Enter your email

### Step 3: Verify Email (if forwarding)

If you configured forwarding:
1. Check your inbox for verification email
2. Click verification link
3. Wait for verification confirmation

### Step 4: Test Sending

Test the new address works:

```bash
# Using Resend API
curl -X POST https://api.resend.com/emails \
  -H "Authorization: Bearer re_your_api_key" \
  -H "Content-Type: application/json" \
  -d '{
    "from": "reminders@praviel.com",
    "to": "your-test-email@example.com",
    "subject": "Test Email",
    "html": "<p>Testing reminders@praviel.com</p>"
  }'
```

---

## Email Address Configuration in Code

### Update `.env` File

After creating the email addresses, update your `backend/.env`:

```bash
# Transactional Emails
EMAIL_FROM_ADDRESS=noreply@praviel.com
EMAIL_FROM_NAME=PRAVIEL

# Marketing Emails
MARKETING_FROM_ADDRESS=marketing@praviel.com
MARKETING_FROM_NAME=PRAVIEL Team
```

### Configure Specific Sender Addresses

For different email types, update the email templates or job functions:

**Example: Use `verify@praviel.com` for verification emails**

In `backend/app/api/routers/email_verification.py`:

```python
# Update from_address for verification emails
email_service = create_email_service(
    provider=settings.EMAIL_PROVIDER,
    resend_api_key=settings.RESEND_API_KEY,
    from_address="verify@praviel.com",  # ← Use verify@
    from_name="PRAVIEL Verification",
)
```

**Example: Use `reminders@praviel.com` for streak reminders**

In `backend/app/jobs/email_jobs.py`:

```python
# Update from_address for reminders
email_service = create_email_service(
    provider=settings.EMAIL_PROVIDER,
    resend_api_key=settings.RESEND_API_KEY,
    from_address="reminders@praviel.com",  # ← Use reminders@
    from_name="PRAVIEL Reminders",
)
```

**Example: Use `achievements@praviel.com` for achievement notifications**

In `backend/app/jobs/email_jobs.py`:

```python
# In send_achievement_notification function
email_service = create_email_service(
    provider=settings.EMAIL_PROVIDER,
    resend_api_key=settings.RESEND_API_KEY,
    from_address="achievements@praviel.com",  # ← Use achievements@
    from_name="PRAVIEL Achievements",
)
```

---

## Recommended Sender Configuration

### Email Type → Sender Address Mapping

| Email Type | From Address | From Name | Priority |
|------------|--------------|-----------|----------|
| Email Verification | `verify@praviel.com` | PRAVIEL Verification | High |
| Password Reset | `noreply@praviel.com` | PRAVIEL Security | High |
| Password Changed | `noreply@praviel.com` | PRAVIEL Security | High |
| Streak Reminders | `reminders@praviel.com` | PRAVIEL Reminders | High |
| SRS Reminders | `reminders@praviel.com` | PRAVIEL Reminders | High |
| Achievement Notifications | `achievements@praviel.com` | PRAVIEL Achievements | High |
| Weekly Progress Digest | `progress@praviel.com` | PRAVIEL Progress | Medium |
| Onboarding Day 1 | `welcome@praviel.com` | PRAVIEL Team | Medium |
| Onboarding Day 3 | `welcome@praviel.com` | PRAVIEL Team | Medium |
| Onboarding Day 7 | `welcome@praviel.com` | PRAVIEL Team | Medium |
| Re-engagement | `community@praviel.com` | PRAVIEL Team | Medium |
| Marketing Broadcasts | `marketing@praviel.com` | PRAVIEL Team | Low |

---

## Email Forwarding Strategy

### Send-Only Addresses

These addresses **should NOT forward** (used only for sending):

- ✅ `noreply@praviel.com` (already configured)
- ✅ `verify@praviel.com` (create as send-only)
- ✅ `reminders@praviel.com` (create as send-only)
- ✅ `achievements@praviel.com` (create as send-only)
- ✅ `progress@praviel.com` (create as send-only)
- ✅ `welcome@praviel.com` (create as send-only)

**Why?** These addresses are automated and users shouldn't reply to them.

### Forwarded Addresses

These addresses **should forward to your inbox** (for receiving):

- ✅ `support@praviel.com` → Your support inbox
- ✅ `business@praviel.com` → Your business email
- ✅ `billing@praviel.com` → Your billing email
- ✅ `help@praviel.com` → Same as support@
- ✅ `admin@praviel.com` → Your admin email
- ✅ `community@praviel.com` → Your community manager email (optional)
- ✅ `marketing@praviel.com` → Your marketing email (optional)
- ✅ `anton@praviel.com` → Your personal email
- ✅ `antonsoloviev@praviel.com` → Your personal email

**Why?** These addresses receive user inquiries that need human responses.

---

## SPF/DKIM/DMARC Configuration

### Already Configured ✅

Based on your DNS export, praviel.com already has:

**SPF Record:**
```
v=spf1 include:_spf.mx.cloudflare.net include:_spf.resend.com ~all
```

**DKIM Record:**
```
resend._domainkey.praviel.com → [CNAME to Resend]
```

**DMARC Record:**
```
_dmarc.praviel.com → "v=DMARC1; p=none; ..."
```

**No additional configuration needed!** ✅

---

## Testing Email Addresses

### Test Send-Only Address

```bash
# Test reminders@praviel.com
curl -X POST https://api.resend.com/emails \
  -H "Authorization: Bearer $RESEND_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "from": "PRAVIEL Reminders <reminders@praviel.com>",
    "to": "your-test-email@example.com",
    "subject": "Test Reminder",
    "html": "<p>Testing reminders@praviel.com</p>"
  }'
```

### Test Forwarded Address

1. Send email to forwarded address (e.g., `support@praviel.com`)
2. Check your forwarding inbox
3. Verify email arrives correctly

---

## Maintenance

### Monthly Checks

- [ ] Check Resend dashboard for bounce rates
- [ ] Review unsubscribe rates for marketing emails
- [ ] Verify SPF/DKIM/DMARC still passing
- [ ] Check email deliverability scores

### Quarterly Reviews

- [ ] Review email forwarding rules
- [ ] Update sender addresses if needed
- [ ] Check for new email types to add
- [ ] Review email volume and adjust rate limits

---

## Troubleshooting

### Email Not Sending

**Check Resend Dashboard:**
1. Go to https://resend.com/emails
2. Look for error messages
3. Check API key permissions

**Common Issues:**
- ❌ Address not verified → Verify in Resend dashboard
- ❌ SPF/DKIM failing → Check DNS records
- ❌ Rate limit exceeded → Upgrade Resend plan

### Forwarding Not Working

**Check Verification:**
1. Go to Resend dashboard
2. Check forwarding address status
3. Resend verification email if needed

**Check Spam Folder:**
- Forwarded emails might land in spam initially
- Mark as "Not Spam" to train filter

---

## Resend Plan Considerations

### Free Plan Limits

- **Emails/month**: 3,000
- **Emails/day**: 100
- **Contacts**: Unlimited
- **Audiences**: Unlimited

### If You Exceed Limits

Consider upgrading to paid plan:
- **Pro Plan**: $20/month, 50,000 emails
- **Scale Plan**: Custom pricing

**Estimate monthly volume:**
- Verification emails: ~500 (new users)
- Reminders: ~3,000 (daily active users)
- Weekly digests: ~500 (active users)
- Onboarding: ~100 (new users)
- Achievements: ~200 (unlocks)

**Total**: ~4,300 emails/month → Upgrade recommended

---

## Quick Reference

### Create These Immediately (High Priority)

```bash
1. verify@praviel.com (send-only)
2. reminders@praviel.com (send-only)
3. achievements@praviel.com (send-only)
```

### Create These Soon (Medium Priority)

```bash
4. progress@praviel.com (send-only)
5. welcome@praviel.com (send-only)
6. community@praviel.com (forward to you)
7. marketing@praviel.com (forward to you)
```

### Already Created ✅

```bash
✅ noreply@praviel.com
✅ admin@praviel.com
✅ support@praviel.com
✅ business@praviel.com
✅ billing@praviel.com
✅ help@praviel.com
✅ anton@praviel.com
✅ antonsoloviev@praviel.com
```

---

## Resources

- **Resend Dashboard**: https://resend.com/emails
- **Resend Email API**: https://resend.com/docs/api-reference/emails/send-email
- **Email Testing Guide**: [docs/EMAIL_TESTING_GUIDE.md](EMAIL_TESTING_GUIDE.md)
- **Email Marketing Guide**: [docs/EMAIL_MARKETING.md](EMAIL_MARKETING.md)

---

**Last Updated**: 2025-10-25
**Author**: Anton Soloviev (antonsoloviev@praviel.com)
