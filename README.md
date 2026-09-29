# 🛡️ VoxGuard — Full-Stack AI Call Security & Deepfake Defense System

> **Next-Generation Call Screening, Multilingual AI Voice Assistant, and Real-Time Deepfake Voice Detection Engine** (similar to Truecaller with an integrated autonomous AI Voice Security Agent).

---

## 🏛️ System Architecture Overview

```
                                  VOXGUARD ARCHITECTURE
                                  ====================

  [ Incoming Android Call ] 
            │
            ▼
  ┌─────────────────────────────────────────────────────────────┐
  │  Android Native Telecom Framework                           │
  │  ├── VoxCallScreeningService (Pre-ring Call Interception)   │
  │  ├── VoxInCallService (Active Call Stream & Audio Capture)   │
  │  └── CallOverlayService (SYSTEM_ALERT_WINDOW Floating Badge)│
  └──────────────────────────────┬──────────────────────────────┘
                                 │
                 MethodChannel / Native Audio Stream
                                 │
                                 ▼
  ┌─────────────────────────────────────────────────────────────┐
  │  Flutter Mobile Client Application (Android)                │
  │  ├── WebSocketAudioService (16kHz PCM Stream / Events)      │
  │  ├── Live Audio Waveform & Animated Risk Badge (🟢 🟡 🔴)   │
  │  ├── Real-Time Multilingual STT Dialogue Viewer             │
  │  └── Contacts Book Whitelist & Truecaller-Style Search UI   │
  └──────────────────────────────┬──────────────────────────────┘
                                 │  WebSocket: /ws/call-stream/{id}
                                 │  REST: /api/caller, /api/risk
                                 ▼
  ┌─────────────────────────────────────────────────────────────┐
  │  VoxGuard FastAPI AI Inference Server (Python 3.11/3.12)    │
  │  ┌───────────────────────────────────────────────────────┐  │
  │  │ ⚡ Real-Time WebSocket Streaming Pipeline              │  │
  │  │  - /ws/detect-audio (Binary 16kHz PCM buffer stream)  │  │
  │  │  - /ws/call-stream/{id} (Full-duplex conversation)    │  │
  │  └───────────────────────────┬───────────────────────────┘  │
  │                              │                              │
  │       ┌──────────────────────┼──────────────────────┐       │
  │       ▼                      ▼                      ▼       │
  │  ┌───────────────┐   ┌───────────────┐   ┌───────────────┐  │
  │  │ Deepfake Voice│   │  Multilingual │   │  NLP Scam     │  │
  │  │ Detector      │   │  STT Service  │   │  Analyzer     │  │
  │  │ (HF / Wav2Vec2│   │  (Whisper/    │   │  (OTP / IRS / │  │
  │  │  DSP Vocoder) │   │   SeamlessM4T)│   │   Extortion)  │  │
  │  └───────┬───────┘   └───────┬───────┘   └───────┬───────┘  │
  │          │                   │                   │          │
  │          └───────────────────┼───────────────────┘          │
  │                              ▼                              │
  │              ┌───────────────────────────────┐              │
  │              │  Dynamic Risk Engine (0-100)  │              │
  │              │  - Spam DB & Community Flags  │              │
  │              │  - 30-Min Burst Call Velocity │              │
  │              │  - Deepfake Confidence Score  │              │
  │              │  - NLP Intent Urgency Penalty │              │
  │              │  - Contact Whitelist Discount │              │
  │              └───────────────┬───────────────┘              │
  │                              ▼                              │
  │              ┌───────────────────────────────┐              │
  │              │  AI Assistant Screening Turn  │              │
  │              │  (ALLOW / CONTINUE / BLOCK)   │              │
  │              └───────────────────────────────┘              │
  │                              │                              │
  │  ┌───────────────────────────┴───────────────────────────┐  │
  │  │ SQLite / PostgreSQL Database (Spam Records, History)  │  │
  │  └───────────────────────────────────────────────────────┘  │
  └─────────────────────────────────────────────────────────────┘
```

