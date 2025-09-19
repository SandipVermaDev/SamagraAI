from fastapi import FastAPI
from api.chat import router as chat_router
from api.document import router as document_router

# Create the main FastAPI application instance
app = FastAPI(
    title="Samagra AI Engine",
    description="The core backend for the Samagra AI multimodal chatbot.",
    version="1.0.0"
)

# Include the router from the api
app.include_router(chat_router)
app.include_router(document_router)

@app.get("/", tags=["Health Check"])
async def root():
    """
    Root endpoint to check if the API is running.
    """
    return {"status": "online", "message": "Welcome to Samagra AI Engine!"}