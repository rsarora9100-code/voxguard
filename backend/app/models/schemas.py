from pydantic import BaseModel, Field
from typing import List, Optional, Dict, Any
from datetime import datetime

class CallerLookupResponse(BaseModel):
    phone_number: str
    name_tag: str
    category: str
    reports_count: int
    base_risk_score: float
    risk_level: str  # "LOW", "MEDIUM", "HIGH"
    color_code: str  # "#10B981", "#F59E0B", "#EF4444"
    is_whitelisted: bool
    contact_name: Optional[str] = None
    call_frequency_recent: int = 0
    recommendation: str  # "ALLOW", "SCREEN_WITH_AI", "BLOCK"

class RiskEvaluationRequest(BaseModel):
    phone_number: str
    caller_name: Optional[str] = None
    live_transcript: Optional[str] = None
    is_deepfake: Optional[bool] = None
    deepfake_confidence: Optional[float] = 0.0
    detected_language: Optional[str] = "en"

class RiskBreakdown(BaseModel):
    database_score: float
    frequency_velocity_penalty: float
    deepfake_penalty: float
    scam_intent_penalty: float
    whitelist_discount: float

class RiskEvaluationResponse(BaseModel):
    phone_number: str
    final_score: float
    risk_level: str  # "LOW", "MEDIUM", "HIGH"
    color_code: str  # "#10B981", "#F59E0B", "#EF4444"
    recommendation: str  # "ALLOW", "SCREEN_WITH_AI", "BLOCK"
    breakdown: RiskBreakdown
    flags: List[str]
    is_deepfake: bool
    scam_intent_detected: bool
    scam_category: Optional[str] = None

class SpamReportRequest(BaseModel):
    phone_number: str
    category: str = "General Spam"
    description: Optional[str] = None
    reporter_id: Optional[str] = "user_device"

class DialogueMessage(BaseModel):
    speaker: str  # "assistant" or "caller"
    text: str
    language: str = "en"
    confidence: float = 1.0
    timestamp: datetime = Field(default_factory=datetime.utcnow)

class CallRecordSchema(BaseModel):
    id: str
    caller_number: str
    caller_name: str
    call_type: str
    status: str
    timestamp: datetime
    duration_seconds: int
    final_risk_score: float
    risk_level: str
    is_deepfake: bool
    deepfake_confidence: float
    scam_detected: bool
    scam_category: Optional[str] = None
    transcript_summary: Optional[str] = None
    dialogues: Optional[List[DialogueMessage]] = []

class AudioChunkAnalysis(BaseModel):
    status: str
    label: str  # "REAL" or "FAKE"
    confidence: float
    is_synthetic: bool
    spectral_entropy: Optional[float] = None
    risk_increment: float

class ScamAnalysisResult(BaseModel):
    is_scam: bool
    confidence: float
    scam_category: Optional[str] = None
    matched_patterns: List[str] = []
    risk_penalty: float = 0.0
    explanation: str

class ScreeningStartRequest(BaseModel):
    caller_number: str
    caller_name: Optional[str] = "Unknown Caller"

class ScreeningStartResponse(BaseModel):
    call_id: str
    initial_assistant_message: str
    initial_risk_score: float
    risk_level: str
    color_code: str
    supported_languages: List[str]

class AssistantTurnRequest(BaseModel):
    call_id: str
    caller_audio_transcript: str
    detected_language: Optional[str] = "en"
    is_deepfake: Optional[bool] = False

class AssistantTurnResponse(BaseModel):
    assistant_reply: str
    decision: str  # "CONTINUE_QUESTIONING", "TERMINATE_CALL_SCAM", "PASS_TO_USER"
    updated_risk_score: float
    risk_level: str
    color_code: str
    scam_alert: Optional[str] = None
