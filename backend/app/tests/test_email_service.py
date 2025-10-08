from __future__ import annotations

import pytest

from app.services.email import (
    EmailConfig,
    EmailProvider,
    EmailSendResult,
    EmailService,
    EmailServiceError,
    create_email_service,
)


@pytest.mark.asyncio
async def test_console_send_password_reset_returns_result() -> None:
    service = EmailService(EmailConfig(provider=EmailProvider.CONSOLE))

    result = await service.send_password_reset(
        to_email="demo@example.com",
        reset_url="https://example.com/reset?token=abc",
        expires_minutes=5,
    )

    assert isinstance(result, EmailSendResult)
    assert result.provider is EmailProvider.CONSOLE
    assert result.message_id is None
    html_preview = service._render_password_reset_template("https://example.com", 5)  # noqa: SLF001
    text_preview = service._render_password_reset_text("https://example.com", 5)  # noqa: SLF001
    assert "Security Notice" in html_preview
    assert "SECURITY NOTICE" in text_preview
    assert "⚠" not in html_preview
    assert "⚠" not in text_preview


@pytest.mark.asyncio
async def test_send_email_wraps_provider_errors() -> None:
    service = EmailService(EmailConfig(provider=EmailProvider.CONSOLE))

    async def _boom(_) -> EmailSendResult:
        raise RuntimeError("boom")

    service._senders[EmailProvider.CONSOLE] = _boom  # noqa: SLF001

    with pytest.raises(EmailServiceError) as exc_info:
        await service.send_email(
            to_email="demo@example.com",
            subject="Subject",
            html_body="<p>Hi</p>",
            text_body="Hi",
        )

    assert exc_info.value.provider is EmailProvider.CONSOLE
    assert isinstance(exc_info.value.__cause__, RuntimeError)


def test_resend_requires_api_key() -> None:
    with pytest.raises(ValueError):
        EmailService(EmailConfig(provider=EmailProvider.RESEND))


def test_create_email_service_accepts_string_provider() -> None:
    service = create_email_service("console")
    assert isinstance(service, EmailService)
