import base64
from typing import Optional
from langchain_core.prompts import PromptTemplate
from langchain_core.output_parsers import StrOutputParser
from langchain_core.runnables import RunnablePassthrough
from langchain_google_genai import ChatGoogleGenerativeAI
from core.config import settings
from services.rag_service import document_store, process_uploaded_document, process_uploaded_image

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
    global document_store
    
    print(f"generate_ai_response called with: message='{message[:100]}...', has_document={document_base64 is not None}")
    current_retriever = document_store.get_retriever()
    print(f"Current retriever state: {current_retriever is not None}")
    
    # If document base64 content is provided, process it
    if document_base64:
        print(f"Processing document from base64 content (filename: {document_filename})")
        try:
            # Decode the base64 content
            document_bytes = base64.b64decode(document_base64)
            print(f"Decoded document size: {len(document_bytes)} bytes")
            
            # Process the document through RAG pipeline
            success = process_uploaded_document(document_bytes)
            print(f"Document processing result: {success}")
            current_retriever = document_store.get_retriever()
            print(f"Vector store retriever after processing: {current_retriever is not None}")
            
            if success:
                print("Document processed successfully via base64")
                # Get list of all uploaded files
                file_list = document_store.get_file_list()
                files_info = ", ".join(file_list)
                # Return a confirmation message that indicates the document is ready
                return f"Perfect! I've successfully processed your document '{document_filename}'. Now I have access to: {files_info}. I'm ready to answer questions about any of this content. What would you like to know?"
            else:
                print("Failed to process document from base64")
                return "Sorry, I had trouble processing your document. Please try again."
        except Exception as e:
            print(f"Error processing base64 document: {e}")
            return "Sorry, I had trouble processing your document. Please try again."

    # If an image is provided inline, attempt to OCR and process it, then continue to answer the question via RAG
    if image_base64:
        print(f"Processing image from base64 content (filename: {image_filename})")
        try:
            image_bytes = base64.b64decode(image_base64)
            ocr_text = process_uploaded_image(image_bytes, image_filename)
            if ocr_text:
                print(f"Image processed successfully: {len(ocr_text)} characters extracted and indexed")
                # Refresh retriever and continue below to RAG flow using the user's message
                current_retriever = document_store.get_retriever()
                print(f"Image text indexed into vector store: {current_retriever is not None}")
            else:
                print("Failed to extract text from image; proceeding without image context")
        except Exception as e:
            print(f"Error processing base64 image: {e}; proceeding without image context")
    
    # 1. Check if the retriever has been created
    current_retriever = document_store.get_retriever()
    print(f"Checking retriever state: {current_retriever is not None}")
    
    if current_retriever is None:
        # If no document or image is uploaded, behave as a general chatbot
        print("No document or image loaded. Using general conversation mode.")
        try:
            ai_response = llm.invoke(message)
            return ai_response.content
        except Exception as e:
            print(f"Error calling AI model: {e}")
            return "Sorry, I'm having trouble thinking right now. Please try again later."
    else:
        # If a document or image is uploaded, use the RAG chain
        print("Document/Image loaded. Using RAG chain for Q&A.")
        print(f"Question: {message}")

        # 2. Create a prompt template for RAG
        template = """
        You are a helpful assistant. Answer the question based only on the following context:
        {context}

        Question: {question}
        
        If the context contains relevant information to answer the question, provide a detailed answer.
        If you cannot find the answer in the context, respond with exactly: "NO_ANSWER_IN_DOCUMENT"
        """
        prompt = PromptTemplate.from_template(template)

        # 3. Create the RAG chain using LangChain Expression Language (LCEL)
        rag_chain = (
            {"context": current_retriever, "question": RunnablePassthrough()}
            | prompt
            | llm
            | StrOutputParser()
        )

        # 4. Invoke the RAG chain with the user's message
        try:
            print("Invoking RAG chain...")
            # First, let's test the retriever directly
            relevant_docs = current_retriever.invoke(message)
            print(f"Found {len(relevant_docs)} relevant documents:")
            for i, doc in enumerate(relevant_docs):
                print(f"Doc {i+1}: {doc.page_content[:200]}...")
            
            # Check if any relevant documents were found
            if not relevant_docs or all(len(doc.page_content.strip()) == 0 for doc in relevant_docs):
                print("No relevant documents found, falling back to general chat")
                # Fall back to general chat mode
                try:
                    ai_response = llm.invoke(message)
                    return ai_response.content
                except Exception as e:
                    print(f"Error in fallback general chat: {e}")
                    return "Sorry, I'm having trouble thinking right now. Please try again later."
            
            # Now invoke the full RAG chain
            result = rag_chain.invoke(message)
            print(f"RAG chain result: {result[:200]}...")
            
            # Check if the model couldn't find the answer in the document
            if "NO_ANSWER_IN_DOCUMENT" in result:
                print("No answer found in document, falling back to general chat")
                # Fall back to general chat mode
                try:
                    ai_response = llm.invoke(message)
                    return ai_response.content
                except Exception as e:
                    print(f"Error in fallback general chat: {e}")
                    return "Sorry, I'm having trouble thinking right now. Please try again later."
            
            return result
        except Exception as e:
            # This will print the DETAILED, REAL error to your terminal
            print("\n" + "="*50)
            print("An error occurred in the RAG Chain:")
            print(e)
            import traceback
            traceback.print_exc()
            print("="*50 + "\n")
            
            # Fall back to general chat mode in case of error
            print("RAG chain failed, falling back to general chat")
            try:
                ai_response = llm.invoke(message)
                return ai_response.content
            except Exception as fallback_error:
                print(f"Fallback general chat also failed: {fallback_error}")
                return "Sorry, I'm having trouble thinking right now. Please try again later."

