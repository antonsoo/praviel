from __future__ import annotations

import os
import subprocess
import sys
from importlib import reload
from pathlib import Path

import httpx
import pytest

RUN_DB = os.getenv("RUN_DB_TESTS") == "1"


@pytest.mark.skipif(not RUN_DB, reason="Set RUN_DB_TESTS=1 to run DB-backed tests")
@pytest.mark.asyncio
async def test_search_endpoint_returns_results() -> None:
    repo_root = Path(__file__).resolve().parent.parent
    tei = repo_root / "tests" / "fixtures" / "perseus_sample_annotated_greek.xml"
    assert tei.exists(), "Sample TEI fixture missing"

    subprocess.run(["docker", "compose", "up", "-d", "db"], check=True)

    env = os.environ.copy()
    backend_path = repo_root / "backend"
    env.setdefault("PYTHONPATH", str(backend_path))
    env.setdefault("DATABASE_URL", "postgresql+psycopg://app:app@localhost:5433/app")

    subprocess.run(
        [sys.executable, "-m", "alembic", "-c", "alembic.ini", "upgrade", "head"],
        check=True,
        env=env,
        cwd=repo_root,
    )

    ingest_env = env.copy()
    ingest_env["PYTHONPATH"] = "."
    ingest_env["PYTHONIOENCODING"] = "utf-8"
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

    sys.path.insert(0, str(backend_path))
    import app.main as app_main  # type: ignore

    reload(app_main)
    app = app_main.app

    async with httpx.AsyncClient(
        transport=httpx.ASGITransport(app=app),
        base_url="http://testserver",
    ) as client:
        response = await client.get(
            "/search",
            params={"q": "?????", "l": "grc", "k": 3, "t": 0.05},
            timeout=30.0,
        )

    assert response.status_code == 200, response.text
    payload = response.json()
    assert isinstance(payload, list)
    assert payload, "Expected at least one search hit"
    first = payload[0]
    assert "text" in first and first["text"]
    assert "idx" in first
    assert first.get("lang") in {None, "grc"}
