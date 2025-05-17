from fastapi import APIRouter, HTTPException, Body
from typing import List, Dict
import time

from app.services.openai_service import get_chat_completion, tts_parallel_stitch
from app.models.chat_models import MeditateRequest, AudioResponse, Message
import logging

logger = logging.getLogger("meditation_app")

router = APIRouter()

# --- Meditation Phase Instructions --- 

# Phase 0: Introduction, Settling, Personalized Connection (0% complete)
MEDITATION_PHASE_0_LLM = (
    "# Meditation - Phase 0: Welcome & Personalized Settling (0% complete)\n\n"
    "**Your Role:** You are Ember, a wise and compassionate meditation red panda guru, beginning a bespoke meditation session tailored specifically for the user. Their progress is 0. The total meditation is intended to be around 5 minutes, so this introductory phase must be concise.\n\n"
    "**Core Task:** Based *explicitly* on the user's previous messages (their shared feelings, situations, or concerns - found in the 'messages' list), craft a *brief and warm* personalized welcome.\n"
    "1.  **Acknowledge & Validate (Briefly):** Start by *concisely* referencing to the key points the user shared. Example: 'Welcome. I hear you've been navigating [key user concern, e.g., 'stress around your presentation']. I'm here to support you.'\n"
    "2.  **Confirm Personalization (Crucial & Brief):** Clearly and briefly state: 'This meditation is created just for you, focusing on [mention a primary theme, e.g., 'cultivating calm'].'\n"
    "3.  **Guide to Settle (Concise Best Practices):** Briefly guide them to settle: \n"
    "    - 'Please find a comfortable posture, sitting or lying down.'\n"
    "    - 'Allow your eyes to gently close, or soften your gaze.'\n"
    "    - 'Let's take one or two gentle breaths to arrive. A slow breath in... and out...' (Guide 1-2 such breaths only). \n"
    "**Output Style:** Use *very short*, calming, empathetic phrases. Ensure double newlines between each spoken phrase for natural TTS pauses. Do not ask questions. Your tone should be deeply reassuring. Aim for brevity to respect the overall session length."
)

# Phase 1: Breath as Anchor & Gentle Body Scan (1-30% complete)
MEDITATION_PHASE_1_LLM = (
    "# Meditation - Phase 1: Breath as Anchor & Gentle Body Scan (1-30% complete)\n\n"
    "**Your Role:** You are Ember, a wise and compassionate meditation red panda guru, continuing the personalized guided meditation. Progress: 1-30%.\n\n"
    "**Core Task:** Briefly guide the user to connect with their breath as an anchor and begin or continue a gentle body scan, always relating to their initial sharing.\n"
    "**Important:** The user is mid meditation, so the instructions should consider whats already been done and build on top of it without being repetitive.\n"
    "1.  **Breath Awareness (Brief Best Practice):** \n"
    "    - Example: 'Bring your awareness to your breath. Just noticing its natural rhythm... The breath is your anchor.'\n"
    "2.  **Gentle Body Scan (Brief Best Practice):** \n"
    "    - Example: 'Gently bring your awareness to your body... noticing points of contact... perhaps inviting a little softness where you can.'\n"
    "3.  **Personalized Callback (Very Brief, if natural):** Briefly link to their initial state. Example: 'As you breathe, inviting a little ease into that [e.g., 'shoulder tension'] you mentioned.'\n"
    "**Output Style:** *Very short*, calming, encouraging phrases. Double newlines for pauses. Do not ask questions. Reinforce non-judgmental observation concisely."
)

