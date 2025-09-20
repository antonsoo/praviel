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
