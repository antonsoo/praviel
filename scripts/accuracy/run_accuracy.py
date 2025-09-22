from __future__ import annotations

import argparse
import json
import sys
import time
import unicodedata
from dataclasses import dataclass
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Dict, Iterable, List, Tuple

import httpx

DEFAULT_BASE_URL = "http://127.0.0.1:8000"

OFFICIAL_DATASETS = [
    Path("tests/accuracy/official/smyth_top5.off.jsonl"),
    Path("tests/accuracy/official/lsj_headword.off.jsonl"),
]

LEGACY_DATASETS = [
    Path("tests/accuracy/smyth_top5.jsonl"),
    Path("tests/accuracy/lsj_headword.jsonl"),
]


@dataclass
class DatasetRow:
    path: Path
    line: int
    payload: Dict[str, Any]


@dataclass
class DatasetSummary:
    path: Path
    dataset_type: str
    hits: int
    total: int

    @property
    def value(self) -> float:
        return self.hits / self.total if self.total else 0.0


@dataclass
class Metric:
    label: str
    hits: int = 0
    total: int = 0
    gate: float = 0.0
    target: float = 0.0
    notes: str = ""

    @property
    def value(self) -> float:
        return self.hits / self.total if self.total else 0.0

    def record(self, hit: bool) -> None:
        self.total += 1
        if hit:
            self.hits += 1


@dataclass
class Miss:
    query: str
    expected: Iterable[str] | str
    observed: Iterable[str]
    path: Path
    line: int


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Run accuracy checks against /reader/analyze")
    parser.add_argument(
        "--datasets",
        nargs="+",
        type=Path,
        default=None,
        help="JSONL accuracy datasets (defaults to official curated sets)",
    )
    parser.add_argument(
        "--base-url",
        default=DEFAULT_BASE_URL,
        help=f"Reader service base URL (default: {DEFAULT_BASE_URL})",
    )
    parser.add_argument(
        "--timeout",
        type=float,
        default=30.0,
        help="Request timeout in seconds (default: 30.0)",
    )
    parser.add_argument(
        "--limit",
        type=int,
        default=None,
        help="Optional per-dataset cap on rows",
    )
    parser.add_argument(
        "--bench",
        action="store_true",
        help="Include latency percentiles in the summary table",
    )
    parser.add_argument(
        "--official",
        dest="official",
        action="store_true",
        default=True,
        help="Use the official dataset bundle (default)",
    )
    parser.add_argument(
        "--no-official",
        dest="official",
        action="store_false",
        help="Use the legacy sample datasets",
    )
    return parser.parse_args()


def accent_fold(text: str | None) -> str:
    if not text:
        return ""
    normalized = unicodedata.normalize("NFD", text)
    stripped = "".join(ch for ch in normalized if unicodedata.category(ch) != "Mn")
    return stripped.casefold()


def load_dataset(path: Path, limit: int | None) -> List[DatasetRow]:
    rows: List[DatasetRow] = []
    with path.open("r", encoding="utf-8") as handle:
        for line_number, raw in enumerate(handle, start=1):
            data = raw.strip()
            if not data or data.startswith("#"):
                continue
            try:
                payload = json.loads(data)
            except json.JSONDecodeError as exc:
                raise ValueError(f"{path}:{line_number} invalid JSON: {exc}") from exc
            rows.append(DatasetRow(path=path, line=line_number, payload=payload))
            if limit is not None and len(rows) >= limit:
                break
    if not rows:
        raise ValueError(f"Dataset {path} contained no usable rows")
    return rows


def detect_dataset_type(rows: List[DatasetRow]) -> str:
    sample = rows[0].payload
    if "expected_anchors" in sample:
        return "smyth"
    if "expected_lemma" in sample:
        return "lsj"
    raise ValueError(f"Unable to detect dataset type for payload keys: {sorted(sample.keys())}")


def percentile(values: List[float], pct: float) -> float:
    if not values:
        return 0.0
    index = max(0, min(len(values) - 1, int(round(pct / 100.0 * (len(values) - 1)))))
    return sorted(values)[index]


