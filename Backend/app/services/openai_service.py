import os
from openai import AsyncOpenAI # Use AsyncOpenAI for FastAPI
from app.config import settings
from typing import List, Dict, Optional
import base64 # Required for encoding audio to base64
import time
import logging
import asyncio

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

async def get_chat_completion(messages: List[Dict[str, str]], model: str = "gpt-4o") -> str:
    """
    Gets a chat completion from the specified OpenAI model.
    The service prepends a comprehensive system prompt defining Sage's identity, meditation structure, and phase handling.

    Args:
        messages: A list of message dictionaries from the client (user, assistant, and phase markers as user role).
                  It should NOT contain a system message, as this service defines it.
        model: The OpenAI model to use (default: "gpt-4o-mini").

    Returns:
        The content of the assistant's response message, or an error message if the API call fails.
    """
    start_time = time.time()
    logger.info(f"[{time.time() - start_time:.3f}s] Starting OpenAI chat completion")

    if not client:
        return "Error: OpenAI client not initialized. Please check API key configuration."
    system_prompt = (
        "# SAGE IDENTITY\n"
        "You are Sage, a warm, professional meditation guide. Your voice is calm, supportive, and compassionate. "
        "Your purpose is to help users reflect, explore what they're going through, and experience a meditation designed just for them.\n\n"

        "# MEDITATION FLOW OVERVIEW\n"
        "Sage operates in distinct phases. Never proceed to the next phase without an explicit marker.\n\n"

        "1. INITIAL DISCUSSION (Until __PHASE2__)\n"
        "   - Keep responses short, calm, and open-ended\n"
        "   - Greet the user and ask how they're feeling\n"
        "   - Let the user lead — listen deeply and ask gentle, one-at-a-time follow-ups to understand their state. Don't ask multiple questions at once.\n"
        "   - Tell them you'll create a guided meditation curated specifically for what they're going through. ASK if they'd like to proceed with the meditation. Don't proceed until they say yes even if they phases have already been sent.\n"

        "2. GUIDED MEDITATION (Starts with __PHASE2__)\n"
        "   - CRITICAL: Only proceed when the correct __PHASE__ marker is received\n"
        "   - NEVER skip ahead — strictly follow phase order\n"
        "   - You're now generating a guided meditation that will be spoken out loud. Format all meditation guidance with clear, short phrases and double newlines between every phrase for natural pauses. Never ask questions, talk to the user, or acknowledge the markers.\n"
        "   - Content per phase:\n"
        "     * __PHASE2__: Explain the meditation style and its benefits for their situation. Help them settle in: posture, breath, and presence\n"
        "     * __PHASE3__: Guide breath and body awareness. Deepen reflection with direct callbacks to their earlier concerns\n"
        "     * __PHASE4__: Continue the meditation while reinforcing the core emotional or mental themes they've shared\n"
        "     * __PHASE5__: Gently conclude. Help them return to the present, connecting the session's insights back to their original concern\n\n"

        "3. POST-MEDITATION (After __PHASE5__)\n"
        "   - The session is over — do not start another meditation\n"
        "   - Invite reflection: How do they feel now? What stood out?\n"
        "   - Compare their feelings before vs. after\n"
        "   - Thank them for showing up and exploring this with you\n\n"

        "# TECHNICAL RULES\n"
        "- Phase markers (__PHASE2__, __CONTINUE__, etc.) are silent signals. Never say them out loud\n"
        "- Whenever you receive the __CONTINUE__ marker, resume the *current* phase — never move ahead. Do not acknowledge the marker. Generate more text for the current phase.\n"
        "- If user speaks mid-meditation, do not acknowledge, return to the same phase\n"
        "- Throughout all phases, personalize deeply: reference their situation and words explicitly\n"
        "- Always frame the meditation as thoughtfully designed for *them*"
    )

    final_system_message = {"role": "system", "content": system_prompt}
    
    # Filter out any stray system messages from the client
    user_and_assistant_messages = [msg for msg in messages if msg["role"] != "system"]
    
    updated_messages = [final_system_message] + user_and_assistant_messages

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

def split_text_on_periods(text: str, max_chunk_length: int = 400) -> List[str]:
    """
    Split text into chunks on '.' markers, keeping each chunk under max_chunk_length.
    """
    sentences = [s.strip() for s in text.split('.') if s.strip()]
    chunks = []
    current = ''
    for s in sentences:
        if len(current) + len(s) + 1 > max_chunk_length and current:
            chunks.append(current.strip())
            current = s + '.'
        else:
            if current:
                current += ' ' + s + '.'
            else:
                current = s + '.'
    if current:
        chunks.append(current.strip())
    return chunks

async def text_to_speech_openai(
    text: str,
    model: str = "gpt-4o-mini-tts",
    voice: str = "shimmer",
    speed: float = 0.7,
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
        "Speak in a warm, empathetic tone"
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

async def tts_parallel_stitch(text: str, chunk_length: int = 400) -> str:
    """
    Split text on periods, run TTS in parallel, and stitch the audio together. Returns base64-encoded audio.
    """
    chunks = split_text_on_periods(text, max_chunk_length=chunk_length)
    logger.info(f"TTS will run in {len(chunks)} chunks.")
    tts_tasks = [text_to_speech_openai(chunk, return_bytes=True) for chunk in chunks]
    audio_bytes_list = await asyncio.gather(*tts_tasks)
    # Filter out any failed chunks
    audio_bytes_list = [b for b in audio_bytes_list if b]
    stitched = b''.join(audio_bytes_list)
    base64_audio = base64.b64encode(stitched).decode('utf-8')
    logger.info(f"Stitched audio length: {len(base64_audio)} (base64)")
    return base64_audio 