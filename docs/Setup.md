# Setup & Run 🛠️

## Prerequisites
- Flutter SDK 3.9+ (Chrome or a device/emulator)
- Python 3.10+
- Google API Key (for Gemini; Vision OCR optional)

## Backend (FastAPI)
```powershell
cd samagra_backend
python -m venv venv
venv\Scripts\Activate.ps1
pip install -r requirements.txt
# Configure environment
# Create .env with: GOOGLE_API_KEY=your_key_here
uvicorn main:app --reload --port 8000
```

## Frontend (Flutter)
```powershell
cd samagra_app
flutter pub get
flutter run -d chrome --web-port 8080
```

## Verify
- Open http://localhost:8000/ → `{ status: "online" }`
- Chat in the app → watch streaming responses
- Upload a PDF → check `/documents/status` reflects it

## Tips
- If mic permission is denied, enable it in OS settings and retry.
- Android builds require JDK 17; configure `JAVA_HOME` or use Android Studio’s embedded JDK.
- Vector store is in-memory; clearing the backend resets uploaded context.
