import os
from openai import OpenAI
from app.logger import get_logger

logger = get_logger(__name__)

class TTSService:
    def __init__(self):
        self.client = OpenAI(api_key=os.getenv("OPENAI_API_KEY"))
        self.voice = "nova"  # Default voice
        self.model = "tts-1"

    async def text_to_speech(self, text: str) -> bytes:
        """
        Convert text to speech using OpenAI's TTS API.
        
        Args:
            text (str): The text to convert to speech
            
        Returns:
            bytes: The audio data in WAV format
            
        Raises:
            Exception: If there's an error converting text to speech
        """
        try:
            response = self.client.audio.speech.create(
                model=self.model,
                voice=self.voice,
                input=text,
                response_format="wav"
            )
            
            audio_bytes = response.content
            if isinstance(audio_bytes, str):
                audio_bytes = audio_bytes.encode('utf-8')
                
            return audio_bytes
            
        except Exception as e:
            logger.error(f"Error converting text to speech: {str(e)}")
            raise 