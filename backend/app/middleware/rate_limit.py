"""WORKING rate limiting using token bucket algorithm with Redis."""

import logging
import time
from typing import Awaitable, Callable

from app.core.config import settings
from fastapi import Request, Response, status
from fastapi.responses import JSONResponse
from redis import asyncio as aioredis
from redis.exceptions import RedisError


class TokenBucketRateLimiter:
    """Token bucket rate limiter - simple and reliable."""

    def __init__(self, redis_url: str):
        self.redis = aioredis.from_url(redis_url, decode_responses=True)
        self._logger = logging.getLogger("app.middleware.rate_limit")
        self._disabled_until = 0.0
        self._last_error_logged = 0.0

    async def check_rate_limit(
        self,
        key: str,
        max_requests: int,
        window_seconds: int,
    ) -> tuple[bool, int]:
        """
        Check rate limit using token bucket algorithm.

        Simple approach: Store count and reset time in Redis.
        Returns: (allowed: bool, remaining: int)
        """
        now = int(time.time())

        if self._disabled_until and now < self._disabled_until:
            return True, max_requests

        # Get current count and reset time
        try:
            pipe = self.redis.pipeline()
            pipe.get(f"{key}:count")
            pipe.get(f"{key}:reset")
            result = await pipe.execute()
        except RedisError as exc:
            self._handle_redis_error(exc)
            return True, max_requests
        else:
            if self._disabled_until:
                self._disabled_until = 0.0

        count = int(result[0]) if result[0] else 0
        reset_time = int(result[1]) if result[1] else now

        # If we've passed the reset time, reset the counter
        if now >= reset_time:
            count = 0
            reset_time = now + window_seconds

        # Check if we can allow this request
        if count < max_requests:
            # Increment counter
            try:
                pipe = self.redis.pipeline()
                pipe.set(f"{key}:count", count + 1, ex=window_seconds + 10)
                pipe.set(f"{key}:reset", reset_time, ex=window_seconds + 10)
                await pipe.execute()
            except RedisError as exc:
                self._handle_redis_error(exc)
                return True, max_requests

            remaining = max_requests - count - 1
            return True, remaining
        else:
            # Limit exceeded
            return False, 0

    async def close(self):
        """Close Redis connection."""
        await self.redis.aclose()

    def _handle_redis_error(self, exc: Exception) -> None:
        now = time.time()
        self._disabled_until = now + 60.0
        if now - self._last_error_logged >= 60.0:
            self._logger.warning(
                "Redis unavailable for rate limiting; allowing requests for 60s fallback: %s",
                exc,
            )
            self._last_error_logged = now


# Global rate limiter instance
_rate_limiter = None


def get_rate_limiter() -> TokenBucketRateLimiter | None:
    """Get global rate limiter instance. Returns None if REDIS_URL not configured."""
    global _rate_limiter
    if _rate_limiter is None and settings.REDIS_URL:
        _rate_limiter = TokenBucketRateLimiter(settings.REDIS_URL)
    return _rate_limiter


async def rate_limit_middleware(
    request: Request, call_next: Callable[[Request], Awaitable[Response]]
) -> Response:
    """
    Rate limiting middleware using token bucket algorithm.

    Applies different limits based on path:
    - Auth endpoints: 10 requests/minute (increased from 5 for usability)
    - Chat endpoints: 20 requests/minute
    - Other POST/PUT/PATCH/DELETE: 30 requests/minute
    - GET requests: 100 requests/minute
    """
    # Skip rate limiting for health and docs endpoints
    if request.url.path in {"/health", "/health/providers", "/docs", "/openapi.json", "/redoc", "/"}:
        return await call_next(request)

    # Determine rate limit based on path and method
    path = request.url.path
    method = request.method

    # Ultra-sensitive endpoints: Very strict limits
    if "/auth/password-reset" in path or "/auth/forgot-password" in path:
        max_requests = 3  # Only 3 password reset attempts per hour
        window_seconds = 3600
        category = "password_reset"
    elif "/users/me/api-keys" in path and method in {"POST", "PUT", "DELETE"}:
        max_requests = 5  # Only 5 API key operations per hour
        window_seconds = 3600
        category = "api_keys"
    elif "/lesson/" in path and method == "POST":
        max_requests = 10  # Only 10 lesson generations per hour (expensive operation)
        window_seconds = 3600
        category = "lesson_generation"
    # Sensitive endpoints: Strict limits
    elif "/auth/register" in path:
        max_requests = 5  # Only 5 registrations per hour (prevent spam)
        window_seconds = 3600
        category = "registration"
    elif "/auth/login" in path:
        max_requests = 10  # 10 login attempts per minute (prevent brute force)
        window_seconds = 60
        category = "login"
    elif "/auth/" in path:
        max_requests = 10
        window_seconds = 60
        category = "auth"
    # Expensive operations: Moderate limits
    elif "/chat/" in path:
        max_requests = 20
        window_seconds = 60
        category = "chat"
    elif "/tts/" in path and method == "POST":
        max_requests = 15  # TTS generation is expensive
        window_seconds = 60
        category = "tts"
    # Standard operations
    elif method in {"POST", "PUT", "PATCH", "DELETE"}:
        max_requests = 30
        window_seconds = 60
        category = "write"
    elif method == "GET":
        max_requests = 100
        window_seconds = 60
        category = "read"
    else:
        # OPTIONS, HEAD, etc - no limit
        return await call_next(request)

    # Get identifier (IP address)
    client_ip = request.client.host if request.client else "unknown"
    rate_limit_key = f"ratelimit:{category}:{client_ip}"

    # Check rate limit (skip if Redis not configured)
    limiter = get_rate_limiter()
    if limiter is None:
        # Redis not configured - allow all requests (no rate limiting)
        response = await call_next(request)
        return response

    allowed, remaining = await limiter.check_rate_limit(rate_limit_key, max_requests, window_seconds)

    if not allowed:
        # Return 429 response directly (don't raise exception in middleware)
        return JSONResponse(
            status_code=status.HTTP_429_TOO_MANY_REQUESTS,
            content={
                "detail": (
                    f"Rate limit exceeded. Maximum {max_requests} requests "
                    f"per minute for {category} endpoints. Please try again later."
                )
            },
            headers={
                "X-RateLimit-Limit": str(max_requests),
                "X-RateLimit-Remaining": "0",
                "X-RateLimit-Reset": str(int(time.time() + window_seconds)),
                "Retry-After": str(window_seconds),
            },
        )

    # Process request
    response = await call_next(request)

    # Add rate limit headers to response
    response.headers["X-RateLimit-Limit"] = str(max_requests)
    response.headers["X-RateLimit-Remaining"] = str(remaining)
    response.headers["X-RateLimit-Reset"] = str(int(time.time() + window_seconds))

    return response
