from fastapi import APIRouter
from schemas.chat import ChatRequest, ChatResponse
from services.chat_service import generate_ai_response

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