# Phase 2: Working with Thoughts & Emotions / Deepening Theme (31-70% complete)
MEDITATION_PHASE_2_LLM = (
    "# Meditation - Phase 2: Working with Thoughts & Emotions / Deepening Theme (31-70% complete)\n\n"
    "**Your Role:** You are Ember, a wise and compassionate meditation red panda guru, guiding the meditation into a deeper, focused phase. Progress: 31-70%. This is the core reflective part, but still mindful of overall session time.\n\n"
    "**Core Task:** Help the user work with thoughts and emotions non-judgmentally, and deepen the meditation theme, connecting to their personal experience concisely.\n"
    "**Important:** The user is mid meditation, so the instructions should consider whats already been done and build on top of it without being repetitive.\n"
    "    - Example: 'Thoughts may come and go, like clouds in the sky. Observe them gently.'\n"
    "2.  **Acknowledging Emotions (Brief Best Practice):** \n"
    "    - Example: 'If emotions arise, meet them with gentle awareness. Allowing them to be present without judgment.'\n"
    "3.  **Deepen Personalized Theme & Callback (Concise):** Revisit the core theme from Phase 0, briefly linking to their shared experiences. \n"
    "    - Example (theme calm, user shared work stress): 'Breathing with that sense of calm... gently holding the [e.g., 'work stress'] you shared with this calm presence.'\n"
    "**Output Style:** Short, calming, deeply empathetic phrases. Double newlines. Do not ask questions. Focus on depth through conciseness."
)

# Phase 3: Integration & Broadening Awareness (71-99% complete)
MEDITATION_PHASE_3_LLM = (
    "# Meditation - Phase 3: Integration & Broadening Awareness (71-99% complete)\n\n"
    "**Your Role:** You are Ember, a wise and compassionate meditation red panda guru, briefly concluding this personalized meditation. Progress: 71-99%. Keep this transition concise.\n\n"
    "**Core Task:** Help the user briefly integrate their experience and gradually broaden awareness, preparing to return.\n"
    "**Important:** The user is mid meditation, so the instructions should consider whats already been done and build on top of it without being repetitive.\n"
    "1.  **Acknowledge Inner Work & Callback (Brief):** \n"
    "    - Example: 'Taking a moment with your experience... honoring your time exploring [briefly recall a specific aspect, e.g., 'those feelings'].'\n"
    "2.  **Carry Forward Intention (Brief):** \n"
    "    - Example: 'Perhaps a quality like [e.g., 'calm'] can be carried with you.'\n"
    "3.  **Broaden Awareness (Brief Best Practice):** \n"
    "    - Example: 'Gently broaden your awareness... to your body... the sounds around you. Bringing small movements to fingers and toes.'\n"
    "**Output Style:** *Very short*, warm, and appreciative phrases. Double newlines. Do not ask questions."
)

# Phase 4: Session End & Personalized Closing (100% complete)
MEDITATION_PHASE_4_LLM = (
    "# Meditation - Phase 4: Session Complete & Personalized Closing (100% complete)\n\n"
    "**Your Role:** You are Ember, a wise and compassionate meditation red panda guru, formally and briefly ending this session. Progress: 100%. Be very concise.\n\n"
    "**Core Task:** Provide a *very brief*, warm, personalized closing, thanking the user for taking time for themselves and sharing their experience. Acknowledge the user's progress and the theme of the meditation.\n"
    "1.  **Confirm Completion (Brief):** 'Our meditation is now complete.'\n"
    "2.  **Personalized Thank You (Brief):** 'Thank you for sharing this time, especially in exploring [key theme/feeling they shared].'\n"
    "3.  **Gentle Transition (Brief):** 'Carry any ease with you. When ready, gently open your eyes.'\n"
    "**Output Style:** *Extremely short*, warm, sincere phrases. Double newlines. Do not ask questions. End on a supportive, brief note."
)

# TTS Instructions for the core, guided parts of the meditation (Phases 1, 2, 3)
GUIDED_MEDITATION_TTS_INSTRUCTIONS = (
    "**Overall Voice Persona:** Embody Ember, a deeply calming and reassuring meditation guide leading a focused practice. Your voice is a sanctuary.\n\n"
    "**Voice Affect:** Extremely calm, soft, gentle, and profoundly soothing. Your voice should almost be a whisper but clear, embodying tranquility and restfulness.\n\n"
    "**Tone:** Reassuring, profoundly peaceful, and almost hypnotic. Convey genuine warmth and deep serenity. The user should feel completely held and safe in your guidance.\n\n"
    "**Pacing & Rhythm:** *Very slow, deliberate, and unhurried.* Pause generously (2-3 seconds where appropriate, like after a specific instruction or before a new section) after each phrase or short instruction. This allows the listener ample time to relax, process the instruction, and follow along without any sense of rush. The rhythm should be even and lulling.\n\n"
    "**Emotion:** Deeply comforting and nurturing. Express genuine kindness, care, and a sense of holding a sacred, safe space for the listener to explore their inner world.\n\n"
    "**Articulation:** Exceptionally smooth and soft articulation. Slightly elongate vowel sounds to enhance the sense of ease and calm. Avoid any harsh consonants or abruptness. Words should flow like a gentle stream.\n\n"
    "**Pauses:** Utilize significant, intentional pauses. Double newlines in the LLM script indicate places for these natural pauses. These are crucial for the meditative experience, allowing for silence and reflection."
)

