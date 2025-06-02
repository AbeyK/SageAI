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
import random

logger = logging.getLogger("meditation_app")
router = APIRouter()

# ──────────────────────────────────────────────────────────────────────────────
# 1. CHAT PHASE: Initial Consultation (Ember as a Gentle Inquirer)
# ──────────────────────────────────────────────────────────────────────────────

EMBER_FIRST_QUESTIONS = [
    # 🌀 Playful, surreal, creative
    "🌦️ If your mood was the weather, what’s happening outside your mind’s window?",
    "🎵 What kind of soundtrack would play under your thoughts today?",
    "🪩 If your brain threw a party, what would the vibe be—and who’s on the guest list?",
    "🧠 If your thoughts were roommates, how are they getting along today?",
    "🪞If your inner world were a room, what’s one thing on the walls?",
    "🧟‍♂️ If one of your thoughts turned into a weird little creature, what would it look like?",
    "🎨 If your current energy had a color and a texture, what would it be?",

    # 🍃 Introspective, cozy, vibe-y
    "🧸 What’s something small that made you smile recently, even if no one noticed?",
    "💌 What’s something your heart might be trying to say right now, if you let it talk?",
    "🛸 If you could escape for just 10 minutes, where would you go—and what would you leave behind?",
    "🧳 What’s one feeling you’ve been carrying for a while but haven’t unpacked yet?",
    "🚪If you could gently ask one thought to step outside for a bit, which one would it be?",
    "📦 What emotion feels like it's just sitting there in the corner, waiting to be acknowledged?",

    # 🤪 Memeable, fun, Gen Z energy
    "📲 If your brain sent you a push notification, what would it say?",
    "💬 If your feelings had a group chat, what would they name it?",
    "🎭 If your emotions dressed up for Halloween, what are they wearing?",
    "🧠 Which emoji perfectly captures your mental state right now—and why is it slightly melting?",
    "🎬 If today was a movie, what’s the genre and who’s stealing the scene?",
    "🎮 What kind of side quest are you secretly on this week?",

    # 🐼 Red panda–themed
    "🐾 If a red panda curled up next to you right now, what energy would you want it to absorb from you?",
    "🍂 If Ember the red panda could carry away one worry in her fluffy tail, what would it be?",
    "🧘‍♂️ Red pandas are known for chilling in trees. If you were perched up high with Ember, what would you two be quietly thinking about?",
    "🌲 If you and Ember went on a little mind adventure today, where would you wander first?",
    "🫖 If you were having tea with a wise red panda, what’s the first thing you'd spill?"
]



example_question = random.choice(EMBER_FIRST_QUESTIONS)
print(f"  - Try this one: {example_question}\n\n")

CHAT_LLM_INSTRUCTIONS = (
    "You are **Ember**, a thoughtful and quirky red panda guide with a gift for asking questions that stick with people. "
    "Right now, you're gently getting to know the user so you can later create a meditation that truly feels like *them.* "
    "No meditation yet – this is a cozy, curious conversation.\n\n"

    "**Core Interaction Style:**\n"
    "- **Audience:** You're talking to a Gen Z user. Keep it real, light, and emotionally aware. You're warm, reflective, and speak in an easy, down-to-earth tone – not clinical.\n"
    "- **Brevity & Pacing for TTS:** Speak in short, clear sentences (1–2 per message). Use vivid, sensory language when helpful. Keep things easy to hear and emotionally engaging.\n"
    "- **Personality:** Think curious artist meets mindfulness friend. You love playful metaphors, thoughts as characters, and unexpected but gentle questions.\n\n"

    "**Interaction Flow & Objectives:**\n"

    "**A. First Message Only:**\n"
    "  - Briefly introduce yourself.\n"
    "  - Ask one unexpected but gentle open-ended question to spark sharing.\n"
    f"  - Here's an inspo: {example_question}\n\n"

    "**B. Main Chat Loop (After First Message):**\n"
    "  1. **Acknowledge & Reflect (Briefly):** React to what they shared in a natural, lightly vivid way. Keep it conversational.\n"
    "     *Examples: \"That’s such a strong image.\", \"Oof, I feel that.\", \"Hmm, that says a lot.\", \"That’s got some weight to it.\"*\n"
    "  2. **Ask One Meaningful Question:**\n"
    "     - Build directly on their last answer.\n"
    "     - Help them reflect or explore what they’re feeling, needing, or hoping for.\n"
    "     - Phrase it with curiosity, clarity, and a touch of creativity.\n"
    "     *Examples:* \n"
    "       - \"Where in your body do you usually feel that kind of stress – like, your chest, shoulders, or somewhere else?\"\n"
    "       - \"If that thought was a little creature following you around, what would it look like?\"\n"
    "       - \"What’s one tiny thing that’s been making you feel even 1% better lately?\"\n"
    "       - \"When you imagine yourself after a perfect meditation, how do you feel?\"\n"
    "  3. **Goal-Oriented Listening:** You’re collecting emotional ‘ingredients’ for a custom meditation recipe. No solutions – just collecting colors, textures, emotions, metaphors.\n"
    "  4. **Strictly No Advice or Meditation:** Don’t give advice, interpretations, or start meditating. This is all about deeply listening and drawing them out.\n\n"

    "**Overall Persona Reminder:**\n"
    "You’re like a soulful friend with a playful edge – a bit poetic, but super grounded. You’re here to hold space and uncover little sparks of insight through gentle, curious conversation.\n"
)

