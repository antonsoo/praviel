from __future__ import annotations

from typing import Optional

from fastapi import APIRouter, Depends, HTTPException, Request, status
from pydantic import BaseModel, EmailStr, Field

from app.core.config import settings
from app.security.auth import get_current_user_optional
from app.services.email import EmailServiceError, create_email_service

router = APIRouter(prefix="/support", tags=["Support"])

_email_service = create_email_service(
    provider=settings.EMAIL_PROVIDER,
    resend_api_key=settings.RESEND_API_KEY,
    sendgrid_api_key=settings.SENDGRID_API_KEY,
    from_address=settings.EMAIL_FROM_ADDRESS or "support@praviel.com",
    from_name=settings.EMAIL_FROM_NAME or "PRAVIEL Support",
    aws_region=settings.AWS_REGION,
    aws_access_key_id=settings.AWS_ACCESS_KEY_ID,
    aws_secret_access_key=settings.AWS_SECRET_ACCESS_KEY,
    mailgun_domain=settings.MAILGUN_DOMAIN,
    mailgun_api_key=settings.MAILGUN_API_KEY,
    postmark_server_token=settings.POSTMARK_SERVER_TOKEN,
)


class BugReportRequest(BaseModel):
    """Payload submitted from the client when reporting an issue."""

    summary: str = Field(..., min_length=5, max_length=160)
    description: str = Field(..., min_length=20, max_length=5000)
    contact_email: Optional[EmailStr] = Field(default=None)
    app_version: Optional[str] = Field(default=None, max_length=120)
    platform: Optional[str] = Field(default=None, max_length=120)
    language: Optional[str] = Field(
        default=None,
        max_length=16,
        description="Active study language code when the bug occurred.",
    )


class BugReportResponse(BaseModel):
    message: str


@router.post("/bug-report", response_model=BugReportResponse, status_code=status.HTTP_202_ACCEPTED)
async def submit_bug_report(
    payload: BugReportRequest,
    request: Request,
    current_user=Depends(get_current_user_optional),
) -> BugReportResponse:
    """Receive bug report submissions and forward them to the support inbox."""

    reporter_email = payload.contact_email or getattr(current_user, "email", None)
    reporter_id = getattr(current_user, "id", None)
    reporter_username = getattr(current_user, "username", None)
    client_ip = request.client.host if request.client else "unknown"

    subject = f"[Bug Report] {payload.summary}"

    text_body = "\n".join(
        [
            "New bug report received from PRAVIEL web client.",
            f"Summary: {payload.summary}",
            "",
            payload.description,
            "",
            "---- Context ----",
            f"Reporter email: {reporter_email or 'not provided'}",
            f"Reporter username: {reporter_username or 'anonymous'}",
            f"Reporter user id: {reporter_id or 'anonymous'}",
            f"Language: {payload.language or 'unknown'}",
            f"App version: {payload.app_version or 'unknown'}",
            f"Platform: {payload.platform or 'unknown'}",
            f"Client IP: {client_ip}",
        ]
    )

    html_body = (
        "<p><strong>New bug report received from PRAVIEL web client.</strong></p>"
        f"<p><strong>Summary:</strong> {payload.summary}</p>"
        f"<p>{payload.description.replace(chr(10), '<br>')}</p>"
        "<hr>"
        "<p><strong>Context</strong></p>"
        "<ul>"
        f"<li><strong>Reporter email:</strong> {reporter_email or 'not provided'}</li>"
        f"<li><strong>Reporter username:</strong> {reporter_username or 'anonymous'}</li>"
        f"<li><strong>Reporter user id:</strong> {reporter_id or 'anonymous'}</li>"
        f"<li><strong>Language:</strong> {payload.language or 'unknown'}</li>"
        f"<li><strong>App version:</strong> {payload.app_version or 'unknown'}</li>"
        f"<li><strong>Platform:</strong> {payload.platform or 'unknown'}</li>"
        f"<li><strong>Client IP:</strong> {client_ip}</li>"
        "</ul>"
    )

    try:
        await _email_service.send_email(
            to_email="support@praviel.com",
            subject=subject,
            html_body=html_body,
            text_body=text_body,
        )
    except EmailServiceError as exc:  # pragma: no cover - external service dependency
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="Unable to submit report right now. Please try again later.",
        ) from exc

    return BugReportResponse(message="Thanks! Your report has been sent to the support team.")
