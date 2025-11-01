# Backend (FastAPI) 🔧

> Prev: [Architecture](Architecture.md) · Next: [Frontend](Frontend.md)

## Modules
- `main.py`: App factory, CORS, router registration.
- `api/chat.py`:
  - `POST /chat`: non-streaming chat; returns `{ reply }`.
  - `POST /chat/stream`: streaming chat (SSE). Accepts `ChatRequest` (see schemas) and emits incremental chunks.
  - `GET /documents/status`: status of the in-memory vector store.
  - `DELETE /documents`: clear all processed documents/images.
  - `POST /model/select`: change active Gemini model.
  - `GET /model/available`: list available models.
- `api/document.py`:
  - `POST /documents/upload`: (compat) upload and process a PDF.
  - `POST /documents/upload-document`: upload PDF and return a typed response.
- `schemas/*.py`: Pydantic models for requests/responses.
- `services/chat_service.py`: core chat + stream pipeline, RAG prompt, image generation branch.
- `services/model_manager.py`: Gemini model init + system instruction; switcher.
- `services/rag_service.py`: RAG ingestion (PDFs, OCR images) and FAISS store.

## Chat Flow
1. Frontend sends `ChatRequest` to `/chat/stream` with `message`, optional `model`, document info, and optional inline `imageBase64`.
2. Backend may process a new document (base64 PDF) or OCR an image and index text in FAISS.
3. If a retriever exists, a RAG chain (Prompt -> Gemini -> `StrOutputParser`) answers grounded on retrieved chunks; otherwise, general chat path is used.
4. Streaming: emits `data: {content: "...", type: "text"}` lines; image responses yield `type: "image"` with `mime_type` and `content` (base64). Ends with `data: {done: true}`.

## RAG Service
- PDFs: `PyPDFLoader` → `RecursiveCharacterTextSplitter` → FAISS (merge/add). `k=10` retriever.
- OCR: Google Vision API first; EasyOCR fallback when unavailable. Extracted text is wrapped in a LangChain `Document` and split/indexed.
- Store lifecycle: in-memory; cleared via `/documents` DELETE.

## Model Manager
- Available models (text + image-gen), defaults to `gemini-2.5-flash-lite`.
- Adds `system_instruction` (concise, engaging, emoji-light Samagra AI persona) to all sessions.
- Image-gen models set `response_modalities` to `[IMAGE, TEXT]`.

Current model catalogue (from `services/model_manager.py`):

- Text
  - `gemini-2.5-flash-lite` – Fastest and most cost-effective
  - `gemini-2.5-flash` – Fast and efficient
  - `gemini-2.5-pro` – Most capable for complex tasks
  - `gemini-2.0-flash-lite` – Lightweight and quick
  - `gemini-2.0-flash` – Balanced performance
- Image Generation
  - `gemini-2.0-flash-preview-image-generation` – Image model

## Schemas
`schemas/chat.py`
- `ChatRequest`: `{ message: str, model?: str, document?: {fileName?, fileSize?}, documentBase64?: str, uploadedDocumentName?: str, imagePath?: str, imageBase64?: str, imageName?: str }`
- `ChatResponse`: `{ reply: str }`
- `ModelSelectionRequest`: `{ model_id: str }`
- `ModelSelectionResponse`: `{ success: bool, message: str, model_id: str }`

`schemas/document.py`
- `DocumentUploadResponse`: `{ success: bool, message: str }`

## Configuration
- `.env` → `core/config.py` loads `GOOGLE_API_KEY` and other settings.

## Run & Test
```bash
cd samagra_backend
python -m venv venv
venv\Scripts\Activate.ps1
pip install -r requirements.txt
# set GOOGLE_API_KEY
uvicorn main:app --reload --port 8000
```

Test:
- `GET /` → health
- `POST /chat/stream` with `{ "message": "Hello" }`
- `POST /documents/upload` with a PDF (multipart)
- `GET /documents/status` to inspect vector store

---
Prev: [Architecture](Architecture.md) · Next: [Frontend](Frontend.md)
