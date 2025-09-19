from __future__ import annotations

import asyncio
import os

import pytest

from backend.app.tests.conftest import run_async

from .report import generate_report, load_gold

RUN_ACCURACY = os.getenv("RUN_ACCURACY_TESTS") == "1"
RUN_DB = os.getenv("RUN_DB_TESTS") == "1"

if os.name == "nt":
    asyncio.set_event_loop_policy(asyncio.WindowsSelectorEventLoopPolicy())
pytestmark = pytest.mark.skipif(
    not (RUN_ACCURACY and RUN_DB),
    reason="Set RUN_DB_TESTS=1 and RUN_ACCURACY_TESTS=1 to run accuracy harness",
)


def test_accuracy_smoke_report(ensure_iliad_sample) -> None:
    data = load_gold()
    report = run_async(generate_report(data))
    print(report)

    assert report["retrieval"]["total"] == len(data.get("retrieval", []))
    assert report["smyth"]["total"] == len(data.get("smyth", []))
    assert report["tokens"]["total"] == len(data.get("tokens", []))
