import os

from pydantic import Field, field_validator
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
    PROJECT_NAME: str = "Ancient Languages API (LDSv1)"
    ENVIRONMENT: str = Field(default="dev")
    ALLOW_DEV_CORS: bool = Field(default=False)
    BYOK_ENABLED: bool = Field(default=False)
    BYOK_ALLOWED_HEADERS: list[str] = Field(
        default_factory=lambda: ["authorization", "x-model-key"],
    )
    COACH_ENABLED: bool = Field(default=False)
    COACH_DEFAULT_MODEL: str | None = Field(default="gpt-5-mini")  # October 2025 update
    LESSONS_ENABLED: bool = Field(default=False)
    LESSONS_OPENAI_DEFAULT_MODEL: str = Field(default="gpt-5-nano")
    LESSONS_ANTHROPIC_DEFAULT_MODEL: str = Field(default="claude-sonnet-4-5-20250929")  # Sonnet 4.5
    LESSONS_GOOGLE_DEFAULT_MODEL: str = Field(default="gemini-2.5-flash")
    TTS_ENABLED: bool = Field(default=False)
    TTS_LICENSE_GUARD: bool = Field(default=True)
    TTS_DEFAULT_MODEL: str = Field(default="gpt-4o-mini-tts")

    # Health check models (for testing vendor API connectivity) - October 2025
    HEALTH_OPENAI_MODEL: str = Field(default="gpt-5-mini")
    HEALTH_ANTHROPIC_MODEL: str = Field(default="claude-sonnet-4-5-20250929")
    HEALTH_GOOGLE_MODEL: str = Field(default="gemini-2.5-flash")

    # Vendor API Keys (server-side BYOK)
    OPENAI_API_KEY: str | None = Field(default=None)
    ANTHROPIC_API_KEY: str | None = Field(default=None)
    GOOGLE_API_KEY: str | None = Field(default=None)

    # Echo Fallback Control
    ECHO_FALLBACK_ENABLED: bool = Field(default=False)

    # Authentication & Security
    JWT_SECRET_KEY: str = Field(default="CHANGE_ME_IN_PRODUCTION_USE_RANDOM_STRING")
    JWT_ALGORITHM: str = Field(default="HS256")
    ACCESS_TOKEN_EXPIRE_MINUTES: int = Field(default=60 * 24 * 7)  # 7 days
    REFRESH_TOKEN_EXPIRE_MINUTES: int = Field(default=60 * 24 * 30)  # 30 days
    ENCRYPTION_KEY: str | None = Field(default=None)  # For encrypting user API keys (BYOK)

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
