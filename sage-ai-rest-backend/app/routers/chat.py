from fastapi import APIRouter, Depends, HTTPException
from app.models import ChatRequest, ChatResponse, ChatMessage
from app.auth.firebase_auth import verify_firebase_token
from app.services.openai_service import get_chat_completion, text_to_speech_openai
from typing import List

router = APIRouter()

@router.post("/chat", response_model=ChatResponse, tags=["Chat"])
async def process_chat(request: ChatRequest, user: dict = Depends(verify_firebase_token)):
    """
    Receives a chat history, gets a response from OpenAI GPT-4o,
    converts the response to speech using OpenAI TTS,
    and returns the text response and base64 encoded audio.
    Requires Firebase authentication.
    """
    print(f"Authenticated user: {user.get('uid')}")
    print(f"Received messages: {request.messages}")

    # Convert Pydantic models to list of dicts for OpenAI API
    # Also add the system prompt if it's not already there or to reinforce it.
    # For MVP, client sends full history. We might add a system prompt here.
    # A more robust solution would involve checking if a system prompt of a certain kind exists.
    
    # Simplified message preparation for OpenAI
    openai_messages = []
    has_system_message = any(msg.role == "system" for msg in request.messages)

    # Add a default system message if none is provided by the client
    # This can be customized based on the meditation app's persona
    if not has_system_message:
        openai_messages.append({"role": "system", "content": "You are a calm and empathetic meditation assistant. Respond in a soothing and supportive tone. Keep responses concise, typically 1-2 sentences, unless more detail is needed for guidance."})
    
    for msg in request.messages:
        openai_messages.append({"role": msg.role, "content": msg.content})

    # Get text response from OpenAI GPT-4o
    text_response = await get_chat_completion(messages=openai_messages)

    if text_response.startswith("Error:"):
        # Handle cases where OpenAI call failed (e.g., API key issue, network error)
        # For now, we can raise an HTTPException or return a modified ChatResponse
        # depending on how we want the client to handle this.
        # Raising an HTTPException might be cleaner for distinct error states.
        raise HTTPException(status_code=503, detail=text_response) # Service Unavailable

    # Generate audio from the text response
    actual_audio_base64 = await text_to_speech_openai(text=text_response)

    if actual_audio_base64.startswith("Error:"):
        # Handle TTS errors. For now, we can send the text response with a note about audio failure,
        # or raise another HTTPException. Let's opt for returning text with an error indication for audio.
        # A more robust solution might involve a specific error code or field in the response.
        print(f"TTS generation failed: {actual_audio_base64}")
        # Fallback: return text_response with an empty/error audio and a relevant caption.
        return ChatResponse(
            text_response=text_response,
            audio_base64="", # Indicate audio failure
            caption=f"Audio generation failed. Displaying text only: {text_response[:50]}..."
        )

    return ChatResponse(
        text_response=text_response,
        audio_base64=actual_audio_base64,
        caption="Caption for: " + text_response[:50] + "..." 
    ) 