from fastapi import FastAPI, UploadFile, File
from app.whisper_handler import transcribe_audio
from app.gpt_handler import generate_meditation
from app.tts_handler import text_to_speech
from app.models import TextInput, TextOutput
from fastapi.responses import StreamingResponse

app = FastAPI()

@app.post("/transcribe", response_model=TextOutput)
async def transcribe(audio: UploadFile = File(...)):
    with open(f"/tmp/{audio.filename}", "wb") as f:
        f.write(await audio.read())
    text = await transcribe_audio(f"/tmp/{audio.filename}")
    return {"text": text}

@app.post("/generate", response_model=TextOutput)
async def generate(input: TextInput):
    meditation_text = await generate_meditation(input.text)
    return {"text": meditation_text}

@app.post("/speak")
async def speak(input: TextInput):
    audio_content = await text_to_speech(input.text)
    return StreamingResponse(iter([audio_content]), media_type="audio/mpeg") 