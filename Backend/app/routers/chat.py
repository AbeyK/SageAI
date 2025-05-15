from fastapi import APIRouter, Depends, HTTPException
from app.models import ChatRequest, ChatResponse, ChatMessage
from app.auth.firebase_auth import verify_firebase_token
from app.services.openai_service import get_chat_completion, text_to_speech_openai
from app.services.rate_limiter import is_rate_limited
from typing import List
import time
import logging
import base64
import os

logger = logging.getLogger("meditation_app")
router = APIRouter()

# Use a path relative to the working directory (which is /app in Docker)
STATIC_MP3_PATH = os.path.join("static", "sage-intro.mp3")

@router.post("/chat", response_model=ChatResponse, tags=["Chat"])
async def process_chat(request: ChatRequest, user: dict = Depends(verify_firebase_token)):
    """
    Receives a chat history, gets a response from OpenAI GPT-4o,
    converts the response to speech using OpenAI TTS,
    and returns the text response and base64 encoded audio.
    Requires Firebase authentication.
    """
    start_time = time.time()
    logger.info(f"[{time.time() - start_time:.3f}s] Starting chat processing")
    
    logger.info(f"[{time.time() - start_time:.3f}s] Authenticated user: {user.get('uid')}")
    logger.info(f"[{time.time() - start_time:.3f}s] Received messages: {request.messages}")

    # If the first message is from the 'initializer' role, return the static mp3
    if request.messages and len(request.messages) == 1:
        try:
            with open(STATIC_MP3_PATH, "rb") as f:
                audio_bytes = f.read()
            audio_base64 = base64.b64encode(audio_bytes).decode("utf-8")
            return ChatResponse(
                text_response="Hello! How're you doing today?",
                audio_base64=audio_base64,
                caption=""
            )
        except Exception as e:
            logger.error(f"Error reading static mp3: {e}")
            raise HTTPException(status_code=500, detail="Could not load intro audio.")

    # Rate limiting check
    if await is_rate_limited(user["uid"]):
        raise HTTPException(status_code=429, detail="Daily limit reached. Please try again tomorrow.")

    # Simplified message preparation for OpenAI
    openai_messages = []
    for msg in request.messages:
        openai_messages.append({"role": msg.role, "content": msg.content})

    logger.info(f"[{time.time() - start_time:.3f}s] Message preparation complete")

    # Get text response from OpenAI GPT-4o
    chat_start = time.time()
    text_response = await get_chat_completion(messages=openai_messages)
    logger.info(f"[{time.time() - start_time:.3f}s] Chat completion took {time.time() - chat_start:.3f}s")

    if text_response.startswith("Error:"):
        logger.error(f"[{time.time() - start_time:.3f}s] OpenAI error: {text_response}")
        raise HTTPException(status_code=503, detail=text_response) # Service Unavailable

    # Generate audio from the text response
    tts_start = time.time()
    actual_audio_base64 = await text_to_speech_openai(text=text_response)
    logger.info(f"[{time.time() - start_time:.3f}s] TTS generation took {time.time() - tts_start:.3f}s")

    if actual_audio_base64.startswith("Error:"):
        logger.error(f"[{time.time() - start_time:.3f}s] TTS error: {actual_audio_base64}")
        return ChatResponse(
            text_response=text_response,
            audio_base64="", # Indicate audio failure
            caption=f"Audio generation failed. Displaying text only: {text_response[:50]}..."
        )

    total_time = time.time() - start_time
    logger.info(f"[{total_time:.3f}s] Total processing time")
    
    return ChatResponse(
        text_response=text_response,
        audio_base64=actual_audio_base64,
        caption="Caption for: " + text_response[:50] + "..." 
    ) 