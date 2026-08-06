import enum
from datetime import datetime
from typing import Optional, List

from sqlalchemy import DateTime, Enum, Float, ForeignKey, Integer, String, Text
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.database import Base


class DeliveryStatus(str, enum.Enum):
    pending = "pending"
    delivered = "delivered"


class DeliveryPartner(Base):
    __tablename__ = "delivery_partners"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, index=True)
    name: Mapped[str] = mapped_column(String(100), nullable=False)
    phone: Mapped[str] = mapped_column(String(15), unique=True, index=True, nullable=False)
    password_hash: Mapped[str] = mapped_column(String(255), nullable=False)
    email: Mapped[Optional[str]] = mapped_column(String(100), nullable=True)
    address: Mapped[Optional[str]] = mapped_column(String(255), nullable=True)
    city: Mapped[Optional[str]] = mapped_column(String(100), nullable=True)
    state: Mapped[Optional[str]] = mapped_column(String(100), nullable=True)
    pincode: Mapped[Optional[str]] = mapped_column(String(10), nullable=True)
    vehicle_type: Mapped[Optional[str]] = mapped_column(String(50), nullable=True)
    vehicle_number: Mapped[Optional[str]] = mapped_column(String(20), nullable=True)
    aadhaar: Mapped[Optional[str]] = mapped_column(String(20), nullable=True)
    profile_image: Mapped[Optional[str]] = mapped_column(String(255), nullable=True)
    created_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow)

    farmers: Mapped[List["Farmer"]] = relationship(back_populates="delivery_partner")


class Farmer(Base):
    __tablename__ = "farmers"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, index=True)
    farmer_id: Mapped[str] = mapped_column(String(20), unique=True, index=True, nullable=False)
    name: Mapped[str] = mapped_column(String(100), nullable=False)
    phone: Mapped[str] = mapped_column(String(15), nullable=False)
    village: Mapped[str] = mapped_column(String(100), nullable=False)
    address: Mapped[str] = mapped_column(String(255), nullable=False)
    district: Mapped[str] = mapped_column(String(100), nullable=False)
    pin_code: Mapped[str] = mapped_column(String(10), nullable=False)
    status: Mapped[DeliveryStatus] = mapped_column(
        Enum(DeliveryStatus), default=DeliveryStatus.pending, nullable=False
    )
    latitude: Mapped[float] = mapped_column(Float, nullable=False)
    longitude: Mapped[float] = mapped_column(Float, nullable=False)
    otp: Mapped[str] = mapped_column(String(4), default="1234", nullable=False)
    delivery_partner_id: Mapped[Optional[int]] = mapped_column(
        ForeignKey("delivery_partners.id"), nullable=True
    )
    created_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow)

    delivery_partner: Mapped[Optional["DeliveryPartner"]] = relationship(back_populates="farmers")
    items: Mapped[List["DeliveryItem"]] = relationship(
        back_populates="farmer", cascade="all, delete-orphan"
    )


class DeliveryItem(Base):
    __tablename__ = "delivery_items"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, index=True)
    farmer_id: Mapped[int] = mapped_column(ForeignKey("farmers.id"), nullable=False)
    name: Mapped[str] = mapped_column(String(100), nullable=False)
    quantity: Mapped[float] = mapped_column(Float, nullable=False)
    unit: Mapped[str] = mapped_column(String(20), nullable=False)

    farmer: Mapped["Farmer"] = relationship(back_populates="items")
