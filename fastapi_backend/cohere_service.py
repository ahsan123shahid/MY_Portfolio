import httpx
import json
from typing import Optional

class CohereService:
    def __init__(self, api_key: str, model: str = "command-r-08-2024"):
        self.api_key = api_key
        self.model = model
        self.url = "https://api.cohere.com/v2/chat"
    
    async def ask(self, prompt: str, max_tokens: int = 2000) -> str:
        messages = [{"role": "user", "content": prompt}]
        
        async with httpx.AsyncClient(timeout=180.0) as client:
            response = await client.post(
                self.url,
                headers={
                    "Authorization": f"Bearer {self.api_key}",
                    "Content-Type": "application/json"
                },
                json={
                    "model": self.model,
                    "messages": messages,
                    "max_tokens": max_tokens
                }
            )
            
            if response.status_code != 200:
                raise Exception(f"Cohere API error: {response.status_code} - {response.text}")
            
            data = response.json()
            content = data.get("message", {}).get("content", [])
            
            if content and isinstance(content, list):
                return content[0].get("text", "")
            return ""

def get_cohere_client() -> CohereService:
    api_key = "k0WGZCrCFLFxrC5OuOHiAQT6Sb4DCLVdcl8SSR0O"
    return CohereService(api_key=api_key)