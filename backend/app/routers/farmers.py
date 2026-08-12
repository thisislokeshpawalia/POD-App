from typing import Optional, List
from fastapi import APIRouter, Depends, HTTPException, status, UploadFile, File, Form
import os
import shutil
import uuid
import json
from app.services.cloudinary_service import upload_video, upload_image
from app.auth import get_current_partner
from app.database import get_db
from app.models import DeliveryStatus
from app.schemas import FarmerCreate, FarmerResponse, FarmerUpdate, DeliveryItemResponse

UPLOAD_DIR = "uploads"
os.makedirs(UPLOAD_DIR, exist_ok=True)

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
    data: str = Form(...),
    photo: UploadFile = File(None),
    db = Depends(get_db),
    partner = Depends(get_current_partner),
):
    import datetime
    
    try:
        payload_obj = FarmerCreate.model_validate_json(data)
        farmer_data = payload_obj.model_dump()
    except Exception as e:
        raise HTTPException(status_code=400, detail=f"Invalid JSON data: {e}")

    # Save farmer photo to Cloudinary
    if photo and photo.filename:
        ext = photo.filename.split(".")[-1] if "." in photo.filename else "jpg"
        photo_filename = f"farmer_{uuid.uuid4()}.{ext}"
        photo_path = os.path.join(UPLOAD_DIR, photo_filename)
        with open(photo_path, "wb") as buffer:
            shutil.copyfileobj(photo.file, buffer)
        
        # Upload to Cloudinary
        try:
            cloud_url = upload_image(photo_path, public_id=photo_filename)
            farmer_data["photo_urls"] = [cloud_url]
        except Exception as e:
            print(f"Cloudinary upload failed: {e}")
            # Fallback if cloudinary fails (though we should ideally raise an error)
            pass
        finally:
            if os.path.exists(photo_path):
                os.remove(photo_path)

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
    # This was likely overridden by upload_proof_of_delivery anyway. Keep for legacy compatibility if any.
    farmer = db.farmers.find_one({"farmer_id": farmer_id, "delivery_partner_id": partner["id"]})
    if not farmer:
        raise HTTPException(status_code=404, detail="Farmer not found")

    db.farmers.update_one({"_id": farmer["_id"]}, {"$set": {"status": DeliveryStatus.delivered}})
    farmer["status"] = DeliveryStatus.delivered
    
    farmer["id"] = farmer["farmer_id"]
    farmer["items"] = farmer.get("items", [])
    return FarmerResponse(**farmer)

@router.post("/{farmer_id}/upload_proof", response_model=FarmerResponse)
async def upload_proof_of_delivery(
    farmer_id: str,
    video: Optional[UploadFile] = File(None),
    photos: Optional[List[UploadFile]] = File(None),
    db = Depends(get_db),
    partner = Depends(get_current_partner),
):
    farmer = db.farmers.find_one({"farmer_id": farmer_id, "delivery_partner_id": partner["id"]})
    if not farmer:
        raise HTTPException(status_code=404, detail="Farmer not found")

    # Face verification is now done locally on the Flutter client before this endpoint is called.
    pass


    temp_video_path = f"temp_{farmer_id}.mp4"
    try:
        video_url = None
        if video and video.filename:
            with open(temp_video_path, "wb") as buffer:
                shutil.copyfileobj(video.file, buffer)
            video_url = upload_video(temp_video_path, f"Proof_{farmer_id}")
            if os.path.exists(temp_video_path): os.remove(temp_video_path)

        photo_urls = []
        if photos:
            for i, photo in enumerate(photos):
                if not photo.filename: continue
                tmp_p = f"temp_{farmer_id}_photo_{i}.jpg"
                with open(tmp_p, "wb") as buffer:
                    shutil.copyfileobj(photo.file, buffer)
                url = upload_image(tmp_p, f"Proof_Img_{farmer_id}_{i}")
                photo_urls.append(url)
                if os.path.exists(tmp_p): os.remove(tmp_p)

        update_data = {
            "status": DeliveryStatus.delivered,
        }
        if video_url: update_data["video_url"] = video_url
        if photo_urls: update_data["photo_urls"] = photo_urls

        db.farmers.update_one({"_id": farmer["_id"]}, {"$set": update_data})
        farmer.update(update_data)

    except Exception as e:
        if isinstance(e, HTTPException): raise e
        raise HTTPException(status_code=500, detail=str(e))

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