---

## 🚀 Key Features

### 1. Automatic Call Screening & AI Voice Assistant
- **Pre-Ring Call Interception**: Intercepts unverified or suspicious phone calls before the phone rings using Android's `CallScreeningService`.
- **Autonomous AI Screening**: Answers on behalf of the user with:
  > *"Hello, I am the VoxGuard AI Voice Assistant. Who is calling and what is the reason for your call?"*
- **Multilingual Support**: Real-time STT across **English**, **Spanish**, **Hindi**, **French**, and **German**.
- **Live Transcription Feed**: Streams the caller's spoken replies directly to the active screen with speaker tags.
- **Smart Forwarding & Auto-Hangup**: Connects genuine callers to the handset or automatically disconnects if extortion/fraud is detected.

### 2. AI Deepfake & Synthetic Voice Classification
- **16kHz PCM Buffer Streaming**: Receives raw audio chunks via binary WebSockets (`/ws/detect-audio` or `/ws/call-stream/{call_id}`).
- **Transformer & DSP Hybrid Pipeline**:
  - Primary: Hugging Face audio classification (`mo-thecreator/Deepfake-audio-detection` / Wav2Vec2 / Audio Spectrogram Transformer).
  - Secondary: High-fidelity DSP Acoustic Artifact Analyzer extracting **spectral flatness (Wiener entropy)**, **vocoder high-frequency decay**, and **zero-crossing rates** for instant edge detection.
- **NLP Scam Intent Detector**: Scans transcripts for high-risk social engineering markers:
  - OTP & Card verification credential theft
  - IRS / FBI / Law enforcement arrest threats
  - Urgent bank wire transfers & gift cards
  - Remote access trojans (AnyDesk, TeamViewer)
  - Family emergency / voice clone kidnapping scams

### 3. Dynamic Caller Risk Level Engine
Computes a live Bayesian **0 – 100 Risk Score**:
- **🟢 LOW RISK (0 – 34%)**: Verified contacts, recognized numbers, authentic human voice (`#10B981`).
- **🟡 MEDIUM RISK (35 – 69%)**: Uncategorized callers, suspicious keywords, rapid burst calls (`#F59E0B`).
- **🔴 HIGH RISK (70 – 100%)**: Known spam DB hits, detected AI voice clones, active scam speech (`#EF4444`).
- **Floating Overlay Badge**: Renders an animated, color-coded floating badge directly on top of the native Android call screen using `SYSTEM_ALERT_WINDOW`.

---

## 📂 Project Directory Structure

