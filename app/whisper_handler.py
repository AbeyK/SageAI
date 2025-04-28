import openai

async def transcribe_audio(audio_url: str) -> str:
    audio_file = open(audio_url, "rb")
    transcript = openai.Audio.transcribe(
        model="whisper-1",
        file=audio_file,
    )
    return transcript["text"] 