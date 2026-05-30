import requests
import json

r = requests.get("http://localhost:8000/api/admin/knowledge-content/Lecture%20Content")
print(json.dumps(r.json(), indent=2)[:1000])