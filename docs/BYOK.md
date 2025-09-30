# Bring Your Own Key (BYOK)

BYOK keeps API tokens request-scoped. The service never persists or logs user-provided keys and the FastAPI dependency only exposes the token for the lifetime of the request context.

## Supported Providers

- **echo** — Offline, deterministic provider (no key required)
- **anthropic** — Claude models (Sonnet 4.5, Opus 4.1, Sonnet 4, Opus 4)
- **openai** — GPT models (GPT-5, GPT-5 mini, GPT-5 nano)
- **google** — Gemini models (2.5 Flash, 2.5 Flash-Lite, 2.5 Flash Preview)

## Headers

The server accepts the following headers (case insensitive):

- `Authorization: Bearer <token>` — standard bearer token form (used for Anthropic, OpenAI, Google)
- `X-Model-Key: <token>` — raw key for vendor-specific integrations

The allowlist is driven by `settings.BYOK_ALLOWED_HEADERS` and logging filters redact the values of those headers before any request/response data is written, satisfying the handbook guideline of no secrets in logs.

## Provider-specific authentication

- **Anthropic**: Uses `x-api-key` header internally, but accepts `Authorization: Bearer` for consistency
- **OpenAI**: Standard `Authorization: Bearer` header
- **Google**: API key passed as query parameter (internally managed)

## Enabling BYOK

Set `BYOK_ENABLED=true` to activate the dependency. When disabled (default), `get_byok_token()` always returns `None` and the middleware still redacts the headers for safety. When enabled:

1. `get_byok_token()` captures the token from the first matching header.
2. The token is stored in `request.state.byok` for downstream dependencies.
3. Middleware strips the sensitive header values from request/response logs.

Always turn off BYOK in shared environments where secrets should not be forwarded, and ensure vendor requests are performed over HTTPS.
