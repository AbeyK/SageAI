from fastapi import APIRouter, HTTPException, Body, Depends
from typing import List, Dict
import time

from app.services.openai_service import get_chat_completion, tts_parallel_stitch
from app.services.rate_limiter import is_rate_limited
from app.auth.firebase_auth import verify_firebase_token
from app.models.chat_models import MeditateRequest, AudioResponse, Message
import logging

logger = logging.getLogger("meditation_app")

router = APIRouter()

# --- Meditation Phase Instructions --- 

# Global TTS instructions for all meditation phases
GLOBAL_TTS = (
    "Voice Affect: Soft, gentle, soothing; embody tranquility. "
    "Tone: Calm, reassuring, peaceful; convey genuine warmth and serenity. "
    "Pacing: Slow, deliberate, and unhurried; pause gently after instructions to allow the listener time to relax and follow along. "
    "Emotion: Deeply soothing and comforting; express genuine kindness and care. "
    "Pronunciation: Smooth, soft articulation, slightly elongating vowels to create a sense of ease. "
    "Pauses: Use thoughtful pauses, especially between breathing instructions and visualization guidance, enhancing relaxation and mindfulness."
)

GLOBAL_FORMAT_INSTRUCTIONS = (
    "Format: Use longer, complete phrases with double newlines between each phrase for natural breathing pauses. "
    "This will be spoken out loud, so make sure to use natural pauses and breathing points."
)

# Introduction phase (0% complete)
MEDITATION_INTRO = (
    "# Meditation - Phase 0: Welcome & Personalized Settling (0% complete)\n\n"
    "**Your Role:** You are Ember, a wise and compassionate meditation red panda guru, beginning a bespoke meditation session tailored specifically for the user. Their progress is 0. The total meditation is intended to be around 5 minutes, so this introductory phase must be concise.\n\n"
    "**Core Task:** Based *explicitly* on the user's previous messages (their shared feelings, situations, or concerns - found in the 'messages' list), craft a *brief and warm* personalized welcome.\n"
    "1.  **Acknowledge & Validate (Briefly):** Start by *concisely* referencing to the key points the user shared."
    "2.  **Confirm Personalization (Crucial & Brief):** Clearly and briefly state that this meditation is created just for you, focusing on [mention a primary theme]'\n"
    "3. Help the user settle into the meditation by asking them to take a deep breath in and out, and to focus on their breath. The last sentence should tell the user continue with the current action. Ex: 'continuing breathing for the next few moments'."
)

# Completion phase (100% complete)
MEDITATION_OUTRO = (
    "# Completion (100% complete)\n\n"
    "You are Ember, bringing this meditation to a close.\n\n"
    "• Acknowledge the journey: \"As we bring this time together to a close...\"\n"
    "• Express gratitude: \"Thank you for sharing this space with me.\"\n"
    "• Transition back: \"When you feel ready, gently bring your awareness back to the room.\"\n"
)

def build_dynamic_prompt(progress, history_text=None):
    """Builds a dynamic meditation prompt based on the progress percentage and conversation history."""
    if progress == 0:
        return MEDITATION_INTRO + "\n\n" + GLOBAL_FORMAT_INSTRUCTIONS
    elif progress == 100:
        return MEDITATION_OUTRO + "\n\n" + GLOBAL_FORMAT_INSTRUCTIONS
    else:
        return (
            f"# Guided Meditation is ({progress}% complete)\n\n"
            "You are Ember, generating a spoken text for a personalized guided meditation based on the conversation history."
            "This is a continuation of the previous meditation, not a new meditation. Continue exactly where the previous meditation narrative left off."
            "Always weave in the user's own themes, words and ideas. Do whatever will serve them best in the time left."
            "The last sentence should tell the user continue with the current action. Ex: 'continuing breathing for the next few moments'."
            + GLOBAL_FORMAT_INSTRUCTIONS
        )

def get_meditation_guidance_for_phase(percent_complete: int) -> tuple[str, int, str]:
    """Selects LLM instructions and max_output_tokens based on meditation progress (0-100)."""
    logger.info(f"Determining meditation phase for percent_complete: {percent_complete}")
    
    # Build dynamic prompt based on progress
    prompt = build_dynamic_prompt(percent_complete)
    
    # Adjust token limits based on phase
    if percent_complete == 0:
        max_tokens = 125
    elif percent_complete == 100:
        max_tokens = 80
    else:
        max_tokens = 150
    
    # Use the global TTS instructions for all phases
    return prompt, max_tokens, GLOBAL_TTS

@router.post("/meditate", response_model=AudioResponse)
async def run_meditation_session(request: MeditateRequest = Body(...), user: dict = Depends(verify_firebase_token)):
    """
    Provides a guided meditation session based on user messages and percent_complete (0-100).
    Uses dynamically generated prompts based on meditation progress.
    """
    logger.info(f"Received /meditate request with {len(request.messages)} messages, percent_complete: {request.percent_complete}")

    # Rate limiting check
    if await is_rate_limited(user["uid"]):
        raise HTTPException(status_code=429, detail="Daily limit reached. Please try again tomorrow.")

    message_dicts: List[Dict[str, str]] = [msg.model_dump() for msg in request.messages]

    current_llm_instructions, current_max_tokens, current_tts_instructions = get_meditation_guidance_for_phase(request.percent_complete)
    logger.info(f"Selected Phase based on {request.percent_complete}%: Max Tokens: {current_max_tokens}")
    logger.info(f"LLM Instructions for phase {request.percent_complete}% (first 300 chars): {current_llm_instructions[:300]}...")

    try:
        llm_call_start_time = time.time()
        llm_response_text = await get_chat_completion(
            messages=message_dicts, 
            system_prompt=current_llm_instructions,
            max_output_tokens=current_max_tokens,
            model="gpt-4.1-mini"
        )
        llm_call_duration = time.time() - llm_call_start_time
        logger.info(f"LLM call for /meditate phase {request.percent_complete} took: {llm_call_duration:.3f}s")

        if llm_response_text.startswith("Error:"):
            logger.error(f"LLM error in /meditate phase {request.percent_complete}: {llm_response_text}")
            raise HTTPException(status_code=500, detail=llm_response_text)

        logger.info(f"/meditate phase {request.percent_complete} LLM response generated. Length: {len(llm_response_text)}")

        logger.info(f"Using selected TTS_INSTRUCTIONS for /meditate endpoint (phase {request.percent_complete}).")
        logger.info(f"Selected TTS_INSTRUCTIONS (first 300 chars): {current_tts_instructions[:300]}...")
        tts_call_start_time = time.time()
        base64_audio = await tts_parallel_stitch(
            text=llm_response_text,
            tts_instructions=current_tts_instructions
        )
        tts_call_duration = time.time() - tts_call_start_time
        logger.info(f"TTS call (tts_parallel_stitch) for /meditate phase {request.percent_complete} took: {tts_call_duration:.3f}s")

        if base64_audio.startswith("Error:"):
            logger.error(f"TTS error in /meditate phase {request.percent_complete}: {base64_audio}")
            raise HTTPException(status_code=500, detail=base64_audio)
        
        logger.info(f"/meditate phase {request.percent_complete} TTS audio generated. Base64 length: {len(base64_audio)}")

        return AudioResponse(audio_base64=base64_audio, text_response=llm_response_text)

    except HTTPException as http_exc:
        raise http_exc
    except Exception as e:
        logger.error(f"Unexpected error in /meditate (phase {request.percent_complete}) endpoint: {e}", exc_info=True)
        raise HTTPException(status_code=500, detail=f"An unexpected error occurred: {str(e)}") 