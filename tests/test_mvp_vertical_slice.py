from __future__ import annotations

import os
import subprocess
import sys
from pathlib import Path

import pytest

RUN_DB = os.getenv("RUN_DB_TESTS") == "1"


@pytest.mark.skipif(not RUN_DB, reason="Set RUN_DB_TESTS=1 to run DB integration tests")
def test_perseus_ingest_vertical_slice() -> None:
    tei = Path("tests/fixtures/perseus_sample_annotated_greek.xml").resolve()
    assert tei.exists()

    subprocess.run(["docker", "compose", "up", "-d", "db"], check=True)
    subprocess.run(["alembic", "-c", "backend/alembic.ini", "upgrade", "head"], check=True)

    env = os.environ.copy()
    env.setdefault("PYTHONPATH", ".")
    cmd = [
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
    ]
    proc = subprocess.run(
        cmd,
        cwd=Path("backend"),
        env=env,
        check=False,
        capture_output=True,
        text=True,
    )
    assert proc.returncode == 0, proc.stderr
    stdout = proc.stdout.strip()
    assert stdout.startswith("Inserted="), stdout
    assert "Work=" in stdout, stdout
