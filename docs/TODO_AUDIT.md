# TODO / Tech-Debt Audit

This document tracks all TODO, FIXME, HACK, and XXX comments in the codebase.

## ✅ Completed Tasks

### Password Reset Email Integration ~~(Priority: Medium)~~ - COMPLETED 2025-10-07

**Status:** ✅ **COMPLETED**

**Implementation Summary:**
- ✅ Email service module created at [backend/app/services/email.py](../backend/app/services/email.py)
- ✅ **Resend** selected as recommended provider (3,000 free emails/month)
- ✅ Multi-provider support: Resend, SendGrid, AWS SES, Mailgun, Postmark, Console (dev)
- ✅ Email templates implemented:
  - Password reset email (HTML + plain text)
  - Welcome email (HTML + plain text)
- ✅ Email configuration added to [backend/app/core/config.py](../backend/app/core/config.py)
- ✅ Environment variables documented in [.env.docker](../.env.docker)
- ✅ Password reset router updated to use email service

**How to Enable Email Sending:**

1. Sign up for Resend (recommended): https://resend.com
2. Get API key from: https://resend.com/api-keys
3. Add to your `.env` file:
   ```bash
   EMAIL_PROVIDER=resend
   RESEND_API_KEY=re_your_api_key_here
   EMAIL_FROM_ADDRESS=noreply@yourdomain.com  # Must verify domain in Resend
   EMAIL_FROM_NAME=Ancient Languages
   FRONTEND_URL=https://yourdomain.com  # For password reset links
   ```
4. Install dependency: `pip install resend` (already in pyproject.toml)

**Alternative Providers:**
Set `EMAIL_PROVIDER` to: `sendgrid`, `aws_ses`, `mailgun`, or `postmark` and provide corresponding API keys.

**Development Mode:**
Leave `EMAIL_PROVIDER=console` to log emails to console instead of sending.

---

### Token Storage Migration ~~(Priority: Unknown)~~ - COMPLETED 2025-10-07

**Status:** ✅ **COMPLETED**

**Implementation Summary:**
- ✅ Database model `PasswordResetToken` created in [backend/app/db/user_models.py](../backend/app/db/user_models.py)
- ✅ Database migration created: [backend/migrations/versions/e4b20b82db07_add_password_reset_token_table.py](../backend/migrations/versions/e4b20b82db07_add_password_reset_token_table.py)
- ✅ Password reset router migrated from in-memory storage to database
- ✅ Tokens persist across server restarts
- ✅ Automatic cleanup of expired tokens on validation
- ✅ Token reuse prevention (tracks `used_at` timestamp)

**To Apply Migration:**
```bash
# Activate conda environment
conda activate ancient-languages-py312

# Apply migration
alembic upgrade head
```

---

## 📋 Active TODOs

Currently, there are **no active TODOs** tracked in this document.

All previously tracked items have been completed.

---

## Documentation

All previously tracked TODOs have been completed and are documented above.

**Last Updated:** 2025-10-07