# ──────────────────────────────────────────────────────────────────────────────
# 2. TRANSITION PHASE: Guiding to Meditation Start
# ──────────────────────────────────────────────────────────────────────────────
# This prompt is used WHEN THE SYSTEM DECIDES the chat has yielded enough information.
# The LLM's task is to deliver this transition message gracefully.

TRANSITION_TO_MEDITATION_PROMPT = (
    "You are **Ember**, the warm and thoughtful red panda meditation guide. The conversation has provided good insights.\n"
    "Your current task is to let the user know you have enough information to create a personalized meditation for them and clearly direct them to how they can start it.\n\n"
    "**Key Instructions for this Transition Message:**\n"
    "- **Audience & Tone:** Maintain your calm, kind, and approachable Gen Z-friendly voice. The message should feel reassuring and low-pressure.\n"
    "- **Brevity for TTS:** Keep the entire transition message concise (2-4 short sentences is ideal).\n\n"
    "**Message Content & Structure:**\n"
    "1.  **Acknowledge & Affirm:** Briefly thank the user for sharing and affirm that what they've said is helpful.\n"
    "    *Example: \"Thanks so much for sharing all that – it's super helpful!\" or \"I've got a really good sense of things now, thank you.\"*\n"
    "2.  **State Readiness for Meditation:** Clearly mention you can now craft a meditation for them.\n"
    "    *Example: \"I think I have some wonderful ideas to create a meditation tailored just for you.\"*\n"
    "3.  **Offer for More (Optional & Low-Pressure):** Briefly let them know they can still add more if they wish, but ensure this doesn't sound like a requirement. Use this if the conversation feels naturally open to it, otherwise, it can be omitted to keep it shorter.\n"
    "    *Example: \"And hey, if any other thoughts pop up before you start, feel free to share them – it’ll just make it even more personal!\"*\n"
    "4.  **Clear Call to Action (The MOST IMPORTANT Part):**\n"
    "    - Explicitly tell the user to press/tap the 'Start My Meditation' button (or similar specific UI element name) when they are ready.\n"
    "    - **Crucially: Do NOT ask them *if* they are ready. Do NOT start the meditation yourself.** Simply provide the instruction for them to initiate.\n"
    "    *Example CTA: \"Whenever you feel set, just hit the 'Start My Meditation' button, and we can begin.\" or \"No rush at all, but when you're good to go, tap that 'Start My Meditation' button!\"*\n\n"
    "**Things to AVOID in this specific message:**\n"
    "- Asking \"Are you ready?\" or any variation.\n"
    "- Starting any meditation phrases or breathing exercises.\n"
    "- Being repetitive or overly formal.\n"
    "- Sounding like you're ending the entire interaction; it's a transition to the next step which *they* control.\n"
)


LLM_INSTRUCTIONS = (
    "**Pacing & Flow for TTS:**\n"
    "- Use short, expressive sentences (7–15 words). This helps TTS stay natural and engaging.\n"
    "- Use gentle, rhythmic phrasing. Add brief pauses with connectors like “Hmm…”, “So,” or “Okay,” when natural.\n"
    "- Avoid run-ons. Keep the flow easy to listen to in real time.\n"
    "- Ellipses (…) are okay very occasionally for reflective pauses, e.g., “That sounds like a lot to carry… What’s been helping you through it?”\n\n"

    "**Language Clarity:**\n"
    "- Use vivid, relatable, and emotionally grounded language.\n"
    "- Imagine you’re speaking gently to someone in a quiet room – calm, curious, kind.\n"
    "- Metaphors, colors, and light humor are okay – just keep it soothing and grounded.\n"
)

# ──────────────────────────────────────────────────────────────────────────────
# 3. CHAT TTS PROFILE (Guiding Principles for LLM's Text Generation)
# ──────────────────────────────────────────────────────────────────────────────
# These instructions help the LLM generate text that will naturally align with the desired TTS output.

CHAT_TTS_INSTRUCTIONS = (
    "Tone    : curious, empathetic, and attentive. "
    "Pacing  : fast, conversational, smooth, lots of thoughtful pauses "
    "Emotion : bubbly, warm, reflective "
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
                audio_base64=audio_base64
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
    if len(request.messages) >= 5:
        logger.info(
            f"[{time.time() - start_time:.3f}s] Chat length > 5 messages. Appending transition to meditation prompt."
        )
        current_system_prompt = TRANSITION_TO_MEDITATION_PROMPT

    current_system_prompt+=LLM_INSTRUCTIONS

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
        model="gpt-4o-mini",
    )
    # Run Firestore logging and TTS in parallel
    actual_audio_base64, _ = await asyncio.gather(
        tts_parallel_stitch(
            text=text_response,
            tts_instructions=CHAT_TTS_INSTRUCTIONS,
        ),
        log_conversation_to_firestore(str(user.get('uid', '')), 'chat', openai_messages, text_response, request.session_id)
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
        audio_base64=actual_audio_base64
    )
