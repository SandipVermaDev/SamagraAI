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
    """
    # 3. Call the AI service to get a reply
    ai_reply = generate_ai_response(request.message)

    # 4. Return the reply in the defined response shape
    return ChatResponse(reply=ai_reply)