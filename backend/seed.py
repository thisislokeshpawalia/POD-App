import requests

BASE_URL = "https://pod-backend-1yr8.onrender.com"
PHONE = "8888888888"

def seed():
    print("Logging in/Registering...")
    res = requests.post(f"{BASE_URL}/auth/login-or-register", json={
        "phone": PHONE,
        "name": "Live Test Agent"
    })
    
    if res.status_code != 200:
        print(f"Auth Failed: {res.text}")
        return
        
    token = res.json().get("access_token")
    headers = {"Authorization": f"Bearer {token}"}
    
    print("Connected! Seeding dummy farmers...")
    farmers_data = [
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
          "items": [{"name": "Fertilizer", "quantity": 2, "unit": "Bags"}]
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
          "items": [{"name": "Pesticide", "quantity": 5, "unit": "Bottles"}]
        },
        {
          "name": "Amit Kumar",
          "phone": "9876543212",
          "village": "Sector 128",
          "address": "Expressway Service Road",
          "district": "Noida",
          "pin_code": "201304",
          "latitude": 28.5174,
          "longitude": 77.3669,
          "otp": "1234",
          "items": [{"name": "Seed Packets", "quantity": 15, "unit": "Packs"}]
        },
        {
          "name": "Neha Gupta",
          "phone": "9876543213",
          "village": "Sector 132",
          "address": "Supertech Eco Village",
          "district": "Noida",
          "pin_code": "201305",
          "latitude": 28.5008,
          "longitude": 77.3823,
          "otp": "1234",
          "items": [{"name": "Organic Compost", "quantity": 4, "unit": "Bags"}]
        },
        {
          "name": "Suresh Yadav",
          "phone": "9876543214",
          "village": "Sector 135",
          "address": "Assotech Business Cresterra",
          "district": "Noida",
          "pin_code": "201304",
          "latitude": 28.5059,
          "longitude": 77.3775,
          "otp": "1234",
          "items": [{"name": "Sprayer", "quantity": 1, "unit": "Piece"}]
        },
        {
          "name": "Anjali Singh",
          "phone": "9876543215",
          "village": "Sector 134",
          "address": "Expressway Link Road",
          "district": "Noida",
          "pin_code": "201304",
          "latitude": 28.5096,
          "longitude": 77.3809,
          "otp": "1234",
          "items": [{"name": "Urea", "quantity": 3, "unit": "Bags"}]
        },
        {
          "name": "Vikas Chauhan",
          "phone": "9876543216",
          "village": "Sector 143",
          "address": "Advant Navis",
          "district": "Noida",
          "pin_code": "201306",
          "latitude": 28.4955,
          "longitude": 77.3908,
          "otp": "1234",
          "items": [{"name": "Drip Pipe", "quantity": 30, "unit": "Meters"}]
        },
        {
          "name": "Pooja Mishra",
          "phone": "9876543217",
          "village": "Sector 129",
          "address": "Noida-Greater Noida Expressway",
          "district": "Noida",
          "pin_code": "201304",
          "latitude": 28.5159,
          "longitude": 77.3692,
          "otp": "1234",
          "items": [{"name": "Plant Growth Booster", "quantity": 6, "unit": "Packets"}]
        }
    ]
    
    for c in farmers_data:
        r = requests.post(f"{BASE_URL}/farmers", json=c, headers=headers)
        print(f"Created {c['name']} -> {r.status_code}")

if __name__ == '__main__':
    seed()
