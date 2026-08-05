from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.auth import create_access_token, get_current_partner, hash_password, verify_password
from app.database import get_db
from app.models import DeliveryPartner
from app.schemas import (
    AuthRequest,
    AuthResponse,
    DeliveryPartnerResponse,
    OtpSendRequest,
    OtpSendResponse,
    OtpVerifyRequest,
    OtpVerifyResponse,
    PhoneCheckRequest,
    PhoneCheckResponse,
    ProfileUpdateRequest,
)

router = APIRouter(prefix="/auth", tags=["Authentication"])


@router.post("/check-phone", response_model=PhoneCheckResponse)
def check_phone(payload: PhoneCheckRequest, db: Session = Depends(get_db)):
    partner = db.query(DeliveryPartner).filter(DeliveryPartner.phone == payload.phone).first()
    return PhoneCheckResponse(exists=partner is not None)


@router.post("/send-otp", response_model=OtpSendResponse)
def send_otp(payload: OtpSendRequest):
    return OtpSendResponse(message=f"OTP sent to {payload.phone}", otp="1234")


@router.post("/verify-otp", response_model=OtpVerifyResponse)
def verify_otp(payload: OtpVerifyRequest):
    # Standard OTP for testing/verification is 1234
    is_valid = payload.otp == "1234"
    return OtpVerifyResponse(valid=is_valid)


@router.post("/login-or-register", response_model=AuthResponse)
def login_or_register(payload: AuthRequest, db: Session = Depends(get_db)):
    """
    If the delivery partner exists (by phone), log them in.
    If not, register a new partner and log them in.
    """
    partner = db.query(DeliveryPartner).filter(DeliveryPartner.phone == payload.phone).first()

    if partner:
        is_new_user = False
    else:
        partner_name = payload.name or f"Partner {payload.phone[-4:]}"
        partner = DeliveryPartner(
            name=partner_name,
            phone=payload.phone,
            password_hash=hash_password(payload.password or "123456"),
        )
        db.add(partner)
        db.commit()
        db.refresh(partner)
        is_new_user = True

    token = create_access_token({"sub": str(partner.id)})
    return AuthResponse(
        access_token=token,
        is_new_user=is_new_user,
        partner=DeliveryPartnerResponse.model_validate(partner),
    )


@router.patch("/profile", response_model=DeliveryPartnerResponse)
def update_profile(
    payload: ProfileUpdateRequest,
    db: Session = Depends(get_db),
    partner: DeliveryPartner = Depends(get_current_partner),
):
    update_data = payload.model_dump(exclude_unset=True)
    for field, value in update_data.items():
        if value is not None:
            setattr(partner, field, value)
    db.commit()
    db.refresh(partner)
    return DeliveryPartnerResponse.model_validate(partner)


@router.get("/me", response_model=DeliveryPartnerResponse)
def get_me(partner: DeliveryPartner = Depends(get_current_partner)):
    return DeliveryPartnerResponse.model_validate(partner)
