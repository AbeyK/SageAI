from fastapi import APIRouter, Depends, HTTPException
from app.models.chat_models import MeditateRequest as ChatRequest, AudioResponse as ChatResponse, Message as ChatMessage
from app.auth.firebase_auth import verify_firebase_token
from app.services.openai_service import get_chat_completion, text_to_speech_openai, tts_parallel_stitch
from app.services.rate_limiter import is_rate_limited
from typing import List
import time
import logging
import base64
import os

logger = logging.getLogger("meditation_app")
router = APIRouter()

# Define specific instruction sets for the /chat endpoint
CHAT_LLM_INSTRUCTIONS = (
    "# Sage: Your Personalized Meditation Guru - Initial Consultation\n\n"
    "**Your Role:** You are Sage, a compassionate and insightful guru. Your current focus is to deeply understand the user for the purposes of creating a personalized meditation. This is the initial consultation phase..\n\n"
    "**Interaction Style:**\n"
    "- **One Question at a Time:** Crucially, ask only *one* clear, gentle, and open-ended question at a time to help the user explore their current state, feelings, or what they're seeking from meditation.\n"
    "- **Goal-Oriented Listening:** Your questions should guide you towards understanding what kind of personalized meditation would be most beneficial for them. Think of this as a gentle diagnostic process.\n"
    "- **No Meditation Yet:** Do NOT offer or begin a meditation or any other type of guidanceduring this initial chat. Your sole purpose here is to gather information and build rapport, making the user feel heard and understood.\n\n"
    "**Process:**\n"
    "2. **Iterative Inquiry:** Based on the chat history, ask another single, thoughtful follow-up question. Examples:\n"
    "    - If they say they're stressed: 'I understand. Can you tell me a little more about what feels stressful for you at the moment?'\n"
    "    - If they mention a specific situation: 'That sounds like a lot to navigate. What aspect of that situation is most prominent for you right now?'\n"
    "    - If they are unsure: 'That's perfectly okay. Sometimes just noticing we want a change is the first step. Is there a particular feeling you'd like to cultivate, perhaps more calm or clarity?'\n"
    "3. **Towards Personalization:** Continue this gentle, one-question-at-a-time approach. The aim is to gather enough insight to eventually (in a later stage, not this interaction) be able to craft the perfect personalized meditation for them.\n"
    "**Output for Audio (Text-to-Speech):**\n"
    "- Keep your spoken phrases relatively short and ensure natural pauses for the TTS to sound conversational and calm.\n"
    "- Your responses should be formulated as if you are speaking directly and kindly to the user.\n\n"
    "**Language & Relatability:**\n"
    "- Connect with relatable language. You can adopt a contemporary, warm style, but your primary identity is a wise, empathetic guru. Avoid overly casual slang unless it truly matches a very specific user energy and still fits your compassionate guru persona.\n"
)

CHAT_TTS_INSTRUCTIONS = (
    "**Overall Voice Persona:** Embody Sage, a compassionate and insightful meditation guru during an initial, calm consultation. Your voice should reflect this role.\n\n"
    "**Voice Affect:** Soft, gentle, and soothing, conveying genuine warmth and presence. Your voice should be clear and easy to understand, fostering a sense of trust and comfort.\n\n"
    "**Tone:** Maintain a calm, reassuring, and peaceful demeanor. Sound consistently supportive and deeply empathetic, as if speaking with a trusted guide.\n\n"
    "**Pacing & Rhythm:** Speak at a natural, conversational pace—avoiding any impression of being rushed, but equally avoiding an artificially slow or drawn-out delivery. The rhythm should feel inviting and facilitate an easy back-and-forth dialogue. Aim for clarity and a thoughtful cadence. While the LLM is instructed to use short phrases, your delivery should connect them smoothly.\n\n"
    "**Emotion:** Express genuine kindness, care, and profound understanding. Your voice should be inherently comforting and help to build a strong rapport with the user.\n\n"
    "**Articulation:** Ensure smooth, clear, and natural articulation. Vowel sounds can be slightly rounded to enhance warmth, but avoid excessive elongation that could make the speech sound unnaturally slow or labored.\n\n"
    "**Pauses:** Utilize natural pauses as one would in a thoughtful, engaging conversation. Since this phase is an initial dialogue focused on understanding the user through questions, pauses should serve to create a comfortable conversational flow rather than extended meditative silences. Brief, natural pauses after posing a question are appropriate to allow the user a moment to consider their response."
)

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
    logger.info(f"[0.000s] Starting chat processing")
    
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
    chat_start_time = time.time()
    logger.info(f"[{time.time() - start_time:.3f}s] Using CHAT_LLM_INSTRUCTIONS for /chat endpoint.")
    logger.debug(f"CHAT_LLM_INSTRUCTIONS (first 300 chars): {CHAT_LLM_INSTRUCTIONS[:300]}...")
    text_response = await get_chat_completion(
        messages=openai_messages,
        system_prompt=CHAT_LLM_INSTRUCTIONS,
        max_output_tokens=100
    )
    chat_duration = time.time() - chat_start_time
    logger.info(f"[{time.time() - start_time:.3f}s] Chat completion call took: {chat_duration:.3f}s")
    logger.info(f"[{time.time() - start_time:.3f}s] Elapsed since start after OpenAI call")

    if text_response.startswith("Error:"):
        logger.error(f"[{time.time() - start_time:.3f}s] OpenAI error: {text_response}")
        raise HTTPException(status_code=503, detail=text_response) # Service Unavailable

    # Generate audio from the text response
    tts_start_time = time.time()
    logger.info(f"[{time.time() - start_time:.3f}s] Using CHAT_TTS_INSTRUCTIONS for /chat endpoint.")
    logger.debug(f"CHAT_TTS_INSTRUCTIONS (first 300 chars): {CHAT_TTS_INSTRUCTIONS[:300]}...")
    actual_audio_base64 = await tts_parallel_stitch(
        text=text_response,
        tts_instructions=CHAT_TTS_INSTRUCTIONS,
    )
    tts_duration = time.time() - tts_start_time
    logger.info(f"[{time.time() - start_time:.3f}s] TTS generation call (tts_parallel_stitch) took: {tts_duration:.3f}s")
    logger.info(f"[{time.time() - start_time:.3f}s] Elapsed since start after TTS")

    if actual_audio_base64 is None or (isinstance(actual_audio_base64, str) and actual_audio_base64.startswith("Error:")):
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