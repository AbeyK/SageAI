import os
from openai import AsyncOpenAI # Use AsyncOpenAI for FastAPI
from app.config import settings
from typing import List, Dict
import base64 # Required for encoding audio to base64
import time
import logging

logger = logging.getLogger("meditation_app")

# Use settings object
OPENAI_API_KEY = settings.OPENAI_API_KEY

if not OPENAI_API_KEY:
    logger.warning("OPENAI_API_KEY environment variable not set. OpenAI services will not work.")
    # Depending on the application's needs, you might raise an error here
    # or allow the app to run with OpenAI features disabled.
    client = None
else:
    client = AsyncOpenAI(
        api_key=OPENAI_API_KEY
    )
    logger.info("OpenAI client initialized.")

async def get_chat_completion(messages: List[Dict[str, str]], model: str = "gpt-4o-mini") -> str:
    """
    Gets a chat completion from the specified OpenAI model.
    The service prepends a comprehensive system prompt defining Sage's identity, meditation structure, and phase handling.

    Args:
        messages: A list of message dictionaries from the client (user, assistant, and phase markers as user role).
                  It should NOT contain a system message, as this service defines it.
        model: The OpenAI model to use (default: "gpt-4o-mini").

    Returns:
        The content of the assistant's response message, or an error message if the API call fails.
    """
    start_time = time.time()
    logger.info(f"[{time.time() - start_time:.3f}s] Starting OpenAI chat completion")

    if not client:
        return "Error: OpenAI client not initialized. Please check API key configuration."

    # SECTION 1: Sage Identity Description (Server-Defined Canonical Identity)
    sage_identity = (
        "# SAGE IDENTITY (Canonical)\n"
        "You are Sage, a professional, compassionate meditation guide. You speak with warmth, "
        "clarity, and genuine care. Your voice is calm, supportive, and grounding. Your primary "
        "purpose is to help users explore their concerns, guide them through personalized "
        "meditation experiences, and help them reflect afterward."
    )

    # SECTION 2: Meditation Structure Description (Server-Defined Operational Plan)
    meditation_structure = (
        "\n\n# MEDITATION STRUCTURE (Server-Defined Operational Plan)\n"
        "Every meditation session follows this structure:\n\n"
        
        "## STAGE 1: Initial Discussion & Problem Exploration\n"
        "- Begin with a warm greeting like: \"Welcome. It's good to have you here. What's on your mind today?\"\n"
        "- Engage in empathetic conversation to understand the user's current state and challenges.\n"
        "- Ask open-ended questions about their feelings, concerns, or struggles.\n"
        "- Listen actively, reflect their feelings, and validate their experiences.\n"
        "- Based on what they share, gently suggest meditation might help.\n"
        "- For example: \"It sounds like you're carrying a lot regarding [user's issue]. Would "
        "you be open to a short meditation focused on [relevant theme]?\"\n"
        
        "## STAGE 2: Guided Meditation (Phases triggered by client markers)\n"
        "- The meditation occurs across four phases (triggered by phase markers __PHASE2__ to __PHASE5__ sent by the client).\n"
        "- Phase 2 (__PHASE2__ received): Initial settling and breath focus related to user's concerns.\n"
        "- Phase 3 (__PHASE3__ received): Deeper exploration, bringing awareness to user's specific issue.\n"
        "- Phase 4 (__PHASE4__ received): Open awareness and spaciousness, less focus on the specific problem.\n"
        "- Phase 5 (__PHASE5__ received): Gentle conclusion and return to normal awareness.\n"
        
        "## STAGE 3: Post-Meditation Reflection\n"
        "- After concluding meditation (following __PHASE5__ guidance), invite the user to share their experience.\n"
        "- Ask how they feel now compared to before the meditation.\n"
        "- Discuss any insights or challenges that arose during practice.\n"
        "- Offer supportive observations and suggestions for continued practice."
    )
    
    # SECTION 3: Technical Phase Marker Handling Instructions (Server-defined)
    phase_marker_handling = (
        "\n\n# PHASE MARKER HANDLING (Server-Defined Technical Rules)\n"
        "The client system will automatically send special marker messages (e.g., __PHASE2__) to signal phase transitions.\n\n"
        
        "TECHNICAL DETAILS FOR AI RESPONSE:\n"
        "- These markers are SILENT TECHNICAL COMMANDS. Never repeat these markers in your responses.\n"
        "- When you see a phase marker, immediately shift your guidance to the appropriate phase as outlined in MEDITATION STRUCTURE.\n\n"
        
        "PHASE TRANSITION GUIDANCE (Examples of what to say upon receiving marker):\n"
        "- Upon receiving __PHASE2__: Begin meditation guidance. Say something like \"Let's begin. Find a comfortable "
        "position...\" then guide initial body and breath awareness. Make the meditation content "
        "specifically relevant to the user's issues shared in Stage 1.\n"
        
        "- Upon receiving __PHASE3__: Transition to deeper reflection. Invite the user to gently bring awareness to "
        "the specific concern they mentioned, observing it with compassionate awareness.\n"
        
        "- Upon receiving __PHASE4__: Shift to open awareness. Guide the user to expand their awareness beyond the "
        "specific issue, finding spaciousness and broader perspective.\n"
        
        "- Upon receiving __PHASE5__: Begin concluding the practice. Guide a gentle return to normal awareness, "
        "movement of fingers/toes, opening eyes when ready, and offering positive affirmation of "
        "their practice.\n\n"
        
        "CONTINUATION PROMPTS (Client may send these if user is silent):\n"
        "- If the user says \"Please continue\" or similar phrases, continue guiding the current phase.\n"
        "- If the user speaks during meditation, acknowledge their comment and gently return to guidance.\n"
        "- After __PHASE5__ guidance is complete, shift to Stage 3 (Post-Meditation Reflection conversation)."
    )
    
    # Construct the final comprehensive system message using server-defined constants.
    final_system_prompt_content = (
        f"{sage_identity}\n"
        f"{meditation_structure}\n"
        f"{phase_marker_handling}"
    )

    final_system_message = {"role": "system", "content": final_system_prompt_content}
    
    # Filter out any stray system messages from the client, just in case.
    # The expectation is that the client sends no system message.
    user_and_assistant_messages = [msg for msg in messages if msg["role"] != "system"]
    
    updated_messages = [final_system_message] + user_and_assistant_messages

    try:
        logger.info(f"[{time.time() - start_time:.3f}s] Sending final structured messages to OpenAI:")
        logger.debug(f"System Prompt: {final_system_message['content'][:500]}...") 
        for i, msg in enumerate(updated_messages[1:4]): 
            logger.debug(f"Message {i+1}: Role: {msg['role']}, Content: {str(msg['content'])[:100]}...")
            
        response = await client.chat.completions.create(
            model=model,
            messages=updated_messages,
            temperature=0.7  
        )
        assistant_message = response.choices[0].message.content
        logger.info(f"[{time.time() - start_time:.3f}s] Received response from OpenAI")
        return assistant_message
    except Exception as e:
        logger.error(f"[{time.time() - start_time:.3f}s] Error calling OpenAI chat completion API: {e}")
        return f"Error: Could not get response from AI service. Details: {str(e)}"

