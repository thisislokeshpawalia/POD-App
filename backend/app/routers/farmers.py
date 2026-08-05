from typing import Optional
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.auth import get_current_partner
from app.database import get_db
from app.models import DeliveryItem, DeliveryPartner, DeliveryStatus, Farmer
from app.schemas import DeliveryItemResponse, FarmerCreate, FarmerResponse, FarmerUpdate

router = APIRouter(prefix="/farmers", tags=["Farmers"])


def _generate_farmer_id(db: Session) -> str:
    last = db.query(Farmer).order_by(Farmer.id.desc()).first()
    next_num = (last.id + 1) if last else 1
    return f"FRM-{next_num:03d}"


def _farmer_to_response(farmer: Farmer) -> FarmerResponse:
    return FarmerResponse(
        id=farmer.farmer_id,
        name=farmer.name,
        phone=farmer.phone,
        village=farmer.village,
        address=farmer.address,
        district=farmer.district,
        pin_code=farmer.pin_code,
        status=farmer.status,
        latitude=farmer.latitude,
        longitude=farmer.longitude,
        otp=farmer.otp,
        items=[DeliveryItemResponse.model_validate(item) for item in farmer.items],
    )


@router.get("", response_model=list[FarmerResponse])
def list_farmers(
    status_filter: Optional[DeliveryStatus] = None,
    db: Session = Depends(get_db),
    partner: DeliveryPartner = Depends(get_current_partner),
):
    query = db.query(Farmer).filter(Farmer.delivery_partner_id == partner.id)
    if status_filter:
        query = query.filter(Farmer.status == status_filter)
    farmers = query.order_by(Farmer.created_at.desc()).all()
    return [_farmer_to_response(f) for f in farmers]


@router.post("", response_model=FarmerResponse, status_code=status.HTTP_201_CREATED)
def create_farmer(
    payload: FarmerCreate,
    db: Session = Depends(get_db),
    partner: DeliveryPartner = Depends(get_current_partner),
):
    farmer = Farmer(
        farmer_id=_generate_farmer_id(db),
        name=payload.name,
        phone=payload.phone,
        village=payload.village,
        address=payload.address,
        district=payload.district,
        pin_code=payload.pin_code,
        latitude=payload.latitude,
        longitude=payload.longitude,
        otp=payload.otp,
        delivery_partner_id=partner.id,
    )
    db.add(farmer)
    db.flush()

    for item in payload.items:
        db.add(
            DeliveryItem(
                farmer_id=farmer.id,
                name=item.name,
                quantity=item.quantity,
                unit=item.unit,
            )
        )

    db.commit()
    db.refresh(farmer)
    return _farmer_to_response(farmer)


@router.get("/{farmer_id}", response_model=FarmerResponse)
def get_farmer(
    farmer_id: str,
    db: Session = Depends(get_db),
    partner: DeliveryPartner = Depends(get_current_partner),
):
    farmer = (
        db.query(Farmer)
        .filter(Farmer.farmer_id == farmer_id, Farmer.delivery_partner_id == partner.id)
        .first()
    )
    if not farmer:
        raise HTTPException(status_code=404, detail="Farmer not found")
    return _farmer_to_response(farmer)


@router.patch("/{farmer_id}", response_model=FarmerResponse)
def update_farmer(
    farmer_id: str,
    payload: FarmerUpdate,
    db: Session = Depends(get_db),
    partner: DeliveryPartner = Depends(get_current_partner),
):
    farmer = (
        db.query(Farmer)
        .filter(Farmer.farmer_id == farmer_id, Farmer.delivery_partner_id == partner.id)
        .first()
    )
    if not farmer:
        raise HTTPException(status_code=404, detail="Farmer not found")

    update_data = payload.model_dump(exclude_unset=True)
    items_data = update_data.pop("items", None)

    for field, value in update_data.items():
        setattr(farmer, field, value)

    if items_data is not None:
        db.query(DeliveryItem).filter(DeliveryItem.farmer_id == farmer.id).delete()
        for item in items_data:
            db.add(
                DeliveryItem(
                    farmer_id=farmer.id,
                    name=item["name"],
                    quantity=item["quantity"],
                    unit=item["unit"],
                )
            )

    db.commit()
    db.refresh(farmer)
    return _farmer_to_response(farmer)


@router.patch("/{farmer_id}/deliver", response_model=FarmerResponse)
def mark_delivered(
    farmer_id: str,
    db: Session = Depends(get_db),
    partner: DeliveryPartner = Depends(get_current_partner),
):
    farmer = (
        db.query(Farmer)
        .filter(Farmer.farmer_id == farmer_id, Farmer.delivery_partner_id == partner.id)
        .first()
    )
    if not farmer:
        raise HTTPException(status_code=404, detail="Farmer not found")

    farmer.status = DeliveryStatus.delivered
    db.commit()
    db.refresh(farmer)
    return _farmer_to_response(farmer)


@router.delete("/{farmer_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_farmer(
    farmer_id: str,
    db: Session = Depends(get_db),
    partner: DeliveryPartner = Depends(get_current_partner),
):
    farmer = (
        db.query(Farmer)
        .filter(Farmer.farmer_id == farmer_id, Farmer.delivery_partner_id == partner.id)
        .first()
    )
    if not farmer:
        raise HTTPException(status_code=404, detail="Farmer not found")

    db.delete(farmer)
    db.commit()
    return None
