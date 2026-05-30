import requests
import json

# Test knowledge chunks
response = requests.get("http://localhost:8000/api/admin/knowledge-chunks/4")
print("Status:", response.status_code)
print(json.dumps(response.json(), indent=2))