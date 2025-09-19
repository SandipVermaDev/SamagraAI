from pydantic_settings import BaseSettings, SettingsConfigDict

class Settings(BaseSettings):
    """
    Holds all the application settings.
    """
    GOOGLE_API_KEY: str

    # This tells Pydantic to load the variables from a .env file
    model_config = SettingsConfigDict(env_file=".env")

# Create a single instance of the Settings class
settings = Settings()