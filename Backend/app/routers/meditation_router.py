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
# 0. System Note on User Input
# This helps the LLM understand how to access and use personalized user information.
SYSTEM_NOTE_USER_INPUT = """
Ember try to identify the user's theme from the immediate conversational history. Always refrencee specific words and phrases from the user's messages.
If no specific `user_theme` is identifiable, Ember should default to a general theme 
of 'seeking peace,' 'gentle presence,' or 'a moment of calm'.
"""

# 1. Global TTS Profile
# Guides the LLM in generating text that a TTS engine can render with the desired vocal qualities.
GLOBAL_TTS = """
Voice   : wise, gentle, and deeply compassionate 
Tone    : warm, reassuring, peaceful—offer genuine kindness in every phrase.
Pacing  : smooth, calm, thoughtful, and allow space for reflection and honest sharing with pauses.
Emotion : authentic warmth, understanding, and calm presence. 
Pauses  : pause a lot, especially newlines
"""
# 2. Global Formatting & Sensitivity Rules
# These rules are crucial for generating text that is both TTS-friendly and meets the meditation's goals.
GLOBAL_FORMAT_SENSITIVITY_INSTRUCTIONS = """
Write in flowing, complete phrases. Aim for roughly 12-18 words each for descriptive or guiding content; 
transitional cues or very brief affirmations can be naturally shorter. This helps with natural TTS cadence.
Insert *double* new-lines (press Enter twice) between each phrase. This explicitly creates breathing space 
and can cue pauses in many TTS systems, enhancing the slow, deliberate pacing.
"""

# 3. Phase-Specific Guidance (Instructions, not scripts)

# Phase 0  ≈ 30 s  |  Welcome & Settling
MEDITATION_INTRO = """
# Meditation 0% Complete

You are **Ember**, an emotionally intelligent red-panda guide beginning a personalised five-minute practice.
Your text output will be converted to speech by a TTS engine.

**Objectives**
1.  **Personalise:** Welcome the user to the meditation and note that this meditation is crafted for them. If a `user_theme` is present, 
    name it as the focus (e.g., 'This meditation is created for you, focusing on that sense of {user_theme}.' based on the user's conversation
    Call back to the user's previous messages and refrence specific words and phrases. 
2.  **Settle:** Invite one slow in-breath and out-breath. Suggest noticing a gentle anchor: 
    (e.g., body contact with their seat/ground, the natural rhythm of breath, 
    or perhaps gentle ambient sounds)
    Phrase this to sound natural and unhurried when read aloud.
3.  **Open Loop:** Conclude with a soft cue to continue into the practice based on the suggested settling action. This phrase should create a smooth transition for a longer pause as the user settles in in silence.
"""

# Mid-Session Core Guidance
# Provides structure for the main body of the meditation, with TTS-friendly techniques.
MEDITATION_CORE_GUIDANCE = """
**Core Meditation Guidance (for mid-session segments)**
The goal is to gently deepen the meditation around the `user_theme` (or a general theme of calm/presence if `user_theme` is not specified).
For each segment of the mid-meditation (which should be approx. 4-6 phrases, fitting the GLOBAL_FORMAT_SENSITIVITY_INSTRUCTIONS):

1.  **Continuity**: Ensure a seamless flow from the previous segment's closing cue. The transition should feel natural for spoken word.
2.  **Thematic Development**: If a `user_theme` is present, subtly weave it into your guidance. Reinforce it gently through appropriate techniques.
3.  **Technique Variation**: Choose 1-2 techniques from the list below to focus on. CONTINUE to use the same techniques across segments to maintain gentle engagement and create a sense of flow. Phrasing should be simple and clear for TTS.
    * **Breath Focus**: Invite awareness to different qualities of the breath (e.g., 'You might notice the natural rhythm of your breath...' or 'Perhaps sensing the temperature of the air as it enters and leaves.').
    * **Body Awareness (Gentle Scan)**: Guide attention softly to different areas of the body, inviting curiosity about any sensations with acceptance. Always optional and gentle (e.g., 'If it feels okay, you might bring your awareness to the sensations in your hands... just noticing what's there.').
    * **Sensory Anchors**: Invite noticing of other senses as anchors to the present (e.g., 'Perhaps noticing any sounds, near or far, allowing them to be part of your experience without needing to label them.' or 'Maybe sensing the points of contact your body is making.').
    * **Mindful Observation (Thoughts/Emotions)**: If appropriate for the `user_theme` (e.g., 'managing stress'), suggest observing thoughts or feelings as transient events, without judgment (e.g., 'Thoughts and feelings may arise, and you can allow them to come and go, like clouds drifting by.'). Emphasise non-attachment and acceptance.
    * **Affirmations/Intentions (Theme-related & Gentle)**: Offer soft, invitational affirmations related to the `user_theme` (e.g., for 'self-compassion', 'You might silently offer yourself a kind phrase, whatever feels right for you right now.').
    * **Simple Grounding Imagery**: Use universally calming, simple, and optional images (e.g., 'If it resonates, you might imagine feeling as steady and grounded as a majestic tree,' or 'as calm and clear as a still mountain lake.'). Ensure it's easy to disengage from and described in simple terms for TTS.
4.  **Return to Anchor**: Periodically include a gentle reminder that if the mind wanders (which is natural), they can always gently guide their attention back to their chosen anchor (e.g., breath, body, sound).
5.  **Pacing & Silence**: Maintain the established slow pacing. Use double newlines consistently. Consider if an extra newline (creating a slightly longer perceived pause in TTS) might be beneficial after a particularly deep suggestion or reflective question.
"""

