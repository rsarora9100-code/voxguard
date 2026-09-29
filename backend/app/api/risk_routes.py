from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from sqlalchemy import func

from app.db.session import get_db
from app.db.models import CallRecord, SpamRecord
from app.models.schemas import (
    RiskEvaluationRequest,
    RiskEvaluationResponse,
    RiskBreakdown
)
from app.services.risk_engine import risk_engine

router = APIRouter(prefix="/risk", tags=["Dynamic Risk Engine"])

@router.post("/evaluate", response_model=RiskEvaluationResponse)
def evaluate_call_risk(request: RiskEvaluationRequest, db: Session = Depends(get_db)):
    """
    Evaluates dynamic risk level for a phone number using spam databases,
    call frequency, deepfake indicators, and live transcript NLP scam patterns.
    """
    res = risk_engine.evaluate(
        db=db,
        phone_number=request.phone_number,
        live_transcript=request.live_transcript,
        is_deepfake=request.is_deepfake or False,
        deepfake_confidence=request.deepfake_confidence or 0.0,
        caller_name=request.caller_name
    )

    breakdown = RiskBreakdown(**res["breakdown"])
    return RiskEvaluationResponse(
        phone_number=res["phone_number"],
        final_score=res["final_score"],
        risk_level=res["risk_level"],
        color_code=res["color_code"],
        recommendation=res["recommendation"],
        breakdown=breakdown,
        flags=res["flags"],
        is_deepfake=res["is_deepfake"],
        scam_intent_detected=res["scam_intent_detected"],
        scam_category=res["scam_category"]
    )

@router.get("/stats")
def get_security_stats(db: Session = Depends(get_db)):
    """
    Dashboard metrics on screened calls, blocked scams, deepfake voices detected,
    and average threat levels.
    """
    total_calls = db.query(CallRecord).count()
    scams_blocked = db.query(CallRecord).filter(CallRecord.status == "blocked").count()
    deepfakes_detected = db.query(CallRecord).filter(CallRecord.is_deepfake == True).count()
    high_risk_calls = db.query(CallRecord).filter(CallRecord.risk_level == "HIGH").count()
    medium_risk_calls = db.query(CallRecord).filter(CallRecord.risk_level == "MEDIUM").count()
    low_risk_calls = db.query(CallRecord).filter(CallRecord.risk_level == "LOW").count()
    known_spam_numbers = db.query(SpamRecord).count()

    avg_score = db.query(func.avg(CallRecord.final_risk_score)).scalar() or 0.0

    return {
        "total_calls_screened": total_calls,
        "scams_blocked": scams_blocked,
        "deepfakes_detected": deepfakes_detected,
        "risk_breakdown": {
            "low_risk_safe": low_risk_calls,
            "medium_risk_suspicious": medium_risk_calls,
            "high_risk_scam": high_risk_calls
        },
        "known_spam_database_size": known_spam_numbers,
        "average_call_risk_score": round(float(avg_score), 1)
    }
