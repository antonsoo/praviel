"""Email service for sending transactional emails.

Supports multiple email providers (Resend, SendGrid, AWS SES, Mailgun, Postmark).
Configure via environment variables.
"""

from __future__ import annotations

import logging
from dataclasses import dataclass
from enum import Enum
from typing import TYPE_CHECKING

if TYPE_CHECKING:
    pass

logger = logging.getLogger(__name__)


class EmailProvider(str, Enum):
    """Supported email service providers."""

    RESEND = "resend"
    SENDGRID = "sendgrid"
    AWS_SES = "aws_ses"
    MAILGUN = "mailgun"
    POSTMARK = "postmark"
    CONSOLE = "console"  # For development - just log to console


@dataclass
class EmailConfig:
    """Email service configuration."""

    provider: EmailProvider
    api_key: str | None = None
    from_address: str = "noreply@ancientlanguages.app"
    from_name: str = "Ancient Languages"
    # Provider-specific settings
    resend_api_key: str | None = None
    sendgrid_api_key: str | None = None
    aws_region: str | None = None
    aws_access_key_id: str | None = None
    aws_secret_access_key: str | None = None
    mailgun_domain: str | None = None
    mailgun_api_key: str | None = None
    postmark_server_token: str | None = None


class EmailService:
    """Service for sending transactional emails."""

    def __init__(self, config: EmailConfig):
        """Initialize email service with configuration."""
        self.config = config
        self._validate_config()

    def _validate_config(self) -> None:
        """Validate that required config is present for the selected provider."""
        if self.config.provider == EmailProvider.CONSOLE:
            return  # No validation needed for console mode

        if self.config.provider == EmailProvider.RESEND and not self.config.resend_api_key:
            msg = "Resend API key is required"
            raise ValueError(msg)

        if self.config.provider == EmailProvider.SENDGRID and not self.config.sendgrid_api_key:
            msg = "SendGrid API key is required"
            raise ValueError(msg)

        if self.config.provider == EmailProvider.AWS_SES:
            if not all(
                [self.config.aws_region, self.config.aws_access_key_id, self.config.aws_secret_access_key]
            ):
                msg = "AWS credentials (region, access key, secret key) are required for SES"
                raise ValueError(msg)

        if self.config.provider == EmailProvider.MAILGUN:
            if not all([self.config.mailgun_domain, self.config.mailgun_api_key]):
                msg = "Mailgun domain and API key are required"
                raise ValueError(msg)

        if self.config.provider == EmailProvider.POSTMARK and not self.config.postmark_server_token:
            msg = "Postmark server token is required"
            raise ValueError(msg)

    async def send_password_reset(
        self,
        to_email: str,
        reset_url: str,
        expires_minutes: int = 15,
    ) -> None:
        """Send password reset email.

        Args:
            to_email: Recipient email address
            reset_url: Full URL for password reset (includes token)
            expires_minutes: Token expiration time in minutes
        """
        subject = "Reset Your Password - Ancient Languages"
        html_body = self._render_password_reset_template(reset_url, expires_minutes)
        text_body = self._render_password_reset_text(reset_url, expires_minutes)

        await self._send_email(
            to_email=to_email,
            subject=subject,
            html_body=html_body,
            text_body=text_body,
        )

    async def send_welcome_email(self, to_email: str, username: str) -> None:
        """Send welcome email to new users.

        Args:
            to_email: Recipient email address
            username: User's username
        """
        subject = "Welcome to Ancient Languages!"
        html_body = self._render_welcome_template(username)
        text_body = self._render_welcome_text(username)

        await self._send_email(
            to_email=to_email,
            subject=subject,
            html_body=html_body,
            text_body=text_body,
        )

    async def _send_email(
        self,
        to_email: str,
        subject: str,
        html_body: str,
        text_body: str,
    ) -> None:
        """Send email using the configured provider.

        Args:
            to_email: Recipient email address
            subject: Email subject line
            html_body: HTML email body
            text_body: Plain text email body
        """
        if self.config.provider == EmailProvider.CONSOLE:
            await self._send_console(to_email, subject, text_body)
        elif self.config.provider == EmailProvider.RESEND:
            await self._send_resend(to_email, subject, html_body, text_body)
        elif self.config.provider == EmailProvider.SENDGRID:
            await self._send_sendgrid(to_email, subject, html_body, text_body)
        elif self.config.provider == EmailProvider.AWS_SES:
            await self._send_aws_ses(to_email, subject, html_body, text_body)
        elif self.config.provider == EmailProvider.MAILGUN:
            await self._send_mailgun(to_email, subject, html_body, text_body)
        elif self.config.provider == EmailProvider.POSTMARK:
            await self._send_postmark(to_email, subject, html_body, text_body)
        else:
            msg = f"Unsupported email provider: {self.config.provider}"
            raise ValueError(msg)

    async def _send_console(self, to_email: str, subject: str, text_body: str) -> None:
        """Log email to console (development mode)."""
        logger.info("=" * 80)
        logger.info("📧 EMAIL (CONSOLE MODE - NOT ACTUALLY SENT)")
        logger.info(f"To: {to_email}")
        logger.info(f"From: {self.config.from_name} <{self.config.from_address}>")
        logger.info(f"Subject: {subject}")
        logger.info("-" * 80)
        logger.info(text_body)
        logger.info("=" * 80)

    async def _send_resend(
        self,
        to_email: str,
        subject: str,
        html_body: str,
        text_body: str,
    ) -> None:
        """Send email via Resend."""
        try:
            import resend
        except ImportError as e:
            msg = "Resend library not installed. Run: pip install resend"
            raise ImportError(msg) from e

        resend.api_key = self.config.resend_api_key

        params = {
            "from": f"{self.config.from_name} <{self.config.from_address}>",
            "to": [to_email],
            "subject": subject,
            "html": html_body,
            "text": text_body,
        }

        response = resend.Emails.send(params)

        if hasattr(response, "get") and response.get("id"):
            logger.info(f"Email sent successfully via Resend to {to_email} (ID: {response['id']})")
        else:
            logger.info(f"Email sent successfully via Resend to {to_email}")

    async def _send_sendgrid(
        self,
        to_email: str,
        subject: str,
        html_body: str,
        text_body: str,
    ) -> None:
        """Send email via SendGrid."""
        try:
            import sendgrid
            from sendgrid.helpers.mail import Content, Email, Mail, To
        except ImportError as e:
            msg = "SendGrid library not installed. Run: pip install sendgrid"
            raise ImportError(msg) from e

        sg = sendgrid.SendGridAPIClient(api_key=self.config.sendgrid_api_key)
        from_email = Email(self.config.from_address, self.config.from_name)
        to = To(to_email)
        content_text = Content("text/plain", text_body)
        content_html = Content("text/html", html_body)

        mail = Mail(from_email, to, subject, content_text)
        mail.add_content(content_html)

        response = sg.client.mail.send.post(request_body=mail.get())

        if response.status_code not in (200, 201, 202):
            msg = f"SendGrid API error: {response.status_code}"
            raise RuntimeError(msg)

        logger.info(f"Email sent successfully via SendGrid to {to_email}")

    async def _send_aws_ses(
        self,
        to_email: str,
        subject: str,
        html_body: str,
        text_body: str,
    ) -> None:
        """Send email via AWS SES."""
        try:
            import boto3
        except ImportError as e:
            msg = "Boto3 library not installed. Run: pip install boto3"
            raise ImportError(msg) from e

        client = boto3.client(
            "ses",
            region_name=self.config.aws_region,
            aws_access_key_id=self.config.aws_access_key_id,
            aws_secret_access_key=self.config.aws_secret_access_key,
        )

        response = client.send_email(
            Source=f"{self.config.from_name} <{self.config.from_address}>",
            Destination={"ToAddresses": [to_email]},
            Message={
                "Subject": {"Data": subject},
                "Body": {
                    "Text": {"Data": text_body},
                    "Html": {"Data": html_body},
                },
            },
        )

        logger.info(f"Email sent successfully via AWS SES to {to_email} (MessageId: {response['MessageId']})")

    async def _send_mailgun(
        self,
        to_email: str,
        subject: str,
        html_body: str,
        text_body: str,
    ) -> None:
        """Send email via Mailgun."""
        try:
            import requests
        except ImportError as e:
            msg = "Requests library not installed. Run: pip install requests"
            raise ImportError(msg) from e

        response = requests.post(
            f"https://api.mailgun.net/v3/{self.config.mailgun_domain}/messages",
            auth=("api", self.config.mailgun_api_key),
            data={
                "from": f"{self.config.from_name} <{self.config.from_address}>",
                "to": to_email,
                "subject": subject,
                "text": text_body,
                "html": html_body,
            },
            timeout=30,
        )

        if response.status_code != 200:
            msg = f"Mailgun API error: {response.status_code} - {response.text}"
            raise RuntimeError(msg)

        logger.info(f"Email sent successfully via Mailgun to {to_email}")

    async def _send_postmark(
        self,
        to_email: str,
        subject: str,
        html_body: str,
        text_body: str,
    ) -> None:
        """Send email via Postmark."""
        try:
            from postmarker.core import PostmarkClient
        except ImportError as e:
            msg = "Postmarker library not installed. Run: pip install postmarker"
            raise ImportError(msg) from e

        postmark = PostmarkClient(server_token=self.config.postmark_server_token)
        postmark.emails.send(
            From=f"{self.config.from_name} <{self.config.from_address}>",
            To=to_email,
            Subject=subject,
            TextBody=text_body,
            HtmlBody=html_body,
        )

        logger.info(f"Email sent successfully via Postmark to {to_email}")

    # Email templates

    def _render_password_reset_template(  # noqa: E501
        self, reset_url: str, expires_minutes: int
    ) -> str:
        """Render HTML template for password reset email."""
        # ruff: noqa: E501
        return f"""
<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <style>
        body {{ font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; line-height: 1.6; color: #333; }}
        .container {{ max-width: 600px; margin: 0 auto; padding: 20px; }}
        .header {{ background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; padding: 30px; text-align: center; border-radius: 8px 8px 0 0; }}
        .content {{ background: #f9fafb; padding: 30px; border-radius: 0 0 8px 8px; }}
        .button {{ display: inline-block; background: #667eea; color: white; padding: 14px 32px; text-decoration: none; border-radius: 6px; margin: 20px 0; font-weight: 600; }}
        .footer {{ text-align: center; margin-top: 30px; color: #6b7280; font-size: 14px; }}
        .warning {{ background: #fef3c7; border-left: 4px solid #f59e0b; padding: 12px; margin: 20px 0; }}
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>🔐 Reset Your Password</h1>
        </div>
        <div class="content">
            <p>Hello,</p>
            <p>We received a request to reset your password for your Ancient Languages account. Click the button below to create a new password:</p>

            <div style="text-align: center;">
                <a href="{reset_url}" class="button">Reset Password</a>
            </div>

            <div class="warning">
                <strong>⚠️ Security Notice:</strong> This link will expire in {expires_minutes} minutes. If you didn't request this password reset, please ignore this email.
            </div>

            <p>If the button doesn't work, copy and paste this link into your browser:</p>
            <p style="word-break: break-all; color: #667eea;">{reset_url}</p>

            <p>Happy learning!<br>The Ancient Languages Team</p>
        </div>
        <div class="footer">
            <p>Ancient Languages App | Learning Ancient Languages Made Easy</p>
        </div>
    </div>
</body>
</html>
"""

    def _render_password_reset_text(self, reset_url: str, expires_minutes: int) -> str:
        """Render plain text template for password reset email."""
        return f"""
Reset Your Password - Ancient Languages

Hello,

We received a request to reset your password for your Ancient Languages account.

To reset your password, visit this link:
{reset_url}

⚠️ SECURITY NOTICE:
- This link will expire in {expires_minutes} minutes
- If you didn't request this password reset, please ignore this email

Happy learning!
The Ancient Languages Team

---
Ancient Languages App | Learning Ancient Languages Made Easy
"""

    def _render_welcome_template(self, username: str) -> str:  # noqa: E501
        """Render HTML template for welcome email."""
        # ruff: noqa: E501
        return f"""
<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <style>
        body {{ font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; line-height: 1.6; color: #333; }}
        .container {{ max-width: 600px; margin: 0 auto; padding: 20px; }}
        .header {{ background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; padding: 30px; text-align: center; border-radius: 8px 8px 0 0; }}
        .content {{ background: #f9fafb; padding: 30px; border-radius: 0 0 8px 8px; }}
        .footer {{ text-align: center; margin-top: 30px; color: #6b7280; font-size: 14px; }}
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>🎉 Welcome to Ancient Languages!</h1>
        </div>
        <div class="content">
            <p>Hello {username},</p>
            <p>Welcome to Ancient Languages! We're thrilled to have you join our community of language learners.</p>

            <p>Here's what you can do:</p>
            <ul>
                <li>📚 Start learning Biblical Hebrew, Koine Greek, and more</li>
                <li>🎯 Track your progress with our gamification system</li>
                <li>💪 Complete daily challenges and unlock achievements</li>
                <li>🌟 Master ancient texts through interactive lessons</li>
            </ul>

            <p>Ready to begin your journey? Open the app and start your first lesson!</p>

            <p>Happy learning!<br>The Ancient Languages Team</p>
        </div>
        <div class="footer">
            <p>Ancient Languages App | Learning Ancient Languages Made Easy</p>
        </div>
    </div>
</body>
</html>
"""

    def _render_welcome_text(self, username: str) -> str:
        """Render plain text template for welcome email."""
        return f"""
Welcome to Ancient Languages!

Hello {username},

Welcome to Ancient Languages! We're thrilled to have you join our community of language learners.

Here's what you can do:
• 📚 Start learning Biblical Hebrew, Koine Greek, and more
• 🎯 Track your progress with our gamification system
• 💪 Complete daily challenges and unlock achievements
• 🌟 Master ancient texts through interactive lessons

Ready to begin your journey? Open the app and start your first lesson!

Happy learning!
The Ancient Languages Team

---
Ancient Languages App | Learning Ancient Languages Made Easy
"""


# Factory function for easy initialization
def create_email_service(
    provider: EmailProvider | str = EmailProvider.CONSOLE,
    **kwargs: str,
) -> EmailService:
    """Create email service with the specified provider.

    Args:
        provider: Email provider to use (sendgrid, aws_ses, mailgun, postmark, console)
        **kwargs: Provider-specific configuration

    Returns:
        Configured EmailService instance

    Example:
        # Console mode (development)
        email_service = create_email_service("console")

        # SendGrid
        email_service = create_email_service(
            "sendgrid",
            sendgrid_api_key="your_key",
            from_address="noreply@yourapp.com"
        )
    """
    if isinstance(provider, str):
        provider = EmailProvider(provider)

    config = EmailConfig(provider=provider, **kwargs)
    return EmailService(config)


__all__ = ["EmailService", "EmailConfig", "EmailProvider", "create_email_service"]
