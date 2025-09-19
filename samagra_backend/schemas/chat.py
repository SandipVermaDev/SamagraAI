from pydantic import BaseModel

class ChatRequest(BaseModel):
    """
    Defines the shape of a request to the /chat endpoint.
    """
    message: str


class ChatResponse(BaseModel):
    """
    Defines the shape of a response from the /chat endpoint.
    """
    reply: str
