import requests
import json

BASE_URL = "https://pod-backend-1yr8.onrender.com"
PHONE = "8888888888"

print("Seeding database via public Render API...")

# 1. Login or Register the test worker
response = requests.post(f"{BASE_URL}/auth/login-or-register", json={
    "phone": PHONE,
    "password": "1234",
    "name": "Test Delivery Partner"
})
if response.status_code != 200:
    print("Failed to authenticate:", response.text)
    exit(1)

token = response.json()["access_token"]
headers = {"Authorization": f"Bearer {token}", "Content-Type": "application/json"}

print("Authenticated successfully. Proceeding to seed farmers...")

# 2. Add Dummy Farmers
farmers = [
    {
        "name": "Rahul Sharma",
        "phone": "9876543210",
        "village": "Sector 132",
        "address": "Jaypee Wish Town",
        "district": "Noida",
        "pin_code": "201304",
        "latitude": 28.5118,
        "longitude": 77.3736,
        "otp": "1234",
        "items": [
            {"name": "Fertilizer", "quantity": 2, "unit": "Bags"}
        ]
    },
    {
        "name": "Priya Verma",
        "phone": "9876543211",
        "village": "Sector 132",
        "address": "Paras Tierea",
        "district": "Noida",
        "pin_code": "201304",
        "latitude": 28.5079,
        "longitude": 77.3708,
        "otp": "1234",
        "items": [
            {"name": "Pesticide", "quantity": 5, "unit": "Bottles"}
        ]
    }
]

for f in farmers:
    resp = requests.post(f"{BASE_URL}/farmers", json=f, headers=headers)
    if resp.status_code == 201:
        print(f"Added {f['name']} successfully.")
    else:
        print(f"Failed to add {f['name']}: {resp.text}")

print("Seeding complete!")
