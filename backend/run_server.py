import uvicorn
from app.core.config import settings

if __name__ == "__main__":
    print(f"🚀 Starting {settings.PROJECT_NAME} v{settings.VERSION}...")
    print(f"📡 API Documentation available at http://localhost:{settings.PORT}/docs")
    print(f"⚡ WebSocket endpoints: ws://localhost:{settings.PORT}/ws/detect-audio and ws://localhost:{settings.PORT}/ws/call-stream/{{call_id}}")
    uvicorn.run("app.main:app", host=settings.HOST, port=settings.PORT, reload=settings.DEBUG)
