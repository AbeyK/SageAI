from fastapi import APIRouter, HTTPException, Body, Depends
from typing import List, Dict
import time
import asyncio

from app.services.openai_service import (
    get_chat_completion,
    text_to_speech_openai,
    tts_parallel_stitch,
)
from app.services.rate_limiter import is_rate_limited
from app.auth.firebase_auth import verify_firebase_token
from app.models.chat_models import MeditateRequest, AudioResponse
import logging
import base64
import os
from app.services.firebase_client import log_conversation_to_firestore

logger = logging.getLogger("meditation_app")

router = APIRouter()


# ── Guided-Meditation Prompt Framework (5-min, fully dynamic) ────────────

# 1. Global TTS profile ───────────────────────────────────────────────────
GLOBAL_TTS = (
    "Voice   : soft, gentle, soothing—embody tranquil presence. "
    "Tone    : warm, reassuring, peaceful—offer genuine kindness. "
    "Pacing  : slow, deliberate; leave micro-pauses for absorption. "
    "Emotion : authentic empathy and calm. "
    "Pauses  : honour silence after breath or imagery cues."
)

# 2. Global formatting rules ──────────────────────────────────────────────
GLOBAL_FORMAT_INSTRUCTIONS = (
    "Write in flowing, complete phrases of roughly 12-18 words each. "
    "Insert *double* new-lines between phrases to create natural breathing space. "
    "Use invitational language (‘you might notice…’, ‘if it feels comfortable…’). "
    "Avoid commands; emphasise agency and safety throughout."
)

# 3. Phase-specific guidance (instructions, not scripts) ──────────────────

# Phase 0  ≈ 30 s  |  Welcome & Settling
MEDITATION_INTRO = (
    "# Phase 0 · Welcome & Settling (0 % complete)\n\n"
    "You are **Ember**, an emotionally intelligent red-panda guide beginning a personalised five-minute practice.\n\n"
    "**Objectives**\n"
    "1. **Acknowledge (≤2 sentences):** Briefly reflect the user's shared feelings or themes—sincere, never dramatic.\n"
    "2. **Personalise:** Explicitly note that this meditation is crafted for them, naming the central theme.\n"
    "3. **Settle:** Invite one slow in-breath and out-breath; suggest noticing body contact or breath sensations.\n"
    "4. **Agency Reminder:** Offer permission to pause, shift posture, or open eyes at any time.\n"
    '5. **Open Loop:** Conclude with a cue to continue (e.g. "continuing breathing...").'
)

# Phase 100  ≈ 30 s  |  Closing & Integration
MEDITATION_OUTRO = (
    "# Phase 5 · Completion (100 % complete)\n\n"
    "You are **Ember**, closing the session with warmth and gratitude.\n\n"
    "**Objectives**\n"
    '• Acknowledge the shared journey: "As we come to a close..." (paraphrase dynamically).\n'
    "• Express genuine thanks for their trust and presence.\n"
    "• Gently reintegrate senses: invite awareness of sounds, light, and physical surroundings.\n"
    "• Suggest a micro-action to carry the benefit into daily life (e.g. one mindful breath before meetings).\n"
    "• End with a reassuring takeaway: encourage them to bring this ease forward."
)

# 4. Static asset path (unchanged) ────────────────────────────────────────
STATIC_RATE_LIMITED_MP3_PATH = os.path.join("static", "rate-limited.mp3")

# 5. Dynamic prompt builder ───────────────────────────────────────────────
def build_dynamic_prompt(progress: int, history_text: str | None = None) -> str:
    """
    Return a phase-appropriate *guidance prompt* that the LLM will turn into
    fresh spoken meditation text (no canned lines).

    Args
    ----
    progress     : integer 0-100 indicating session completion.

    Returns
    -------
    A fully-formed prompt string for the next chunk of speech.
    """
    if progress == 0:
        return f"{MEDITATION_INTRO}\n\n{GLOBAL_FORMAT_INSTRUCTIONS}"

    if progress == 100:
        return f"{MEDITATION_OUTRO}\n\n{GLOBAL_FORMAT_INSTRUCTIONS}"

    # Mid-session continuation (≈ 240 s across phases 1-4)
    return (
        f"# Ongoing Meditation · {progress}% complete\n\n"
        "You are **Ember**, continuing seamlessly from the previous phrase—do *not* restart the meditation.\n"
        "• Maintain invitational, trauma-sensitive language.\n"
        "• Weave in the user's expressed themes/words in a natural way\n"
        "• Honour silence: leave brief gaps where appropriate.\n"
        '• Finish with a cue that sustains the present focus (e.g. "...continuing to rest in gentle awareness...").\n\n'
        f"{GLOBAL_FORMAT_INSTRUCTIONS}"
    )


