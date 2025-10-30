# Email Marketing with Resend

**Complete guide to using Resend Broadcasts and Audiences for marketing emails in PRAVIEL.**

---

## Overview

PRAVIEL integrates with [Resend](https://resend.com) for both transactional and marketing emails:

- **Transactional emails**: Password resets, welcome emails (via `EmailService`)
- **Marketing emails**: Newsletters, announcements, product updates (via `EmailMarketingService`)

This guide focuses on marketing email features using Resend's Broadcasts and Audiences APIs.

---

## Features

### Audiences (Mailing Lists)
- Create and manage multiple audiences (e.g., "Newsletter Subscribers", "Pro Users", "Beta Testers")
- Import contacts programmatically
- Automatic unsubscribe handling

### Contacts
- Add contacts with email, first name, last name
- Update contact information
- Manage subscription status
- Bulk import support

### Broadcasts
- Send emails to entire audiences
- Personalize with template variables (`{{{FIRST_NAME}}}`, `{{{LAST_NAME}}}`)
- One-click unsubscribe (`{{{RESEND_UNSUBSCRIBE_URL}}}`)
- Create drafts and review before sending

---

## Configuration

### Environment Variables

```bash
# Required for marketing emails
EMAIL_PROVIDER=resend
RESEND_API_KEY=re_your_api_key_here

# From address for marketing emails
MARKETING_FROM_ADDRESS=marketing@praviel.com
MARKETING_FROM_NAME=PRAVIEL Team
```

Add these to your `backend/.env` file.

### API Key Permissions

Ensure your Resend API key has permissions for:
- ✅ Broadcasts
- ✅ Audiences
- ✅ Contacts

---

## Usage Examples

### 1. Initialize the Service

```python
from app.core.config import settings
from app.services.email_marketing import create_email_marketing_service

# Initialize service
marketing_service = create_email_marketing_service(
    api_key=settings.RESEND_API_KEY
)
```

### 2. Create an Audience

```python
# Create a new mailing list
audience = await marketing_service.create_audience(
    name="Newsletter Subscribers"
)

print(f"Created audience: {audience.id}")
# Output: Created audience: 78261eea-8f8b-4381-83c6-79fa7120f1cf
```

### 3. Add Contacts to Audience

```python
# Add a single contact
contact = await marketing_service.add_contact(
    audience_id=audience.id,
    email="user@example.com",
    first_name="Jane",
    last_name="Doe"
)

# Add multiple contacts
contacts = [
    {"email": "john@example.com", "first_name": "John"},
    {"email": "alice@example.com", "first_name": "Alice"},
]

for contact_data in contacts:
    await marketing_service.add_contact(
        audience_id=audience.id,
        **contact_data
    )
```

### 4. Create and Send a Broadcast

```python
from app.services.email_marketing import BroadcastCreateParams

# Create HTML template with personalization and unsubscribe
html_template = """
<!DOCTYPE html>
<html>
<head>
    <style>
        body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
        .container { max-width: 600px; margin: 0 auto; padding: 20px; }
        .header { background: #667eea; color: white; padding: 20px; text-align: center; }
        .content { padding: 20px; }
        .footer { text-align: center; padding: 20px; color: #666; font-size: 14px; }
        .unsubscribe { color: #667eea; text-decoration: none; }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>PRAVIEL News</h1>
        </div>
        <div class="content">
            <p>Hi {{{FIRST_NAME|there}}},</p>

            <h2>We've Added 5 New Languages!</h2>

            <p>We're excited to announce that PRAVIEL now supports:</p>
            <ul>
                <li>Old Norse</li>
                <li>Old English</li>
                <li>Classical Arabic</li>
                <li>Classical Tamil</li>
                <li>Akkadian</li>
            </ul>

            <p>Start exploring these languages today in the app!</p>

            <p>Best regards,<br>The PRAVIEL Team</p>
        </div>
        <div class="footer">
            <p>You're receiving this because you subscribed to PRAVIEL updates.</p>
            <p><a href="{{{RESEND_UNSUBSCRIBE_URL}}}" class="unsubscribe">Unsubscribe</a></p>
            <p>© 2025 PRAVIEL | Learning Ancient Languages</p>
        </div>
    </div>
</body>
</html>
"""

# Create broadcast
broadcast = await marketing_service.create_broadcast(
    BroadcastCreateParams(
        audience_id=audience.id,
        from_email="PRAVIEL Team <marketing@praviel.com>",
        subject="🎉 5 New Languages Added to PRAVIEL!",
        html=html_template,
        name="New Languages Announcement - October 2025"
    )
)

print(f"Created broadcast: {broadcast.id}")

# Review in Resend dashboard, then send
await marketing_service.send_broadcast(broadcast.id)
print("Broadcast sent!")
```

### 5. List Audiences and Contacts

```python
# List all audiences
audiences = await marketing_service.list_audiences()
for aud in audiences:
    print(f"{aud.name}: {aud.id}")

# List contacts in an audience
contacts = await marketing_service.list_contacts(audience.id)
for contact in contacts:
    status = "Unsubscribed" if contact.unsubscribed else "Active"
    print(f"{contact.email} ({contact.first_name}): {status}")
```

### 6. Update Contact Information

```python
# Update contact details
updated_contact = await marketing_service.update_contact(
    audience_id=audience.id,
    contact_id=contact.id,
    first_name="Jane",
    last_name="Smith",  # Changed last name
)

# Manually unsubscribe a contact
await marketing_service.update_contact(
    audience_id=audience.id,
    contact_id=contact.id,
    unsubscribed=True
)
```

### 7. Remove Contacts

```python
# Remove a contact from audience
await marketing_service.remove_contact(
    audience_id=audience.id,
    contact_id=contact.id
)
```

---

## Template Variables

### Personalization

Use triple curly braces with fallback values:

```html
<!-- First name with fallback -->
Hi {{{FIRST_NAME|there}}},

<!-- Last name with fallback -->
Dear {{{LAST_NAME|user}}},

<!-- Full name -->
Hello {{{FIRST_NAME}}} {{{LAST_NAME}}},
```

### Unsubscribe URL (REQUIRED)

**CRITICAL**: All marketing emails MUST include an unsubscribe link:

```html
<!-- Text link -->
<a href="{{{RESEND_UNSUBSCRIBE_URL}}}">Unsubscribe</a>

<!-- Button -->
<a href="{{{RESEND_UNSUBSCRIBE_URL}}}" style="background: #667eea; color: white; padding: 10px 20px; text-decoration: none;">
    Unsubscribe
</a>

<!-- Footer text -->
<p>
    Don't want these emails?
    <a href="{{{RESEND_UNSUBSCRIBE_URL}}}">Unsubscribe here</a>
</p>
```

Resend automatically:
- Generates unique unsubscribe URLs per recipient
- Handles the unsubscribe flow
- Marks contacts as unsubscribed
- Excludes unsubscribed contacts from future broadcasts

---

## Best Practices

### 1. Unsubscribe Compliance

✅ **REQUIRED**: Include `{{{RESEND_UNSUBSCRIBE_URL}}}` in all marketing emails
✅ **Placement**: Visible in footer (not hidden or tiny text)
✅ **Clarity**: Use clear language like "Unsubscribe" (not "Manage preferences")

### 2. Email Content

- **Subject lines**: Keep under 50 characters, avoid spam triggers (!!!!, FREE, etc.)
- **Preheader**: First 100 characters appear in inbox preview
- **Mobile-friendly**: Use responsive design, 600px max width
- **Plain text**: Always provide text version (Resend auto-generates if omitted)

### 3. Sender Reputation

- **From address**: Use consistent sender (e.g., `marketing@praviel.com`)
- **From name**: Use recognizable brand name (`PRAVIEL Team`)
- **Authentication**: Ensure SPF, DKIM, DMARC are configured (already done for praviel.com)

### 4. Audience Segmentation

Create separate audiences for different user segments:

```python
# Segment by user type
newsletter_subscribers = await marketing_service.create_audience("Newsletter Subscribers")
pro_users = await marketing_service.create_audience("Pro Users")
beta_testers = await marketing_service.create_audience("Beta Testers")

# Segment by language interest
greek_learners = await marketing_service.create_audience("Greek Learners")
latin_learners = await marketing_service.create_audience("Latin Learners")
```

### 5. Testing

Before sending to entire audience:

1. Create a test broadcast
2. Add test contacts (your own emails)
3. Review in Resend dashboard
4. Send test broadcast
5. Check rendering in multiple email clients
6. Then send to production audience

---

## Example: User Signup Newsletter Flow

```python
from app.services.email_marketing import create_email_marketing_service
from app.core.config import settings

async def subscribe_user_to_newsletter(user_email: str, user_name: str):
    """Subscribe a new user to the newsletter after signup."""

    marketing_service = create_email_marketing_service(
        api_key=settings.RESEND_API_KEY
    )

    # Get or create newsletter audience
    audiences = await marketing_service.list_audiences()
    newsletter_audience = next(
        (aud for aud in audiences if aud.name == "Newsletter Subscribers"),
        None
    )

    if not newsletter_audience:
        newsletter_audience = await marketing_service.create_audience(
            "Newsletter Subscribers"
        )

    # Add user to audience
    try:
        await marketing_service.add_contact(
            audience_id=newsletter_audience.id,
            email=user_email,
            first_name=user_name,
            unsubscribed=False  # User explicitly opted in
        )
        logger.info(f"Added {user_email} to newsletter")
    except Exception as exc:
        logger.error(f"Failed to add {user_email} to newsletter: {exc}")
```

---

## Example: Monthly Newsletter

```python
async def send_monthly_newsletter():
    """Send monthly newsletter to all subscribers."""

    marketing_service = create_email_marketing_service(
        api_key=settings.RESEND_API_KEY
    )

    # Get newsletter audience
    audiences = await marketing_service.list_audiences()
    newsletter_audience = next(
        aud for aud in audiences if aud.name == "Newsletter Subscribers"
    )

    # Create HTML content
    html = """
    <div style="max-width: 600px; margin: 0 auto; font-family: Arial, sans-serif;">
        <h1>PRAVIEL Monthly Update - October 2025</h1>

        <p>Hi {{{FIRST_NAME|there}}},</p>

        <h2>What's New This Month</h2>
        <ul>
            <li>5 new languages added</li>
            <li>Improved AI lesson generation</li>
            <li>New gamification features</li>
        </ul>

        <h2>Featured Text: Homer's Iliad</h2>
        <p>Explore the first epic of Western literature with our new interactive reader...</p>

        <hr>
        <p style="text-align: center; color: #666;">
            <a href="{{{RESEND_UNSUBSCRIBE_URL}}}" style="color: #667eea;">Unsubscribe</a>
        </p>
    </div>
    """

    # Create and send broadcast
    broadcast = await marketing_service.create_broadcast(
        BroadcastCreateParams(
            audience_id=newsletter_audience.id,
            from_email="PRAVIEL Team <marketing@praviel.com>",
            subject="PRAVIEL Monthly Update - October 2025",
            html=html,
            name="Monthly Newsletter - October 2025"
        )
    )

    # Send immediately (or schedule via Resend dashboard)
    await marketing_service.send_broadcast(broadcast.id)

    logger.info(f"Sent monthly newsletter (broadcast {broadcast.id})")
```

---

## Error Handling

```python
from app.services.email_marketing import EmailMarketingServiceError

try:
    audience = await marketing_service.create_audience("My Audience")
    contact = await marketing_service.add_contact(
        audience_id=audience.id,
        email="user@example.com"
    )
except EmailMarketingServiceError as exc:
    logger.error(f"Email marketing error: {exc}")
    # Handle error appropriately
except ImportError:
    logger.error("Resend library not installed")
    # pip install resend
except ValueError as exc:
    logger.error(f"Invalid API key: {exc}")
    # Check RESEND_API_KEY in .env
```

---

## API Reference

### EmailMarketingService Methods

#### Audiences
- `create_audience(name: str) -> Audience`
- `list_audiences() -> list[Audience]`
- `get_audience(audience_id: str) -> Audience`
- `delete_audience(audience_id: str) -> bool`

#### Contacts
- `add_contact(audience_id, email, first_name=None, last_name=None, unsubscribed=False) -> Contact`
- `update_contact(audience_id, contact_id, **kwargs) -> Contact`
- `remove_contact(audience_id, contact_id) -> bool`
- `list_contacts(audience_id: str) -> list[Contact]`

#### Broadcasts
- `create_broadcast(params: BroadcastCreateParams) -> Broadcast`
- `send_broadcast(broadcast_id: str) -> bool`
- `get_broadcast(broadcast_id: str) -> Broadcast`

---

## Resend Dashboard

Access your Resend dashboard at: https://resend.com/emails

Features:
- View all audiences and contacts
- Review broadcast drafts before sending
- Monitor delivery, opens, clicks
- Manage unsubscribes
- View analytics and reports

---

## Legal & Compliance

### CAN-SPAM Act (US)
✅ Include unsubscribe link in every email
✅ Honor unsubscribe requests within 10 days (Resend handles automatically)
✅ Use accurate "From" address and subject line
✅ Include physical mailing address in footer

### GDPR (EU)
✅ Obtain explicit consent before adding to mailing list
✅ Provide clear privacy policy
✅ Allow users to access, export, and delete their data
✅ Document consent records

### Example Compliant Footer

```html
<div style="text-align: center; padding: 20px; color: #666; font-size: 12px;">
    <p>
        PRAVIEL | Learning Ancient Languages<br>
        [Your Physical Address]<br>
        <a href="{{{RESEND_UNSUBSCRIBE_URL}}}">Unsubscribe</a> |
        <a href="https://praviel.com/privacy">Privacy Policy</a>
    </p>
</div>
```

---

## Resources

- **Resend Documentation**: https://resend.com/docs
- **Broadcast API**: https://resend.com/docs/api-reference/broadcasts/create-broadcast
- **Audiences API**: https://resend.com/docs/api-reference/audiences/create-audience
- **Email Best Practices**: https://resend.com/blog/email-best-practices

---

## Questions?

- **Technical Support**: support@praviel.com
- **Business Inquiries**: business@praviel.com
- **GitHub Issues**: https://github.com/antonsoo/praviel/issues

---

**Last Updated**: 2025-10-25
**Author**: Anton Soloviev (antonsoloviev@praviel.com)
