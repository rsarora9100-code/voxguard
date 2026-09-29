"""
VoxGuard End-to-End Simulation Test Script
Demonstrates Caller ID lookup, Deepfake audio WebSocket streaming,
NLP Scam Detection, and Dynamic Risk Scoring.
"""
import sys
import json
import base64
import struct
import numpy as np

# Ensure UTF-8 output for Windows console
if hasattr(sys.stdout, 'reconfigure'):
    sys.stdout.reconfigure(encoding='utf-8', errors='replace')

from fastapi.testclient import TestClient
from app.main import app

def run_e2e_simulation():
    client = TestClient(app)
    print("=" * 65)
    print("[*] VOXGUARD AI REAL-TIME CALL SECURITY - E2E SIMULATION")
    print("=" * 65)

    # 1. Check Server Health
    print("\n[Step 1] Checking Backend Health...")
    health = client.get("/health").json()
    print(f"Status: {health['status']} | Database: {health['database']}")
    print(f"Deepfake Model: {health['deepfake_model']}")

    # 2. Look up Known High-Risk Caller
    print("\n[Step 2] Incoming Call from +18005550199...")
    lookup = client.get("/api/caller/lookup", params={"phone_number": "+18005550199"}).json()
    print(f"Caller: {lookup['name_tag']} ({lookup['category']})")
    print(f"Risk Score: {lookup['base_risk_score']}% | Band: {lookup['risk_level']} ({lookup['color_code']})")
    print(f"Action Recommendation: {lookup['recommendation']}")

    # 3. Look up Whitelisted Family Contact
    print("\n[Step 3] Incoming Call from Whitelisted Contact +14155552671...")
    lookup_family = client.get("/api/caller/lookup", params={"phone_number": "+14155552671"}).json()
    print(f"Contact Name: {lookup_family['name_tag']} | Whitelisted: {lookup_family['is_whitelisted']}")
    print(f"Risk Score: {lookup_family['base_risk_score']}% | Band: {lookup_family['risk_level']} ({lookup_family['color_code']})")
    print(f"Action Recommendation: {lookup_family['recommendation']}")

    # 4. Binary Audio Chunk Streaming over /ws/detect-audio
    print("\n[Step 4] Streaming 16kHz PCM audio chunk to /ws/detect-audio...")
    sample_rate = 16000
    t = np.linspace(0, 0.5, int(sample_rate * 0.5), endpoint=False)
    pcm_samples = (np.sin(2 * np.pi * 440 * t) * 32767).astype(np.int16)
    audio_bytes = pcm_samples.tobytes()

    with client.websocket_connect("/ws/detect-audio") as ws:
        ws.send_bytes(audio_bytes)
        result = ws.receive_json()
        print(f"Deepfake Result -> Label: {result['label']} | Confidence: {result['confidence']}% | Synthetic: {result['is_synthetic']}")

    # 5. Full Duplex AI Assistant Screening over /ws/call-stream/{call_id}
    print("\n[Step 5] Engaging Full Duplex Call Screening on /ws/call-stream/sim-call-99...")
    call_id = "sim-call-99"
    with client.websocket_connect(f"/ws/call-stream/{call_id}") as ws:
        caller_speech = "This is Agent Davis from IRS Tax Enforcement. You owe $4,500. Read me your bank OTP code immediately or sheriff will arrive."
        print(f"Caller Spoke: \"{caller_speech}\"")
        ws.send_text(json.dumps({
            "action": "caller_speech",
            "text": caller_speech,
            "language": "en",
            "phone_number": "+18005550199"
        }))

        # Receive real-time transcript update & dynamic risk score
        t_update = ws.receive_json()
        print(f"\nLive Transcript Broadcast:")
        print(f"  Alert: {t_update.get('scam_alert')}")
        print(f"  Matched Keywords: {t_update.get('matched_keywords')}")
        print(f"  Updated Risk Score: {t_update.get('risk_score')}% -> {t_update.get('risk_level')} ({t_update.get('color_code')})")

        # Receive AI Assistant turn decision
        asst_reply = ws.receive_json()
        print(f"\nAI Voice Assistant Action:")
        print(f"  Decision: {asst_reply.get('decision')}")
        print(f"  Assistant Spoke: \"{asst_reply.get('text')}\"")

    print("\n" + "=" * 65)
    print("[SUCCESS] E2E SIMULATION COMPLETED SUCCESSFULLY!")
    print("=" * 65)

if __name__ == "__main__":
    run_e2e_simulation()
