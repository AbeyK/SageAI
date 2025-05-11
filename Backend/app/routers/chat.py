from fastapi import APIRouter, Depends, HTTPException
from app.models import ChatRequest, ChatResponse, ChatMessage
from app.auth.firebase_auth import verify_firebase_token
from app.services.openai_service import get_chat_completion, text_to_speech_openai
from typing import List
import time
import logging

logger = logging.getLogger("meditation_app")
router = APIRouter()

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
        # Handle cases where OpenAI call failed (e.g., API key issue, network error)
        # For now, we can raise an HTTPException or return a modified ChatResponse
        # depending on how we want the client to handle this.
        # Raising an HTTPException might be cleaner for distinct error states.
        logger.error(f"[{time.time() - start_time:.3f}s] OpenAI error: {text_response}")
        raise HTTPException(status_code=503, detail=text_response) # Service Unavailable

    # Generate audio from the text response
    tts_start = time.time()
    actual_audio_base64 = await text_to_speech_openai(text=text_response)
    logger.info(f"[{time.time() - start_time:.3f}s] TTS generation took {time.time() - tts_start:.3f}s")

    if actual_audio_base64.startswith("Error:"):
        # Handle TTS errors. For now, we can send the text response with a note about audio failure,
        # or raise another HTTPException. Let's opt for returning text with an error indication for audio.
        # A more robust solution might involve a specific error code or field in the response.
        logger.error(f"[{time.time() - start_time:.3f}s] TTS error: {actual_audio_base64}")
        # Fallback: return text_response with an empty/error audio and a relevant caption.
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