import os
import subprocess
import sys
from pathlib import Path

import pytest

RUN_DB = os.getenv("RUN_DB_TESTS") == "1"


@pytest.mark.skipif(not RUN_DB, reason="Set RUN_DB_TESTS=1 to run DB integration tests")
def test_search_trgm_demo_end_to_end(tmp_path):
    root = Path.cwd()
    tei = root / "tests" / "fixtures" / "perseus_sample_annotated_greek.xml"
    assert tei.exists(), "fixture missing"

    subprocess.run(["docker", "compose", "up", "-d", "db"], check=True)
    subprocess.run(["alembic", "upgrade", "head"], check=True)

    cmd_ingest = [
        "ancient-mvp",
        "--tei",
        str(tei),
        "--language",
        "grc",
        "--ensure-table",
    ]
    result = subprocess.run(cmd_ingest, capture_output=True, text=True)
    if result.returncode != 0:
        pkg_root = root / "backend"
        result = subprocess.run(
            [
                sys.executable,
                "-m",
                "pipeline.perseus_ingest",
                "--tei",
                str(tei),
                "--language",
                "grc",
                "--ensure-table",
            ],
            cwd=pkg_root,
            capture_output=True,
            text=True,
        )
        assert result.returncode == 0, result.stderr

    query = "Μῆνιν"
    cmd_search = [
        "ancient-search",
        "--q",
        query,
        "-l",
        "grc",
        "-k",
        "3",
        "-t",
        "0.05",
    ]
    search = subprocess.run(cmd_search, capture_output=True, text=True)
    if search.returncode != 0:
        pkg_root = root / "backend"
        search = subprocess.run(
            [
                sys.executable,
                "-m",
                "pipeline.search_trgm",
                "--q",
                query,
                "-l",
                "grc",
                "-k",
                "3",
                "-t",
                "0.05",
            ],
            cwd=pkg_root,
            capture_output=True,
            text=True,
        )
    assert search.returncode == 0, search.stderr
    output = search.stdout.strip()
    assert "Μῆνιν" in output or "Μηνιν" in output, output
    assert "score=" in output, output
