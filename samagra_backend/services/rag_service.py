import os
import tempfile
from langchain_community.vectorstores import FAISS
from langchain_community.document_loaders import PyPDFLoader
from langchain.text_splitter import RecursiveCharacterTextSplitter
from langchain_google_genai  import GoogleGenerativeAIEmbeddings
from core.config import settings
from typing import Optional
import base64
import json
import requests
from langchain.schema import Document

# EasyOCR fallback imports
try:
    import easyocr
    from PIL import Image
    import io
    import numpy as np
    _EASYOCR_AVAILABLE = True
except ImportError:
    _EASYOCR_AVAILABLE = False

# This will hold our document's knowledge in memory.
# Using a simple class to manage state more robustly
class DocumentStore:
    def __init__(self):
        self.retriever = None
        self.document_info = None
    
    def set_retriever(self, retriever, doc_info=None):
        self.retriever = retriever
        self.document_info = doc_info
        print(f"DocumentStore: Set retriever, active: {self.retriever is not None}")
    
    def get_retriever(self):
        print(f"DocumentStore: Getting retriever, active: {self.retriever is not None}")
        return self.retriever
    
    def clear(self):
        self.retriever = None
        self.document_info = None
        print("DocumentStore: Cleared")
    
    def has_retriever(self):
        return self.retriever is not None

# Global document store instance
document_store = DocumentStore()

def process_uploaded_document(file_content: bytes):
    """
    Processes the content of an uploaded file and prepares it for Q&A.
    """
    global document_store

    print(f"process_uploaded_document called with {len(file_content)} bytes")

    # 1. Save the uploaded file content to a temporary file on the server.
    #    LangChain's document loaders often work best with file paths.
    with tempfile.NamedTemporaryFile(delete=False, suffix=".pdf") as temp_file:
        temp_file.write(file_content)
        temp_file_path = temp_file.name
        print(f"Created temporary file: {temp_file_path}")

    try:
        # 2. Load the document using the PyPDFLoader.
        loader = PyPDFLoader(temp_file_path)
        documents = loader.load()
        print(f"Loaded {len(documents)} document pages")

        if not documents:
            print("No content found in document")
            return False

        # 3. Split the document into smaller, manageable chunks.
        text_splitter = RecursiveCharacterTextSplitter(chunk_size=1000, chunk_overlap=200)
        docs = text_splitter.split_documents(documents)
        print(f"Split document into {len(docs)} chunks")

        if not docs:
            print("No chunks created from document")
            return False

        # 4. Create the embeddings and the FAISS vector store.
        #    This step converts the text chunks into numerical vectors.
        embeddings = GoogleGenerativeAIEmbeddings(
            model="models/gemini-embedding-001",
            google_api_key=settings.GOOGLE_API_KEY
        )
        print("Created embeddings model")
        
        db = FAISS.from_documents(docs, embeddings)
        print("Created FAISS database")

        # 5. Make the vector store a "retriever" and save it in our document store.
        retriever = db.as_retriever(search_kwargs={"k": 5}) # We'll retrieve the top 5 most relevant chunks.
        document_store.set_retriever(retriever, {"chunks": len(docs), "pages": len(documents)})

        print("Document processed successfully. Retriever is ready.")
        return True

    except Exception as e:
        print(f"An error occurred during document processing: {e}")
        import traceback
        traceback.print_exc()
        return False
    finally:
        # 6. Clean up and remove the temporary file.
        try:
            os.remove(temp_file_path)
            print(f"Cleaned up temporary file: {temp_file_path}")
        except Exception as e:
            print(f"Error cleaning up temp file: {e}")


def process_uploaded_image(image_content: bytes, filename: Optional[str] = None) -> Optional[str]:
    """
    Extracts text from an uploaded image using Google Vision API (primary)
    with EasyOCR as fallback. Indexes extracted text into FAISS vector store.
    Returns extracted text on success, None on failure.
    """
    global vector_store_retriever

    extracted_text = None

    # Try Google Vision API first
    api_key = getattr(settings, 'GOOGLE_API_KEY', None)
    if api_key:
        print("Attempting Google Vision API...")
        try:
            # Encode image as base64
            b64_image = base64.b64encode(image_content).decode()
            
            # Prepare Google Vision API request
            payload = {
                'requests': [
                    {
                        'image': {'content': b64_image},
                        'features': [{'type': 'TEXT_DETECTION', 'maxResults': 1}],
                    }
                ]
            }
            
            # Call Google Vision API
            url = f'https://vision.googleapis.com/v1/images:annotate?key={api_key}'
            response = requests.post(url, json=payload, timeout=15)
            response.raise_for_status()
            
            # Parse response
            data = response.json()
            if 'responses' in data and data['responses']:
                annotation = data['responses'][0]
                
                # Extract text (prefer fullTextAnnotation for better formatting)
                if 'fullTextAnnotation' in annotation and annotation['fullTextAnnotation'].get('text'):
                    extracted_text = annotation['fullTextAnnotation']['text']
                elif 'textAnnotations' in annotation and annotation['textAnnotations']:
                    extracted_text = annotation['textAnnotations'][0].get('description', '')
                
                if extracted_text and extracted_text.strip():
                    print(f"Google Vision extracted {len(extracted_text)} characters from image {filename}")
                else:
                    print('Google Vision returned no text for image.')
                    
        except requests.exceptions.RequestException as e:
            print(f"Google Vision API request failed: {e}")
        except Exception as e:
            print(f"Error with Google Vision: {e}")
    else:
        print("No Google API key configured.")

    # If Google Vision failed or returned no text, try EasyOCR fallback
    if not extracted_text and _EASYOCR_AVAILABLE:
        print("Attempting EasyOCR fallback...")
        try:
            # Convert bytes to PIL Image
            image = Image.open(io.BytesIO(image_content))
            # Convert to numpy array for EasyOCR
            image_np = np.array(image)
            
            # Initialize EasyOCR reader (English by default)
            reader = easyocr.Reader(['en'])
            
            # Extract text
            results = reader.readtext(image_np)
            
            # Combine all text results
            text_parts = [result[1] for result in results if result[1].strip()]
            if text_parts:
                extracted_text = '\n'.join(text_parts)
                print(f"EasyOCR extracted {len(extracted_text)} characters from image {filename}")
            else:
                print("EasyOCR found no text in image.")
                
        except Exception as e:
            print(f"EasyOCR failed: {e}")
    elif not extracted_text:
        print("EasyOCR not available and Google Vision failed.")

    # If no text extracted by either method
    if not extracted_text or not extracted_text.strip():
        print("No text could be extracted from image.")
        return None
        
    # Create LangChain Document and index it
    try:
        doc = Document(page_content=extracted_text, metadata={"source": filename or "image"})
        
        # Split text into chunks
        text_splitter = RecursiveCharacterTextSplitter(chunk_size=1000, chunk_overlap=200)
        docs = text_splitter.split_documents([doc])
        
        # Create embeddings and FAISS vector store
        embeddings = GoogleGenerativeAIEmbeddings(
            model="models/gemini-embedding-001",
            google_api_key=settings.GOOGLE_API_KEY
        )
        db = FAISS.from_documents(docs, embeddings)
        retriever = db.as_retriever(search_kwargs={"k": 5})
        document_store.set_retriever(retriever, {"source": "image", "filename": filename})
        
        print("Image text indexed successfully.")
        return extracted_text
        
    except Exception as e:
        print(f"Error indexing extracted text: {e}")
        return extracted_text  # Return text even if indexing fails