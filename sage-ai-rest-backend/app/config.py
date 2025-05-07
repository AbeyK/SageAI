from pydantic_settings import BaseSettings, SettingsConfigDict
from typing import Optional

class Settings(BaseSettings):
    """Manages application settings and loads them from environment variables."""
    OPENAI_API_KEY: Optional[str] = None
    FIREBASE_SERVICE_ACCOUNT_KEY_PATH: Optional[str] = None

    # Optional: Define default values or other configurations here
    # e.g., DEFAULT_GPT_MODEL: str = "gpt-4o"

    # Pydantic-settings configuration to load from a .env file
    model_config = SettingsConfigDict(env_file=".env", env_file_encoding='utf-8', extra='ignore')

# Create a single instance of the settings to be used throughout the application
settings = Settings()

# You can add a check here to ensure critical settings are loaded
if not settings.OPENAI_API_KEY:
    print("WARNING: OPENAI_API_KEY is not set in the environment or .env file.")
if not settings.FIREBASE_SERVICE_ACCOUNT_KEY_PATH:
    print("WARNING: FIREBASE_SERVICE_ACCOUNT_KEY_PATH is not set in the environment or .env file.") 