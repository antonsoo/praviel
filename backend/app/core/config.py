from pydantic_settings import BaseSettings
from pydantic import PostgresDsn
import os

class Settings(BaseSettings):
    # Database URL format: postgresql+driver://user:password@host/dbname
    # We use the asyncpg driver.
    # !!! This MUST be provided by the environment variable DATABASE_URL !!!
    DATABASE_URL: PostgresDsn
    
    API_V1_STR: str = "/api/v1"
    PROJECT_NAME: str = "Ancient Languages API"

    class Config:
        # We are relying purely on shell environment variables
        case_sensitive = True

# Create a singleton instance of the settings
# This will raise an error if DATABASE_URL is not found in the environment.
settings = Settings()