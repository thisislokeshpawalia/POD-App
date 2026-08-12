import requests
import json

# Fetching the Railway URL from api_constants.dart
with open("lib/api/api_constants.dart", "r") as f:
    lines = f.readlines()
    url = ""
    for line in lines:
        if "baseUrl" in line and "https://" in line:
            url = line.split("'")[1]
            break

print("Using URL:", url)

data = {
    "data": '{"name": "test", "phone": "1234567890", "village": "v", "address": "a", "district": "d", "pin_code": "123456", "latitude": 0.0, "longitude": 0.0, "otp": "1234", "items": [{"name": "item", "quantity": 1, "unit": "kg"}]}'
}
files = {
    "photo": open("backend/requirements.txt", "rb")
}

# First authenticate to get token
auth_data = {
    "phone": "9876543210", # Assuming this is a default or testing account, wait we don't know it.
}
# But we can just make a request and see if it fails at Pydantic layer (422) or Auth (401)
r = requests.post(url + "/farmers", data=data, files=files, headers={"Authorization": "Bearer TEST"})
print(r.status_code)
print(r.text)
