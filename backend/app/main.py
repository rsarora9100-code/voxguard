import os
import json
import base64
from contextlib import asynccontextmanager
from fastapi import FastAPI, WebSocket, WebSocketDisconnect, Depends
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from fastapi.responses import FileResponse
from sqlalchemy.orm import Session

from app.core.config import settings
from app.core.logging import logger
from app.db.session import engine, Base, get_db, SessionLocal
from app.db.seed_data import seed_database
from app.services.deepfake_detector import deepfake_detector
from app.services.stt_service import stt_service
from app.services.scam_analyzer import scam_analyzer
from app.services.risk_engine import risk_engine
from app.services.ai_assistant import ai_assistant
from app.api.caller_routes import router as caller_router
from app.api.screening_routes import router as screening_router
from app.api.risk_routes import router as risk_router
from app.api.health_routes import router as health_router

# Ensure database tables exist immediately
Base.metadata.create_all(bind=engine)
seed_database()

@asynccontextmanager
async def lifespan(app: FastAPI):
    logger.info("Initializing database and seeding baseline spam numbers...")
    Base.metadata.create_all(bind=engine)
    seed_database()
    logger.info(f"{settings.PROJECT_NAME} v{settings.VERSION} ready on port {settings.PORT}.")
    yield

# Initialize FastAPI App with Lifespan
app = FastAPI(
    title=settings.PROJECT_NAME,
    version=settings.VERSION,
    description="Real-time Call Management, Deepfake Voice Detection, and Multilingual AI Screening Server",
    lifespan=lifespan
)

# CORS Middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.ALLOWED_ORIGINS,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Static & Web Mobile Client
static_path = os.path.join(os.path.dirname(__file__), "static")
if os.path.exists(static_path):
    app.mount("/static", StaticFiles(directory=static_path), name="static")

@app.get("/app", include_in_schema=False)
def serve_mobile_app():
    index_file = os.path.join(static_path, "index.html")
    if os.path.exists(index_file):
        return FileResponse(index_file)
    return {"message": "Mobile client static files not found."}

# Include REST Routers
app.include_router(health_router)
app.include_router(caller_router, prefix=settings.API_V1_PREFIX)
app.include_router(screening_router, prefix=settings.API_V1_PREFIX)
app.include_router(risk_router, prefix=settings.API_V1_PREFIX)

# =====================================================================
# 1. Core WebSocket: /ws/detect-audio (Binary 16kHz PCM stream)
# =====================================================================
@app.websocket("/ws/detect-audio")
async def websocket_detect_audio(websocket: WebSocket):
    await websocket.accept()
    logger.info("Client connected to /ws/detect-audio")
    try:
        while True:
            message = await websocket.receive()
            if "bytes" in message and message["bytes"]:
                audio_data = message["bytes"]
            elif "text" in message and message["text"]:
                try:
                    payload = json.loads(message["text"])
                    if "audio_base64" in payload:
                        audio_data = base64.b64decode(payload["audio_base64"])
                    else:
                        continue
                except Exception:
                    continue
            else:
                continue

            analysis = deepfake_detector.analyze_audio_chunk(audio_data)

            await websocket.send_json({
                "status": "success",
                "label": analysis["label"],
                "confidence": analysis["confidence"],
                "is_synthetic": analysis["is_synthetic"],
                "risk_increment": analysis.get("risk_increment", 0.0),
                "method": analysis.get("method", "detector")
            })

    except (WebSocketDisconnect, RuntimeError):
        logger.info("Client disconnected from /ws/detect-audio")
    except Exception as e:
        logger.error(f"Error in /ws/detect-audio: {e}")
        try:
            await websocket.close()
        except Exception:
            pass

