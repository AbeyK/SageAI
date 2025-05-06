import time
from app.services.llm_service import LLMService
from app.services.tts_service import TTSService
from app.logger import get_logger

logger = get_logger(__name__)

class MeditationService:
    def __init__(self):
        self.llm_service = LLMService()
        self.tts_service = TTSService()

    async def process_request(self, user_text: str) -> bytes:
        """
        Process a meditation request by getting an LLM response and converting it to speech.
        
        Args:
            user_text (str): The user's meditation request
            
        Returns:
            bytes: The audio response in WAV format
            
        Raises:
            Exception: If there's an error processing the request
        """
        start_time = time.time()
        logger.info(f"Starting request processing for: {user_text[:100]}...")
        
        try:
            # Get LLM response
            llm_start = time.time()
            llm_response = await self.llm_service.get_response(user_text)
            llm_duration = time.time() - llm_start
            logger.info(f"LLM response ({llm_duration:.2f}s): {llm_response[:100]}...")
            
            # Convert to speech
            tts_start = time.time()
            audio_bytes = await self.tts_service.text_to_speech(llm_response)
            tts_duration = time.time() - tts_start
            
            total_duration = time.time() - start_time
            logger.info(f"TTS response received ({tts_duration:.2f}s) - Total size: {len(audio_bytes)} bytes")
            logger.info(f"Total processing time: {total_duration:.2f}s (LLM: {llm_duration:.2f}s, TTS: {tts_duration:.2f}s)")
            
            return audio_bytes
            
        except Exception as e:
            error_duration = time.time() - start_time
            logger.error(f"Error after {error_duration:.2f}s: {str(e)}")
            raise 