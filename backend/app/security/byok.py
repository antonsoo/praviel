from __future__ import annotations

from typing import Iterable, Mapping, Optional

from fastapi import Request

from app.core.config import settings


def extract_byok_token(
    headers: Mapping[str, str],
    *,
    allowed: Iterable[str],
) -> Optional[str]:
    """Return the first BYOK token found in *headers* for the given allowlist."""

    for raw_header in allowed:
        header = (raw_header or "").lower().strip()
        if not header:
            continue
        raw_value = headers.get(header)
        if not raw_value and hasattr(headers, "items"):
            for candidate, candidate_value in headers.items():
                if candidate.lower() == header and candidate_value:
                    raw_value = candidate_value
                    break
        if not raw_value:
            continue
        value = raw_value.strip()
        if not value:
            continue
        if header == "authorization":
            scheme, _, remainder = value.partition(" ")
            if scheme.strip().lower() != "bearer":
                continue
            token = remainder.strip()
            if token:
                return token
            continue
        return value
    return None


def get_byok_token(request: Request) -> Optional[str]:
    """Extract a request-scoped BYOK token from approved headers.

    When settings.BYOK_ENABLED is false the dependency returns None
    and does not touch request state. When enabled it looks for a bearer
    token in Authorization or a raw key in X-Model-Key (case insensitive)
    and stores the value in request.state.byok for the duration of the request.
    """

    if not settings.BYOK_ENABLED:
        request.state.byok = None
        return None

    token = extract_byok_token(request.headers, allowed=settings.BYOK_ALLOWED_HEADERS)
    request.state.byok = token
    return token
