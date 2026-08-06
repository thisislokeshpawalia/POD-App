import os
import subprocess

files = {
    'backend/requirements.txt': """fastapi==0.115.6
uvicorn[standard]==0.34.0
pymongo==4.10.1
python-jose[cryptography]==3.3.0
passlib[bcrypt]==1.7.4
python-multipart==0.0.20
pydantic-settings==2.7.0
jinja2==3.1.5
""",

    'backend/app/config.py': """from pydantic_settings import BaseSettings

class Settings(BaseSettings):
    mongodb_url: str = "mongodb+srv://podapp796_db_user:obqxukNI0z20czpq@cluster0.ehucwbg.mongodb.net/?retryWrites=true&w=majority&appName=Cluster0"
    secret_key: str = "7294b4b2e83151811eefcbdf7e324abef8a1e5088f1dc344c2de0cc7b9ffae"
    algorithm: str = "HS256"
    access_token_expire_minutes: int = 60 * 24 * 7

    class Config:
        env_file = ".env"

settings = Settings()
""",

    'backend/app/database.py': """from pymongo import MongoClient
import pymongo
from app.config import settings

client = MongoClient(settings.mongodb_url, serverSelectionTimeoutMS=5000)
db = client["pody_db"]

def get_db():
    yield db
""",

    'backend/app/models.py': """import enum

class DeliveryStatus(str, enum.Enum):
    pending = "pending"
    delivered = "delivered"
""",

    'backend/app/auth.py': """from typing import Optional
from datetime import datetime, timedelta
from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from jose import JWTError, jwt
import bcrypt

from app.config import settings
from app.database import get_db

security = HTTPBearer()

def hash_password(password: str) -> str:
    pwd_bytes = password.encode('utf-8')[:72]
    salt = bcrypt.gensalt()
    return bcrypt.hashpw(pwd_bytes, salt).decode('utf-8')

def verify_password(plain_password: str, hashed_password: str) -> bool:
    try:
        pwd_bytes = plain_password.encode('utf-8')[:72]
        hash_bytes = hashed_password.encode('utf-8')
        return bcrypt.checkpw(pwd_bytes, hash_bytes)
    except Exception:
        return False

def create_access_token(data: dict) -> str:
    to_encode = data.copy()
    expire = datetime.utcnow() + timedelta(minutes=settings.access_token_expire_minutes)
    to_encode.update({"exp": expire})
    return jwt.encode(to_encode, settings.secret_key, algorithm=settings.algorithm)

def get_current_partner(
    credentials: HTTPAuthorizationCredentials = Depends(security),
    db = Depends(get_db),
):
    token = credentials.credentials
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Invalid or expired token",
        headers={"WWW-Authenticate": "Bearer"},
    )
    try:
        payload = jwt.decode(token, settings.secret_key, algorithms=[settings.algorithm])
        partner_id = payload.get("sub")
        if partner_id is None:
            raise credentials_exception
    except JWTError:
        raise credentials_exception

    partner = db.delivery_partners.find_one({"id": int(partner_id)})
    if partner is None:
        raise credentials_exception
    return partner
""",

    'backend/app/routers/auth.py': """import random
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
""",

    'backend/app/routers/farmers.py': """from typing import Optional
from fastapi import APIRouter, Depends, HTTPException, status
from app.auth import get_current_partner
from app.database import get_db
from app.models import DeliveryStatus
from app.schemas import FarmerCreate, FarmerResponse, FarmerUpdate, DeliveryItemResponse

router = APIRouter(prefix="/farmers", tags=["Farmers"])

def _generate_farmer_id(db) -> str:
    last = db.farmers.find_one({}, sort=[("_id", -1)])
    if last and "farmer_id" in last:
        try:
            num = int(last["farmer_id"].split("-")[1])
            return f"FRM-{num + 1:03d}"
        except:
            pass
    return "FRM-001"

@router.get("", response_model=list[FarmerResponse])
def list_farmers(
    status_filter: Optional[DeliveryStatus] = None,
    db = Depends(get_db),
    partner = Depends(get_current_partner),
):
    query = {"delivery_partner_id": partner["id"]}
    if status_filter:
        query["status"] = status_filter
    
    farmers = list(db.farmers.find(query).sort("created_at", -1))
    
    responses = []
    for f in farmers:
        f["id"] = f["farmer_id"]
        f["items"] = f.get("items", [])
        responses.append(FarmerResponse(**f))
    return responses

@router.post("", response_model=FarmerResponse, status_code=status.HTTP_201_CREATED)
def create_farmer(
    payload: FarmerCreate,
    db = Depends(get_db),
    partner = Depends(get_current_partner),
):
    import datetime
    farmer_data = payload.model_dump()
    farmer_data["farmer_id"] = _generate_farmer_id(db)
    farmer_data["id"] = farmer_data["farmer_id"]
    farmer_data["delivery_partner_id"] = partner["id"]
    farmer_data["status"] = DeliveryStatus.pending
    farmer_data["created_at"] = datetime.datetime.utcnow()
    
    db.farmers.insert_one(farmer_data)
    
    farmer_data["items"] = farmer_data.get("items", [])
    return FarmerResponse(**farmer_data)

@router.get("/{farmer_id}", response_model=FarmerResponse)
def get_farmer(
    farmer_id: str,
    db = Depends(get_db),
    partner = Depends(get_current_partner),
):
    farmer = db.farmers.find_one({"farmer_id": farmer_id, "delivery_partner_id": partner["id"]})
    if not farmer:
        raise HTTPException(status_code=404, detail="Farmer not found")
        
    farmer["id"] = farmer["farmer_id"]
    farmer["items"] = farmer.get("items", [])
    return FarmerResponse(**farmer)

@router.patch("/{farmer_id}", response_model=FarmerResponse)
def update_farmer(
    farmer_id: str,
    payload: FarmerUpdate,
    db = Depends(get_db),
    partner = Depends(get_current_partner),
):
    farmer = db.farmers.find_one({"farmer_id": farmer_id, "delivery_partner_id": partner["id"]})
    if not farmer:
        raise HTTPException(status_code=404, detail="Farmer not found")

    update_data = payload.model_dump(exclude_unset=True)
    if update_data:
        db.farmers.update_one({"_id": farmer["_id"]}, {"$set": update_data})
        farmer.update(update_data)
        
    farmer["id"] = farmer["farmer_id"]
    farmer["items"] = farmer.get("items", [])
    return FarmerResponse(**farmer)

@router.patch("/{farmer_id}/deliver", response_model=FarmerResponse)
def mark_delivered(
    farmer_id: str,
    db = Depends(get_db),
    partner = Depends(get_current_partner),
):
    farmer = db.farmers.find_one({"farmer_id": farmer_id, "delivery_partner_id": partner["id"]})
    if not farmer:
        raise HTTPException(status_code=404, detail="Farmer not found")

    db.farmers.update_one({"_id": farmer["_id"]}, {"$set": {"status": DeliveryStatus.delivered}})
    farmer["status"] = DeliveryStatus.delivered
    
    farmer["id"] = farmer["farmer_id"]
    farmer["items"] = farmer.get("items", [])
    return FarmerResponse(**farmer)

@router.delete("/{farmer_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_farmer(
    farmer_id: str,
    db = Depends(get_db),
    partner = Depends(get_current_partner),
):
    result = db.farmers.delete_one({"farmer_id": farmer_id, "delivery_partner_id": partner["id"]})
    if result.deleted_count == 0:
        raise HTTPException(status_code=404, detail="Farmer not found")
    return None
""",

    'backend/app/main.py': """from pathlib import Path
from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import HTMLResponse
from fastapi.templating import Jinja2Templates

from app.routers import auth, farmers

app = FastAPI(
    title="Subsidy Delivery Partner API (MongoDB)",
    description="Backend for delivery partner authentication and farmer management",
    version="1.0.0",
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

templates = Jinja2Templates(directory=str(Path(__file__).parent / "templates"))

app.include_router(auth.router)
app.include_router(farmers.router)

@app.get("/")
def root():
    return {
        "message": "Subsidy Delivery Partner API (MongoDB)",
        "docs": "/docs"
    }
"""
}

for filepath, content in files.items():
    with open(filepath, "w", encoding="utf-8") as f:
        f.write(content)

try:
    subprocess.run(['git', 'add', 'backend/'], check=True)
    subprocess.run(['git', 'commit', '-m', 'Migrate backend to MongoDB'], check=True)
    subprocess.run(['git', 'push'], check=True)
    print("Migration and Git push successful!")
except Exception as e:
    print(f"Git push failed: {e}")
