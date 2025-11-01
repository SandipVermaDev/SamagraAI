# API Reference 🔗

> Prev: [Frontend](Frontend.md) · Next: [Workflow](Workflow.md)

Base URL: `http://localhost:8000`

## Health
- `GET /` → `{ status: "online", message: "..." }`

## Chat
- `POST /chat` (non-streaming)
  - Body: `ChatRequest`
  - Response: `{ reply: string }`

- `POST /chat/stream` (SSE)
  - Body: `ChatRequest`
  - Stream items (one per line, prefixed with `data:`):
    - `{ content: string, type?: "text" }`
    - `{ content: base64-string, type: "image", mime_type: "image/png|..." }`
    - `{ done: true }` when complete

### ChatRequest
```json
{
  "message": "string",
  "model": "optional model id",
  "document": { "fileName": "optional", "fileSize": 123 },
  "documentBase64": "optional base64 PDF",
  "uploadedDocumentName": "optional server-side name",
  "imagePath": "optional path",
  "imageBase64": "optional base64 image",
  "imageName": "optional name"
}
```

## Documents
- `POST /documents/upload` (multipart form)
  - Field: `file` (PDF)
  - Response: `{ message, filename, size }` (compat endpoint)

- `POST /documents/upload-document`
  - Field: `file` (PDF)
  - Response: `{ success: bool, message: string }`

- `GET /documents/status`
  - Response: `{ has_content: bool, file_count: number, files: string[] }`

- `DELETE /documents`
  - Clears FAISS index in memory

## Models

---
- `POST /model/select` → `{ success, message, model_id }`
- `GET /model/available` → `{ models: { id, name, description, mode }[], current_model: id }`

Prev: [Frontend](Frontend.md) · Next: [Workflow](Workflow.md)