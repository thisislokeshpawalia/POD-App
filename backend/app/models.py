import enum

class DeliveryStatus(str, enum.Enum):
    pending = "pending"
    delivered = "delivered"
