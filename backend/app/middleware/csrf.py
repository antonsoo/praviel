"""CSRF protection middleware for state-changing operations."""

from __future__ import annotations

import secrets
from typing import Awaitable, Callable

from app.core.config import settings
from fastapi import HTTPException, Request, Response, status

# Methods that require CSRF protection (state-changing operations)
PROTECTED_METHODS = {"POST", "PUT", "PATCH", "DELETE"}

# Paths that are exempt from CSRF (e.g., login where you don't have token yet)
EXEMPT_PATHS = {
    "/api/v1/auth/login",
    "/api/v1/auth/register",
    "/api/v1/auth/refresh",
    "/health",
    "/health/providers",
    "/docs",
    "/openapi.json",
    "/redoc",
}


async def csrf_middleware(request: Request, call_next: Callable[[Request], Awaitable[Response]]) -> Response:
    """
    CSRF protection middleware using double-submit cookie pattern.

    For state-changing operations (POST, PUT, PATCH, DELETE), validates that:
    1. X-CSRF-Token header matches the csrf_token cookie
    2. Both exist and match

    GET, HEAD, OPTIONS, and TRACE are always allowed (idempotent/safe methods).

    This prevents CSRF attacks where malicious sites trigger authenticated
    requests to our API from a user's browser.
    """
    # Skip CSRF check in development if configured
    if settings.is_dev_environment and not getattr(settings, "CSRF_ENABLED_IN_DEV", False):
        return await call_next(request)

    # Skip safe methods (GET, HEAD, OPTIONS, TRACE)
    if request.method not in PROTECTED_METHODS:
        response = await call_next(request)
        # Set CSRF token cookie for future protected requests
        if "csrf_token" not in request.cookies:
            csrf_token = secrets.token_urlsafe(32)
            response.set_cookie(
                key="csrf_token",
                value=csrf_token,
                httponly=True,
                secure=not settings.is_dev_environment,
                samesite="strict",
                max_age=86400,  # 24 hours
            )
        return response

    # Skip exempt paths
    if request.url.path in EXEMPT_PATHS:
        return await call_next(request)

    # Validate CSRF token for protected methods
    csrf_cookie = request.cookies.get("csrf_token")
    csrf_header = request.headers.get("X-CSRF-Token")

    if not csrf_cookie or not csrf_header:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="CSRF token missing. Include X-CSRF-Token header matching csrf_token cookie.",
        )

    if not secrets.compare_digest(csrf_cookie, csrf_header):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="CSRF token mismatch. Token in header does not match cookie.",
        )

    # CSRF validation passed, process request
    return await call_next(request)
