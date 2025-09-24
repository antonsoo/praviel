from __future__ import annotations

import argparse
import asyncio
import importlib
import json
import sys
from pathlib import Path
from typing import Any, Awaitable, Callable, Optional, Tuple

REPO_ROOT = Path(__file__).resolve().parents[2]
_runner_cache: Optional[Tuple[Callable[[str], Awaitable[Any]], Callable[[], Awaitable[Any]]]] = None


def _load_runner() -> Tuple[Callable[[str], Awaitable[Any]], Callable[[], Awaitable[Any]]]:
    global _runner_cache
    if _runner_cache is None:
        if str(REPO_ROOT) not in sys.path:
            sys.path.insert(0, str(REPO_ROOT))
        module = importlib.import_module("tests.accuracy.runner")
        _runner_cache = (module.run_accuracy, module.run_in_process)
    return _runner_cache


def _write_report(report: Any, output: Path) -> None:
    output.parent.mkdir(parents=True, exist_ok=True)
    with output.open("w", encoding="utf-8") as handle:
        json.dump(report.to_json(), handle, indent=2, ensure_ascii=False)


def _print_summary(report: Any) -> None:
    data = report.to_json()
    print("Reader accuracy report")
    print(f"Smyth Top-5 Accuracy: {data['smyth_top5']:.4f} ({report.n_smyth} queries)")
    print(f"LSJ Headword Accuracy: {data['lsj_headword']:.4f} ({report.n_lsj} tokens)")


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Run Reader accuracy harness")
    parser.add_argument(
        "--base-url",
        default="http://127.0.0.1:8000",
        help="Base URL for the running API server",
    )
    parser.add_argument(
        "--output",
        type=Path,
        default=Path("artifacts/accuracy_report.json"),
        help="Destination JSON file (default: artifacts/accuracy_report.json)",
    )
    parser.add_argument(
        "--in-process",
        action="store_true",
        help="Use the in-process ASGI app (no running server required)",
    )
    return parser.parse_args()


async def _run(args: argparse.Namespace) -> Any:
    run_accuracy, run_in_process = _load_runner()
    if args.in_process:
        return await run_in_process()
    return await run_accuracy(args.base_url)


def main() -> None:
    args = parse_args()
    report = asyncio.run(_run(args))
    _write_report(report, args.output)
    _print_summary(report)
    print(json.dumps(report.to_json(), ensure_ascii=False))


if __name__ == "__main__":  # pragma: no cover
    main()
