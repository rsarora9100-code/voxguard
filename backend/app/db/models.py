import uuid
from datetime import datetime
from sqlalchemy import Column, String, Integer, Float, Boolean, DateTime, Text, ForeignKey
from sqlalchemy.orm import relationship
from app.db.session import Base

class SpamRecord(Base):
    __tablename__ = "spam_records"

    id = Column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    phone_number = Column(String(32), unique=True, index=True, nullable=False)
    name_tag = Column(String(128), default="Unknown Caller")
    category = Column(String(64), default="General Spam")  # Robocall, Telemarketing, Bank Fraud, IRS Impersonation
    reports_count = Column(Integer, default=1)
    base_risk_score = Column(Float, default=75.0)
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

class ContactWhitelist(Base):
    __tablename__ = "contact_whitelist"

    id = Column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    phone_number = Column(String(32), unique=True, index=True, nullable=False)
    contact_name = Column(String(128), nullable=False)
    relationship = Column(String(64), default="Contact")
    created_at = Column(DateTime, default=datetime.utcnow)

class CallRecord(Base):
    __tablename__ = "call_records"

    id = Column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    caller_number = Column(String(32), index=True, nullable=False)
    caller_name = Column(String(128), default="Unknown Caller")
    call_type = Column(String(32), default="incoming")  # incoming, screened, blocked, answered
    status = Column(String(32), default="completed")     # active, completed, rejected
    timestamp = Column(DateTime, default=datetime.utcnow, index=True)
    duration_seconds = Column(Integer, default=0)
    final_risk_score = Column(Float, default=0.0)       # 0 - 100
    risk_level = Column(String(16), default="LOW")      # LOW, MEDIUM, HIGH
    is_deepfake = Column(Boolean, default=False)
    deepfake_confidence = Column(Float, default=0.0)
    scam_detected = Column(Boolean, default=False)
    scam_category = Column(String(64), nullable=True)
    transcript_summary = Column(Text, nullable=True)

    dialogues = relationship("AssistantDialogue", back_populates="call", cascade="all, delete-orphan")

class AssistantDialogue(Base):
    __tablename__ = "assistant_dialogues"

    id = Column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    call_id = Column(String(36), ForeignKey("call_records.id", ondelete="CASCADE"), nullable=False)
    speaker = Column(String(32), nullable=False)  # "assistant" or "caller"
    text = Column(Text, nullable=False)
    language = Column(String(16), default="en")
    confidence = Column(Float, default=1.0)
    timestamp = Column(DateTime, default=datetime.utcnow)

    call = relationship("CallRecord", back_populates="dialogues")

class CommunityReport(Base):
    __tablename__ = "community_reports"

    id = Column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    phone_number = Column(String(32), index=True, nullable=False)
    reporter_id = Column(String(64), default="anonymous")
    category = Column(String(64), nullable=False)  # "Robocall", "Phishing", "Extortion", "Deepfake Audio"
    description = Column(Text, nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow)