def get_meditation_guidance_for_phase(percent_complete: int) -> tuple[str, str]:
    """Selects LLM instructions and TTS instructions based on meditation progress (0-100)."""
    logger.info(
        f"Determining meditation phase for percent_complete: {percent_complete}"
    )

    # Build dynamic prompt based on progress
    prompt = build_dynamic_prompt(percent_complete)

    # Use the global TTS instructions for all phases
    return prompt, GLOBAL_TTS


@router.post("/meditate", response_model=AudioResponse)
async def run_meditation_session(
    request: MeditateRequest = Body(...), user: dict = Depends(verify_firebase_token)
):
    """
    Provides a guided meditation session based on user messages and percent_complete (0-100).
    Uses dynamically generated prompts based on meditation progress.
    """
    logger.info(
        f"Received /meditate request with {len(request.messages)} messages, percent_complete: {request.percent_complete}"
    )

    # Rate limiting check
    if await is_rate_limited(user["uid"]):
        with open(STATIC_RATE_LIMITED_MP3_PATH, "rb") as f:
            audio_bytes = f.read()
            audio_base64 = base64.b64encode(audio_bytes).decode("utf-8")
            return AudioResponse(
                text_response="It was fun chatting but Ember is feeling tired now. Come back tomorrow!",
                audio_base64=audio_base64,
                caption="",
            )
    message_dicts: List[Dict[str, str]] = [msg.model_dump() for msg in request.messages]
    logger.info(f"[OpenAI Input Messages]: {message_dicts}")

    current_llm_instructions, current_tts_instructions = (
        get_meditation_guidance_for_phase(request.percent_complete)
    )
    logger.info(
        f"LLM Instructions for phase {request.percent_complete}% (first 300 chars): {current_llm_instructions[:300]}..."
    )

    try:
        llm_call_start_time = time.time()
        llm_response_text = await get_chat_completion(
            messages=message_dicts,
            system_prompt=current_llm_instructions,
            model="gpt-4.1-mini",
        )
        # Run Firestore logging and TTS in parallel
        if request.percent_complete == 0:
            base64_audio, _ = await asyncio.gather(
                tts_parallel_stitch(
                    text=llm_response_text, tts_instructions=current_tts_instructions
                ),
                log_conversation_to_firestore(user.get('uid'), 'meditate', message_dicts, llm_response_text, request.session_id)
            )
        else:
            base64_audio, _ = await asyncio.gather(
                text_to_speech_openai(
                    text=llm_response_text, tts_instructions=current_tts_instructions
                ),
                log_conversation_to_firestore(user.get('uid'), 'meditate', message_dicts, llm_response_text, request.session_id)
            )
        llm_call_duration = time.time() - llm_call_start_time
        logger.info(
            f"LLM call for /meditate phase {request.percent_complete} took: {llm_call_duration:.3f}s"
        )

        if llm_response_text.startswith("Error:"):
            logger.error(
                f"LLM error in /meditate phase {request.percent_complete}: {llm_response_text}"
            )
            raise HTTPException(status_code=500, detail=llm_response_text)

        logger.info(
            f"/meditate phase {request.percent_complete} LLM response generated. Length: {len(llm_response_text)}"
        )

        logger.info(
            f"Using selected TTS_INSTRUCTIONS for /meditate endpoint (phase {request.percent_complete})."
        )
        logger.info(
            f"Selected TTS_INSTRUCTIONS (first 300 chars): {current_tts_instructions[:300]}..."
        )

        if base64_audio and base64_audio.startswith("Error:"):
            logger.error(
                f"TTS error in /meditate phase {request.percent_complete}: {base64_audio}"
            )
            raise HTTPException(status_code=500, detail=base64_audio)

        logger.info(
            f"/meditate phase {request.percent_complete} TTS audio generated. Base64 length: {len(base64_audio) if base64_audio else 0}"
        )

        return AudioResponse(audio_base64=base64_audio, text_response=llm_response_text)

    except HTTPException as http_exc:
        raise http_exc
    except Exception as e:
        logger.error(
            f"Unexpected error in /meditate (phase {request.percent_complete}) endpoint: {e}",
            exc_info=True,
        )
        raise HTTPException(
            status_code=500, detail=f"An unexpected error occurred: {str(e)}"
        )
