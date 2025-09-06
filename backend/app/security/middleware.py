import json

from starlette.requests import Request
from starlette.responses import Response
from starlette.types import Message

SENSITIVE_KEYS = {
    "api_key",
    "openai_api_key",
    "anthropic_api_key",
    "elevenlabs_api_key",
}


async def _reset_body(request: Request, body: bytes):
    async def receive() -> Message:
        return {"type": "http.request", "body": body}

    request._receive = receive


async def redact_api_keys_middleware(request: Request, call_next):
    ctype = request.headers.get("content-type", "")
    if ctype.startswith("application/json"):
        body = await request.body()
        await _reset_body(request, body)
        try:
            data = json.loads(body.decode("utf-8"))

            def scrub(x):
                if isinstance(x, dict):
                    return {k: ("***" if k.lower() in SENSITIVE_KEYS else scrub(v)) for k, v in x.items()}
                if isinstance(x, list):
                    return [scrub(v) for v in x]
                return x

            request.state.redacted_body = scrub(data)
        except Exception:
            request.state.redacted_body = None
    response: Response = await call_next(request)
    return response
