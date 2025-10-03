"""Provider health check endpoint for testing vendor API connectivity"""
from __future__ import annotations

import time
from typing import Any

from fastapi import APIRouter, Depends

from app.core.config import Settings, get_settings

router = APIRouter()


@router.get("/health/providers")
async def health_providers(
    settings: Settings = Depends(get_settings),
) -> dict[str, Any]:
    """Test connectivity to all vendor APIs"""
    try:
        import httpx
    except ImportError:
        return {
            "error": "httpx not installed",
            "timestamp": int(time.time()),
        }

    results: dict[str, Any] = {}
    timeout = httpx.Timeout(8.0)

    async with httpx.AsyncClient(timeout=timeout) as client:
        # Test Anthropic
        if settings.ANTHROPIC_API_KEY:
            try:
                resp = await client.post(
                    "https://api.anthropic.com/v1/messages",
                    headers={
                        "x-api-key": settings.ANTHROPIC_API_KEY,
                        "anthropic-version": "2023-06-01",
                        "content-type": "application/json",
                    },
                    json={
                        "model": "claude-sonnet-4-20250514",
                        "max_tokens": 8,
                        "messages": [{"role": "user", "content": [{"type": "text", "text": "ping"}]}],
                    },
                )
                ok = resp.status_code == 200
                results["anthropic"] = {
                    "ok": ok,
                    "status": resp.status_code,
                    "error": None if ok else resp.text[:200],
                }
            except Exception as e:
                results["anthropic"] = {"ok": False, "status": None, "error": str(e)[:200]}
        else:
            results["anthropic"] = {"ok": False, "status": None, "error": "API key not configured"}

        # Test Gemini (Google)
        if settings.GOOGLE_API_KEY:
            try:
                # Note: Using v1beta for latest models
                url = f"https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key={settings.GOOGLE_API_KEY}"
                resp = await client.post(
                    url,
                    json={"contents": [{"parts": [{"text": "ping"}]}]},
                )
                ok = resp.status_code == 200
                results["google"] = {
                    "ok": ok,
                    "status": resp.status_code,
                    "error": None if ok else resp.text[:200],
                }
            except Exception as e:
                results["google"] = {"ok": False, "status": None, "error": str(e)[:200]}
        else:
            results["google"] = {"ok": False, "status": None, "error": "API key not configured"}

        # Test OpenAI
        if settings.OPENAI_API_KEY:
            try:
                resp = await client.post(
                    "https://api.openai.com/v1/chat/completions",
                    headers={
                        "Authorization": f"Bearer {settings.OPENAI_API_KEY}",
                        "Content-Type": "application/json",
                    },
                    json={
                        "model": "gpt-4o-mini",
                        "messages": [{"role": "user", "content": "ping"}],
                        "max_tokens": 8,
                    },
                )
                ok = resp.status_code == 200
                results["openai"] = {
                    "ok": ok,
                    "status": resp.status_code,
                    "error": None if ok else resp.text[:200],
                }
            except Exception as e:
                results["openai"] = {"ok": False, "status": None, "error": str(e)[:200]}
        else:
            results["openai"] = {"ok": False, "status": None, "error": "API key not configured"}

    results["timestamp"] = int(time.time())
    return results
