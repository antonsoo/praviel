from __future__ import annotations

from typing import Optional

from fastapi import Request

from app.core.config import settings


def get_byok_token(request: Request) -> Optional[str]:
    """Extract a request-scoped BYOK token from approved headers.

    When settings.BYOK_ENABLED is false the dependency returns None
    and does not touch request state. When enabled it looks for a bearer
    token in Authorization or a raw key in X-Model-Key (case
    insensitive) and stores the value in request.state.byok for the
    duration of the request.
    """

    if not settings.BYOK_ENABLED:
        request.state.byok = None
        return None

    token: Optional[str] = None
    headers = request.headers

    for header in settings.BYOK_ALLOWED_HEADERS:
        value = headers.get(header)
        if not value:
            continue
        if header.lower() == "authorization":
            scheme, _, remainder = value.partition(" ")
            if scheme.lower() != "bearer" or not remainder.strip():
                continue
            token = remainder.strip()
            break
        if value.strip():
            token = value.strip()
            break

    request.state.byok = token
    return token
