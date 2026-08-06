from typing import Optional
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
