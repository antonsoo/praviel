"""Security headers middleware for production deployment."""

from typing import Awaitable, Callable

from app.core.config import settings
from fastapi import Request, Response


async def security_headers_middleware(
    request: Request, call_next: Callable[[Request], Awaitable[Response]]
) -> Response:
    """
    Add security headers to all responses.

    Headers added:
    - X-Content-Type-Options: nosniff
    - X-Frame-Options: DENY
    - X-XSS-Protection: 1; mode=block
    - Strict-Transport-Security (HSTS) - production only
    - Content-Security-Policy (CSP)
    - Referrer-Policy: strict-origin-when-cross-origin
    """
    response = await call_next(request)

    # Prevent MIME type sniffing
    response.headers["X-Content-Type-Options"] = "nosniff"

    # Prevent clickjacking
    response.headers["X-Frame-Options"] = "DENY"

    # Enable XSS protection (legacy browsers)
    response.headers["X-XSS-Protection"] = "1; mode=block"

    # Limit referrer information
    response.headers["Referrer-Policy"] = "strict-origin-when-cross-origin"

    # HSTS - Force HTTPS (only in production)
    if not settings.is_dev_environment:
        # max-age=31536000 = 1 year
        response.headers["Strict-Transport-Security"] = "max-age=31536000; includeSubDomains"

    # Content Security Policy
    # Adjust based on your needs - this is a strict policy
    csp_directives = [
        "default-src 'self'",
        "script-src 'self' 'unsafe-inline' 'unsafe-eval'",  # Needed for Flutter web
        "style-src 'self' 'unsafe-inline'",  # Needed for inline styles
        "img-src 'self' data: https:",  # Allow images from self, data URLs, and HTTPS
        "font-src 'self' data:",
        "connect-src 'self'",  # API calls to same origin
        "frame-ancestors 'none'",  # Same as X-Frame-Options
        "base-uri 'self'",
        "form-action 'self'",
    ]

    # In development, be more permissive
    if settings.is_dev_environment:
        csp_directives = [
            "default-src 'self' 'unsafe-inline' 'unsafe-eval'",
            "img-src 'self' data: https: http:",
            "connect-src 'self' http://localhost:* ws://localhost:*",  # Allow local dev servers
        ]

    response.headers["Content-Security-Policy"] = "; ".join(csp_directives)

    # Permissions Policy (formerly Feature-Policy)
    # Restrict access to browser features
    permissions_policy = [
        "geolocation=()",  # Disable geolocation
        "microphone=()",  # Disable microphone
        "camera=()",  # Disable camera
        "payment=()",  # Disable payment APIs
        "usb=()",  # Disable USB
    ]
    response.headers["Permissions-Policy"] = ", ".join(permissions_policy)

    return response
