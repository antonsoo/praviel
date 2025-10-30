"""License enforcement helpers for TTS requests."""

from __future__ import annotations

import json
import logging
import re
from typing import Any

from sqlalchemy import text

from app.db.session import SessionLocal

_LOGGER = logging.getLogger("app.tts.license_guard")
_REF_PATTERN = re.compile(r"(?P<label>[A-Za-z]{1,4})\.(?P<ref>\d+(?:[.:-]\d+)*)")


async def evaluate_tts_request(text_value: str) -> dict[str, str] | None:
    """
    Inspect the request text and return a violation detail payload when TTS should be blocked.
    Returns None when no guard applies.
    """
    label_ref = _extract_reference(text_value)
    if not label_ref:
        return None

    label, ref = label_ref
    try:
        license_meta, source_title = await _fetch_license(label, ref)
    except Exception as exc:  # pragma: no cover - defensive guard
        _LOGGER.warning("license lookup failed label=%s ref=%s: %s", label, ref, exc)
        return None

    if not license_meta:
        return None

    if _is_restricted(license_meta):
        return {
            "reason": "TTS disabled for non-commercial source",
            "ref": f"{label}.{ref}",
            "license": _summarize_license(license_meta),
            "source": source_title or label,
        }
    return None


def _extract_reference(text_value: str) -> tuple[str, str] | None:
    if not text_value:
        return None
    match = _REF_PATTERN.search(text_value)
    if not match:
        return None
    label = match.group("label") or ""
    ref = match.group("ref") or ""
    label = label.strip()
    ref = ref.strip()
    if not label or not ref:
        return None
    return label, ref


async def _fetch_license(label: str, ref: str) -> tuple[Any | None, str | None]:
    async with SessionLocal() as session:
        result = await session.execute(
            text(
                """
                SELECT sd.license, sd.title AS source_title, tw.title AS work_title, tw.author AS work_author
                FROM text_segment AS ts
                JOIN text_work AS tw ON tw.id = ts.work_id
                JOIN source_doc AS sd ON sd.id = tw.source_id
                WHERE ts.ref = :ref
                """
            ),
            {"ref": ref},
        )
        for row in result.mappings():
            if _matches_label(label, row.get("work_title"), row.get("work_author")):
                return row.get("license"), row.get("source_title") or row.get("work_title")
    return None, None


def _matches_label(label: str, title: str | None, author: str | None) -> bool:
    normalized = (label or "").strip().lower()
    if not normalized:
        return False
    for candidate in (title, author):
        abbrev = _abbreviate(candidate)
        if abbrev and abbrev.lower() == normalized:
            return True
    return False


def _abbreviate(value: str | None) -> str | None:
    if not value:
        return None
    stripped = "".join(ch for ch in value.strip() if ch.isalpha())
    if not stripped:
        return None
    if len(stripped) >= 2:
        return stripped[:2].capitalize()
    return stripped.capitalize()


def _is_restricted(payload: Any) -> bool:
    text_parts: list[str] = []

    def _collect(value: Any) -> None:
        if value is None:
            return
        if isinstance(value, str):
            text_parts.append(value)
        elif isinstance(value, (list, tuple, set)):
            for item in value:
                _collect(item)
        elif isinstance(value, dict):
            for item in value.values():
                _collect(item)
        else:
            text_parts.append(str(value))

    _collect(payload)
    if not text_parts:
        return False
    lowered = " ".join(text_parts).lower()
    noncommercial_markers = ("noncommercial", "non-commercial", "non commercial", "no-tts")
    restricted_markers = ("nc", *noncommercial_markers)
    license_markers = ("cc", "license", "rights", "all rights")
    if any(marker in lowered for marker in restricted_markers):
        if "nc" in lowered and "cc" in lowered:
            return True
        if any(marker in lowered for marker in noncommercial_markers):
            return True
        if any(marker in lowered for marker in license_markers):
            return True
    return False


def _summarize_license(payload: Any) -> str:
    if isinstance(payload, str):
        return payload
    if isinstance(payload, dict):
        for key in ("license", "name", "id", "code"):
            value = payload.get(key)
            if isinstance(value, str) and value.strip():
                return value
        return json.dumps(payload, ensure_ascii=False)
    return str(payload)