# =====================================================================
# 2. Comprehensive WebSocket: /ws/call-stream/{call_id}
# =====================================================================
@app.websocket("/ws/call-stream/{call_id}")
async def websocket_call_stream(websocket: WebSocket, call_id: str):
    await websocket.accept()
    logger.info(f"Active call stream opened for Call ID: {call_id}")

    db: Session = SessionLocal()
    caller_number = "Unknown"

    try:
        from app.db.models import CallRecord
        call_rec = db.query(CallRecord).filter(CallRecord.id == call_id).first()
        if call_rec:
            caller_number = call_rec.caller_number

        while True:
            msg = await websocket.receive()

            audio_chunk: bytes = None
            text_input: str = None
            target_lang: str = "en"

            if "bytes" in msg and msg["bytes"]:
                audio_chunk = msg["bytes"]
            elif "text" in msg and msg["text"]:
                try:
                    data = json.loads(msg["text"])
                    action = data.get("action", "")
                    target_lang = data.get("language", "en")
                    if "phone_number" in data:
                        caller_number = data["phone_number"]

                    if action == "audio_chunk" and "audio_base64" in data:
                        audio_chunk = base64.b64decode(data["audio_base64"])
                    elif action == "caller_speech":
                        text_input = data.get("text", "")
                    elif action == "ping":
                        await websocket.send_json({"type": "pong"})
                        continue
                except Exception as ex:
                    logger.debug(f"JSON parse error on stream: {ex}")
                    continue

            # Process Audio Chunk if present
            is_deepfake = False
            deepfake_conf = 0.0
            if audio_chunk:
                df_res = deepfake_detector.analyze_audio_chunk(audio_chunk)
                is_deepfake = df_res["is_synthetic"]
                deepfake_conf = df_res["confidence"]

                await websocket.send_json({
                    "type": "audio_classification",
                    "label": df_res["label"],
                    "confidence": deepfake_conf,
                    "is_synthetic": is_deepfake
                })

                if not text_input:
                    stt_res = stt_service.transcribe_audio_chunk(audio_chunk, target_language=target_lang)
                    if stt_res["text"]:
                        text_input = stt_res["text"]
                        target_lang = stt_res["language"]

            # Process Spoken Text / Transcript if present
            if text_input:
                scam_res = scam_analyzer.analyze_transcript(text_input, language=target_lang)

                risk_eval = risk_engine.evaluate(
                    db=db,
                    phone_number=caller_number,
                    live_transcript=text_input,
                    is_deepfake=is_deepfake,
                    deepfake_confidence=deepfake_conf
                )

                await websocket.send_json({
                    "type": "transcript_update",
                    "speaker": "caller",
                    "text": text_input,
                    "language": target_lang,
                    "scam_alert": scam_res["scam_category"] if scam_res["is_scam"] else None,
                    "matched_keywords": scam_res.get("matched_patterns", []),
                    "risk_score": risk_eval["final_score"],
                    "risk_level": risk_eval["risk_level"],
                    "color_code": risk_eval["color_code"],
                    "recommendation": risk_eval["recommendation"]
                })

                ai_turn = ai_assistant.process_caller_turn(
                    db=db,
                    call_id=call_id,
                    caller_transcript=text_input,
                    detected_language=target_lang,
                    is_deepfake=is_deepfake,
                    deepfake_confidence=deepfake_conf
                )

                await websocket.send_json({
                    "type": "assistant_reply",
                    "speaker": "assistant",
                    "text": ai_turn["assistant_reply"],
                    "decision": ai_turn["decision"],
                    "risk_score": ai_turn["updated_risk_score"],
                    "risk_level": ai_turn["risk_level"],
                    "color_code": ai_turn["color_code"]
                })

    except (WebSocketDisconnect, RuntimeError):
        logger.info(f"Stream cleanly closed for Call ID: {call_id}")
    except Exception as e:
        logger.error(f"Error in /ws/call-stream/{call_id}: {e}")
        try:
            await websocket.close()
        except Exception:
            pass
    finally:
        db.close()

if __name__ == "__main__":
    import uvicorn
    uvicorn.run("app.main:app", host="0.0.0.0", port=8000, reload=True)
