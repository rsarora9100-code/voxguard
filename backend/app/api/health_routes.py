from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from sqlalchemy import text
from app.db.session import get_db
from app.core.config import settings

router = APIRouter(tags=["Health & Status"])

@router.get("/")
def root():
    return {
        "service": settings.PROJECT_NAME,
        "version": settings.VERSION,
        "status": "online",
        "docs_url": "/docs",
        "description": "Full-Stack Real-Time Call Management & Security AI Engine"
    }

@router.get("/health")
def health_check(db: Session = Depends(get_db)):
    db_ok = False
    try:
        db.execute(text("SELECT 1"))
        db_ok = True
    except Exception:
        db_ok = False

    return {
        "status": "healthy" if db_ok else "degraded",
        "database": "connected" if db_ok else "unreachable",
        "deepfake_model": settings.DEEPFAKE_MODEL_NAME,
        "sample_rate_hz": settings.SAMPLE_RATE,
        "supported_languages": settings.SUPPORTED_LANGUAGES,
        "risk_thresholds": {
            "low": f"0 - {settings.LOW_RISK_MAX}",
            "medium": f"{settings.LOW_RISK_MAX + 1} - {settings.MEDIUM_RISK_MAX}",
            "high": f"{settings.MEDIUM_RISK_MAX + 1} - 100"
        }
    }
