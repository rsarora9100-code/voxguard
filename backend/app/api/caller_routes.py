from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session
from typing import List, Optional

from app.db.session import get_db
from app.db.models import SpamRecord, ContactWhitelist, CallRecord, CommunityReport
from app.models.schemas import (
    CallerLookupResponse,
    SpamReportRequest,
    CallRecordSchema,
    DialogueMessage
)
from app.services.risk_engine import risk_engine

router = APIRouter(prefix="/caller", tags=["Caller ID & Reputation"])

@router.get("/lookup", response_model=CallerLookupResponse)
def lookup_caller(
    phone_number: str = Query(..., description="Phone number with country code, e.g. +18005550199"),
    db: Session = Depends(get_db)
):
    """
    Look up caller reputation, spam database hits, contact whitelist status,
    and calculate baseline risk score before call connects.
    """
    normalized_num = phone_number.strip().replace(" ", "").replace("-", "")

    # Evaluate baseline risk
    eval_res = risk_engine.evaluate(db, normalized_num)

    whitelist_entry = db.query(ContactWhitelist).filter(
        ContactWhitelist.phone_number == normalized_num
    ).first()

    spam_entry = db.query(SpamRecord).filter(
        SpamRecord.phone_number == normalized_num
    ).first()

    recent_count = db.query(CallRecord).filter(
        CallRecord.caller_number == normalized_num
    ).count()

    return CallerLookupResponse(
        phone_number=normalized_num,
        name_tag=eval_res["caller_name"],
        category=spam_entry.category if spam_entry else ("Personal Contact" if whitelist_entry else "Uncategorized"),
        reports_count=spam_entry.reports_count if spam_entry else 0,
        base_risk_score=eval_res["final_score"],
        risk_level=eval_res["risk_level"],
        color_code=eval_res["color_code"],
        is_whitelisted=bool(whitelist_entry),
        contact_name=whitelist_entry.contact_name if whitelist_entry else None,
        call_frequency_recent=recent_count,
        recommendation=eval_res["recommendation"]
    )

@router.post("/report-spam")
def report_spam(report: SpamReportRequest, db: Session = Depends(get_db)):
    """
    Submit a community spam or fraud report for a phone number.
    Automatically boosts risk score and category classification.
    """
    normalized_num = report.phone_number.strip().replace(" ", "").replace("-", "")

    # Save community report
    comm_report = CommunityReport(
        phone_number=normalized_num,
        reporter_id=report.reporter_id,
        category=report.category,
        description=report.description
    )
    db.add(comm_report)

    # Update or insert into SpamRecord
    spam_record = db.query(SpamRecord).filter(
        SpamRecord.phone_number == normalized_num
    ).first()

    if spam_record:
        spam_record.reports_count += 1
        spam_record.category = report.category
        spam_record.base_risk_score = min(spam_record.base_risk_score + 5.0, 99.0)
    else:
        spam_record = SpamRecord(
            phone_number=normalized_num,
            name_tag=f"Reported {report.category}",
            category=report.category,
            reports_count=1,
            base_risk_score=75.0
        )
        db.add(spam_record)

    db.commit()

    return {
        "status": "success",
        "message": f"Report recorded for {normalized_num}.",
        "new_reports_count": spam_record.reports_count,
        "updated_risk_score": spam_record.base_risk_score
    }

@router.get("/history", response_model=List[CallRecordSchema])
def get_call_history(limit: int = 50, db: Session = Depends(get_db)):
    """
    Retrieve call history with security ratings, deepfake tags, and transcript summaries.
    """
    calls = db.query(CallRecord).order_by(CallRecord.timestamp.desc()).limit(limit).all()
    results = []
    for c in calls:
        dialogues = [
            DialogueMessage(
                speaker=d.speaker,
                text=d.text,
                language=d.language,
                confidence=d.confidence,
                timestamp=d.timestamp
            ) for d in c.dialogues
        ]
        results.append(
            CallRecordSchema(
                id=c.id,
                caller_number=c.caller_number,
                caller_name=c.caller_name,
                call_type=c.call_type,
                status=c.status,
                timestamp=c.timestamp,
                duration_seconds=c.duration_seconds,
                final_risk_score=c.final_risk_score,
                risk_level=c.risk_level,
                is_deepfake=c.is_deepfake,
                deepfake_confidence=c.deepfake_confidence,
                scam_detected=c.scam_detected,
                scam_category=c.scam_category,
                transcript_summary=c.transcript_summary,
                dialogues=dialogues
            )
        )
    return results

@router.post("/whitelist")
def add_to_whitelist(
    phone_number: str,
    contact_name: str,
    relationship: str = "Contact",
    db: Session = Depends(get_db)
):
    """
    Add a trusted number to the contact whitelist to reduce false positives.
    """
    normalized_num = phone_number.strip().replace(" ", "").replace("-", "")
    existing = db.query(ContactWhitelist).filter(
        ContactWhitelist.phone_number == normalized_num
    ).first()

    if existing:
        existing.contact_name = contact_name
        existing.relationship = relationship
    else:
        new_entry = ContactWhitelist(
            phone_number=normalized_num,
            contact_name=contact_name,
            relationship=relationship
        )
        db.add(new_entry)

    db.commit()
    return {"status": "success", "message": f"{contact_name} added to whitelist."}
