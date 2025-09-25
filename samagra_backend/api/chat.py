from fastapi import APIRouter
from schemas.chat import ChatRequest, ChatResponse
from services.chat_service import generate_ai_response
from services.rag_service import document_store

# 1. Create a new router
router = APIRouter(tags=["Chat"])


# 2. Define the chat endpoint
@router.post("/chat", response_model=ChatResponse)
async def handle_chat_request(request: ChatRequest):
    """
    This endpoint receives a user's message and returns the AI's response.
    It now supports document processing via base64 content.
    """
    print(f"Received chat request: message='{request.message}', has_document={request.documentBase64 is not None}")
    if request.document:
        print(f"Document info: fileName={request.document.fileName}, fileSize={request.document.fileSize}")
    
    # 3. Call the AI service to get a reply, passing document data if available
    ai_reply = generate_ai_response(
        message=request.message,
        document_base64=request.documentBase64,
        document_filename=request.document.fileName if request.document else None
        ,
        image_base64=request.imageBase64,
        image_filename=request.imageName,
    )

    # 4. Return the reply in the defined response shape
    return ChatResponse(reply=ai_reply)


@router.get("/documents/status")
async def get_documents_status():
    """
    Get information about currently loaded documents and images.
    """
    file_list = document_store.get_file_list()
    has_content = document_store.has_retriever()
    return {
        "has_content": has_content,
        "file_count": len(file_list),
        "files": file_list
    }

@router.delete("/documents")
async def clear_documents():
    """
    Clear all processed documents from memory to allow general chat mode.
    """
    document_store.clear()
    return {"message": "Documents cleared successfully"}