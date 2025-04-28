import openai

async def text_to_speech(text_input: str) -> bytes:
    response = openai.Audio.speech.create(
        model="tts-1",
        voice="nova",  # You can change voice
        input=text_input
    )
    return response.content 