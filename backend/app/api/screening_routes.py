from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from typing import List

from app.db.session import get_db
from app.db.models import CallRecord, AssistantDialogue
from app.models.schemas import (
    ScreeningStartRequest,
    ScreeningStartResponse,
    AssistantTurnRequest,
    AssistantTurnResponse,
    DialogueMessage
)
from app.services.ai_assistant import ai_assistant

router = APIRouter(prefix="/screening", tags=["AI Call Screening"])

@router.post("/start", response_model=ScreeningStartResponse)
def start_call_screening(request: ScreeningStartRequest, db: Session = Depends(get_db)):
    """
    Initiates AI Call Screening session for incoming call.
    Returns initial AI Assistant greeting asking for caller name & purpose.
    """
    res = ai_assistant.start_screening(
        db=db,
        caller_number=request.caller_number,
        caller_name=request.caller_name
    )
    return ScreeningStartResponse(**res)

@router.post("/turn", response_model=AssistantTurnResponse)
def handle_screening_turn(request: AssistantTurnRequest, db: Session = Depends(get_db)):
    """
    Processes caller response, runs real-time scam and deepfake evaluation,
    and returns AI Assistant reply + call forwarding decision.
    """
    turn_res = ai_assistant.process_caller_turn(
        db=db,
        call_id=request.call_id,
        caller_transcript=request.caller_audio_transcript,
        detected_language=request.detected_language or "en",
        is_deepfake=request.is_deepfake or False
    )
    return AssistantTurnResponse(**turn_res)

@router.get("/{call_id}/transcript", response_model=List[DialogueMessage])
def get_call_transcript(call_id: str, db: Session = Depends(get_db)):
    """
    Get real-time live transcript feed for an active or completed screened call.
    """
    call_rec = db.query(CallRecord).filter(CallRecord.id == call_id).first()
    if not call_rec:
        raise HTTPException(status_code=404, detail="Call record not found")

    dialogues = db.query(AssistantDialogue).filter(
        AssistantDialogue.call_id == call_id
    ).order_by(AssistantDialogue.timestamp.asc()).all()

    return [
        DialogueMessage(
            speaker=d.speaker,
            text=d.text,
            language=d.language,
            confidence=d.confidence,
            timestamp=d.timestamp
        )
        for d in dialogues
    ]
