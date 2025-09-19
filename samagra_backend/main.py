from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from api.chat import router as chat_router
from api.document import router as document_router

# Create the main FastAPI application instance
app = FastAPI(
    title="Samagra AI Engine",
    description="The core backend for the Samagra AI multimodal chatbot.",
    version="1.0.0"
)

# Add CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Allows all origins
    allow_credentials=True,
    allow_methods=["*"],  # Allows all methods
    allow_headers=["*"],  # Allows all headers
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