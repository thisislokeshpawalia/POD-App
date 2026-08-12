import requests

url = "https://pod-app-production-818a.up.railway.app"
auth_data = {
    "phone": "9999999999",
    "password": "testpassword",
    "name": "Test Partner"
}

r = requests.post(url + "/auth/login-or-register", json=auth_data)
if r.status_code == 200:
    token = r.json()["access_token"]
    print("Got token:", token)
    
    data = {
        "data": '{"name": "test", "phone": "1234567890", "village": "v", "address": "a", "district": "d", "pin_code": "123456", "latitude": 0.0, "longitude": 0.0, "otp": "1234", "items": [{"name": "item", "quantity": 1, "unit": "kg"}]}'
    }
    files = {
        "photo": open("backend/requirements.txt", "rb")
    }

    r2 = requests.post(url + "/farmers", data=data, files=files, headers={"Authorization": f"Bearer {token}"})
    print(r2.status_code)
    print(r2.text)
else:
    print("Login failed", r.status_code, r.text)
