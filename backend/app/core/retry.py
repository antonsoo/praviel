"""Retry logic with exponential backoff for API calls"""
from __future__ import annotations

import asyncio
import random
from typing import Awaitable, Callable, TypeVar

T = TypeVar("T")


async def with_retry(
    fn: Callable[[], Awaitable[T]],
    *,
    max_attempts: int = 3,
    base_delay: float = 0.5,
    max_delay: float = 4.0,
) -> T:
    """Retry async function with exponential backoff

    Args:
        fn: Async function to retry
        max_attempts: Maximum number of attempts (default: 3)
        base_delay: Base delay in seconds (default: 0.5)
        max_delay: Maximum delay in seconds (default: 4.0)

    Returns:
        Result from successful function call

    Raises:
        Last exception if all retries fail
    """
    last_exception = None

    for attempt in range(max_attempts):
        try:
            return await fn()
        except Exception as e:
            last_exception = e

            # Don't retry on last attempt
            if attempt == max_attempts - 1:
                raise

            # Calculate delay with jitter
            delay = min(max_delay, base_delay * (2**attempt) + random.uniform(0, 0.2))

            await asyncio.sleep(delay)

    # Should never reach here, but for type safety
    if last_exception:
        raise last_exception
    raise RuntimeError("Retry logic failed unexpectedly")