```
voxguard/
├── backend/
│   ├── app/
│   │   ├── __init__.py
│   │   ├── main.py                    # FastAPI server & WebSocket handlers (/ws/detect-audio, /ws/call-stream)
│   │   ├── core/
│   │   │   ├── config.py              # Environment settings, thresholds, audio rates
│   │   │   └── logging.py             # Structured logger
│   │   ├── db/
│   │   │   ├── models.py              # SpamRecord, ContactWhitelist, CallRecord, AssistantDialogue
│   │   │   ├── session.py             # SQLAlchemy session & SQLite/Postgres configuration
│   │   │   └── seed_data.py           # Preloaded spam numbers and whitelisted sample contacts
│   │   ├── models/
│   │   │   └── schemas.py             # Pydantic request/response schemas
│   │   ├── services/
│   │   │   ├── deepfake_detector.py   # Transformer + DSP Acoustic Artifact Analyzer for 16kHz audio
│   │   │   ├── stt_service.py         # Multilingual Whisper speech-to-text service
│   │   │   ├── scam_analyzer.py       # Multilingual NLP scam intent classifier
│   │   │   ├── risk_engine.py         # Multi-factor dynamic risk scoring engine
│   │   │   └── ai_assistant.py        # Conversational screening dialogue manager
│   │   └── api/
│   │       ├── caller_routes.py       # Caller ID lookup, report spam, history, whitelist
│   │       ├── screening_routes.py    # AI screening session start, dialogue turn processing
│   │       ├── risk_routes.py         # Dynamic risk evaluation and security statistics
│   │       └── health_routes.py       # Health check and root status
│   ├── tests/
│   │   ├── conftest.py                # Database test fixtures
│   │   ├── test_risk_engine.py        # Risk engine unit tests
│   │   ├── test_scam_analyzer.py      # NLP scam pattern tests
│   │   ├── test_deepfake_detector.py  # 16kHz PCM audio chunk & DSP analyzer tests
│   │   ├── test_api.py                # REST endpoints integration tests
│   │   └── test_websocket.py          # WebSocket audio streaming tests
│   ├── deploy/
│   │   ├── render.yaml                # Render cloud blueprint
│   │   ├── railway.json               # Railway deployment configuration
│   │   ├── cloudbuild.yaml            # Google Cloud Run deployment pipeline
│   │   └── aws-ecs-task.json          # AWS ECS Fargate task definition
│   ├── Dockerfile                     # Multi-stage container with libsndfile, ffmpeg & PyTorch
│   ├── docker-compose.yml             # Full-stack composition with PostgreSQL
│   ├── requirements.txt               # Backend dependencies
│   ├── run_server.py                  # Server runner script
│   ├── test_client_simulation.py      # Turnkey E2E simulation script
│   └── voxguard.db                    # Auto-generated SQLite database
│
└── frontend/
    ├── pubspec.yaml                   # Flutter dependencies
    ├── lib/
    │   ├── main.dart                  # Flutter entrypoint & dark security theme
    │   ├── models/
    │   │   ├── caller_info.dart       # Caller reputation model
    │   │   ├── risk_assessment.dart   # Risk score breakdown model
    │   │   ├── call_record.dart       # Call history model
    │   │   └── transcript_entry.dart  # Dialogue speech entry model
    │   ├── services/
    │   │   ├── api_service.dart       # REST client for backend
    │   │   ├── websocket_service.dart # Real-time binary audio streamer
    │   │   ├── call_screening_service.dart # Android CallScreeningService bridge
    │   │   ├── overlay_service.dart   # SYSTEM_ALERT_WINDOW floating badge bridge
    │   │   └── contacts_service.dart  # Local contact cache & whitelist
    │   ├── widgets/
    │   │   ├── risk_badge.dart        # 🟢 / 🟡 / 🔴 animated pulsing indicator
    │   │   ├── live_transcript_list.dart # Real-time chat bubbles with scam alerts
    │   │   ├── audio_waveform_visualizer.dart # Animated frequency bar visualizer
    │   │   └── call_action_bar.dart   # Reject, Answer, and AI Screen buttons
    │   ├── screens/
    │   │   ├── home_screen.dart       # Dashboard with security stats & incoming call simulator
    │   │   ├── active_call_screen.dart# Real-time incoming call UI with floating badge & transcripts
    │   │   ├── ai_screening_screen.dart # Dedicated AI screening conversation manager
    │   │   ├── caller_lookup_screen.dart# Truecaller-style reputation lookup
    │   │   └── settings_screen.dart   # Sensitivity, backend URL, and Android permissions
    │   └── test/
    │       └── widget_test.dart       # Flutter unit and widget tests
    └── android/
        ├── app/
        │   ├── build.gradle           # Android SDK 34, minSdk 26
        │   └── src/main/
        │       ├── AndroidManifest.xml # Permissions for CallScreening, InCallService, Overlay
        │       ├── kotlin/com/voxguard/app/
        │       │   ├── MainActivity.kt            # MethodChannels for screening and overlay
        │       │   ├── VoxCallScreeningService.kt # Android CallScreeningService implementation
        │       │   ├── VoxInCallService.kt        # Android InCallService for active calls
        │       │   └── CallOverlayService.kt      # Floating window overlay service
        │       └── res/layout/
        │           └── layout_call_overlay.xml    # Native floating overlay XML layout
        ├── build.gradle
        ├── settings.gradle
        └── fastlane/
            ├── Fastfile               # Automated APK build & Google Play deployment lanes
            └── Appfile                # Package identifier configuration
```

