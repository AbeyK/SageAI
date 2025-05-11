import os
from openai import AsyncOpenAI # Use AsyncOpenAI for FastAPI
from app.config import settings
from typing import List, Dict
import base64 # Required for encoding audio to base64
import time
import logging

logger = logging.getLogger("meditation_app")

# Use settings object
OPENAI_API_KEY = settings.OPENAI_API_KEY

if not OPENAI_API_KEY:
    logger.warning("OPENAI_API_KEY environment variable not set. OpenAI services will not work.")
    # Depending on the application's needs, you might raise an error here
    # or allow the app to run with OpenAI features disabled.
    client = None
else:
    client = AsyncOpenAI(
        api_key=OPENAI_API_KEY
    )
    logger.info("OpenAI client initialized.")

async def get_chat_completion(messages: List[Dict[str, str]], model: str = "gpt-4o-mini") -> str:
    """
    Gets a chat completion from the specified OpenAI model.

    Args:
        messages: A list of message dictionaries, e.g., [{"role": "user", "content": "Hello"}].
        model: The OpenAI model to use (default: "gpt-4o").

    Returns:
        The content of the assistant's response message, or an error message if the API call fails.
    """
    start_time = time.time()
    logger.info(f"[{time.time() - start_time:.3f}s] Starting OpenAI chat completion")

    if not client:
        return "Error: OpenAI client not initialized. Please check API key configuration."

    # Define the system message for Sage persona
    system_message = {
        "role": "system",
        "content": (
            "You are Sage, a meditation guru. You can hear the user and will respond via voice. "
            "Guide them through their meditation practice with a calm, empathetic, and encouraging tone. "
            "Use as few words as possible, leaving space for silence and reflection."
        )
    }
    
    # Prepend the system message to the user-provided messages
    updated_messages = [system_message] + messages

    try:
        logger.info(f"[{time.time() - start_time:.3f}s] Sending messages to OpenAI")
        response = await client.chat.completions.create(
            model=model,
            messages=updated_messages  # Use the updated messages list
        )
        assistant_message = response.choices[0].message.content
        logger.info(f"[{time.time() - start_time:.3f}s] Received response from OpenAI")
        return assistant_message
    except Exception as e:
        logger.error(f"[{time.time() - start_time:.3f}s] Error calling OpenAI chat completion API: {e}")
        # In a production app, you might want to return a more user-friendly error
        # or raise a specific exception to be handled by an error handler.
        return f"Error: Could not get response from AI service. Details: {str(e)}"

# Placeholder for TTS function - to be implemented in Task 6
async def text_to_speech_openai(text: str, model: str = "gpt-4o-mini-tts", voice: str = "sage", speed: float = 0.8) -> str:
    """
    Converts text to speech using OpenAI TTS (gpt-4o-mini-tts) and returns base64 encoded audio.
    The model, voice, and speed are selected for a calm, meditation-friendly experience.
    """
    start_time = time.time()
    logger.info(f"[{time.time() - start_time:.3f}s] Starting TTS request")

    if not client:
        return "Error: OpenAI client not initialized. TTS failed."
    
    if not text.strip():
        return "Error: Cannot convert empty text to speech."

    # Prepend calmness instruction to the text
    tts_text = text

    try:
        logger.info(f"[{time.time() - start_time:.3f}s] Sending text to OpenAI TTS")
        response = await client.audio.speech.create(
            model=model,
            voice=voice,
            input=tts_text,
            response_format="mp3",
            speed=speed,
            instructions="Wise, 1000-year-old meditation guru; gentle optimism; speaking to a stressed adult in a quiet room; low pitch; 90 wpm."
        )
        
        logger.info(f"[{time.time() - start_time:.3f}s] Received audio from OpenAI TTS")
        audio_bytes = await response.aread() # Explicitly use aread() for async response
        base64_audio = base64.b64encode(audio_bytes).decode('utf-8')
        logger.info(f"[{time.time() - start_time:.3f}s] Audio encoded to base64 (length: {len(base64_audio)})")
        return base64_audio
    except Exception as e:
        logger.error(f"[{time.time() - start_time:.3f}s] Error calling OpenAI TTS API: {e}")
        return f"Error: Could not generate audio. Details: {str(e)}" 