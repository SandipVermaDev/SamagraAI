from fastapi import APIRouter
from fastapi.responses import StreamingResponse
from schemas.chat import ChatRequest, ChatResponse, ModelSelectionRequest, ModelSelectionResponse
from services.chat_service import generate_ai_response, generate_ai_response_stream
from services.rag_service import document_store
from services.model_manager import model_manager

# 1. Create a new router
router = APIRouter(tags=["Chat"])


# 2. Define the streaming chat endpoint
@router.post("/chat/stream")
async def handle_chat_stream_request(request: ChatRequest):
    """
    This endpoint receives a user's message and returns the AI's response as a stream.
    It now supports document processing via base64 content and optional model selection per request.
    """
    print(f"Received streaming chat request: message='{request.message}', has_document={request.documentBase64 is not None}, model={request.model}")
    if request.document:
        print(f"Document info: fileName={request.document.fileName}, fileSize={request.document.fileSize}")
    
    # Set model if specified in request
    if request.model:
        model_manager.set_model(request.model)
    
    # Return streaming response
    return StreamingResponse(
        generate_ai_response_stream(
            message=request.message,
            document_base64=request.documentBase64,
            document_filename=request.document.fileName if request.document else None,
            image_base64=request.imageBase64,
            image_filename=request.imageName,
        ),
        media_type="text/event-stream",
        headers={
            "Cache-Control": "no-cache",
            "Connection": "keep-alive",
        }
    )


# 3. Keep the old non-streaming endpoint for backward compatibility
@router.post("/chat", response_model=ChatResponse)
async def handle_chat_request(request: ChatRequest):
    """
    This endpoint receives a user's message and returns the AI's response.
    It now supports document processing via base64 content and optional model selection per request.
    """
    print(f"Received chat request: message='{request.message}', has_document={request.documentBase64 is not None}, model={request.model}")
    if request.document:
        print(f"Document info: fileName={request.document.fileName}, fileSize={request.document.fileSize}")
    
    # Set model if specified in request
    if request.model:
        model_manager.set_model(request.model)
    
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
    return {"message": "All documents cleared successfully"}

@router.post("/model/select", response_model=ModelSelectionResponse)
async def select_model(request: ModelSelectionRequest):
    """
    Set the AI model to use for chat responses.
    """
    try:
        success = model_manager.set_model(request.model_id)
        if success:
            return ModelSelectionResponse(
                success=True,
                message=f"Model successfully changed to {request.model_id}",
                model_id=request.model_id
            )
        else:
            return ModelSelectionResponse(
                success=False,
                message=f"Invalid model ID: {request.model_id}",
                model_id=request.model_id
            )
    except Exception as e:
        return ModelSelectionResponse(
            success=False,
            message=f"Error changing model: {str(e)}",
            model_id=request.model_id
        )

@router.get("/model/available")
async def get_available_models():
    """
    Get the list of available AI models.
    """
    return {
        "models": [
            {
                "id": model_id,
                "name": info["name"],
                "description": info["description"]
            }
            for model_id, info in model_manager.AVAILABLE_MODELS.items()
        ],
        "current_model": model_manager.current_model_id
    }
    return {"message": "Documents cleared successfully"}