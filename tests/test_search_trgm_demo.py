from __future__ import annotations

import json
import os
import subprocess
import sys
from pathlib import Path

import pytest

RUN_DB = os.getenv("RUN_DB_TESTS") == "1"


@pytest.mark.skipif(not RUN_DB, reason="Set RUN_DB_TESTS=1 to run DB-backed tests")
def test_search_trgm_cli_returns_hits() -> None:
    repo_root = Path(__file__).resolve().parent.parent
    tei = repo_root / "tests" / "fixtures" / "perseus_sample_annotated_greek.xml"
    assert tei.exists(), "Sample TEI fixture missing"

    subprocess.run(["docker", "compose", "up", "-d", "db"], check=True)

    backend_path = repo_root / "backend"
    env = os.environ.copy()
    env.setdefault("PYTHONPATH", str(backend_path))
    env.setdefault("DATABASE_URL", "postgresql+asyncpg://app:app@localhost:5433/app")
    env.setdefault("DATABASE_URL_SYNC", "postgresql+psycopg://app:app@localhost:5433/app")

    alembic_env = env.copy()
    alembic_env["DATABASE_URL"] = env["DATABASE_URL_SYNC"]
    subprocess.run(
        [sys.executable, "-m", "alembic", "-c", "alembic.ini", "upgrade", "head"],
        check=True,
        env=alembic_env,
        cwd=repo_root,
    )

    ingest_env = env.copy()
    ingest_env["PYTHONPATH"] = "."
    ingest_env["PYTHONIOENCODING"] = "utf-8"
    ingest_env["DATABASE_URL_SYNC"] = env["DATABASE_URL_SYNC"]
    subprocess.run(
        [
            sys.executable,
            "-m",
            "pipeline.perseus_ingest",
            "--tei",
            str(tei),
            "--language",
            "grc",
            "--source",
            "perseus-sample",
            "--ensure-table",
        ],
        check=True,
        cwd=backend_path,
        env=ingest_env,
    )

    search_env = env.copy()
    search_env["PYTHONPATH"] = str(backend_path)
    search_env["PYTHONIOENCODING"] = "utf-8"
    search_env["DATABASE_URL_SYNC"] = env["DATABASE_URL_SYNC"]
    proc = subprocess.run(
        [
            sys.executable,
            "-m",
            "pipeline.search_trgm",
            "Μῆνιν",
            "-k",
            "3",
            "-t",
            "0.05",
        ],
        check=True,
        capture_output=True,
        text=True,
        cwd=repo_root,
        env=search_env,
    )

    lines = [line for line in proc.stdout.splitlines() if line.strip()]
    assert lines, "Expected search CLI output"
    first = json.loads(lines[0])
    assert first.get("text")
    assert "idx" in first
