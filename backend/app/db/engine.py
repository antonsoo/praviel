"""
Utilities for creating asyncpg-backed SQLAlchemy engines with safe SSL handling.

Railway/Neon style DATABASE_URL strings often include ``sslmode`` (and related)
query parameters that asyncpg does not understand. This module normalizes those
URLs and converts SSL-related options into ``connect_args`` that asyncpg accepts.

IMPORTANT - Neon Pooled Connections (PgBouncer):
    When using Neon's pooled connections (URLs with "-pooler" in hostname), you MUST
    disable prepared statements to avoid "password authentication failed" errors.
    This is handled automatically in session.py by detecting "-pooler" and setting:
        - statement_cache_size=0
        - prepared_statement_cache_size=0

    See: https://github.com/sqlalchemy/sqlalchemy/issues/6467
    See: https://neon.com/docs/connect/connection-pooling
"""

from __future__ import annotations

import logging
import os
import ssl
from typing import Any, Dict, Tuple

from sqlalchemy.engine import URL, make_url
from sqlalchemy.ext.asyncio import AsyncEngine, create_async_engine

_LOGGER = logging.getLogger("app.db.engine")

_FALSE_VALUES = {"0", "false", "off", "no"}
_TRUE_VALUES = {"1", "true", "on", "yes"}


def _expand_path(value: str | None) -> str | None:
    """Expand environment variables and user home references in filesystem paths."""
    if not value:
        return None
    return os.path.expanduser(os.path.expandvars(value))


def _to_lower_str(value: Any) -> str:
    """Coerce a query param value (possibly list/bool/int) to a lower-cased string."""
    if isinstance(value, (list, tuple)):
        if not value:
            return ""
        value = value[-1]
    if isinstance(value, bool):
        return "true" if value else "false"
    return str(value).strip().lower()


def _build_ssl_context(
    *,
    mode: str,
    sslrootcert: str | None,
    sslcert: str | None,
    sslkey: str | None,
) -> ssl.SSLContext:
    """
    Build an SSLContext matching libpq sslmode semantics for asyncpg.

    - disable: handled before context creation.
    - allow/prefer/require/verify-full: default context with hostname checks.
    - verify-ca: verification without hostname validation.
    """
    context = ssl.create_default_context()

    root_cert_path = _expand_path(sslrootcert)
    if root_cert_path:
        try:
            context.load_verify_locations(cafile=root_cert_path)
        except FileNotFoundError as exc:
            raise RuntimeError(f"sslrootcert not found at {root_cert_path}") from exc

    cert_path = _expand_path(sslcert)
    key_path = _expand_path(sslkey)
    if cert_path:
        try:
            context.load_cert_chain(certfile=cert_path, keyfile=key_path)
        except FileNotFoundError as exc:
            raise RuntimeError(f"sslcert not found at {cert_path}") from exc

    mode_lower = mode.lower()
    if mode_lower == "verify-ca":
        context.check_hostname = False
        context.verify_mode = ssl.CERT_REQUIRED
    else:
        # prefer/allow/require/verify-full default to full verification
        context.check_hostname = True
        context.verify_mode = ssl.CERT_REQUIRED

    return context


def normalize_asyncpg_url(raw_url: str) -> Tuple[str, Dict[str, Any]]:
    """
    Normalize an asyncpg SQLAlchemy URL by stripping unsupported query params
    and translating them into asyncpg-compatible connect arguments.

    Returns:
        tuple(url, connect_args)
    """
    sa_url: URL = make_url(raw_url)
    query: Dict[str, Any] = dict(sa_url.query)
    connect_args: Dict[str, Any] = {}

    ssl_flag = query.pop("ssl", None)
    sslmode = query.pop("sslmode", None)
    sslrootcert = query.pop("sslrootcert", None)
    sslcert = query.pop("sslcert", None)
    sslkey = query.pop("sslkey", None)

    ssl_configured = False

    if ssl_flag is not None:
        ssl_flag_value = _to_lower_str(ssl_flag)
        if ssl_flag_value in _FALSE_VALUES:
            connect_args["ssl"] = False
            ssl_configured = True
        elif ssl_flag_value in _TRUE_VALUES:
            if any([sslrootcert, sslcert, sslkey]):
                connect_args["ssl"] = _build_ssl_context(
                    mode="require",
                    sslrootcert=sslrootcert,
                    sslcert=sslcert,
                    sslkey=sslkey,
                )
            else:
                connect_args["ssl"] = True
            ssl_configured = True
        else:
            _LOGGER.warning("Unrecognized ssl query value '%s'; defaulting to ssl=True", ssl_flag_value)
            connect_args["ssl"] = True
            ssl_configured = True

    if not ssl_configured and sslmode is not None:
        sslmode_value = _to_lower_str(sslmode)
        if sslmode_value == "disable":
            connect_args["ssl"] = False
            ssl_configured = True
        elif sslmode_value in {"allow", "prefer", "require", "verify-full", "verify-ca"}:
            connect_args["ssl"] = _build_ssl_context(
                mode=sslmode_value,
                sslrootcert=sslrootcert,
                sslcert=sslcert,
                sslkey=sslkey,
            )
            ssl_configured = True
            _LOGGER.info("Configured asyncpg SSL using sslmode=%s", sslmode_value)
        else:
            raise RuntimeError(f"Unsupported sslmode '{sslmode_value}' in DATABASE_URL")

    if not ssl_configured and any([sslrootcert, sslcert, sslkey]):
        # Certificates provided without explicit directive -> assume require
        connect_args["ssl"] = _build_ssl_context(
            mode="require",
            sslrootcert=sslrootcert,
            sslcert=sslcert,
            sslkey=sslkey,
        )
        ssl_configured = True
        _LOGGER.info("Configured asyncpg SSL using provided certificates (default require).")

    # Remove any unused SSL params from the query string
    for key in ("sslmode", "ssl", "sslrootcert", "sslcert", "sslkey"):
        query.pop(key, None)

    normalized_url = sa_url.set(query=query)
    return str(normalized_url), connect_args


def create_asyncpg_engine(
    raw_url: str,
    *,
    connect_args: Dict[str, Any] | None = None,
    **engine_kwargs: Any,
) -> AsyncEngine:
    """
    Create an asyncpg AsyncEngine with automatic SSL normalization.
    """
    normalized_url, ssl_connect_args = normalize_asyncpg_url(raw_url)

    merged_connect_args: Dict[str, Any] = {}
    if ssl_connect_args:
        merged_connect_args.update(ssl_connect_args)
    if connect_args:
        merged_connect_args.update(connect_args)

    if merged_connect_args:
        engine_kwargs = {**engine_kwargs, "connect_args": merged_connect_args}

    return create_async_engine(normalized_url, **engine_kwargs)


__all__ = ["create_asyncpg_engine", "normalize_asyncpg_url"]
