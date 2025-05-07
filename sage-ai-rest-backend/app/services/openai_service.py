import os
from openai import AsyncOpenAI # Use AsyncOpenAI for FastAPI
from app.config import settings
from typing import List, Dict
import base64 # Required for encoding audio to base64

# Use settings object
OPENAI_API_KEY = settings.OPENAI_API_KEY

if not OPENAI_API_KEY:
    print("WARNING: OPENAI_API_KEY environment variable not set. OpenAI services will not work.")
    # Depending on the application's needs, you might raise an error here
    # or allow the app to run with OpenAI features disabled.
    client = None
else:
    client = AsyncOpenAI(
        api_key=OPENAI_API_KEY
    )
    print("OpenAI client initialized.")

async def get_chat_completion(messages: List[Dict[str, str]], model: str = "gpt-4o") -> str:
    """
    Gets a chat completion from the specified OpenAI model.

    Args:
        messages: A list of message dictionaries, e.g., [{"role": "user", "content": "Hello"}].
        model: The OpenAI model to use (default: "gpt-4o").

    Returns:
        The content of the assistant's response message, or an error message if the API call fails.
    """
    if not client:
        return "Error: OpenAI client not initialized. Please check API key configuration."

    try:
        print(f"Sending messages to OpenAI: {messages}")
        response = await client.chat.completions.create(
            model=model,
            messages=messages
        )
        assistant_message = response.choices[0].message.content
        print(f"Received response from OpenAI: {assistant_message}")
        return assistant_message
    except Exception as e:
        print(f"Error calling OpenAI chat completion API: {e}")
        # In a production app, you might want to return a more user-friendly error
        # or raise a specific exception to be handled by an error handler.
        return f"Error: Could not get response from AI service. Details: {str(e)}"

# Placeholder for TTS function - to be implemented in Task 6
async def text_to_speech_openai(text: str, model: str = "tts-1-hd", voice: str = "alloy") -> str:
    """
    Converts text to speech using OpenAI TTS and returns base64 encoded audio.
    """
    print("Client class is:", type(client))

    if not client:
        return "Error: OpenAI client not initialized. TTS failed."
    
    if not text.strip():
        return "Error: Cannot convert empty text to speech."

    try:
        print(f"Requesting TTS from OpenAI for: '{text[:70]}...' Model: {model}, Voice: {voice}")
        response = await client.audio.speech.create(
            model=model,
            voice=voice,
            input=text,
            response_format="mp3"
        )
        
        audio_bytes = await response.aread() # Explicitly use aread() for async response
        base64_audio = base64.b64encode(audio_bytes).decode('utf-8')
        print(f"TTS audio generated and base64 encoded (length: {len(base64_audio)})")
        print(f"First 100 chars of base64: {base64_audio[:100]}...")
        return base64_audio
    except Exception as e:
        print(f"Error calling OpenAI TTS API: {e}")
        return f"Error: Could not generate audio. Details: {str(e)}" 