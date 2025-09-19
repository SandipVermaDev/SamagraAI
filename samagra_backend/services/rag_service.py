import os
import tempfile
from langchain_community.vectorstores import FAISS
from langchain_community.document_loaders import PyPDFLoader
from langchain.text_splitter import RecursiveCharacterTextSplitter
from langchain_google_genai  import GoogleGenerativeAIEmbeddings
from core.config import settings

# This global variable will hold our document's knowledge in memory.
# In a real-world application, you would manage this state more robustly.
vector_store_retriever = None

def process_uploaded_document(file_content: bytes):
    """
    Processes the content of an uploaded file and prepares it for Q&A.
    """
    global vector_store_retriever

    # 1. Save the uploaded file content to a temporary file on the server.
    #    LangChain's document loaders often work best with file paths.
    with tempfile.NamedTemporaryFile(delete=False, suffix=".pdf") as temp_file:
        temp_file.write(file_content)
        temp_file_path = temp_file.name

    try:
        # 2. Load the document using the PyPDFLoader.
        loader = PyPDFLoader(temp_file_path)
        documents = loader.load()

        # 3. Split the document into smaller, manageable chunks.
        text_splitter = RecursiveCharacterTextSplitter(chunk_size=1000, chunk_overlap=200)
        docs = text_splitter.split_documents(documents)

        # 4. Create the embeddings and the FAISS vector store.
        #    This step converts the text chunks into numerical vectors.
        embeddings = GoogleGenerativeAIEmbeddings(
            model="models/gemini-embedding-001",
            google_api_key=settings.GOOGLE_API_KEY
        )
        db = FAISS.from_documents(docs, embeddings)

        # 5. Make the vector store a "retriever" and save it globally.
        #    A retriever is an object that can find the most relevant document chunks.
        vector_store_retriever = db.as_retriever(search_kwargs={"k": 5}) # We'll retrieve the top 5 most relevant chunks.

        print("Document processed successfully. Retriever is ready.")
        return True

    except Exception as e:
        print(f"An error occurred during document processing: {e}")
        return False
    finally:
        # 6. Clean up and remove the temporary file.
        os.remove(temp_file_path)