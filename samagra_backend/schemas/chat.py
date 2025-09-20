from pydantic import BaseModel
from typing import Optional, Dict, Any

class DocumentInfo(BaseModel):
    """
    Document metadata sent with the chat request.
    """
    fileName: Optional[str] = None
    fileSize: Optional[int] = None

class ChatRequest(BaseModel):
    """
    Defines the shape of a request to the /chat endpoint.
    """
    message: str
    model: Optional[str] = None
    document: Optional[DocumentInfo] = None
    documentBase64: Optional[str] = None
    uploadedDocumentName: Optional[str] = None
    imagePath: Optional[str] = None


class ChatResponse(BaseModel):
    """
    Defines the shape of a response from the /chat endpoint.
    """
    reply: str
