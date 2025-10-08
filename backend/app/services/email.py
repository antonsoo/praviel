"""Email service for sending transactional emails.

Supports multiple email providers (Resend, SendGrid, AWS SES, Mailgun, Postmark).
Configure via environment variables.
"""

from __future__ import annotations

import asyncio
import logging
import textwrap
import time
from dataclasses import dataclass
from enum import Enum
from typing import Any, Awaitable, Callable, TypeVar

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


@dataclass(frozen=True)
class EmailMessage:
    """Container for rendered email content."""

    to_email: str
    subject: str
    html_body: str
    text_body: str


class EmailServiceError(RuntimeError):
    """Raised when an email provider fails to send a message."""

    def __init__(
        self,
        message: str,
        *,
        provider: EmailProvider,
        cause: Exception | None = None,
    ) -> None:
        super().__init__(message)
        self.provider = provider
        if cause is not None:
            self.__cause__ = cause


@dataclass(frozen=True)
class EmailSendResult:
    """Details returned from a provider send operation."""

    provider: EmailProvider
    message_id: str | None = None
    details: dict[str, Any] | None = None


T = TypeVar("T")


class EmailService:
    """Service for sending transactional emails."""

    def __init__(self, config: EmailConfig):
        """Initialize email service with configuration."""
        self.config = config
        self._validate_config()
        self._senders: dict[EmailProvider, Callable[[EmailMessage], Awaitable[EmailSendResult]]] = {
            EmailProvider.CONSOLE: self._send_console,
            EmailProvider.RESEND: self._send_resend,
            EmailProvider.SENDGRID: self._send_sendgrid,
            EmailProvider.AWS_SES: self._send_aws_ses,
            EmailProvider.MAILGUN: self._send_mailgun,
            EmailProvider.POSTMARK: self._send_postmark,
        }

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

    def _from_header(self) -> str:
        return f"{self.config.from_name} <{self.config.from_address}>"

    @staticmethod
    async def _run_in_thread(func: Callable[..., T], *args: Any, **kwargs: Any) -> T:
        """Run blocking provider SDK calls without freezing the event loop."""
        return await asyncio.to_thread(func, *args, **kwargs)

    async def send_password_reset(
        self,
        to_email: str,
        reset_url: str,
        expires_minutes: int = 15,
    ) -> EmailSendResult:
        """Send password reset email.

        Args:
            to_email: Recipient email address
            reset_url: Full URL for password reset (includes token)
            expires_minutes: Token expiration time in minutes

        Returns:
            EmailSendResult: Provider response metadata (message id when available).
        """
        subject = "Reset Your Password - Ancient Languages"
        html_body = self._render_password_reset_template(reset_url, expires_minutes)
        text_body = self._render_password_reset_text(reset_url, expires_minutes)

        return await self.send_email(
            to_email=to_email,
            subject=subject,
            html_body=html_body,
            text_body=text_body,
        )

    async def send_welcome_email(self, to_email: str, username: str) -> EmailSendResult:
        """Send welcome email to new users.

        Args:
            to_email: Recipient email address
            username: User's username

        Returns:
            EmailSendResult: Provider response metadata (message id when available).
        """
        subject = "Welcome to Ancient Languages!"
        html_body = self._render_welcome_template(username)
        text_body = self._render_welcome_text(username)

        return await self.send_email(
            to_email=to_email,
            subject=subject,
            html_body=html_body,
            text_body=text_body,
        )

    async def send_email(
        self,
        to_email: str,
        subject: str,
        html_body: str,
        text_body: str,
    ) -> EmailSendResult:
        """Send email using the configured provider.

        Args:
            to_email: Recipient email address
            subject: Email subject line
            html_body: HTML email body
            text_body: Plain text email body

        Returns:
            EmailSendResult: Provider response metadata (message id when available).
        """
        message = EmailMessage(
            to_email=to_email,
            subject=subject,
            html_body=html_body,
            text_body=text_body,
        )

        sender = self._senders.get(self.config.provider)
        if not sender:
            msg = f"Unsupported email provider: {self.config.provider}"
            raise ValueError(msg)

        started = time.perf_counter()
        try:
            result = await sender(message)
        except ImportError as exc:
            msg = f"{self.config.provider.value} provider requires additional dependencies"
            raise EmailServiceError(msg, provider=self.config.provider, cause=exc) from exc
        except Exception as exc:  # pragma: no cover - defensive logging
            msg = f"{self.config.provider.value} provider failed to send email"
            raise EmailServiceError(msg, provider=self.config.provider, cause=exc) from exc

        elapsed_ms = (time.perf_counter() - started) * 1000
        if result is None:
            result = EmailSendResult(provider=self.config.provider)

        if result.message_id:
            logger.info(
                "Email sent via %s in %.1f ms (message id: %s)",
                self.config.provider.value,
                elapsed_ms,
                result.message_id,
            )
        else:
            logger.info(
                "Email sent via %s in %.1f ms",
                self.config.provider.value,
                elapsed_ms,
            )

        return result

    async def _send_console(self, message: EmailMessage) -> None:
        """Log email to console (development mode)."""
        logger.info("=" * 80)
        logger.info("[Email] Console mode - not actually sent")
        logger.info(f"To: {message.to_email}")
        logger.info(f"From: {self._from_header()}")
        logger.info(f"Subject: {message.subject}")
        logger.info("-" * 80)
        logger.info(message.text_body)
        logger.info("=" * 80)

        return EmailSendResult(provider=EmailProvider.CONSOLE)

    async def _send_resend(self, message: EmailMessage) -> None:
        """Send email via Resend."""
        try:
            import resend
        except ImportError as exc:
            msg = "Resend library not installed. Run: pip install resend"
            raise ImportError(msg) from exc

        resend.api_key = self.config.resend_api_key

        def _send() -> Any:
            params = {
                "from": self._from_header(),
                "to": [message.to_email],
                "subject": message.subject,
                "html": message.html_body,
                "text": message.text_body,
            }
            return resend.Emails.send(params)

        response = await self._run_in_thread(_send)
        message_id = None
        if isinstance(response, dict):
            message_id = response.get("id")
        else:
            message_id = getattr(response, "id", None)

        details: dict[str, Any] | None = None
        if isinstance(response, dict):
            details = response

        return EmailSendResult(
            provider=EmailProvider.RESEND,
            message_id=message_id,
            details=details,
        )

    async def _send_sendgrid(self, message: EmailMessage) -> None:
        """Send email via SendGrid."""
        try:
            import sendgrid
            from sendgrid.helpers.mail import Content, Email, Mail, To
        except ImportError as exc:
            msg = "SendGrid library not installed. Run: pip install sendgrid"
            raise ImportError(msg) from exc

        def _send() -> tuple[str | None, int, dict[str, Any]]:
            sg = sendgrid.SendGridAPIClient(api_key=self.config.sendgrid_api_key)
            from_email = Email(self.config.from_address, self.config.from_name)
            recipient = To(message.to_email)
            content_text = Content("text/plain", message.text_body)
            content_html = Content("text/html", message.html_body)

            mail = Mail(from_email, recipient, message.subject, content_text)
            mail.add_content(content_html)

            response = sg.client.mail.send.post(request_body=mail.get())
            if response.status_code not in (200, 201, 202):
                msg = f"SendGrid API error: {response.status_code}"
                raise RuntimeError(msg)

            headers = dict(getattr(response, "headers", {}) or {})
            return headers.get("X-Message-Id"), response.status_code, headers

        message_id, status_code, headers = await self._run_in_thread(_send)
        return EmailSendResult(
            provider=EmailProvider.SENDGRID,
            message_id=message_id,
            details={"status_code": status_code, "headers": headers},
        )

    async def _send_aws_ses(self, message: EmailMessage) -> None:
        """Send email via AWS SES."""
        try:
            import boto3
        except ImportError as exc:
            msg = "Boto3 library not installed. Run: pip install boto3"
            raise ImportError(msg) from exc

        def _send() -> str:
            client = boto3.client(
                "ses",
                region_name=self.config.aws_region,
                aws_access_key_id=self.config.aws_access_key_id,
                aws_secret_access_key=self.config.aws_secret_access_key,
            )

            response = client.send_email(
                Source=self._from_header(),
                Destination={"ToAddresses": [message.to_email]},
                Message={
                    "Subject": {"Data": message.subject},
                    "Body": {
                        "Text": {"Data": message.text_body},
                        "Html": {"Data": message.html_body},
                    },
                },
            )
            return response["MessageId"]

        message_id = await self._run_in_thread(_send)
        return EmailSendResult(
            provider=EmailProvider.AWS_SES,
            message_id=message_id,
        )

    async def _send_mailgun(self, message: EmailMessage) -> None:
        """Send email via Mailgun."""
        try:
            import requests
        except ImportError as exc:
            msg = "Requests library not installed. Run: pip install requests"
            raise ImportError(msg) from exc

        def _send() -> tuple[int, str]:
            response = requests.post(
                f"https://api.mailgun.net/v3/{self.config.mailgun_domain}/messages",
                auth=("api", self.config.mailgun_api_key),
                data={
                    "from": self._from_header(),
                    "to": message.to_email,
                    "subject": message.subject,
                    "text": message.text_body,
                    "html": message.html_body,
                },
                timeout=30,
            )

            if response.status_code != 200:
                msg = f"Mailgun API error: {response.status_code} - {response.text}"
                raise RuntimeError(msg)

            return response.status_code, response.text

        status_code, response_text = await self._run_in_thread(_send)
        return EmailSendResult(
            provider=EmailProvider.MAILGUN,
            details={"status_code": status_code, "response": response_text},
        )

    async def _send_postmark(self, message: EmailMessage) -> None:
        """Send email via Postmark."""
        try:
            from postmarker.core import PostmarkClient
        except ImportError as exc:
            msg = "Postmarker library not installed. Run: pip install postmarker"
            raise ImportError(msg) from exc

        def _send() -> dict[str, Any] | None:
            postmark = PostmarkClient(server_token=self.config.postmark_server_token)
            return postmark.emails.send(
                From=self._from_header(),
                To=message.to_email,
                Subject=message.subject,
                TextBody=message.text_body,
                HtmlBody=message.html_body,
            )

        response = await self._run_in_thread(_send)
        message_id = None
        if isinstance(response, dict):
            message_id = response.get("MessageID") or response.get("MessageId")
        return EmailSendResult(
            provider=EmailProvider.POSTMARK,
            message_id=message_id,
            details=response if isinstance(response, dict) else None,
        )

    # Email templates

    def _render_password_reset_template(  # noqa: E501
        self, reset_url: str, expires_minutes: int
    ) -> str:
        """Render HTML template for password reset email."""
        # ruff: noqa: E501
        html = f"""\
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
            <h1>Reset Your Password</h1>
        </div>
        <div class="content">
            <p>Hello,</p>
            <p>We received a request to reset your password for your Ancient Languages account. Click the button below to create a new password:</p>

            <div style="text-align: center;">
                <a href="{reset_url}" class="button">Reset Password</a>
            </div>

            <div class="warning">
                <strong>Security Notice:</strong> This link will expire in {expires_minutes} minutes. If you didn't request this password reset, please ignore this email.
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
        return textwrap.dedent(html).strip()

    def _render_password_reset_text(self, reset_url: str, expires_minutes: int) -> str:
        """Render plain text template for password reset email."""
        template = f"""\
