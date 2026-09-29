import pytest
import base64
import json
from fastapi.testclient import TestClient
from app.main import app

client = TestClient(app)

def test_websocket_detect_audio_raw_bytes():
    # Construct 16-bit PCM buffer (16000 Hz, 0.1 sec = 1600 samples = 3200 bytes)
    dummy_pcm = b"\x00\x00" * 1600
    with client.websocket_connect("/ws/detect-audio") as websocket:
        websocket.send_bytes(dummy_pcm)
        data = websocket.receive_json()
        assert data["status"] == "success"
        assert "label" in data
        assert "confidence" in data
        assert "is_synthetic" in data

def test_websocket_detect_audio_base64_json():
    dummy_pcm = b"\x00\x00" * 1600
    b64_audio = base64.b64encode(dummy_pcm).decode("utf-8")
    with client.websocket_connect("/ws/detect-audio") as websocket:
        websocket.send_text(json.dumps({"audio_base64": b64_audio}))
        data = websocket.receive_json()
        assert data["status"] == "success"
        assert data["label"] in ["REAL", "FAKE"]

def test_websocket_call_stream():
    call_id = "test-call-ws-001"
    with client.websocket_connect(f"/ws/call-stream/{call_id}") as websocket:
        # Send ping
        websocket.send_text(json.dumps({"action": "ping"}))
        pong = websocket.receive_json()
        assert pong.get("type") == "pong"

        # Send caller speech turn
        websocket.send_text(json.dumps({
            "action": "caller_speech",
            "text": "Hello, I am calling from Amazon security to verify your account login.",
            "language": "en",
            "phone_number": "+18885550199"
        }))

        # Expect transcript update
        t_update = websocket.receive_json()
        assert t_update["type"] == "transcript_update"
        assert "risk_score" in t_update
        assert "color_code" in t_update

        # Expect AI Assistant response
        asst_msg = websocket.receive_json()
        assert asst_msg["type"] == "assistant_reply"
        assert "text" in asst_msg
        assert "decision" in asst_msg
