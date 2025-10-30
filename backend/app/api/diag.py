from __future__ import annotations

import hashlib
import logging
import os
from typing import Any

from fastapi import APIRouter, Request

from app.security.byok import extract_byok_token

try:
    import httpx  # type: ignore[import]
except ImportError:  # pragma: no cover - optional dependency
    httpx = None  # type: ignore[assignment]

_LOGGER = logging.getLogger("app.api.diag.byok")

router = APIRouter(prefix="/diag/byok", tags=["Diagnostics"])


@router.get("/openai")
async def byok_openai_probe(request: Request) -> dict[str, Any]:
    if httpx is None:  # pragma: no cover - env misconfiguration
        raise RuntimeError("httpx is required for the BYOK probe")

    token = extract_byok_token(
        request.headers,
        allowed=("authorization", "x-model-key"),
    )
    base_url = _resolve_openai_base()
    endpoint = f"{base_url}/models"
    headers = {"Content-Type": "application/json"}
    if token:
        headers["Authorization"] = f"Bearer {token}"

    base_hash = _hash_base(base_url)
    timeout = httpx.Timeout(5.0, connect=3.0, read=5.0)

    try:
        async with httpx.AsyncClient(timeout=timeout) as client:
            response = await client.get(endpoint, headers=headers)
    except httpx.TimeoutException:
        _LOGGER.debug("OpenAI BYOK probe timeout base_hash=%s", base_hash)
        return {
            "ok": False,
            "status": 0,
            "reason": "openai_timeout",
            "base_url": base_url,
            "timeout": _timeout_payload(timeout),
        }
    except httpx.HTTPError:
        _LOGGER.debug("OpenAI BYOK probe network error base_hash=%s", base_hash)
        return {
            "ok": False,
            "status": 0,
            "reason": "openai_network",
            "base_url": base_url,
            "timeout": _timeout_payload(timeout),
        }

    status = response.status_code
    _LOGGER.debug("OpenAI BYOK probe status=%s base_hash=%s", status, base_hash)

    if status == 200:
        model_hint = _extract_model_hint(response)
        return {
            "ok": True,
            "status": status,
            "model_hint": model_hint,
            "base_url": base_url,
            "timeout": _timeout_payload(timeout),
        }

    reason = _map_probe_reason(status)
    return {
        "ok": False,
        "status": status,
        "reason": reason,
        "base_url": base_url,
        "timeout": _timeout_payload(timeout),
    }


def _resolve_openai_base() -> str:
    override = os.getenv("OPENAI_API_BASE")
    if override and override.strip():
        return override.strip().rstrip("/")
    return "https://api.openai.com/v1"


def _hash_base(base_url: str) -> str:
    digest = hashlib.sha256(base_url.encode("utf-8")).hexdigest()
    return digest[:10]


def _map_probe_reason(status: int) -> str:
    if status == 401:
        return "openai_401"
    if status == 403:
        return "openai_403"
    if status == 404:
        return "openai_404"
    return f"openai_http_{status}"


def _extract_model_hint(response: Any) -> str | None:
    try:
        payload = response.json()
    except ValueError:
        return None
    if not isinstance(payload, dict):
        return None
    data = payload.get("data")
    if isinstance(data, list) and data:
        first = data[0]
        if isinstance(first, dict):
            model_id = first.get("id")
            if isinstance(model_id, str):
                return model_id
        if isinstance(first, str):
            return first
    return None


def _timeout_payload(timeout) -> dict[str, float | None]:
    return {
        "connect": getattr(timeout, "connect", None),
        "read": getattr(timeout, "read", None),
        "write": getattr(timeout, "write", None),
        "pool": getattr(timeout, "pool", None),
    }
