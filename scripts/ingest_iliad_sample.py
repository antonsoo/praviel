import argparse
import asyncio
import sys
from pathlib import Path
from typing import Any, Dict, Tuple

sys.path.insert(0, str(Path(__file__).parent.parent / "backend"))

from app.core.config import settings
from app.db.session import SessionLocal
from app.ingestion.jobs import ingest_iliad_sample

DEFAULT_SLICE = "1.1-1.50"


def _parse_line_ref(value: str) -> int:
    try:
        book_part, line_part = value.split(".", 1)
    except ValueError as exc:
        raise argparse.ArgumentTypeError(f"Invalid ref '{value}' (expected format 1.23)") from exc
    try:
        book = int(book_part)
        line = int(line_part)
    except ValueError as exc:
        raise argparse.ArgumentTypeError(f"Invalid ref '{value}' (non-numeric component)") from exc
    if book != 1:
        raise argparse.ArgumentTypeError("Only Book 1 is supported in the demo ingest")
    if line < 1:
        raise argparse.ArgumentTypeError("Line numbers must be >= 1")
    return line


def _parse_slice(spec: str, start_override: str | None, end_override: str | None) -> Tuple[int, int]:
    parts = spec.split("-", 1)
    if len(parts) != 2:
        raise argparse.ArgumentTypeError("Slice must use the format 1.start-1.end")
    base_start, base_end = parts
    start_ref = start_override or base_start
    end_ref = end_override or base_end
    start_line = _parse_line_ref(start_ref)
    end_line = _parse_line_ref(end_ref)
    if end_line < start_line:
        raise argparse.ArgumentTypeError("End ref must not precede start ref")
    return start_line, end_line


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Ingest a demo slice of Iliad Book 1")
    parser.add_argument(
        "--slice",
        default=DEFAULT_SLICE,
        help="Inclusive slice to ingest (format: 1.start-1.end; default 1.1-1.50)",
    )
    parser.add_argument("--start", help="Override the start ref (e.g. 1.5)")
    parser.add_argument("--end", help="Override the end ref (e.g. 1.25)")
    return parser.parse_args()


def _resolve_paths() -> Tuple[Path, Path]:
    root = Path(settings.DATA_VENDOR_ROOT)
    tei = root / "perseus" / "iliad" / "book1.xml"
    tokens = root / "perseus" / "iliad" / "book1_tokens.xml"
    if not tei.exists():
        raise FileNotFoundError(f"Missing Iliad TEI at {tei}")
    return tei, tokens


async def _run_ingest(tei: Path, tokens: Path, start_line: int, end_line: int) -> Dict[str, Any]:
    async with SessionLocal() as db:
        return await ingest_iliad_sample(
            db,
            tei,
            tokens,
            start_line=start_line,
            end_line=end_line,
        )


def _format_summary(result: Dict[str, Any]) -> str:
    slice_info = result.get("slice", {}) if isinstance(result, dict) else {}
    start_ref = slice_info.get("start", "1.1") if isinstance(slice_info, dict) else "1.1"
    end_ref = slice_info.get("end", start_ref)
    added = result.get("segments_added", "?") if isinstance(result, dict) else "?"
    total = result.get("segments_total", "?") if isinstance(result, dict) else "?"
    return f"Ingested Iliad lines {start_ref}–{end_ref} ({added} added, {total} total)."


def main() -> None:
    args = parse_args()
    start_line, end_line = _parse_slice(args.slice, args.start, args.end)
    tei, tokens = _resolve_paths()
    result = asyncio.run(_run_ingest(tei, tokens, start_line, end_line))
    print(_format_summary(result))


if __name__ == "__main__":
    main()
