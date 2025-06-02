from openai import AsyncOpenAI  # Use AsyncOpenAI for FastAPI
from app.config import settings
from typing import List, Dict, Optional, Iterable, Union
import base64  # Required for encoding audio to base64
import time
import logging
import asyncio
import re

logger = logging.getLogger("meditation_app")

# Use settings object
OPENAI_API_KEY = settings.OPENAI_API_KEY

if not OPENAI_API_KEY:
    logger.warning(
        "OPENAI_API_KEY environment variable not set. OpenAI services will not work."
    )
    # Depending on the application's needs, you might raise an error here
    # or allow the app to run with OpenAI features disabled.
    client = None
else:
    client = AsyncOpenAI(api_key=OPENAI_API_KEY)
    logger.info("OpenAI client initialized.")


async def get_chat_completion(
    messages: Iterable[Dict[str, str]],
    system_prompt: str,
    model: str,
    max_output_tokens: Optional[int] = None,
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
    logger.info(
        f"[{time.time() - start_time:.3f}s] Starting OpenAI chat completion with specific system prompt."
    )

    if not client:
        return (
            "Error: OpenAI client not initialized. Please check API key configuration."
        )

    final_system_message = {"role": "system", "content": system_prompt}

    # Ensure messages are in the correct format for OpenAI (List[Dict[str, str]])
    updated_messages: List[Dict[str, str]] = [final_system_message] + [
        {"role": str(m["role"]), "content": str(m["content"])} for m in messages
    ]

    try:
        logger.info(
            f"[{time.time() - start_time:.3f}s] Sending final structured messages to OpenAI:"
        )
        logger.debug(f"System Prompt: {final_system_message['content'][:500]}...")
        for i, msg in enumerate(updated_messages[1:4]):
            logger.debug(
                f"Message {i + 1}: Role: {msg['role']}, Content: {str(msg['content'])[:100]}..."
            )

        completion_params = {
            "model": model,
            "messages": updated_messages,
            "temperature": 0.7,
        }
        if max_output_tokens is not None:
            completion_params["max_tokens"] = max_output_tokens
            logger.info(
                f"[{time.time() - start_time:.3f}s] Requesting max_output_tokens: {max_output_tokens}"
            )

        response = await client.chat.completions.create(**completion_params)  # type: ignore
        assistant_message = response.choices[0].message.content
        logger.info(f"[{time.time() - start_time:.3f}s] Received response from OpenAI")
        return assistant_message
    except Exception as e:
        logger.error(
            f"[{time.time() - start_time:.3f}s] Error calling OpenAI chat completion API: {e}"
        )
        return f"Error: Could not get response from AI service. Details: {str(e)}"


def split_text_for_fast_tts(text: str, max_chunks: int = 3, min_total_chars: int = 180, min_chunk_size: int = 80) -> List[str]:
    """
    Split text into at most max_chunks (default 3) for TTS streaming, with similar sizes.
    If the text is short, return 1 or 2 chunks as appropriate.
    Splits on sentence-ending punctuation, em-dash, and commas.
    Won't split if text is below min_total_chars, or if resulting chunks would be too small.
    """
    text = text.strip()
    if len(text) <= min_total_chars:
        return [text]

    # Split on . ! ? ; — , followed by whitespace
    fragments = re.split(r'(?<=[.!?;,—])\s+', text)
    fragments = [f.strip() for f in fragments if f.strip()]
    # Ensure each fragment ends with a strong delimiter
    fragments = [f if f[-1] in ".!?;,—" else f + "." for f in fragments]

    # Try splitting into max_chunks, then 2, then 1
    for n_chunks in range(max_chunks, 0, -1):
        if len(fragments) <= n_chunks:
            return fragments
        total_chars = sum(len(f) for f in fragments)
        target_size = total_chars // n_chunks
        if target_size < min_chunk_size:
            continue
        chunks, current = [], ""
        for f in fragments:
            if not current:
                current = f
            elif len(current) + 1 + len(f) <= target_size or len(chunks) >= n_chunks - 1:
                current += " " + f
            else:
                chunks.append(current)
                current = f
        if current:
            chunks.append(current)
        if all(len(chunk) >= min_chunk_size or len(chunks) == 1 for chunk in chunks):
            return chunks
    # Fallback: just return the whole text as one chunk
    return [text]


async def text_to_speech_openai(
    text: str,
    tts_instructions: str,
    model: str = "gpt-4o-mini-tts",
    voice: str = "sage",
    return_bytes: bool = False,
) -> Union[str, bytes]:
    """
    Converts text to speech using OpenAI TTS and returns base64 encoded audio or raw bytes.
    Uses the provided tts_instructions.
    """
    start_time = time.time()
    logger.info(f"[TTS][{start_time}] text_to_speech_openai called. Text length: {len(text)}, Instructions: {tts_instructions[:50]}...")

    if not client:
        return (
            b"" if return_bytes
            else "Error: OpenAI client not initialized. TTS failed."
        )

    if not text.strip():
        return b"" if return_bytes else "Error: Cannot convert empty text to speech."

    try:
        tts_api_start = time.time()
        logger.info(f"[TTS][{tts_api_start - start_time:.3f}s] Sending text to OpenAI TTS API.")
        response = await client.audio.speech.create(
            model=model,
            voice=voice,
            input=text,
            response_format="mp3",
            instructions=tts_instructions,
        )
        tts_api_end = time.time()
        logger.info(f"[TTS][{tts_api_end - start_time:.3f}s] Received audio from OpenAI TTS. API duration: {tts_api_end - tts_api_start:.3f}s")
        audio_bytes = (
            await response.aread()
        )  # Explicitly use aread() for async response
        audio_read_end = time.time()
        logger.info(f"[TTS][{audio_read_end - start_time:.3f}s] Audio bytes read. Read duration: {audio_read_end - tts_api_end:.3f}s")
        if return_bytes:
            return audio_bytes
        base64_audio = base64.b64encode(audio_bytes).decode("utf-8")
        logger.info(
            f"[TTS][{time.time() - start_time:.3f}s] Audio encoded to base64 (length: {len(base64_audio)})"
        )
        return base64_audio
    except Exception as e:
        logger.error(
            f"[TTS][{time.time() - start_time:.3f}s] Error calling OpenAI TTS API: {e}"
        )
        return (
            b"" if return_bytes else f"Error: Could not generate audio. Details: {str(e)}"
        )


async def tts_parallel_stitch(text: str, tts_instructions: str) -> str:
    """
    Split text on periods, run TTS in parallel, and stitch the audio together. Returns base64-encoded audio.
    Requires tts_instructions to pass to underlying calls.
    """
    start_time = time.time()
    logger.info(f"[TTS][{start_time}] tts_parallel_stitch called. Text length: {len(text)}")
    chunks = split_text_for_fast_tts(text)
    logger.info(f"[TTS][{time.time() - start_time:.3f}s] TTS will run in {len(chunks)} chunks using specific instructions.")
    tts_tasks = [
        text_to_speech_openai(
            chunk, return_bytes=True, tts_instructions=tts_instructions
        )
        for chunk in chunks
    ]
    gather_start = time.time()
    audio_bytes_list = await asyncio.gather(*tts_tasks)
    gather_end = time.time()
    logger.info(f"[TTS][{gather_end - start_time:.3f}s] All TTS chunks complete. Gather duration: {gather_end - gather_start:.3f}s")
    # Only keep bytes, ignore str or None
    audio_bytes_list = [b for b in audio_bytes_list if isinstance(b, (bytes, bytearray))]
    stitched = b"".join(audio_bytes_list)  # type: ignore
    base64_audio = base64.b64encode(stitched).decode("utf-8")
    logger.info(f"[TTS][{time.time() - start_time:.3f}s] Stitched audio length: {len(base64_audio)} (base64)")
    return base64_audio
