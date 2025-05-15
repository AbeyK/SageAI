from pydantic import BaseModel, Field
from typing import List, Dict, Optional

class Message(BaseModel):
    role: str
    content: str

class MeditateRequest(BaseModel):
    messages: List[Message] = Field(..., example=[{"role": "user", "content": "I'm feeling stressed about work."}])

class AudioResponse(BaseModel):
    audio_base64: str = Field(..., description="Base64 encoded MP3 audio data.")
    text_response: str = Field(..., description="The text content of the assistant's response.") 