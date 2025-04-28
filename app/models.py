from pydantic import BaseModel

class AudioInput(BaseModel):
    audio_url: str

class TextInput(BaseModel):
    text: str

class TextOutput(BaseModel):
    text: str

class AudioOutput(BaseModel):
    audio_url: str 