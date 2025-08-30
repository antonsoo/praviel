from pydantic_settings import BaseSettings
from pydantic import PostgresDsn
import os

# Define the directory for CLTK models relative to the backend directory.
# This assumes config.py is in backend/app/core/
BASE_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
CLTK_DATA_DIR = os.path.join(BASE_DIR, "cltk_data")

class Settings(BaseSettings):
    # Database URL (Must be provided by environment variable)
    DATABASE_URL: PostgresDsn
    
    API_V1_STR: str = "/api/v1"
    PROJECT_NAME: str = "Ancient Languages API"

    class Config:
        case_sensitive = True

# Ensure the CLTK directory exists
if not os.path.exists(CLTK_DATA_DIR):
    os.makedirs(CLTK_DATA_DIR, exist_ok=True)
    print(f"CLTK data directory ensured at: {CLTK_DATA_DIR}")

# Set the environment variable required by CLTK internally
os.environ["CLTK_DATA"] = CLTK_DATA_DIR

# Create a singleton instance of the settings
settings = Settings()