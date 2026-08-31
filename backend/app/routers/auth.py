import os
import shutil
import uuid
import random
from datetime import datetime
from fastapi import APIRouter, Depends, HTTPException, status, Request

from app.auth import create_access_token, get_current_partner, hash_password, verify_password
from app.database import get_db
from app.services.cloudinary_service import upload_image
from app.schemas import (
    AuthRequest, AuthResponse, DeliveryPartnerResponse,
    OtpSendRequest, OtpSendResponse, OtpVerifyRequest,
    OtpVerifyResponse, PhoneCheckRequest, PhoneCheckResponse,
    ProfileUpdateRequest
)

UPLOAD_DIR = "uploads"
os.makedirs(UPLOAD_DIR, exist_ok=True)

router = APIRouter(prefix="/auth", tags=["Authentication"])

@router.post("/check-phone", response_model=PhoneCheckResponse)
def check_phone(payload: PhoneCheckRequest, db = Depends(get_db)):
    partner = db.delivery_partners.find_one({"phone": payload.phone})
    return PhoneCheckResponse(exists=partner is not None)

@router.post("/send-otp", response_model=OtpSendResponse)
def send_otp(payload: OtpSendRequest):
    return OtpSendResponse(message=f"OTP sent to {payload.phone}", otp="1234")

@router.post("/verify-otp", response_model=OtpVerifyResponse)
def verify_otp(payload: OtpVerifyRequest):
    return OtpVerifyResponse(valid=(payload.otp == "1234"))

@router.post("/login-or-register", response_model=AuthResponse)
def login_or_register(payload: AuthRequest, db = Depends(get_db)):
    partner = db.delivery_partners.find_one({"phone": payload.phone})
    if partner:
        is_new_user = False
    else:
        partner_name = payload.name or f"Partner {payload.phone[-4:]}"
        partner = {
            "id": random.randint(100000, 999999), 
            "name": partner_name,
            "phone": payload.phone,
            "password_hash": hash_password(payload.password or "123456"),
            "created_at": datetime.utcnow()
        }
        db.delivery_partners.insert_one(partner)
        is_new_user = True

    token = create_access_token({"sub": str(partner["id"])})
    return AuthResponse(
        access_token=token,
        is_new_user=is_new_user,
        partner=DeliveryPartnerResponse(**partner),
    )

@router.patch("/profile", response_model=DeliveryPartnerResponse)
async def update_profile(
    request: Request,
    db = Depends(get_db),
    partner = Depends(get_current_partner),
):
    content_type = request.headers.get("content-type", "")
    update_data = {}

    if "multipart/form-data" in content_type:
        form = await request.form()
        for field in ["name", "email", "address", "city", "state", "pincode", "vehicle_type", "vehicle_number", "aadhaar"]:
            val = form.get(field)
            if val is not None and str(val).strip():
                update_data[field] = str(val).strip()
        
        photo = form.get("profile_image")
        if photo and hasattr(photo, "filename") and photo.filename:
            ext = photo.filename.split(".")[-1] if "." in photo.filename else "jpg"
            photo_filename = f"partner_{uuid.uuid4()}.{ext}"
            photo_path = os.path.join(UPLOAD_DIR, photo_filename)
            with open(photo_path, "wb") as buffer:
                shutil.copyfileobj(photo.file, buffer)
            try:
                cloud_url = upload_image(photo_path, public_id=photo_filename)
                update_data["profile_image"] = cloud_url
            except Exception as e:
                print(f"Cloudinary upload failed: {e}")
            finally:
                if os.path.exists(photo_path):
                    os.remove(photo_path)
    else:
        try:
            body = await request.json()
            payload = ProfileUpdateRequest(**body)
            update_data = payload.model_dump(exclude_unset=True)
        except Exception:
            pass

    if update_data:
        db.delivery_partners.update_one({"id": partner["id"]}, {"$set": update_data})
        partner.update(update_data)
    
    return DeliveryPartnerResponse(**partner)

@router.get("/me", response_model=DeliveryPartnerResponse)
def get_me(partner = Depends(get_current_partner)):
    return DeliveryPartnerResponse(**partner)
