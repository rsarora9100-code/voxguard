import pytest
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from datetime import datetime, timedelta

from app.db.session import Base
from app.db.models import SpamRecord, ContactWhitelist, CallRecord
from app.services.risk_engine import risk_engine

@pytest.fixture
def test_db():
    engine = create_engine("sqlite:///:memory:")
    Base.metadata.create_all(bind=engine)
    TestingSessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
    db = TestingSessionLocal()
    try:
        # Prepopulate
        db.add(SpamRecord(
            phone_number="+18005559999",
            name_tag="Known Robocall Service",
            category="Robocall",
            reports_count=50,
            base_risk_score=85.0
        ))
        db.add(ContactWhitelist(
            phone_number="+15551234567",
            contact_name="Alice Smith",
            relationship="Friend"
        ))
        db.commit()
        yield db
    finally:
        db.close()

def test_whitelist_contact_low_risk(test_db):
    result = risk_engine.evaluate(test_db, "+15551234567")
    assert result["risk_level"] == "LOW"
    assert result["color_code"] == "#10B981"
    assert result["recommendation"] == "ALLOW"
    assert result["final_score"] <= 34.0

def test_known_spam_high_risk(test_db):
    result = risk_engine.evaluate(test_db, "+18005559999")
    assert result["risk_level"] == "HIGH"
    assert result["color_code"] == "#EF4444"
    assert result["recommendation"] == "BLOCK"
    assert result["final_score"] >= 70.0

def test_unknown_caller_neutral(test_db):
    result = risk_engine.evaluate(test_db, "+19998887766")
    assert result["risk_level"] == "LOW"
    assert result["final_score"] <= 34.0
    assert any("Unknown Number" in flag for flag in result["flags"])

def test_burst_frequency_penalty(test_db):
    now = datetime.utcnow()
    # Add 4 calls in past 10 minutes
    for i in range(4):
        test_db.add(CallRecord(
            id=f"burst-{i}",
            caller_number="+19998887766",
            timestamp=now - timedelta(minutes=5)
        ))
    test_db.commit()

    result = risk_engine.evaluate(test_db, "+19998887766")
    assert result["breakdown"]["frequency_velocity_penalty"] > 0
    assert result["final_score"] > 10.0

def test_deepfake_escalation(test_db):
    result = risk_engine.evaluate(
        test_db,
        "+19998887766",
        is_deepfake=True,
        deepfake_confidence=92.0
    )
    assert result["is_deepfake"] is True
    assert result["breakdown"]["deepfake_penalty"] > 30.0
    assert result["risk_level"] in ["MEDIUM", "HIGH"]

def test_scam_language_escalation(test_db):
    transcript = "This is the IRS police, please send the OTP and transfer money right now or you will be arrested."
    result = risk_engine.evaluate(
        test_db,
        "+19998887766",
        live_transcript=transcript
    )
    assert result["scam_intent_detected"] is True
    assert result["risk_level"] == "HIGH"
    assert result["recommendation"] == "BLOCK"