---

## 🧪 Testing & Verification

The backend includes a comprehensive test suite of **27 unit & integration tests**:
- Dynamic Risk Engine scoring (whitelist discounts, known spam hits, burst frequency)
- Multilingual NLP Scam Intent Detection (English, Spanish, Hindi, French, German)
- 16kHz PCM audio chunk analysis and deepfake detection
- REST API endpoints (Health, Caller Lookup, Report Spam, Risk Evaluate, Screening Dialogue)
- WebSocket `/ws/detect-audio` and `/ws/call-stream/{call_id}` real-time streaming

### Run Unit Tests:
```powershell
cd backend
python -m pytest tests/ -v
```
*(Result: **27 passed in 0.75s**)*

### Run Interactive E2E Simulation:
```powershell
cd backend
python test_client_simulation.py
```

---

## 🛠️ Step-by-Step Execution Guide

### Step 1: Start the Backend Server Locally
```powershell
cd backend
python run_server.py
```
- Interactive Swagger API Documentation: `http://localhost:8000/docs`
- Health Endpoint: `http://localhost:8000/health`
- Binary Audio WebSocket: `ws://localhost:8000/ws/detect-audio`
- Call Stream WebSocket: `ws://localhost:8000/ws/call-stream/{call_id}`

### Step 2: Docker Container Deployment
Build and run the backend using Docker:
```bash
cd backend
docker build -t voxguard-backend .
docker run -d -p 8000:8000 --name voxguard-api voxguard-backend
```
Or start full stack with PostgreSQL:
```bash
docker-compose up -d
```

### Step 3: Cloud Deployment

#### Option A: Render.com
1. Connect your Git repository to Render.
2. Render will automatically detect `backend/deploy/render.yaml` and provision both the FastAPI Docker service and managed PostgreSQL database.

#### Option B: Google Cloud Run
```bash
cd backend
gcloud builds submit --config=deploy/cloudbuild.yaml
```

#### Option C: Railway
```bash
cd backend
railway up
```

### Step 4: Run & Build the Android Mobile App

#### 1. Configure Backend URL
In `frontend/lib/services/api_service.dart` (or via the in-app Settings screen), ensure `baseUrl` points to your backend:
- Android Emulator: `http://10.0.2.2:8000`
- Physical Device on LAN: `http://<YOUR_COMPUTER_LOCAL_IP>:8000`
- Cloud Production: `https://your-voxguard-api.onrender.com`

#### 2. Run Debug Mode
```bash
cd frontend
flutter pub get
flutter run
```

#### 3. Build Release APK with Fastlane or Gradle
```bash
cd frontend/android
# Using Gradle directly:
./gradlew assembleRelease

# Or using Fastlane:
fastlane build_apk
```
The output APK will be generated at:
`frontend/build/app/outputs/flutter-apk/app-release.apk`

---

## 🔐 Android Native Permissions Setup

When running VoxGuard on an Android device:
1. **Call Screening Role**: Open **Settings** in the app and tap **"Enable"** on *Call Screening Service Role*. Select VoxGuard as the default caller ID & spam app.
2. **System Alert Window**: Tap **"Enable"** on *SYSTEM_ALERT_WINDOW Overlay* to permit the floating 🟢/🟡/🔴 badge to draw on top of native incoming phone calls.
3. **Audio Permission**: Grant `RECORD_AUDIO` to enable local mic capture and real-time streaming to the backend.

---

## 📄 License
VoxGuard is open-source software licensed under the MIT License.