def evaluate(
    client: httpx.Client,
    rows: List[DatasetRow],
    dataset_type: str,
    metrics: Dict[str, Metric],
    misses: Dict[str, List[Miss]],
    dataset_key: str,
    dataset_misses: Dict[str, List[Miss]],
    latencies_ms: List[float],
    timeout: float,
) -> Tuple[int, int]:
    local_hits = 0

    for row in rows:
        payload = row.payload
        query = str(payload.get("q", ""))
        if not query:
            raise ValueError(f"{row.path}:{row.line} missing 'q' field")

        include_flags: Dict[str, bool] = {}
        if dataset_type == "smyth":
            include_flags["smyth"] = True
        elif dataset_type == "lsj":
            include_flags["lsj"] = True
        else:
            raise ValueError(f"Unsupported dataset type: {dataset_type}")

        params = {"include": json.dumps(include_flags)} if include_flags else None
        body = {"q": query}

        start = time.perf_counter()
        response = client.post("/reader/analyze", params=params, json=body, timeout=timeout)
        elapsed_ms = (time.perf_counter() - start) * 1000.0
        latencies_ms.append(elapsed_ms)

        response.raise_for_status()
        data = response.json()

        if dataset_type == "smyth":
            expected = {anchor for anchor in payload.get("expected_anchors", []) if anchor}
            grammar = data.get("grammar") or []
            anchors = [entry.get("anchor") for entry in grammar[:5] if entry.get("anchor")]
            hit = bool(expected and expected & set(anchors))
            metrics["smyth"].record(hit)
            if hit:
                local_hits += 1
            else:
                miss = Miss(
                    query=query,
                    expected=sorted(expected),
                    observed=anchors,
                    path=row.path,
                    line=row.line,
                )
                misses.setdefault("smyth", []).append(miss)
                dataset_misses.setdefault(dataset_key, []).append(miss)
        else:
            expected = accent_fold(str(payload.get("expected_lemma", "")))
            lexicon = data.get("lexicon") or []
            lemmas = {accent_fold(entry.get("lemma")) for entry in lexicon if entry.get("lemma")}
            hit = bool(expected and expected in lemmas)
            metrics["lsj"].record(hit)
            if hit:
                local_hits += 1
            else:
                miss = Miss(
                    query=query,
                    expected=str(payload.get("expected_lemma", "")),
                    observed=sorted(lemma for lemma in lemmas if lemma),
                    path=row.path,
                    line=row.line,
                )
                misses.setdefault("lsj", []).append(miss)
                dataset_misses.setdefault(dataset_key, []).append(miss)

    return local_hits, len(rows)

def build_table(metrics: Dict[str, Metric], bench: bool, latencies_ms: List[float]) -> str:
    header = "| Metric | Value | N | Notes |\n| --- | --- | --- | --- |"
    rows: List[str] = []
    rows.append(header)

    smyth = metrics["smyth"]
    smyth_notes = f"gate {smyth.gate:.2f} (target {smyth.target:.2f})"
    rows.append(
        f"| {smyth.label} | {smyth.value:.3f} ({smyth.hits}/{smyth.total}) | {smyth.total} | {smyth_notes} |"
    )

    lsj = metrics["lsj"]
    lsj_notes = f"gate {lsj.gate:.2f} (target {lsj.target:.2f})"
    rows.append(f"| {lsj.label} | {lsj.value:.3f} ({lsj.hits}/{lsj.total}) | {lsj.total} | {lsj_notes} |")

    if bench:
        p50 = percentile(latencies_ms, 50)
        p95 = percentile(latencies_ms, 95)
        notes = "dev-only bench"
        rows.append(f"| Latency p50/p95 (ms) | {p50:.1f} / {p95:.1f} | {len(latencies_ms)} | {notes} |")

    return "\n".join(rows)


