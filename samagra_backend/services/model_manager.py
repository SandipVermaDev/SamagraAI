"""
Model Manager for handling AI model selection and initialization
"""
from langchain_google_genai import ChatGoogleGenerativeAI
from core.config import settings

class ModelManager:
    """Manages AI model instances and switching"""
    
    # Available models mapping
    AVAILABLE_MODELS = {
        'gemini-2.5-flash-lite': 'gemini-2.5-flash-lite',
        'gemini-2.5-flash': 'gemini-2.5-flash',
        'gemini-2.5-pro': 'gemini-2.5-pro',
        'gemini-2.0-flash-lite': 'gemini-2.0-flash-lite',
        'gemini-2.0-flash': 'gemini-2.0-flash',
    }
    
    def __init__(self):
        self._current_model_id = 'gemini-2.5-flash-lite'  # Default model
        self._llm = None
        self._initialize_model()
    
    def _initialize_model(self):
        """Initialize the language model with current settings"""
        model_name = self.AVAILABLE_MODELS.get(
            self._current_model_id,
            'gemini-2.5-flash-lite'
        )
        
        print(f"Initializing model: {model_name}")
        
        self._llm = ChatGoogleGenerativeAI(
            model=model_name,
            google_api_key=settings.GOOGLE_API_KEY,
            convert_system_message_to_human=True,
            streaming=True
        )
    
    def get_llm(self):
        """Get the current language model instance"""
        return self._llm
    
    def set_model(self, model_id: str):
        """
        Change the current model
        
        Args:
            model_id: The model identifier (e.g., 'gemini-2.5-flash')
        
        Returns:
            bool: True if model was changed successfully, False otherwise
        """
        if model_id not in self.AVAILABLE_MODELS:
            print(f"Warning: Unknown model ID '{model_id}'. Using default.")
            return False
        
        if model_id != self._current_model_id:
            print(f"Switching model from {self._current_model_id} to {model_id}")
            self._current_model_id = model_id
            self._initialize_model()
            return True
        
        return True
    
    def get_current_model_id(self) -> str:
        """Get the current model ID"""
        return self._current_model_id
    
    def get_available_models(self) -> dict:
        """Get dictionary of available models"""
        return self.AVAILABLE_MODELS.copy()


# Global model manager instance
model_manager = ModelManager()
