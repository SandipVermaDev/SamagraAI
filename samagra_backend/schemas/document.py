from pydantic import BaseModel

class DocumentUploadResponse(BaseModel):
    """
    Defines the response after a document is uploaded.
    """
    success: bool
    message: str