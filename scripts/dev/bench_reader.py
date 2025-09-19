from __future__ import annotations

import argparse
import asyncio
import statistics
import time
from typing import List

import httpx

DEFAULT_URL = "http://localhost:8000/reader/analyze"
DEFAULT_QUERY = {"q": "μῆνιν ἄειδε"}


async def _bench(url: str, runs: int, warmup: int, payload: dict[str, str]) -> List[float]:
    durations: List[float] = []
    async with httpx.AsyncClient(timeout=30.0) as client:
        for _ in range(warmup):
            response = await client.post(url, json=payload)
            response.raise_for_status()
        for _ in range(runs):
            start = time.perf_counter()
            response = await client.post(url, json=payload)
            response.raise_for_status()
            durations.append((time.perf_counter() - start) * 1000.0)
    return durations


def _percentile(samples: List[float], pct: float) -> float:
    if not samples:
        return 0.0
    ordered = sorted(samples)
    idx = int(round((pct / 100.0) * (len(ordered) - 1)))
    return ordered[idx]


async def main() -> None:
    parser = argparse.ArgumentParser(description="Benchmark /reader/analyze latency")
    parser.add_argument("--url", default=DEFAULT_URL, help="Endpoint to benchmark")
    parser.add_argument("--runs", type=int, default=200, help="Timed request count (default: 200)")
    parser.add_argument("--warmup", type=int, default=50, help="Warmup request count (default: 50)")
    parser.add_argument("--query", default=DEFAULT_QUERY["q"], help="Query string to send")
    args = parser.parse_args()

    durations = await _bench(args.url, args.runs, args.warmup, {"q": args.query})
    p50 = statistics.median(durations) if durations else 0.0
    p95 = _percentile(durations, 95.0)
    avg = statistics.fmean(durations) if durations else 0.0

    print(
        f"Benchmark for {args.url} samples={len(durations)} warmup={args.warmup} "
        f"p50={p50:.1f}ms p95={p95:.1f}ms avg={avg:.1f}ms"
    )


if __name__ == "__main__":  # pragma: no cover
    asyncio.run(main())
