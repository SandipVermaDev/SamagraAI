# Presentation Guide 🎬

This script-style guide helps you present SamagraAI smoothly in ~10 minutes.

## 1) Vision (30s)
- SamagraAI is a multimodal copilot: chat + documents (RAG) + images (OCR) with live streaming.
- Built with Flutter (frontend) and FastAPI + LangChain + Gemini (backend).

## 2) Architecture (1 min)
- Show Architecture.md diagram.
- Call out: FAISS in-memory vector store, Gemini chat + embeddings, Vision OCR with EasyOCR fallback.
- Persona: concise, engaging responses with subtle emoji.

## 3) Demo Flow (4 min)
- Start server and app (see Setup.md). 
- Ask a general question → observe streaming.
- Upload a PDF and ask a specific question → answer grounded by RAG.
- Send an image with text → OCR text becomes searchable context.

## 4) Developer Experience (2 min)
- Frontend: Provider state, markdown message bubbles, speech input, SSE parser.
- Backend: `/chat/stream` SSE, RAG service, model manager.
- Easy to extend: swap vector store, add web search, persistence.

## 5) Q&A (2–3 min)
- Data freshness: use RAG; optional web retrieval.
- Memory: rolling window + summary pattern if needed.
- Security: API keys via .env, CORS configured.

## Links
- [Architecture](Architecture.md)
- [Backend](Backend.md)
- [Frontend](Frontend.md)
- [API](API.md)
- [Workflow](Workflow.md)
- [Setup](Setup.md)