def write_artifact(
    metrics: Dict[str, Metric],
    dataset_summaries: List[DatasetSummary],
    misses: Dict[str, List[Miss]],
    dataset_misses: Dict[str, List[Miss]],
    latencies_ms: List[float],
    bench: bool,
    path: Path,
) -> None:
    summary = {
        "timestamp": datetime.now(tz=timezone.utc).isoformat(),
        "metrics": {
            "smyth@5": {
                "value": metrics["smyth"].value,
                "hits": metrics["smyth"].hits,
                "total": metrics["smyth"].total,
                "gate": metrics["smyth"].gate,
                "target": metrics["smyth"].target,
            },
            "lsj_headword": {
                "value": metrics["lsj"].value,
                "hits": metrics["lsj"].hits,
                "total": metrics["lsj"].total,
                "gate": metrics["lsj"].gate,
                "target": metrics["lsj"].target,
            },
        },
        "datasets": {
            str(summary.path): {
                "type": summary.dataset_type,
                "value": summary.value,
                "hits": summary.hits,
                "total": summary.total,
                "misses": [
                    {
                        "query": miss.query,
                        "expected": miss.expected,
                        "observed": miss.observed,
                        "path": str(miss.path),
                        "line": miss.line,
                    }
                    for miss in dataset_misses.get(str(summary.path), [])
                ],
            }
            for summary in dataset_summaries
        },
        "misses": {
            key: [
                {
                    "query": miss.query,
                    "expected": miss.expected,
                    "observed": miss.observed,
                    "path": str(miss.path),
                    "line": miss.line,
                }
                for miss in value
            ]
            for key, value in misses.items()
        },
    }
    if bench:
        summary["latency_ms"] = {
            "count": len(latencies_ms),
            "p50": percentile(latencies_ms, 50),
            "p95": percentile(latencies_ms, 95),
            "mean": sum(latencies_ms) / len(latencies_ms) if latencies_ms else 0.0,
        }

    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(summary, ensure_ascii=False, indent=2), encoding="utf-8")


def main() -> int:
    args = parse_args()

    if args.datasets:
        dataset_paths = list(args.datasets)
    else:
        dataset_paths = list(OFFICIAL_DATASETS if args.official else LEGACY_DATASETS)

    metrics = {
        "smyth": Metric(label="Smyth@5", gate=0.70, target=0.85),
        "lsj": Metric(label="LSJ headword", gate=0.80, target=0.90),
    }
    misses: Dict[str, List[Miss]] = {}
    dataset_misses: Dict[str, List[Miss]] = {}
    dataset_summaries: List[DatasetSummary] = []
    latencies_ms: List[float] = []

    with httpx.Client(base_url=args.base_url, timeout=args.timeout) as client:
        for dataset_path in dataset_paths:
            rows = load_dataset(dataset_path, args.limit)
            dataset_type = detect_dataset_type(rows)
            hits, total = evaluate(
                client=client,
                rows=rows,
                dataset_type=dataset_type,
                metrics=metrics,
                misses=misses,
                dataset_key=str(dataset_path),
                dataset_misses=dataset_misses,
                latencies_ms=latencies_ms,
                timeout=args.timeout,
            )
            dataset_summaries.append(
                DatasetSummary(path=dataset_path, dataset_type=dataset_type, hits=hits, total=total)
            )

    if dataset_summaries:
        dataset_rows = ["| Dataset | Type | Accuracy | Hits |", "| --- | --- | --- | --- |"]
        for summary in dataset_summaries:
            dataset_rows.append(
                (
                    f"| {summary.path} | {summary.dataset_type} | "
                    f"{summary.value:.3f} | {summary.hits}/{summary.total} |"
                )
            )
        print(*dataset_rows, sep=chr(10))
        print()

    table = build_table(metrics, args.bench, latencies_ms)
    print(table)
    print()

    smyth_value = metrics["smyth"].value
    lsj_value = metrics["lsj"].value
    summary_line = (
        f"Overall: Smyth@5 {smyth_value:.3f} ({metrics['smyth'].hits}/{metrics['smyth'].total}), "
        f"LSJ headword {lsj_value:.3f} ({metrics['lsj'].hits}/{metrics['lsj'].total})"
    )
    print(summary_line)

    if misses:
        print()
        for key, records in misses.items():
            print(f"Misses for {key}: {len(records)}")
            for miss in records:
                print(
                    f"  - {miss.query} (expected={miss.expected}, observed={miss.observed})"
                    f" [{miss.path}:{miss.line}]"
                )

    artifact_path = Path("artifacts") / "accuracy_summary.json"
    write_artifact(
        metrics,
        dataset_summaries,
        misses,
        dataset_misses,
        latencies_ms,
        args.bench,
        artifact_path,
    )

    exit_ok = smyth_value >= metrics["smyth"].gate and lsj_value >= metrics["lsj"].gate
    return 0 if exit_ok else 1


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except httpx.HTTPError as exc:
        print(f"HTTP error during accuracy run: {exc}", file=sys.stderr)
        raise SystemExit(2)
    except Exception as exc:  # pragma: no cover
        print(f"ERROR: {exc}", file=sys.stderr)
        raise SystemExit(3)
