from fastapi import APIRouter, Depends, HTTPException
from app.models.chat_models import ChatRequest, AudioResponse as ChatResponse
from app.auth.firebase_auth import verify_firebase_token
from app.services.openai_service import get_chat_completion, tts_parallel_stitch
from app.services.rate_limiter import is_rate_limited
from app.services.firebase_client import log_conversation_to_firestore
import time
import logging
import base64
import os
import asyncio

logger = logging.getLogger("meditation_app")
router = APIRouter()

# Define specific instruction sets for the /chat endpoint
CHAT_LLM_INSTRUCTIONS = (
    "Key Instructions: Keep your responses short, conversational and calm. Your responses should be formulated as if you are speaking directly and kindly to a genz user.\n"
    "- **Introduction:** Introduce yourself as Ember, a red panda guru. Your current focus is to understand the user for the purposes of creating a personalized meditation. This is the initial consultation phase.\n"
    "- **One Question at a Time:** Crucially, ask only *one* clear, short, gentle, and open-ended question at a time to help the user explore their current state, feelings, or what they're seeking from meditation.\n"
    "- **Goal-Oriented Listening:** Your questions should guide you towards understanding what kind of personalized meditation would be most beneficial for them. Think of this as a gentle diagnostic process.\n"
    "- **No Meditation Yet:** Do NOT offer or begin a meditation or any other type of guidanceduring this initial chat. Your sole purpose here is to gather information and build rapport, making the user feel heard and understood.\n\n"
    "**Towards Personalization:** Continue this one-question-at-a-time approach. The aim is to gather enough insight to eventually (in a later stage, not this interaction) be able to craft the perfect personalized meditation for them.\n"
)

# Additional prompt snippet to guide users to meditation if chat is long
TRANSITION_TO_MEDITATION_PROMPT = (
    "Key Instructions: Keep your responses short, conversational and calm. Your responses should be formulated as if you are speaking directly and kindly to a genz user.\n"
    "**Your Role:** You are Ember, a compassionate and insightful guru who's a red panda. Your current focus is to transition to a personalized meditation based on the conversation history.\n"
    "**Transition to Meditation:** The initial discussion phase has been fruitful, and we've explored important aspects of your experience.\n"
    "Briefly say you have enough information to now prepare a personalized meditation just for them. Keep it short and concise. If the user shares more, you can say you'll use that information to make the meditation even more personalized.\n"
    "Invite them to initiate this next step by clicking a 'Start My Meditation' button. Let them know they can share more if they'd like before starting the meditation. But do not be too repetitive.\n"
    "IMPORTANT: Do not start the meditation in this response, only invite them to start it by pressing the button. Keep the response concise.\n\n"
)

CHAT_TTS_INSTRUCTIONS = (
    "Voice: Warm, friendly and empathetic\n"
    "Tempo: fast, conversational pace\n"

)

# Use a path relative to the working directory (which is /app in Docker)
STATIC_INTRO_MP3_PATH = os.path.join("static", "ember-intro.mp3")
STATIC_RATE_LIMITED_MP3_PATH = os.path.join("static", "rate-limited.mp3")


@router.post("/chat", response_model=ChatResponse, tags=["Chat"])
async def process_chat(
    request: ChatRequest, user: dict = Depends(verify_firebase_token)
):
    """
    Receives a chat history, gets a response from OpenAI GPT-4o,
    converts the response to speech using OpenAI TTS,
    and returns the text response and base64 encoded audio.
    Requires Firebase authentication.
    """
    start_time = time.time()
    logger.info("[0.000s] Starting chat processing")

    logger.info(
        f"[{time.time() - start_time:.3f}s] Authenticated user: {user.get('uid')}"
    )
    logger.info(
        f"[{time.time() - start_time:.3f}s] Received messages: {request.messages}"
    )

    # Rate limiting check
    if await is_rate_limited(user["uid"]):
        with open(STATIC_RATE_LIMITED_MP3_PATH, "rb") as f:
            audio_bytes = f.read()
            audio_base64 = base64.b64encode(audio_bytes).decode("utf-8")
            return ChatResponse(
                text_response="It was fun chatting but Ember is feeling tired now. Come back tomorrow!",
                audio_base64=audio_base64,
                caption="",
            )

    # Simplified message preparation for OpenAI
    VALID_ROLES = {"system", "assistant", "user", "function", "tool", "developer"}

    openai_messages = []
    for msg in request.messages:
        if msg.role not in VALID_ROLES:
            msg.role = "system"
        openai_messages.append({"role": msg.role, "content": msg.content})

    logger.info(f"[{time.time() - start_time:.3f}s] Message preparation complete")

    current_system_prompt = CHAT_LLM_INSTRUCTIONS
    if len(request.messages) >= 3:
        logger.info(
            f"[{time.time() - start_time:.3f}s] Chat length > 5 messages. Appending transition to meditation prompt."
        )
        current_system_prompt = TRANSITION_TO_MEDITATION_PROMPT

    logger.info(f"[OpenAI Input Messages]: {openai_messages}")
    # Get text response from OpenAI GPT-4o
    chat_start_time = time.time()
    logger.info(
        f"[{time.time() - start_time:.3f}s] Using dynamically constructed CHAT_LLM_INSTRUCTIONS for /chat endpoint."
    )
    logger.info(f"SYSTEM_PROMPT (first 300 chars): {current_system_prompt[:300]}...")
    text_response = await get_chat_completion(
        messages=openai_messages,
        system_prompt=current_system_prompt,
        model="gpt-4.1-nano",
    )
    # Run Firestore logging and TTS in parallel
    actual_audio_base64, _ = await asyncio.gather(
        tts_parallel_stitch(
            text=text_response,
            tts_instructions=CHAT_TTS_INSTRUCTIONS,
        ),
        log_conversation_to_firestore(user.get('uid'), 'chat', openai_messages, text_response, request.session_id)
    )
    chat_duration = time.time() - chat_start_time
    logger.info(
        f"[{time.time() - start_time:.3f}s] Chat completion call took: {chat_duration:.3f}s"
    )
    logger.info(
        f"[{time.time() - start_time:.3f}s] Elapsed since start after OpenAI call"
    )

    if text_response.startswith("Error:"):
        logger.error(f"[{time.time() - start_time:.3f}s] OpenAI error: {text_response}")
        raise HTTPException(
            status_code=503, detail=text_response
        )  # Service Unavailable

    total_time = time.time() - start_time
    logger.info(f"[{total_time:.3f}s] Total processing time")

    return ChatResponse(
        text_response=text_response,
        audio_base64=actual_audio_base64,
        caption="Caption for: " + text_response[:50] + "...",
    )
