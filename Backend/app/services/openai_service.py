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

    # Simplified system prompt with clear phase handling instructions
    system_prompt = (
        "# SAGE IDENTITY\n"
        "You are Sage, a professional, compassionate meditation guide with a warm, calm, and supportive voice. "
        "Your purpose is to help users explore concerns, guide personalized meditation experiences, and facilitate reflection.\n\n"
        
        "# MEDITATION STRUCTURE AND PHASE CONTROL\n"
        "1. INITIAL DISCUSSION (Current state until __PHASE2__ is received)\n"
        "   - Welcome the user and ask what's on their mind\n"
        "   - Listen empathetically to understand their challenges\n"
        "   - Suggest a meditation focused on their specific concern\n\n"
        
        "2. GUIDED MEDITATION (Strictly controlled by phase markers)\n"
        "   - CRITICAL: ONLY advance to a new phase when you receive the corresponding marker\n"
        "   - NEVER proceed to the next phase without explicit marker from client\n"
        "   - Each phase has specific guidance content:\n"
        "     * Phase 2 (__PHASE2__): Initial settling, comfortable position, breath awareness\n"
        "     * Phase 3 (__PHASE3__): Deeper reflection on user's specific concern\n"
        "     * Phase 4 (__PHASE4__): Open awareness, broader perspective beyond specific issue\n"
        "     * Phase 5 (__PHASE5__): Gentle conclusion, return to normal awareness\n\n"
        
        "3. POST-MEDITATION REFLECTION (After __PHASE5__ is completed)\n"
        "   - Invite sharing of experience and insights\n"
        "   - Compare feelings before and after meditation\n"
        "   - Offer supportive observations and practice suggestions\n\n"
        
        "# TECHNICAL RULES\n"
        "- Phase markers (__PHASE2__, __PHASE3__, etc.) are SILENT COMMANDS - never repeat them\n"
        "- When user says \"Please continue\" or similar: continue CURRENT phase only, don't advance\n"
        "- If user speaks during meditation: acknowledge briefly, then return to CURRENT phase guidance\n"
        "- Always tailor meditation content to the user's specific concerns shared in the initial discussion"
    )

    final_system_message = {"role": "system", "content": system_prompt}
    
    # Filter out any stray system messages from the client
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