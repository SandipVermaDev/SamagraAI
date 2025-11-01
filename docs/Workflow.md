# Workflow & App Flow 🔄

> Prev: [API](API.md) · Next: [Setup](Setup.md)

## End-to-End Message Flow

```mermaid
sequenceDiagram
  autonumber
  participant U as User
  participant F as Flutter App
  participant B as FastAPI Backend
  participant R as RAG Service (FAISS)
  participant M as Gemini (Chat)

  U->>F: Type message / attach docs/images
  F->>B: Upload new PDFs (multipart)
  B->>R: Split document into chunks
  R-->>B: Add/merge into FAISS
  U->>F: Send message
  F->>B: POST /chat/stream (SSE)
  alt Has image (inline)
    B->>R: OCR (Vision/EasyOCR) and index text
  end
  B->>R: Retrieve context (if available)
  B->>M: Prompt (system + context + question)
  M-->>B: Stream tokens
  B-->>F: SSE chunks (text and/or image)
  F-->>U: Live update AI bubble
```

## Context Handling
- The backend keeps an in-memory FAISS index across uploads until cleared.
- For each turn, if a retriever exists, a RAG chain grounds answers on top‑k chunks.
- Images are treated as additional text context after OCR.

## Attachments UX
- Documents/images selected for the next message appear as a preview above the input bar (staged list).
- On send, documents upload first; the chat request references them and the stream begins.

## Error Paths

---
- OCR or PDF parsing failure → proceed without extra context; user is informed in the stream.
- SSE parse errors on client → gracefully stop and show partial answer.

Prev: [API](API.md) · Next: [Setup](Setup.md)