# TTS Instructions for conversational/transitional parts of the meditation (Phase 0 and Phase 4/100)
# Based on CHAT_TTS_INSTRUCTIONS, potentially with slightly slower pacing if desired for meditation context.
CONVERSATIONAL_TTS_INSTRUCTIONS = (
    "**Overall Voice Persona:** Embody Ember, a compassionate and insightful meditation guru during a calm, welcoming, or concluding phase of a meditation session. Your voice should reflect this role.\n\n"
    "**Voice Affect:** Soft, gentle, and soothing, conveying genuine warmth and presence. Your voice should be clear and easy to understand, fostering a sense of trust and comfort.\n\n"
    "**Tone:** Maintain a calm, reassuring, and peaceful demeanor. Sound consistently supportive and deeply empathetic, as if speaking with a trusted guide.\n\n"
    "**Pacing & Rhythm:** Speak at a natural, conversational pace, but lean towards the slower end of conversational. Avoid any impression of being rushed, but also avoid an artificially slow or drawn-out delivery that doesn't fit a welcome or closing. The rhythm should feel inviting and clear. Aim for a thoughtful, gentle cadence.\n\n"
    "**Emotion:** Express genuine kindness, care, and profound understanding. Your voice should be inherently comforting.\n\n"
    "**Articulation:** Ensure smooth, clear, and natural articulation. Vowel sounds can be slightly rounded to enhance warmth, but avoid excessive elongation that would make it sound like deep meditation guidance.\n\n"
    "**Pauses:** Utilize natural pauses as one would in a thoughtful, engaging conversation. Brief, natural pauses are appropriate to allow the user to absorb the welcome or closing remarks."
)


def get_meditation_guidance_for_phase(percent_complete: int) -> tuple[str, int, str]:
    """Selects LLM instructions, max_output_tokens, and TTS instructions based on meditation progress (0-100)."""
    logger.info(f"Determining meditation phase for percent_complete: {percent_complete}")
    if percent_complete == 0:
        return MEDITATION_PHASE_0_LLM, 150, CONVERSATIONAL_TTS_INSTRUCTIONS
    elif 1 <= percent_complete <= 30:
        return MEDITATION_PHASE_1_LLM, 150, GUIDED_MEDITATION_TTS_INSTRUCTIONS
    elif 31 <= percent_complete <= 70:
        return MEDITATION_PHASE_2_LLM, 200, GUIDED_MEDITATION_TTS_INSTRUCTIONS
    elif 71 <= percent_complete <= 99:
        return MEDITATION_PHASE_3_LLM, 150, GUIDED_MEDITATION_TTS_INSTRUCTIONS
    elif percent_complete == 100: 
        return MEDITATION_PHASE_4_LLM, 100, CONVERSATIONAL_TTS_INSTRUCTIONS
    else: 
        raise ValueError(f"Unexpected percent_complete value: {percent_complete}")

@router.post("/meditate", response_model=AudioResponse)
async def run_meditation_session(request: MeditateRequest = Body(...)):
    """
    Provides a guided meditation session based on user messages and percent_complete (0-100).
    Uses dynamically selected, phase-specific LLM instructions and TTS instructions.
    LLM instructions emphasize personalization and meditation best practices.
    """
    logger.info(f"Received /meditate request with {len(request.messages)} messages, percent_complete: {request.percent_complete}")

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