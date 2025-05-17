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

async def get_chat_completion(
    messages: List[Dict[str, str]],
    system_prompt: str,
    model: str,
    max_output_tokens: Optional[int] = None
) -> str:
    """
    Gets a chat completion from the specified OpenAI model using the provided system prompt.

    Args:
        messages: A list of message dictionaries from the client.
        system_prompt: The system prompt to use for the chat completion.
        model: The OpenAI model to use.
        max_output_tokens: Optional. The maximum number of tokens to generate in the chat completion.

    Returns:
        The content of the assistant's response message, or an error message if the API call fails.
    """
    start_time = time.time()
    logger.info(f"[{time.time() - start_time:.3f}s] Starting OpenAI chat completion with specific system prompt.")

    if not client:
        return "Error: OpenAI client not initialized. Please check API key configuration."

    final_system_message = {"role": "system", "content": system_prompt}
    
    # Filter out any stray system messages from the client

    updated_messages = [final_system_message] + messages

    try:
        logger.info(f"[{time.time() - start_time:.3f}s] Sending final structured messages to OpenAI:")
        logger.debug(f"System Prompt: {final_system_message['content'][:500]}...") 
        for i, msg in enumerate(updated_messages[1:4]): 
            logger.debug(f"Message {i+1}: Role: {msg['role']}, Content: {str(msg['content'])[:100]}...")
            
        completion_params = {
            "model": model,
            "messages": updated_messages,
            "temperature": 0.7
        }
        if max_output_tokens is not None:
            completion_params["max_tokens"] = max_output_tokens
            logger.info(f"[{time.time() - start_time:.3f}s] Requesting max_output_tokens: {max_output_tokens}")

        response = await client.chat.completions.create(**completion_params)
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
    tts_instructions: str,
    model: str = "gpt-4o-mini-tts",
    voice: str = "shimmer",
    return_bytes: bool = False
) -> Optional[str]:
    """
    Converts text to speech using OpenAI TTS and returns base64 encoded audio or raw bytes.
    Uses the provided tts_instructions.
    """
    start_time = time.time()
    logger.info(f"[{time.time() - start_time:.3f}s] Starting TTS request with specific instructions.")

    if not client:
        return None if return_bytes else "Error: OpenAI client not initialized. TTS failed."
    
    if not text.strip():
        return None if return_bytes else "Error: Cannot convert empty text to speech."

    try:
        logger.info(f"[{time.time() - start_time:.3f}s] Sending text to OpenAI TTS with instructions: {tts_instructions[:100]}...")
        response = await client.audio.speech.create(
            model=model,
            voice=voice,
            input=text,
            response_format="mp3",
            instructions=tts_instructions
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

async def tts_parallel_stitch(text: str, tts_instructions: str) -> str:
    """
    Split text on periods, run TTS in parallel, and stitch the audio together. Returns base64-encoded audio.
    Requires tts_instructions to pass to underlying calls.
    """
    chunks = split_text_on_periods(text)
    logger.info(f"TTS will run in {len(chunks)} chunks using specific instructions.")
    # Pass mandatory tts_instructions to each text_to_speech_openai call
    tts_tasks = [text_to_speech_openai(chunk, return_bytes=True, tts_instructions=tts_instructions) for chunk in chunks]
    audio_bytes_list = await asyncio.gather(*tts_tasks)
    # Filter out any failed chunks
    audio_bytes_list = [b for b in audio_bytes_list if b]
    stitched = b''.join(audio_bytes_list)
    base64_audio = base64.b64encode(stitched).decode('utf-8')
    logger.info(f"Stitched audio length: {len(base64_audio)} (base64)")
    return base64_audio 