Reset Your Password - Ancient Languages

Hello,

We received a request to reset your password for your Ancient Languages account.

To reset your password, visit this link:
{reset_url}

SECURITY NOTICE:
- This link will expire in {expires_minutes} minutes
- If you didn't request this password reset, please ignore this email

Happy learning!
The Ancient Languages Team

---
Ancient Languages App | Learning Ancient Languages Made Easy
"""
        return textwrap.dedent(template).strip()

    def _render_welcome_template(self, username: str) -> str:  # noqa: E501
        """Render HTML template for welcome email."""
        # ruff: noqa: E501
        html = f"""\
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
            <h1>Welcome to Ancient Languages!</h1>
        </div>
        <div class="content">
            <p>Hello {username},</p>
            <p>Welcome to Ancient Languages! We're thrilled to have you join our community of language learners.</p>

            <p>Here's what you can do:</p>
            <ul>
                <li>Start learning Biblical Hebrew, Koine Greek, and more</li>
                <li>Track your progress with our gamification system</li>
                <li>Complete daily challenges and unlock achievements</li>
                <li>Master ancient texts through interactive lessons</li>
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
        return textwrap.dedent(html).strip()

    def _render_welcome_text(self, username: str) -> str:
        """Render plain text template for welcome email."""
        template = f"""\
Welcome to Ancient Languages!

Hello {username},

Welcome to Ancient Languages! We're thrilled to have you join our community of language learners.

Here's what you can do:
- Start learning Biblical Hebrew, Koine Greek, and more
- Track your progress with our gamification system
- Complete daily challenges and unlock achievements
- Master ancient texts through interactive lessons

Ready to begin your journey? Open the app and start your first lesson!

Happy learning!
The Ancient Languages Team

---
Ancient Languages App | Learning Ancient Languages Made Easy
"""
        return textwrap.dedent(template).strip()


# Factory function for easy initialization
def create_email_service(
    provider: EmailProvider | str = EmailProvider.CONSOLE,
    **kwargs: Any,
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


__all__ = [
    "EmailService",
    "EmailConfig",
    "EmailProvider",
    "EmailServiceError",
    "EmailSendResult",
    "create_email_service",
]
