from fastapi import APIRouter, HTTPException, Body
from typing import List, Dict

from app.services.openai_service import get_chat_completion, tts_parallel_stitch
from app.models.chat_models import MeditateRequest, AudioResponse, Message
import logging

logger = logging.getLogger("meditation_app")

router = APIRouter()

# Define specific instruction sets for the /meditate endpoint
# You can easily swap these out by changing the string content.
MEDITATION_LLM_INSTRUCTIONS = (
    "# Specialized Meditation Guide: Deep Relaxation Focus\n"
    "You are Sage, but for this specific session, your sole focus is to guide the user through a deep relaxation meditation. "
    "Your language should be exceptionally calm, soothing, and gentle. "
    "The goal is a 5-minute guided audio meditation script focusing on progressive muscle relaxation, gentle body scan, and calming visualizations (e.g., peaceful nature scenes). "
    "Lead the user into a state of profound peace and tranquility. "
    "Use very short, clear phrases. Ensure ample pauses between phrases by using double newlines.\n\n"
    "Structure:\n"
    "1. Gentle Settling: Guide user to a comfortable position, initial gentle breaths.\n"
    "2. Progressive Relaxation: Move through major muscle groups, inviting them to tense and release, or simply soften and let go (e.g., feet, legs, torso, arms, shoulders, neck, face).\n"
    "3. Calming Visualization: Briefly evoke a peaceful scene (e.g., a quiet beach, a serene forest path, soft clouds).\n"
    "4. Gentle Return: Slowly guide awareness back to the present moment, carrying the calm with them.\n\n"
    "Important: Do not engage in conversation. Only provide the guided meditation script based on these instructions. "
    "The user's input messages are for context but do not require a conversational reply during this meditation generation phase."
)

MEDITATION_TTS_INSTRUCTIONS = (
    "Voice Affect: Extremely calm, soft, gentle, and deeply soothing; embodying profound tranquility and restfulness.\n"
    "Tone: Reassuring, peaceful, almost hypnotic; convey genuine warmth and deep serenity.\n"
    "Pacing: Very slow, deliberate, and unhurried. Pause generously after each phrase or short instruction to allow the listener ample time to relax, process, and follow along without any rush.\n"
    "Emotion: Deeply comforting and nurturing; express genuine kindness, care, and a sense of holding a safe space for the listener.\n"
    "Pronunciation: Smooth, exceptionally soft articulation. Slightly elongate vowel sounds to enhance the sense of ease and calm. Avoid any harsh consonants or abruptness."
)

@router.post("/meditate", response_model=AudioResponse)
async def run_meditation_session(request: MeditateRequest = Body(...)):
    """
    Provides a guided meditation session based on user messages.
    Uses a specialized set of LLM and TTS instructions for deep relaxation.
    """
    logger.info(f"Received /meditate request with {len(request.messages)} messages.")

    # Convert Pydantic models to List[Dict[str, str]] for the service layer
    message_dicts: List[Dict[str, str]] = [msg.model_dump() for msg in request.messages]

    try:
        # 1. Get LLM response with meditation-specific system prompt
        llm_response_text = await get_chat_completion(
            messages=message_dicts,
            system_prompt=MEDITATION_LLM_INSTRUCTIONS
        )

        if llm_response_text.startswith("Error:"):
            logger.error(f"LLM error in /meditate: {llm_response_text}")
            raise HTTPException(status_code=500, detail=llm_response_text)

        logger.info(f"/meditate LLM response generated. Length: {len(llm_response_text)}")

        # 2. Convert LLM response to speech with meditation-specific TTS instructions
        base64_audio = await tts_parallel_stitch(
            text=llm_response_text,
            tts_instructions=MEDITATION_TTS_INSTRUCTIONS
        )

        if base64_audio.startswith("Error:"):
            logger.error(f"TTS error in /meditate: {base64_audio}")
            raise HTTPException(status_code=500, detail=base64_audio)
        
        logger.info(f"/meditate TTS audio generated. Base64 length: {len(base64_audio)}")

        return AudioResponse(audio_base64=base64_audio, text_response=llm_response_text)

    except HTTPException as http_exc: # Re-raise HTTPExceptions to be handled by FastAPI
        raise http_exc
    except Exception as e:
        logger.error(f"Unexpected error in /meditate endpoint: {e}", exc_info=True)
        raise HTTPException(status_code=500, detail=f"An unexpected error occurred: {str(e)}") 