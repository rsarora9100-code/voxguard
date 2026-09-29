import pytest
from fastapi.testclient import TestClient
from app.main import app

client = TestClient(app)

def test_health_endpoint():
    response = client.get("/health")
    assert response.status_code == 200
    data = response.json()
    assert data["status"] == "healthy"
    assert "deepfake_model" in data

def test_root_endpoint():
    response = client.get("/")
    assert response.status_code == 200
    data = response.json()
    assert "VoxGuard" in data["service"]

def test_caller_lookup_spam():
    # +18005550199 is pre-seeded as IRS Tax Relief Scam
    response = client.get("/api/caller/lookup", params={"phone_number": "+18005550199"})
    assert response.status_code == 200
    data = response.json()
    assert data["risk_level"] == "HIGH"
    assert data["color_code"] == "#EF4444"
    assert data["recommendation"] == "BLOCK"

def test_caller_lookup_whitelisted():
    # +14155552671 is pre-seeded as Sarah Miller (Mom)
    response = client.get("/api/caller/lookup", params={"phone_number": "+14155552671"})
    assert response.status_code == 200
    data = response.json()
    assert data["is_whitelisted"] is True
    assert data["risk_level"] == "LOW"
    assert data["color_code"] == "#10B981"
    assert data["recommendation"] == "ALLOW"

def test_report_spam_endpoint():
    response = client.post("/api/caller/report-spam", json={
        "phone_number": "+15559998877",
        "category": "Extortion Scam",
        "description": "Caller threatened to cancel passport"
    })
    assert response.status_code == 200
    data = response.json()
    assert data["status"] == "success"

def test_risk_evaluate_endpoint():
    payload = {
        "phone_number": "+19991112233",
        "live_transcript": "Please send your credit card CVV and OTP immediately",
        "is_deepfake": True,
        "deepfake_confidence": 88.0
    }
    response = client.post("/api/risk/evaluate", json=payload)
    assert response.status_code == 200
    data = response.json()
    assert data["risk_level"] == "HIGH"
    assert data["scam_intent_detected"] is True

def test_screening_start_and_turn():
    # 1. Start screening
    start_resp = client.post("/api/screening/start", json={
        "caller_number": "+18885554433",
        "caller_name": "Delivery Driver"
    })
    assert start_resp.status_code == 200
    start_data = start_resp.json()
    call_id = start_data["call_id"]
    assert "initial_assistant_message" in start_data

    # 2. Caller turn - legitimate delivery
    turn_resp = client.post("/api/screening/turn", json={
        "call_id": call_id,
        "caller_audio_transcript": "Hi, this is FedEx, I am at the gate with your package.",
        "detected_language": "en"
    })
    assert turn_resp.status_code == 200
    turn_data = turn_resp.json()
    assert turn_data["decision"] in ["PASS_TO_USER", "CONTINUE_QUESTIONING"]

    # 3. Retrieve transcript
    trans_resp = client.get(f"/api/screening/{call_id}/transcript")
    assert trans_resp.status_code == 200
    trans_list = trans_resp.json()
    assert len(trans_list) >= 2

def test_security_stats():
    resp = client.get("/api/risk/stats")
    assert resp.status_code == 200
    data = resp.json()
    assert "scams_blocked" in data
    assert "known_spam_database_size" in data
