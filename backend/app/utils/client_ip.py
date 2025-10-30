"""Utilities for extracting client IP addresses from requests.

Handles various proxy scenarios and header configurations.
"""

from __future__ import annotations

from fastapi import Request


def get_client_ip(request: Request) -> str:
    """Extract the client's IP address from the request.

    Handles various proxy scenarios:
    1. X-Forwarded-For header (most common proxy scenario)
    2. X-Real-IP header (nginx, cloudflare)
    3. Direct client.host (no proxy)

    Args:
        request: FastAPI request object

    Returns:
        Client IP address as string
    """
    # Check X-Forwarded-For (standard proxy header)
    # Format: "client, proxy1, proxy2"
    forwarded_for = request.headers.get("X-Forwarded-For")
    if forwarded_for:
        # Take the first IP (the original client)
        client_ip = forwarded_for.split(",")[0].strip()
        if client_ip:
            return client_ip

    # Check X-Real-IP (nginx, cloudflare)
    real_ip = request.headers.get("X-Real-IP")
    if real_ip:
        return real_ip.strip()

    # Fall back to direct client host
    if request.client and request.client.host:
        return request.client.host

    # Last resort fallback (should never happen)
    return "unknown"
