import cloudinary
import cloudinary.uploader
import os
from app.config import settings

def setup_cloudinary():
    if settings.cloudinary_url:
        import os
        os.environ["CLOUDINARY_URL"] = settings.cloudinary_url
        cloudinary.config()

def upload_video(file_path: str, public_id: str) -> str:
    """
    Uploads a video to Cloudinary and returns the secure HTTPS URL.
    """
    setup_cloudinary()
    
    response = cloudinary.uploader.upload(
        file_path,
        resource_type="video",
        public_id=public_id,
        folder="POD-App/proofs",
    )
    
    # Return the secure https url
    return response.get("secure_url")

def upload_pdf(file_path: str, public_id: str) -> str:
    """
    Uploads a PDF invoice to Cloudinary and returns the secure HTTPS URL.
    """
    setup_cloudinary()
    
    response = cloudinary.uploader.upload(
        file_path,
        resource_type="image", # Use image for PDFs to allow web delivery
        public_id=public_id,
        folder="POD-App/invoices",
    )
    
    return response.get("secure_url")

def upload_image(file_path: str, public_id: str) -> str:
    setup_cloudinary()
    response = cloudinary.uploader.upload(
        file_path,
        resource_type="image",
        public_id=public_id,
        folder="POD-App/proofs",
    )
    return response.get("secure_url")
