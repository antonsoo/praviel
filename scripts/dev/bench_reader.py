from __future__ import annotations

import argparse
import asyncio
import json
import statistics
import time
from typing import Any, Dict, List

import httpx

DEFAULT_BASE_URL = "http://127.0.0.1:8000"
READER_PATH = "/reader/analyze"
DEFAULT_PAYLOAD = {"q": "μῆνιν ἄειδε"}


def _parse_json(text: str, *, label: str) -> Dict[str, Any]:
    try:
        data = json.loads(text)
    except json.JSONDecodeError as exc:
        raise argparse.ArgumentTypeError(f"Invalid {label} JSON: {exc}") from exc
    if not isinstance(data, dict):
        raise argparse.ArgumentTypeError(f"{label} JSON must be an object")
    return data


def _percentile(values: List[float], pct: float) -> float:
    if not values:
        return 0.0
    ordered = sorted(values)
    index = int(round((pct / 100.0) * (len(ordered) - 1)))
    return ordered[index]


async def _bench(
    *,
    base_url: str,
    runs: int,
    warmup: int,
    payload: Dict[str, Any],
    include: Dict[str, Any],
    timeout: float,
) -> List[float]:
    params = {"include": json.dumps(include)} if include else None
    durations: List[float] = []
    async with httpx.AsyncClient(base_url=base_url, timeout=timeout) as client:
        for _ in range(warmup):
            response = await client.post(READER_PATH, params=params, json=payload)
            response.raise_for_status()
        for _ in range(runs):
            start = time.perf_counter()
            response = await client.post(READER_PATH, params=params, json=payload)
            response.raise_for_status()
            durations.append((time.perf_counter() - start) * 1000.0)
    return durations


async def main() -> None:
    parser = argparse.ArgumentParser(description="Benchmark /reader/analyze latency")
    parser.add_argument("--base-url", default=DEFAULT_BASE_URL, help="Server base URL")
    parser.add_argument("--runs", type=int, default=150, help="Timed request count (default: 150)")
    parser.add_argument("--warmup", type=int, default=30, help="Warmup request count (default: 30)")
    parser.add_argument(
        "--payload",
        default=json.dumps(DEFAULT_PAYLOAD, ensure_ascii=False),
        help="JSON payload for the request",
    )
    parser.add_argument(
        "--include",
        default="{}",
        help='JSON object passed as include query string (e.g. {"lsj":true})',
    )
    parser.add_argument("--timeout", type=float, default=30.0, help="Request timeout in seconds")
    args = parser.parse_args()

    payload = _parse_json(args.payload, label="payload")
    include = _parse_json(args.include, label="include") if args.include else {}

    durations = await _bench(
        base_url=args.base_url,
        runs=args.runs,
        warmup=args.warmup,
        payload=payload,
        include=include,
        timeout=args.timeout,
    )
    p50 = _percentile(durations, 50.0)
    p95 = _percentile(durations, 95.0)
    p99 = _percentile(durations, 99.0)
    mean = statistics.fmean(durations) if durations else 0.0

    print("| Stat | Value (ms) |")
    print("| --- | --- |")
    print(f"| p50 | {p50:.1f} |")
    print(f"| p95 | {p95:.1f} |")
    print(f"| p99 | {p99:.1f} |")
    print(f"| mean | {mean:.1f} |")
    print()
    params_repr = json.dumps(include, ensure_ascii=False)
    payload_repr = json.dumps(payload, ensure_ascii=False)
    print(
        "Runs={runs} Warmup={warmup} BaseURL={base_url}{path} Include={include} Payload={payload}".format(
            runs=args.runs,
            warmup=args.warmup,
            base_url=args.base_url.rstrip("/"),
            path=READER_PATH,
            include=params_repr,
            payload=payload_repr,
        )
    )


if __name__ == "__main__":  # pragma: no cover
    asyncio.run(main())
