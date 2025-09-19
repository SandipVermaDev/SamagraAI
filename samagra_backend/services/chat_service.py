from langchain_core.prompts import PromptTemplate
from langchain_core.output_parsers import StrOutputParser
from langchain_core.runnables import RunnablePassthrough
from langchain_google_genai import ChatGoogleGenerativeAI
from core.config import settings
from services.rag_service import vector_store_retriever

# 1. Initialize the Language Model
llm = ChatGoogleGenerativeAI(
    model="gemini-2.5-flash-lite",
    google_api_key=settings.GOOGLE_API_KEY,
    convert_system_message_to_human=True
)

def generate_ai_response(message: str) -> str:
    """
    This is the core function that gets a response from the AI model.
    It is now "context-aware" and will use the RAG pipeline if a document
    has been processed.
    """
    # 1. Check if the retriever has been created
    if vector_store_retriever is None:
        # If no document is uploaded, behave as a general chatbot
        print("No document loaded. Using general conversation mode.")
        try:
            ai_response = llm.invoke(message)
            return ai_response.content
        except Exception as e:
            print(f"Error calling AI model: {e}")
            return "Sorry, I'm having trouble thinking right now. Please try again later."
    else:
        # If a document is uploaded, use the RAG chain
        print("Document loaded. Using RAG chain for Q&A.")

        # 2. Create a prompt template for RAG
        template = """
        You are a helpful assistant. Answer the question based only on the following context:
        {context}

        Question: {question}
        """
        prompt = PromptTemplate.from_template(template)

        # 3. Create the RAG chain using LangChain Expression Language (LCEL)
        rag_chain = (
            {"context": vector_store_retriever, "question": RunnablePassthrough()}
            | prompt
            | llm
            | StrOutputParser()
        )

        # 4. Invoke the RAG chain with the user's message
        try:
            # Invoke the RAG chain with the user's message
            return rag_chain.invoke(message)
        except Exception as e:
            # This will print the DETAILED, REAL error to your terminal
            print("\n" + "="*50)
            print("An error occurred in the RAG Chain:")
            print(e)
            print("="*50 + "\n")
            return "An error occurred while answering with the document. Check the server terminal for details."

