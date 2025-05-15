from pydantic import BaseModel
from typing import List, Optional

class ChatMessage(BaseModel):
    """Model for a single message in the chat history."""
    role: str
    content: str

class ChatRequest(BaseModel):
    """Model for the incoming chat request."""
    messages: List[ChatMessage]

class MeditationRequest(BaseModel):
    """Model for the incoming meditation request."""
    messages: List[ChatMessage]
    phase: str

class ChatResponse(BaseModel):
    """Model for the chat response."""
    text_response: str
    audio_base64: str
    caption: Optional[str] = None 