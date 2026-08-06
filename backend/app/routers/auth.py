import random
from datetime import datetime
from fastapi import APIRouter, Depends, HTTPException, status

from app.auth import create_access_token, get_current_partner, hash_password, verify_password
from app.database import get_db
from app.schemas import (
    AuthRequest, AuthResponse, DeliveryPartnerResponse,
    OtpSendRequest, OtpSendResponse, OtpVerifyRequest,
    OtpVerifyResponse, PhoneCheckRequest, PhoneCheckResponse,
    ProfileUpdateRequest
)

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

    token = create_access_token({"sub": partner["id"]})
    return AuthResponse(
        access_token=token,
        is_new_user=is_new_user,
        partner=DeliveryPartnerResponse(**partner),
    )

@router.patch("/profile", response_model=DeliveryPartnerResponse)
def update_profile(
    payload: ProfileUpdateRequest,
    db = Depends(get_db),
    partner = Depends(get_current_partner),
):
    update_data = payload.model_dump(exclude_unset=True)
    if update_data:
        db.delivery_partners.update_one({"id": partner["id"]}, {"$set": update_data})
        partner.update(update_data)
    
    return DeliveryPartnerResponse(**partner)

@router.get("/me", response_model=DeliveryPartnerResponse)
def get_me(partner = Depends(get_current_partner)):
    return DeliveryPartnerResponse(**partner)