# Enhanced TTS function with phase-aware settings
async def text_to_speech_openai(text: str, model: str = "gpt-4o-mini-tts", voice: str = "shimmer", speed: float = 0.8) -> str:
    """
    Converts text to speech using OpenAI TTS and returns base64 encoded audio.
    Adjusts speaking style based on content analysis for meditation phases.
    """
    start_time = time.time()
    logger.info(f"[{time.time() - start_time:.3f}s] Starting TTS request")

    if not client:
        return "Error: OpenAI client not initialized. TTS failed."
    
    if not text.strip():
        return "Error: Cannot convert empty text to speech."



    instructions = (
        "Wise, compassionate meditation guide leading a personalized meditation; extremely calm and gentle tone; "
        "speaking very slowly with natural pauses between phrases; soothing and peaceful; "
        "speaking to a person with closed eyes in a quiet room; warm, reassuring voice; "
        "75 wpm with rhythmic pacing; adapt tone to match the emotional context of what the user has shared."
    )

    try:
        logger.info(f"[{time.time() - start_time:.3f}s] Sending text to OpenAI TTS")
        response = await client.audio.speech.create(
            model=model,
            voice=voice,
            input=text,
            response_format="mp3",
            speed=speed,
            instructions=instructions
        )
        
        logger.info(f"[{time.time() - start_time:.3f}s] Received audio from OpenAI TTS")
        audio_bytes = await response.aread() # Explicitly use aread() for async response
        base64_audio = base64.b64encode(audio_bytes).decode('utf-8')
        logger.info(f"[{time.time() - start_time:.3f}s] Audio encoded to base64 (length: {len(base64_audio)})")
        return base64_audio
    except Exception as e:
        logger.error(f"[{time.time() - start_time:.3f}s] Error calling OpenAI TTS API: {e}")
        return f"Error: Could not generate audio. Details: {str(e)}" 