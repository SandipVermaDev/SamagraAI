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
# Using a simple class to manage state more robustly with cumulative storage
class DocumentStore:
    def __init__(self):
        self.vector_db = None  # FAISS vector database
        self.retriever = None
        self.uploaded_files = []  # Track uploaded files
        self.embeddings = None  # Store embeddings instance for reuse
    
    def initialize_embeddings(self):
        """Initialize embeddings if not already done"""
        if self.embeddings is None:
            self.embeddings = GoogleGenerativeAIEmbeddings(
                model="models/gemini-embedding-001",
                google_api_key=settings.GOOGLE_API_KEY
            )
            print("DocumentStore: Initialized embeddings")
        return self.embeddings
    
    def add_documents(self, docs, file_info):
        """Add new documents to existing vector store or create new one"""
        embeddings = self.initialize_embeddings()
        
        if self.vector_db is None:
            # Create new vector store
            print("DocumentStore: Creating new vector store")
            self.vector_db = FAISS.from_documents(docs, embeddings)
        else:
            # Add to existing vector store
            print("DocumentStore: Adding documents to existing vector store")
            new_db = FAISS.from_documents(docs, embeddings)
            self.vector_db.merge_from(new_db)
        
        # Update retriever
        self.retriever = self.vector_db.as_retriever(search_kwargs={"k": 10})  # Increased k for multiple documents
        
        # Track uploaded file
        self.uploaded_files.append(file_info)
        
        print(f"DocumentStore: Now contains {len(self.uploaded_files)} files")
        print(f"DocumentStore: Files: {[f.get('filename', f.get('source', 'unknown')) for f in self.uploaded_files]}")
        
        return True
    
    def get_retriever(self):
        print(f"DocumentStore: Getting retriever, active: {self.retriever is not None}")
        if self.retriever:
            print(f"DocumentStore: Contains {len(self.uploaded_files)} files")
        return self.retriever
    
    def clear(self):
        self.vector_db = None
        self.retriever = None
        self.uploaded_files = []
        # Keep embeddings instance for reuse
        print("DocumentStore: Cleared all documents")
    
    def has_retriever(self):
        return self.retriever is not None
    
    def get_file_list(self):
        return [f.get('filename', f.get('source', 'unknown')) for f in self.uploaded_files]

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

        # 4. Add documents to the cumulative vector store
        file_info = {
            "type": "document", 
            "filename": temp_file_path.split("/")[-1], 
            "chunks": len(docs), 
            "pages": len(documents)
        }
        
        success = document_store.add_documents(docs, file_info)
        if success:
            print("Document processed successfully and added to vector store.")
        else:
            print("Failed to add document to vector store.")
            return False
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
    global document_store

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
        
    # Create LangChain Document and add to cumulative vector store
    try:
        doc = Document(page_content=extracted_text, metadata={"source": filename or "image"})
        
        # Split text into chunks
        text_splitter = RecursiveCharacterTextSplitter(chunk_size=1000, chunk_overlap=200)
        docs = text_splitter.split_documents([doc])
        
        # Add to cumulative vector store
        file_info = {
            "type": "image", 
            "filename": filename or "image", 
            "source": "image",
            "chunks": len(docs),
            "text_length": len(extracted_text)
        }
        
        success = document_store.add_documents(docs, file_info)
        if success:
            print("Image text indexed successfully and added to vector store.")
        else:
            print("Failed to add image text to vector store.")
            return extracted_text  # Return text even if indexing fails
        
        return extracted_text
        
    except Exception as e:
        print(f"Error indexing extracted text: {e}")
        return extracted_text  # Return text even if indexing fails