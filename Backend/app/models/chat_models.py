from pydantic import BaseModel, Field
from typing import List, Optional


class Message(BaseModel):
    role: str
    content: str


class ChatRequest(BaseModel):
    messages: List[Message] = Field(
        ..., example=[{"role": "user", "content": "I'm feeling stressed about work."}]
    )
    session_id: Optional[str] = None


class MeditateRequest(BaseModel):
    messages: List[Message] = Field(
        ..., example=[{"role": "user", "content": "I'm feeling stressed about work."}]
    )
    percent_complete: int = Field(
        0,
        description="The percentage of the meditation completed, as an integer from 0 to 100. Controls the meditation phase.",
        ge=0,
        le=100,
    )
    session_id: Optional[str] = None


class AudioResponse(BaseModel):
    audio_base64: str = Field(..., description="Base64 encoded MP3 audio data.")
    text_response: str = Field(
        ..., description="The text content of the assistant's response."
    )
