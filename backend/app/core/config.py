from pydantic_settings import BaseSettings
from pydantic import PostgresDsn
import os

class Settings(BaseSettings):
    # Default Database URL format: postgresql+driver://user:password@host/dbname
    # We use the asyncpg driver.
    # !!! IMPORTANT: Replace with your actual PostgreSQL credentials and database name !!!
    # You can also set this via an environment variable DATABASE_URL
    DATABASE_URL: PostgresDsn = "postgresql+asyncpg://user:password@localhost/ancient_languages_db"
    
    API_V1_STR: str = "/api/v1"
    PROJECT_NAME: str = "Ancient Languages API"

    class Config:
        # If you want to load settings from a .env file, uncomment the line below
        # env_file = ".env"
        case_sensitive = True

# Create a singleton instance of the settings
settings = Settings()