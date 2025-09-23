from fastapi import APIRouter, UploadFile, File, HTTPException, status
from schemas.document import DocumentUploadResponse
from services.rag_service import process_uploaded_document

# Create a new router for document-related endpoints
router = APIRouter(tags=["Document"])

@router.post("/upload-document", response_model=DocumentUploadResponse)
async def upload_document(file: UploadFile = File(...)):
    """
    Accepts a PDF file upload and processes it to create a vector store.
    """
    # Optional: Check if the uploaded file is a PDF
    if file.content_type != "application/pdf":
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid file type. Please upload a PDF."
        )

    try:
        # Read the content of the uploaded file as bytes
        file_content = await file.read()

        # Call the service function from the previous step to process the document
        success = process_uploaded_document(file_content)

        if success:
            return DocumentUploadResponse(
                success=True,
                message=f"Document '{file.filename}' processed and ready for Q&A."
            )
        else:
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Failed to process the document in the RAG service."
            )

    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"An unexpected error occurred: {str(e)}"
        )

@router.post("/upload")
async def upload_document_v2(file: UploadFile = File(...)):
    """
    Upload and process a document file (alternative endpoint for frontend compatibility).
    """
    try:
        # Read the file content
        file_content = await file.read()
        
        # Process the document
        success = process_uploaded_document(file_content)
        
        if success:
            return {
                "message": f"Document '{file.filename}' uploaded and processed successfully",
                "filename": file.filename,
                "size": len(file_content)
            }
        else:
            raise HTTPException(status_code=400, detail="Failed to process document")
            
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error processing document: {str(e)}")