from datetime import datetime
from enum import Enum
from typing import Optional

from pydantic import BaseModel, Field


class DeliveryStatus(str, Enum):
    pending = "pending"
    delivered = "delivered"


class DeliveryItemCreate(BaseModel):
    name: str = Field(..., min_length=1, max_length=100)
    quantity: float = Field(..., gt=0)
    unit: str = Field(..., min_length=1, max_length=20)


class DeliveryItemResponse(BaseModel):
    name: str
    quantity: float
    unit: str

    model_config = {"from_attributes": True}


class PhoneCheckRequest(BaseModel):
    phone: str = Field(..., min_length=10, max_length=15)


class PhoneCheckResponse(BaseModel):
    exists: bool


class OtpSendRequest(BaseModel):
    phone: str = Field(..., min_length=10, max_length=15)


class OtpSendResponse(BaseModel):
    message: str
    otp: str = "1234"


class OtpVerifyRequest(BaseModel):
    phone: str = Field(..., min_length=10, max_length=15)
    otp: str = Field(..., min_length=4, max_length=6)


class OtpVerifyResponse(BaseModel):
    valid: bool


class AuthRequest(BaseModel):
    phone: str = Field(..., min_length=10, max_length=15)
    password: str = Field(default="123456", min_length=4, max_length=100)
    name: Optional[str] = Field(None, min_length=1, max_length=100)


class AuthResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"
    is_new_user: bool
    partner: "DeliveryPartnerResponse"


class ProfileUpdateRequest(BaseModel):
    name: Optional[str] = None
    email: Optional[str] = None
    address: Optional[str] = None
    city: Optional[str] = None
    state: Optional[str] = None
    pincode: Optional[str] = None
    vehicle_type: Optional[str] = None
    vehicle_number: Optional[str] = None
    aadhaar: Optional[str] = None
    profile_image: Optional[str] = None


class DeliveryPartnerResponse(BaseModel):
    id: int
    name: str
    phone: str
    email: Optional[str] = None
    address: Optional[str] = None
    city: Optional[str] = None
    state: Optional[str] = None
    pincode: Optional[str] = None
    vehicle_type: Optional[str] = None
    vehicle_number: Optional[str] = None
    aadhaar: Optional[str] = None
    profile_image: Optional[str] = None
    created_at: datetime

    model_config = {"from_attributes": True}


class FarmerCreate(BaseModel):
    name: str = Field(..., min_length=1, max_length=100)
    phone: str = Field(..., min_length=10, max_length=15)
    village: str = Field(..., min_length=1, max_length=100)
    address: str = Field(..., min_length=1, max_length=255)
    district: str = Field(..., min_length=1, max_length=100)
    pin_code: str = Field(..., min_length=6, max_length=10)
    latitude: float
    longitude: float
    otp: str = Field(default="1234", min_length=4, max_length=4)
    items: list[DeliveryItemCreate] = Field(..., min_length=1)


class FarmerUpdate(BaseModel):
    name: Optional[str] = None
    phone: Optional[str] = None
    village: Optional[str] = None
    address: Optional[str] = None
    district: Optional[str] = None
    pin_code: Optional[str] = None
    status: Optional[DeliveryStatus] = None
    latitude: Optional[float] = None
    longitude: Optional[float] = None
    otp: Optional[str] = None
    items: Optional[list[DeliveryItemCreate]] = None


class FarmerResponse(BaseModel):
    id: str  # farmer_id like FRM-001
    name: str
    phone: str
    village: str
    address: str
    district: str
    pin_code: str
    status: DeliveryStatus
    latitude: float
    longitude: float
    otp: str
    items: list[DeliveryItemResponse]

    model_config = {"from_attributes": True}
