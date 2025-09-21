import logging
import re
from typing import Any, Callable, Tuple

from app.core.config import settings

_SENSITIVE_KEYWORDS = {
    "api_key",
    "openai_api_key",
    "anthropic_api_key",
    "elevenlabs_api_key",
}
_SENSITIVE_KEYWORDS.update(settings.BYOK_ALLOWED_HEADERS)
_SENSITIVE_KEYWORDS.update(header.replace("-", "_") for header in settings.BYOK_ALLOWED_HEADERS)


def _scrub_text(text: str) -> str:
    """Mask any API key values found in the string."""
    if not isinstance(text, str) or not text:
        return text
    masked = text
    for keyword in _SENSITIVE_KEYWORDS:
        pattern = re.escape(keyword)
        masked = re.sub(
            rf'(?i)("(?P<key>{pattern})"\s*:\s*")(?P<val>[^"]+)"',
            lambda m: f'{m.group(1)}***"',
            masked,
        )
        masked = re.sub(
            rf"(?i)('(?P<key>{pattern})'\s*:\s*')(?P<val>[^']+)'",
            lambda m: f"{m.group(1)}***'",
            masked,
        )
        masked = re.sub(
            rf"(?i)(?P<key>{pattern})\s*=\s*(?P<val>[^&\s,\'\"]+)",
            lambda m: f'{m.group("key")}="***"',
            masked,
        )
        masked = re.sub(
            rf"(?i)(?P<key>{pattern})\s*:\s*(?P<val>[^\r\n]+)",
            lambda m: f"{m.group('key')}: ***",
            masked,
        )
    return masked


class SensitiveFilter(logging.Filter):
    """Secondary safety net: mask keys if present in the final formatted msg."""

    def filter(self, record: logging.LogRecord) -> bool:
        # Use getMessage() which handles formatting if args exist
        msg = record.getMessage()
        # Optimization: check for the phrase before running regex
        lower = msg.lower()
        if any(keyword in lower for keyword in _SENSITIVE_KEYWORDS):
            # Rewrite msg and clear args to avoid re-formatting with stale values
            record.msg = _scrub_text(msg)
            record.args = ()
        return True


_configured = False


def _sanitizing_record_factory(orig_factory: Callable[..., logging.LogRecord]):
    """The core interception point: scrubs the record upon creation."""

    def factory(*args: Any, **kwargs: Any) -> logging.LogRecord:
        record = orig_factory(*args, **kwargs)
        # Scrub raw msg
        if isinstance(record.msg, str):
            record.msg = _scrub_text(record.msg)
        # Scrub any string args (if %-style formatting is used)
        if isinstance(record.args, Tuple) and record.args:
            new_args: list[Any] = []
            for a in record.args:
                new_args.append(_scrub_text(a) if isinstance(a, str) else a)
            record.args = tuple(new_args)
        return record

    return factory


def setup_logging() -> None:
    """Idempotent setup: install record factory scrub + root filter."""
    global _configured
    if _configured:
        return

    # Attach a basic handler only if none exist (pytest/caplog adds its own)
    root = logging.getLogger()
    if not root.handlers:
        logging.basicConfig(
            level=logging.INFO,
            format="%(asctime)s - %(name)s - %(levelname)s - %(message)s",
        )

    # 1. Install sanitizing record factory (affects all handlers including caplog)
    orig = logging.getLogRecordFactory()
    logging.setLogRecordFactory(_sanitizing_record_factory(orig))

    # 2. Add a filter on the root for belt-and-suspenders protection
    if not any(isinstance(f, SensitiveFilter) for f in root.filters):
        root.addFilter(SensitiveFilter())

    _configured = True
