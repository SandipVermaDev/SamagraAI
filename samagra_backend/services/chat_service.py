import base64
from typing import Optional
from langchain_core.prompts import PromptTemplate
from langchain_core.output_parsers import StrOutputParser
from langchain_core.runnables import RunnablePassthrough
from langchain_google_genai import ChatGoogleGenerativeAI
from core.config import settings
from services.rag_service import vector_store_retriever, process_uploaded_document, process_uploaded_image

# 1. Initialize the Language Model
llm = ChatGoogleGenerativeAI(
    model="gemini-2.5-flash-lite",
    google_api_key=settings.GOOGLE_API_KEY,
    convert_system_message_to_human=True
)

def generate_ai_response(
    message: str,
    document_base64: Optional[str] = None,
    document_filename: Optional[str] = None,
    image_base64: Optional[str] = None,
    image_filename: Optional[str] = None,
) -> str:
    """
    This is the core function that gets a response from the AI model.
    It is now "context-aware" and will use the RAG pipeline if a document
    has been processed or if document content is provided via base64.
    """
    global vector_store_retriever
    
    # If document base64 content is provided, process it
    if document_base64:
        print(f"Processing document from base64 content (filename: {document_filename})")
        try:
            # Decode the base64 content
            document_bytes = base64.b64decode(document_base64)
            print(f"Decoded document size: {len(document_bytes)} bytes")
            
            # Process the document through RAG pipeline
            success = process_uploaded_document(document_bytes)
            if success:
                print("Document processed successfully via base64")
            else:
                print("Failed to process document from base64")
                return "Sorry, I had trouble processing your document. Please try again."
        except Exception as e:
            print(f"Error processing base64 document: {e}")
            return "Sorry, I had trouble processing your document. Please try again."

    # If an image is provided inline, attempt to OCR and process it
    ocr_text = None
    if image_base64:
        print(f"Processing image from base64 content (filename: {image_filename})")
        try:
            image_bytes = base64.b64decode(image_base64)
            ocr_text = process_uploaded_image(image_bytes, image_filename)
            if ocr_text:
                print(f"Image processed successfully via Google Vision: {len(ocr_text)} characters extracted")
            else:
                print("Failed to extract text from image")
        except Exception as e:
            print(f"Error processing base64 image: {e}")
            ocr_text = None
    
    # 1. Check if the retriever has been created
    if vector_store_retriever is None:
        # If no document is uploaded, behave as a general chatbot
        print("No document loaded. Using general conversation mode.")
        try:
            # If we have OCR text from the image, include it in the prompt
            if ocr_text:
                combined_prompt = (
                    f"Here is text extracted from an image:\n\n{ocr_text}\n\n"
                    f"Based on this text, please answer: {message}"
                )
                ai_response = llm.invoke(combined_prompt)
                return ai_response.content

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

