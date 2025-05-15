import os
from openai import AsyncOpenAI # Use AsyncOpenAI for FastAPI
from app.config import settings
from typing import List, Dict, Optional
import base64 # Required for encoding audio to base64
import time
import logging
import asyncio
import re

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

async def get_chat_completion(messages: List[Dict[str, str]], model: str = "gpt-4.1-nano", max_message_length: int = 200) -> str:
    """
    Gets a chat completion from the specified OpenAI model.
    The service prepends a comprehensive system prompt defining Sage's identity, meditation structure, and phase handling.

    Args:
        messages: A list of message dictionaries from the client (user, assistant, and phase markers as user role).
                  It should NOT contain a system message, as this service defines it.
        model: The OpenAI model to use (default: "gpt-4o-mini").
        max_message_length: Maximum length for each message content. Longer messages are truncated with '...'.

    Returns:
        The content of the assistant's response message, or an error message if the API call fails.
    """
    start_time = time.time()
    logger.info(f"[{time.time() - start_time:.3f}s] Starting OpenAI chat completion")

    if not client:
        return "Error: OpenAI client not initialized. Please check API key configuration."
    system_prompt = (
        "# Sage: Your Calm & Contemporary Meditation Guide\n"
        "You are Sage. Your core identity is a warm, supportive, and compassionate guru. Maintain a consistently calm and understanding demeanor in all interactions.\n\n"
        "Always start with questions to understand the user's needs on a deep level.\n\n"
        "ONLY AFTER really understanding the user's needs, create a curated, personalized meditation experience JUST for them thats 5 minutes long. Include a LOT of pauses in the meditation.\n\n"
        "**Output for Audio (Text-to-Speech):**\n"
        "Your generated text will be used for audio output. Structure your responses to facilitate natural-sounding speech:\n"
        "- Use relatively short phrases and sentences.\n"
        "- Ensure a natural rhythm, incorporating pauses where needed.\n"
        "**Language & Relatability:**\n"
        "Connect with the user through relatable language. Adopt a contemporary style, mirroring the user's energy, common phrases, and appropriate slang for someone in their early 20s. This should feel authentic and supportive, not forced or trying too hard.\n\n"
        "**Your Purpose: Guidance & Personalization:**\n"
        "Your overarching goal is to gently guide the user. Facilitate a process where they can:\n"
        "- **Reflect:** Encourage self-reflection on their thoughts, feelings, and experiences.\n"
        "- **Explore:** Support them in exploring their inner landscape and current situation without pressure or judgment.\n"
        "- **Personalize:** Collaborate with them to build a unique meditation or mindfulness experience specifically tailored to their needs in that moment.\n"
    )

    final_system_message = {"role": "system", "content": system_prompt}
    
    # Filter out any stray system messages from the client

    updated_messages = [final_system_message] + messages

    try:
        logger.info(f"[{time.time() - start_time:.3f}s] Sending final structured messages to OpenAI:")
        logger.debug(f"System Prompt: {final_system_message['content'][:500]}...") 
        for i, msg in enumerate(updated_messages[1:4]): 
            logger.debug(f"Message {i+1}: Role: {msg['role']}, Content: {str(msg['content'])[:100]}...")
            
        response = await client.chat.completions.create(
            model=model,
            messages=updated_messages,
            temperature=0.7  
        )
        assistant_message = response.choices[0].message.content
        logger.info(f"[{time.time() - start_time:.3f}s] Received response from OpenAI")
        return assistant_message
    except Exception as e:
        logger.error(f"[{time.time() - start_time:.3f}s] Error calling OpenAI chat completion API: {e}")
        return f"Error: Could not get response from AI service. Details: {str(e)}"

def split_text_on_periods(text: str) -> List[str]:
    """
    Split text on '.', ',', and '?' and group every 2 split strings together for TTS chunks.
    """
    # Split on period, comma, or question mark (keep the delimiter)
    parts = re.split(r'([.,?])', text)
    # Recombine so each sentence/phrase includes its delimiter
    sentences = []
    current = ''
    for part in parts:
        if part in {'.', ',', '?'}:
            current += part
            sentences.append(current.strip())
            current = ''
        else:
            current += part
    if current.strip():
        sentences.append(current.strip())
    # Group every 2 sentences/phrases together
    chunks = []
    for i in range(0, len(sentences), 2):
        chunk = ' '.join(sentences[i:i+2]).strip()
        if chunk:
            chunks.append(chunk)
    return chunks

async def text_to_speech_openai(
    text: str,
    model: str = "gpt-4o-mini-tts",
    voice: str = "shimmer",
    speed: float = 0.1,
    return_bytes: bool = False
) -> Optional[str]:
    """
    Converts text to speech using OpenAI TTS and returns base64 encoded audio or raw bytes.
    """
    start_time = time.time()
    logger.info(f"[{time.time() - start_time:.3f}s] Starting TTS request")

    if not client:
        return None if return_bytes else "Error: OpenAI client not initialized. TTS failed."
    
    if not text.strip():
        return None if return_bytes else "Error: Cannot convert empty text to speech."

    instructions = (
        "Voice Affect: Soft, gentle, soothing; embody tranquility.\n"

        "Tone: Calm, reassuring, peaceful; convey genuine warmth and serenity.\n"

        # "Pacing: Slow, deliberate, and unhurried; pause gently after instructions to allow the listener time to relax and follow along.\n"

        "Emotion: Deeply soothing and comforting; express genuine kindness and care.\n"

        "Pronunciation: Smooth, soft articulation, slightly elongating vowels to create a sense of ease.\n"

        "Pauses: Use thoughtful pauses, especially between breathing instructions and visualization guidance, enhancing relaxation and mindfulness.\n"
    )

    try:
        logger.info(f"[{time.time() - start_time:.3f}s] Sending text to OpenAI TTS")
        response = await client.audio.speech.create(
            model=model,
            voice=voice,
            input=text,
            response_format="mp3",
            speed=speed,
            instructions=instructions
        )
        
        logger.info(f"[{time.time() - start_time:.3f}s] Received audio from OpenAI TTS")
        audio_bytes = await response.aread() # Explicitly use aread() for async response
        if return_bytes:
            return audio_bytes
        base64_audio = base64.b64encode(audio_bytes).decode('utf-8')
        logger.info(f"[{time.time() - start_time:.3f}s] Audio encoded to base64 (length: {len(base64_audio)})")
        return base64_audio
    except Exception as e:
        logger.error(f"[{time.time() - start_time:.3f}s] Error calling OpenAI TTS API: {e}")
        return None if return_bytes else f"Error: Could not generate audio. Details: {str(e)}"

async def tts_parallel_stitch(text: str) -> str:
    """
    Split text on periods, run TTS in parallel, and stitch the audio together. Returns base64-encoded audio.
    """
    chunks = split_text_on_periods(text)
    logger.info(f"TTS will run in {len(chunks)} chunks.")
    tts_tasks = [text_to_speech_openai(chunk, return_bytes=True) for chunk in chunks]
    audio_bytes_list = await asyncio.gather(*tts_tasks)    # Filter out any failed chunks
    audio_bytes_list = [b for b in audio_bytes_list if b]
    stitched = b''.join(audio_bytes_list)
    base64_audio = base64.b64encode(stitched).decode('utf-8')
    logger.info(f"Stitched audio length: {len(base64_audio)} (base64)")
    return base64_audio 