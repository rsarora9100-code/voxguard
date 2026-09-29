import os
from pydantic_settings import BaseSettings, SettingsConfigDict
from typing import List

class Settings(BaseSettings):
    PROJECT_NAME: str = "VoxGuard AI Call Security"
    VERSION: str = "1.0.0"
    API_V1_PREFIX: str = "/api"
    DEBUG: bool = True
    
    # Host & Port
    HOST: str = "0.0.0.0"
    PORT: int = 8000
    
    # CORS
    ALLOWED_ORIGINS: List[str] = ["*"]
    
    # Database
    DATABASE_URL: str = "sqlite:///./voxguard.db"
    
    # Deepfake Detection
    DEEPFAKE_MODEL_NAME: str = "mo-thecreator/Deepfake-audio-detection"
    DEEPFAKE_CONFIDENCE_THRESHOLD: float = 75.0  # % above which voice is flagged as synthetic
    SAMPLE_RATE: int = 16000  # 16kHz PCM
    
    # STT Settings
    WHISPER_MODEL_SIZE: str = "base"
    SUPPORTED_LANGUAGES: List[str] = ["en", "es", "hi", "fr", "de", "zh", "ar", "pt"]
    
    # Risk Engine Thresholds (0 - 100)
    LOW_RISK_MAX: int = 34      # 0 - 34: 🟢 LOW RISK (Safe)
    MEDIUM_RISK_MAX: int = 69   # 35 - 69: 🟡 MEDIUM RISK (Suspicious)
    # 70 - 100: 🔴 HIGH RISK (Scam / Deepfake)
    
    # Frequency Tracking
    BURST_CALL_WINDOW_MINUTES: int = 30
    BURST_CALL_THRESHOLD: int = 3  # calls within window considered burst

    model_config = SettingsConfigDict(env_file=".env", case_sensitive=True, extra="allow")

settings = Settings()
