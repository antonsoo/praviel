"""Accuracy evaluation harness for Reader v0."""

from __future__ import annotations

import asyncio
import importlib
import json
import sys
from dataclasses import dataclass
from pathlib import Path
from typing import Dict, Iterable, List, Sequence, Tuple

import httpx

BACKEND_ROOT = Path(__file__).resolve().parents[2] / "backend"
_normalize_module = None


def _load_normalize():
    global _normalize_module
    if _normalize_module is None:
        if str(BACKEND_ROOT) not in sys.path:
            sys.path.insert(0, str(BACKEND_ROOT))
        _normalize_module = importlib.import_module("app.ingestion.normalize")
    return _normalize_module


_OFFICIAL_DIR = Path(__file__).resolve().parent / "official"


@dataclass(slots=True)
class SmythSample:
    q: str
    expected_anchors: Tuple[str, ...]


@dataclass(slots=True)
class LSJSample:
    q: str
    expected_lemma: str


@dataclass(slots=True)
class AccuracyReport:
    smyth_top5: float
    lsj_headword: float
    n_smyth: int
    n_lsj: int

    def to_json(self) -> Dict[str, float | int]:
        return {
            "smyth_top5": round(self.smyth_top5, 4),
            "lsj_headword": round(self.lsj_headword, 4),
            "n_smyth": self.n_smyth,
            "n_lsj": self.n_lsj,
        }


def load_official_smyth() -> List[SmythSample]:
    path = _OFFICIAL_DIR / "smyth_top5.off.jsonl"
    return list(_load_smyth_samples(path))


def load_official_lsj() -> List[LSJSample]:
    path = _OFFICIAL_DIR / "lsj_headword.off.jsonl"
    return list(_load_lsj_samples(path))


def _load_smyth_samples(path: Path) -> Iterable[SmythSample]:
    with path.open("r", encoding="utf-8") as handle:
        for line in handle:
            data = json.loads(line)
            q = data["q"].strip()
            anchors = tuple(anchor.strip() for anchor in data.get("expected_anchors", []) if anchor.strip())
            if not q or not anchors:
                continue
            yield SmythSample(q=q, expected_anchors=anchors)


def _load_lsj_samples(path: Path) -> Iterable[LSJSample]:
    normalize = _load_normalize()
    with path.open("r", encoding="utf-8") as handle:
        for line in handle:
            data = json.loads(line)
            q = data["q"].strip()
            expected = normalize.accent_fold(data["expected_lemma"]).strip()
            if not q or not expected:
                continue
            yield LSJSample(q=q, expected_lemma=expected)


class AccuracyRunner:
    """Compute Smyth and LSJ accuracy metrics using the Reader API."""

    def __init__(self, client: httpx.AsyncClient) -> None:
        self._client = client

    async def run(self) -> AccuracyReport:
        smyth_samples = load_official_smyth()
        lsj_samples = load_official_lsj()

        smyth_hits = await self._eval_smyth(smyth_samples)
        lsj_hits = await self._eval_lsj(lsj_samples)

        smyth_acc = smyth_hits / len(smyth_samples) if smyth_samples else 0.0
        lsj_acc = lsj_hits / len(lsj_samples) if lsj_samples else 0.0
        return AccuracyReport(
            smyth_top5=smyth_acc,
            lsj_headword=lsj_acc,
            n_smyth=len(smyth_samples),
            n_lsj=len(lsj_samples),
        )

    async def _eval_smyth(self, samples: Sequence[SmythSample]) -> int:
        params = {"include": json.dumps({"smyth": True})}
        hits = 0
        for sample in samples:
            response = await self._client.post(
                "/reader/analyze",
                params=params,
                json={"q": sample.q},
                timeout=30.0,
            )
            response.raise_for_status()
            payload = response.json()
            entries = payload.get("grammar") or []
            anchors = [entry.get("anchor") for entry in entries[:5] if entry.get("anchor")]
            if any(anchor in sample.expected_anchors for anchor in anchors):
                hits += 1
        return hits

    async def _eval_lsj(self, samples: Sequence[LSJSample]) -> int:
        params = {"include": json.dumps({"lsj": True})}
        hits = 0
        normalize = _load_normalize()
        for sample in samples:
            response = await self._client.post(
                "/reader/analyze",
                params=params,
                json={"q": sample.q},
                timeout=30.0,
            )
            response.raise_for_status()
            payload = response.json()
            entries = payload.get("lexicon") or []
            lemmas = [
                normalize.accent_fold(entry.get("lemma", "")) for entry in entries if entry.get("lemma")
            ]
            if any(lemma == sample.expected_lemma for lemma in lemmas):
                hits += 1
        return hits


async def run_accuracy(base_url: str = "http://127.0.0.1:8000") -> AccuracyReport:
    async with httpx.AsyncClient(base_url=base_url, timeout=30.0) as client:
        runner = AccuracyRunner(client)
        return await runner.run()


async def run_in_process() -> AccuracyReport:
    from contextlib import AsyncExitStack

    from app.main import app

    transport = httpx.ASGITransport(app=app)
    async with AsyncExitStack() as stack:
        await stack.enter_async_context(app.router.lifespan_context(app))
        async with httpx.AsyncClient(transport=transport, base_url="http://testserver") as client:
            runner = AccuracyRunner(client)
            return await runner.run()


if __name__ == "__main__":  # pragma: no cover - manual invocation helper
    report = asyncio.run(run_in_process())
    print(json.dumps(report.to_json(), indent=2))
