# SamagraAI – Multimodal Chat Assistant 🧠✨

SamagraAI is a Flutter-based chat application backed by a FastAPI service that blends LLM chat (Gemini), Retrieval-Augmented Generation (RAG) over uploaded PDFs and OCR’ed images, and streaming responses. This repo contains both the Flutter app (`samagra_app/`) and the Python backend (`samagra_backend/`).

- Frontend: Flutter (Material 3, Provider) with speech input, attachments, streaming markdown rendering, light/dark themes.
- Backend: FastAPI with LangChain, FAISS vector store, Google Generative AI (Gemini) for chat + embeddings, OCR via Google Vision with EasyOCR fallback.

Docs hub:
- docs/README.md – start here
- docs/Architecture.md – system architecture and diagrams
- docs/Backend.md – services and pipelines (chat, RAG, OCR)
- docs/Frontend.md – widgets, providers, app flow
- docs/API.md – endpoints and payloads
- docs/Workflow.md – end‑to‑end message/data flow
- docs/Setup.md – environment and run instructions
- docs/Presentation.md – professor‑ready narrative

## Quick Start

Prerequisites:
- Flutter SDK (3.9+) and a device or Chrome for web
- Python 3.10+ and a virtual environment
- Google API key (for Gemini + optional Vision OCR)

Backend (FastAPI):

```bash
# From repo root
cd samagra_backend
python -m venv venv
# Windows PowerShell
venv\Scripts\Activate.ps1
pip install -r requirements.txt
# Set GOOGLE_API_KEY in .env (see core/config.py)
uvicorn main:app --reload --port 8000
```

Frontend (Flutter):

```bash
# From repo root
cd samagra_app
flutter pub get
flutter run -d chrome --web-port 8080
```

## Features
- Chat with Gemini models (configurable) with streaming tokens
- Upload PDFs for RAG; persistent in-memory FAISS index per server process
- Send images; OCR text added to the same vector store (Vision API → EasyOCR fallback)
- Attach multiple docs; preview above input; selective staging
- Speech-to-text input (mobile/desktop via plugin; web fallback)
- Theming (light/dark), markdown rendering with code blocks

See the docs folder for full details.
