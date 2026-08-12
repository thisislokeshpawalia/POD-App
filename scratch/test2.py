import requests

url = "https://pod-app-production-818a.up.railway.app/farmers"
data = {
    "data": '{"name": "test", "phone": "1234567890", "village": "v", "address": "a", "district": "d", "pin_code": "123456", "latitude": 0.0, "longitude": 0.0, "otp": "1234", "items": [{"name": "item", "quantity": 1, "unit": "kg"}]}'
}
files = {
    "photo": open("backend/requirements.txt", "rb")
}

# The backend expects authorization, but let's see what error it returns first (401 or 422).
r = requests.post(url, data=data, files=files, headers={"Authorization": "Bearer TEST"})
print(r.status_code)
print(r.text)