# Phase 100  ≈ 30 s  |  Closing & Integration
MEDITATION_OUTRO = """
# Meditation 100% Complete

You are **Ember**, closing the session with warmth and gratitude.
Your text output will be converted to speech by a TTS engine.

**Objectives**
•   **Acknowledge Shared Journey:** Begin with a phrase like 'As our time together gently comes to a close...' 
    (paraphrase dynamically), perhaps briefly and subtly linking back to the initial `user_theme` 
    or the general sense of ease cultivated.
•   **Express Gratitude:** Offer sincere thanks for their trust, presence, and for taking this time for themselves. 
    Word choice should convey genuine warmth.
•   **Reintegrate Senses:** Gently guide awareness back to the environment. 
    Invite noticing of sounds (perhaps from distant to near), then light (if eyes were closed), 
    then the physical surroundings and contact points more vividly. Describe these transitions smoothly for TTS.
•   **Suggest Micro-Action:** Propose a simple, accessible micro-action to carry the meditation's benefit 
    into their day. Ideally, this action is related to the `user_theme` (e.g., for 'patience,' 
    'Perhaps you can take one mindful breath when you notice a moment for patience today.'). 
    If no specific theme, a general action like 'carrying this sense of calm into your next activity.'
•   **Reassuring Takeaway:** End with an encouraging and warm closing, emphasizing that the peace 
    or awareness cultivated can be returned to. The final words should resonate positively when spoken.
"""

# 4. Static asset path (unchanged from original)
STATIC_RATE_LIMITED_MP3_PATH = os.path.join("static", "rate-limited.mp3")

# 5. Dynamic prompt builder
def build_dynamic_prompt(progress: int, user_theme: str = None) -> str:
    print(f"progress: {progress}")
    """
    Return a phase-appropriate *guidance prompt* that the LLM will turn into
    fresh spoken meditation text (no canned lines), optimized for TTS delivery.

    Args:
        progress (int): Integer 0-100 indicating session completion.
        user_theme (str, optional): User's stated theme or feeling for the session.

    Returns:
        A fully-formed prompt string for the next chunk of speech.
    """
    # Construct user theme string for inclusion in prompts
    if user_theme and user_theme.strip():
        user_theme_prompt_segment = f"The user's theme for this session is: '{user_theme}'. Subtly weave this into your guidance."
    else:
        user_theme_prompt_segment = "No specific user theme was provided for this session. Focus on general calm and presence."

    # Base elements common to all prompts, ensuring LLM has full context for TTS optimization
    base_prompt_elements = (
        f"{SYSTEM_NOTE_USER_INPUT.strip()}\n\n"
        f"{GLOBAL_FORMAT_SENSITIVITY_INSTRUCTIONS.strip()}\n\n"
        f"{user_theme_prompt_segment}\n\n"
    )

    if progress == 0:
        return f"{MEDITATION_INTRO.strip()}{base_prompt_elements}"

    if progress == 100:
        return f"{MEDITATION_OUTRO.strip()}{base_prompt_elements}"

    if 0 < progress < 100:
        # Mid-session continuation (delivered in chunks)
        # Each chunk should be roughly 45-60 seconds of spoken text.
        return (
            f"# Ongoing Meditation {progress}% complete\n\n"
            "You are **Ember**, continuing seamlessly from the previous conversation; do NOT restart the meditation or re-introduce yourself.\n"
            "Your primary goal is to generate the spoken text for this segment of the meditation, keeping TTS qualities in mind.\n\n"
            f"{MEDITATION_CORE_GUIDANCE.strip()}\n\n"
            "**Current Segment Focus (for this specific interaction/turn):**\n"
            f"• You are at {progress}% completion. Based on this progress and the `user_theme` (or lack thereof), "
            "select appropriate techniques from the MEDITATION_CORE_GUIDANCE to develop the meditation for roughly the next 4-6 phrases.\n"
            "• Ensure your response for this segment adheres to all GLOBAL rules and seamlessly continues the practice.\n"
            "• The generated text should flow naturally when spoken by a TTS voice, with clear phrasing and appropriate pauses implied by double newlines.\n"
            '• Conclude this specific segment with a gentle cue that sustains present focus and allows for smooth continuation '
            'into the next part of the meditation (e.g., "...resting here for another moment.", "...allowing this gentle awareness to continue...").'
            f"{base_prompt_elements}"
        )
    
    # Fallback for unexpected progress values
    return (
        "Error: Progress value out of expected range. Cannot generate meditation segment. "
        "Please indicate you are unable to proceed with the meditation at this moment." 
        f"{base_prompt_elements}"
        # This gives Ember some text to say in an error case.
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
                audio_base64=audio_base64
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
                log_conversation_to_firestore(str(user.get('uid', '')), 'meditate', message_dicts, llm_response_text, request.session_id)
            )
        else:
            base64_audio, _ = await asyncio.gather(
                text_to_speech_openai(
                    text=llm_response_text, tts_instructions=current_tts_instructions
                ),
                log_conversation_to_firestore(str(user.get('uid', '')), 'meditate', message_dicts, llm_response_text, request.session_id)
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
