import os

from pydantic import Field, field_validator, model_validator
from pydantic_settings import BaseSettings, SettingsConfigDict

# Absolute path to backend/
BASE_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))


def _abs_from_backend(rel: str) -> str:
    return os.path.normpath(os.path.abspath(os.path.join(BASE_DIR, rel)))


class Settings(BaseSettings):
    # Required
    DATABASE_URL: str
    REDIS_URL: str

    # Core
    EMBED_DIM: int = Field(default=1536)
    API_V1_STR: str = "/api/v1"
    PROJECT_NAME: str = "PRAVIEL API (LDSv1)"
    ENVIRONMENT: str = Field(default="dev")
    ALLOW_DEV_CORS: bool = Field(default=False)
    BYOK_ENABLED: bool = Field(default=False)
    BYOK_ALLOWED_HEADERS: list[str] = Field(
        default_factory=lambda: ["authorization", "x-model-key"],
    )
    COACH_ENABLED: bool = Field(default=False)
    # October 2025 Model Defaults - See docs/AI_AGENT_GUIDELINES.md
    # DO NOT change these to older model names (gpt-4, claude-3, etc.)
    # Using dated models for production stability (recommended over aliases)
    # ⚠️ PROTECTED BY VALIDATION - See _validate_model_versions below
    COACH_DEFAULT_MODEL: str | None = Field(default="gpt-5-mini-2025-08-07")
    LESSONS_ENABLED: bool = Field(default=False)
    LESSONS_OPENAI_DEFAULT_MODEL: str = Field(default="gpt-5-nano-2025-08-07")
    LESSONS_ANTHROPIC_DEFAULT_MODEL: str = Field(default="claude-sonnet-4-5-20250929")
    LESSONS_GOOGLE_DEFAULT_MODEL: str = Field(default="gemini-2.5-flash")
    TTS_ENABLED: bool = Field(default=False)
    TTS_LICENSE_GUARD: bool = Field(default=True)
    TTS_DEFAULT_MODEL: str = Field(default="tts-1")  # OpenAI TTS: tts-1 or tts-1-hd
    TTS_GOOGLE_DEFAULT_MODEL: str = Field(default="gemini-2.5-flash-tts")  # Gemini TTS

    # Health check models (for testing vendor API connectivity) - October 2025
    HEALTH_OPENAI_MODEL: str = Field(default="gpt-5-mini-2025-08-07")
    HEALTH_ANTHROPIC_MODEL: str = Field(default="claude-sonnet-4-5-20250929")
    HEALTH_GOOGLE_MODEL: str = Field(default="gemini-2.5-flash")

    # Vendor API Keys (server-side BYOK)
    OPENAI_API_KEY: str | None = Field(default=None)
    ANTHROPIC_API_KEY: str | None = Field(default=None)
    GOOGLE_API_KEY: str | None = Field(default=None)

    # Demo API Keys (free tier for non-technical users)
    # These keys are used as fallback when users don't have their own keys
    # Set to None to disable demo keys for a specific provider
    DEMO_OPENAI_API_KEY: str | None = Field(default=None)
    DEMO_ANTHROPIC_API_KEY: str | None = Field(default=None)
    DEMO_GOOGLE_API_KEY: str | None = Field(default=None)

    # Demo API Rate Limits (per user per day)
    # These limits are generous for alpha testing - can be increased later
    DEMO_DAILY_REQUEST_LIMIT: int = Field(default=30)  # requests per day
    DEMO_WEEKLY_REQUEST_LIMIT: int = Field(default=150)  # requests per week
    DEMO_ENABLED: bool = Field(default=True)  # Master switch for demo keys

    # Echo Fallback Control
    ECHO_FALLBACK_ENABLED: bool = Field(default=False)

    # Authentication & Security
    JWT_SECRET_KEY: str = Field(default="CHANGE_ME_IN_PRODUCTION_USE_RANDOM_STRING")
    JWT_ALGORITHM: str = Field(default="HS256")
    ACCESS_TOKEN_EXPIRE_MINUTES: int = Field(default=60 * 24 * 7)  # 7 days
    REFRESH_TOKEN_EXPIRE_MINUTES: int = Field(default=60 * 24 * 30)  # 30 days
    ENCRYPTION_KEY: str | None = Field(default=None)  # For encrypting user API keys (BYOK)

    # Email Service Configuration
    EMAIL_PROVIDER: str = Field(default="console")  # console, resend, sendgrid, aws_ses, mailgun, postmark
    EMAIL_FROM_ADDRESS: str = Field(default="noreply@praviel.com")
    EMAIL_FROM_NAME: str = Field(default="PRAVIEL")
    FRONTEND_URL: str = Field(default="http://localhost:8080")  # For password reset links
    # Provider-specific keys (optional, based on EMAIL_PROVIDER)
    RESEND_API_KEY: str | None = Field(default=None)
    SENDGRID_API_KEY: str | None = Field(default=None)
    AWS_REGION: str | None = Field(default=None)
    AWS_ACCESS_KEY_ID: str | None = Field(default=None)
    AWS_SECRET_ACCESS_KEY: str | None = Field(default=None)
    MAILGUN_DOMAIN: str | None = Field(default=None)
    MAILGUN_API_KEY: str | None = Field(default=None)
    POSTMARK_SERVER_TOKEN: str | None = Field(default=None)

    @model_validator(mode="after")
    def _validate_security_settings(self) -> "Settings":
        """Validate security settings after all fields are set."""
        # Check JWT secret key in production
        if self.JWT_SECRET_KEY == "CHANGE_ME_IN_PRODUCTION_USE_RANDOM_STRING":
            if self.ENVIRONMENT.lower() not in {"dev", "development", "local"}:
                raise ValueError(
                    "JWT_SECRET_KEY must be set to a secure random value in production. "
                    "Generate one with: python -c 'import secrets; print(secrets.token_urlsafe(32))'"
                )

        # Validate JWT key length
        if len(self.JWT_SECRET_KEY) < 32:
            raise ValueError("JWT_SECRET_KEY must be at least 32 characters long for security")

        # Check encryption key when BYOK is enabled in production
        if self.BYOK_ENABLED:
            if self.ENVIRONMENT.lower() not in {"dev", "development", "local"} and not self.ENCRYPTION_KEY:
                raise ValueError(
                    "ENCRYPTION_KEY must be set when BYOK_ENABLED=true in production. "
                    "Generate one with: python -c 'from cryptography.fernet import Fernet; "
                    "print(Fernet.generate_key().decode())'"
                )

        return self

    @model_validator(mode="after")
    def _validate_model_versions(self) -> "Settings":
        """
        CRITICAL VALIDATION: Prevent AI agents from downgrading models.

        This validator enforces October 2025 API models and will FAIL THE BUILD
        if any AI agent tries to downgrade to older models.

        DO NOT REMOVE OR MODIFY THIS VALIDATOR.
        """
        banned_patterns = {
            "gpt-4": "GPT-4 models are BANNED. Use GPT-5 models only (gpt-5, gpt-5-mini, gpt-5-nano).",
            "gpt-3": "GPT-3 models are BANNED. Use GPT-5 models only.",
            "claude-3": (
                "Claude 3 models are BANNED. Use Claude 4.x models only (claude-sonnet-4-5, claude-opus-4-1)."
            ),
            "claude-2": "Claude 2 models are BANNED. Use Claude 4.x models only.",
            "gemini-1": (
                "Gemini 1.x models are BANNED. Use Gemini 2.5 models only (gemini-2.5-flash, gemini-2.5-pro)."
            ),
        }

        models_to_check = [
            ("COACH_DEFAULT_MODEL", self.COACH_DEFAULT_MODEL),
            ("LESSONS_OPENAI_DEFAULT_MODEL", self.LESSONS_OPENAI_DEFAULT_MODEL),
            ("LESSONS_ANTHROPIC_DEFAULT_MODEL", self.LESSONS_ANTHROPIC_DEFAULT_MODEL),
            ("LESSONS_GOOGLE_DEFAULT_MODEL", self.LESSONS_GOOGLE_DEFAULT_MODEL),
            ("HEALTH_OPENAI_MODEL", self.HEALTH_OPENAI_MODEL),
            ("HEALTH_ANTHROPIC_MODEL", self.HEALTH_ANTHROPIC_MODEL),
            ("HEALTH_GOOGLE_MODEL", self.HEALTH_GOOGLE_MODEL),
        ]

        for field_name, model_value in models_to_check:
            if not model_value:
                continue
            model_lower = model_value.lower()
            for banned, error_msg in banned_patterns.items():
                if banned in model_lower:
                    raise ValueError(
                        f"\n\n{'=' * 80}\n"
                        f"❌ MODEL DOWNGRADE DETECTED IN {field_name}\n"
                        f"{'=' * 80}\n"
                        f"Current value: {model_value}\n"
                        f"Error: {error_msg}\n"
                        f"\n"
                        f"This codebase uses October 2025 APIs. DO NOT downgrade models.\n"
                        f"Read CLAUDE.md and docs/AI_AGENT_GUIDELINES.md before making changes.\n"
                        f"{'=' * 80}\n"
                    )

        return self

    # Data roots (defaults point to repo-root/data/** resolved from backend/)
    DATA_VENDOR_ROOT: str = Field(default=_abs_from_backend("../data/vendor"))
    DATA_DERIVED_ROOT: str = Field(default=_abs_from_backend("../data/derived"))

    # Normalize env-provided values to absolute paths
    @field_validator("DATA_VENDOR_ROOT", "DATA_DERIVED_ROOT", mode="before")
    @classmethod
    def _norm_paths(cls, v: str) -> str:
        if not v:
            return v
        return v if os.path.isabs(v) else _abs_from_backend(v)

    @field_validator("ENVIRONMENT", mode="before")
    @classmethod
    def _normalize_environment(cls, value: str | None) -> str:
        if not value:
            return "dev"
        return str(value).lower()

    @field_validator("BYOK_ALLOWED_HEADERS", mode="after")
    @classmethod
    def _normalize_byok_headers(cls, value: list[str]) -> list[str]:
        normalized = []
        seen = set()
        for header in value:
            if not header:
                continue
            lowered = header.lower().strip()
            if lowered and lowered not in seen:
                normalized.append(lowered)
                seen.add(lowered)
        return normalized or ["authorization", "x-model-key"]

    @property
    def is_dev_environment(self) -> bool:
        return self.ENVIRONMENT in {"dev", "development", "local"}

    @property
    def dev_cors_enabled(self) -> bool:
        return self.ALLOW_DEV_CORS and self.is_dev_environment

    model_config = SettingsConfigDict(
        env_file=os.path.join(BASE_DIR, ".env"),
        env_file_encoding="utf-8",
        case_sensitive=True,
        extra="ignore",
    )


settings = Settings()


def get_settings() -> Settings:
    return settings
