from langchain_google_genai import ChatGoogleGenerativeAI
from core.config import settings

# 1. Initialize the Language Model
llm = ChatGoogleGenerativeAI(
    model="gemini-2.5-pro",
    google_api_key=settings.GOOGLE_API_KEY,
    convert_system_message_to_human=True
)

def generate_ai_response(message: str) -> str:
    """
    This is the core function that gets a response from the AI model.
    """
    try:
        # 2. Invoke the model with the user's message
        ai_response = llm.invoke(message)
        
        # 3. Extract and return the text content from the response
        return ai_response.content
    except Exception as e:
        # A simple way to handle potential errors from the API
        print(f"Error calling AI model: {e}")
        return "Sorry, I'm having trouble thinking right now. Please try again later."
