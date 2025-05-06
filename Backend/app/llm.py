import os
from dotenv import load_dotenv
import openai
import aiohttp
import asyncio
import base64
import re
from app.logger import get_logger

# Load environment variables from .env file
load_dotenv()

logger = get_logger(__name__)
client = openai.OpenAI(api_key=os.getenv("OPENAI_API_KEY"))

def split_into_sentences(text):
    # Simple regex-based sentence splitter
    sentences = re.split(r'(?<=[.!?])\s+', text)
    return [s.strip() for s in sentences if s.strip()]

async def stream_llm_to_tts(user_text: str):
    logger.info(f"Starting LLM stream for text: {user_text[:100]}...")
    
    try:
        stream = client.chat.completions.create(
            model="gpt-4",
            messages=[
                {"role": "system",
                 "content": "You are Sage, a calm meditation guide."},
                {"role": "user", "content": user_text},
            ],
            stream=True,
        )
        logger.info("LLM stream started successfully")

        current_sentence = ""
        sentence_count = 0
        
        for chunk in stream:
            if chunk.choices[0].delta.content is None:
                continue
                
            text = chunk.choices[0].delta.content
            current_sentence += text
            sentences = split_into_sentences(current_sentence)
            
            if len(sentences) > 1:
                logger.debug(f"Processing {len(sentences)-1} complete sentences")
                for sentence in sentences[:-1]:
                    sentence_count += 1
                    logger.info(f"Processing sentence {sentence_count}: {sentence[:100]}...")
                    async for audio in tts_stream(sentence):
                        yield audio
                current_sentence = sentences[-1]
        
        if current_sentence.strip():
            sentence_count += 1
            logger.info(f"Processing final sentence {sentence_count}: {current_sentence[:100]}...")
            async for audio in tts_stream(current_sentence):
                yield audio
                
        logger.info(f"Completed LLM stream with {sentence_count} sentences")
        
    except Exception as e:
        logger.error(f"Error in LLM stream: {str(e)}")
        raise

async def tts_stream(text: str):
    text = text.strip()
    if not text:
        logger.warning("Empty text received for TTS")
        return
    
    max_chunk_size = 500
    if len(text) > max_chunk_size:
        chunks = [text[i:i+max_chunk_size] for i in range(0, len(text), max_chunk_size)]
        logger.info(f"Split text into {len(chunks)} chunks for TTS")
    else:
        chunks = [text]
    
    for i, chunk in enumerate(chunks, 1):
        try:
            logger.info(f"Requesting TTS for chunk {i}/{len(chunks)}")
            response = client.audio.speech.create(
                model="tts-1",
                voice="alloy",
                input=chunk,
                response_format="wav"
            )
            
            # Read the response content
            audio_bytes = response.content
            logger.debug(f"Received audio chunk {i} (size: {len(audio_bytes)} bytes)")
            
            # Convert to bytes if needed
            if isinstance(audio_bytes, str):
                audio_bytes = audio_bytes.encode('utf-8')
            
            yield audio_bytes
            
        except Exception as e:
            logger.error(f"Error in TTS stream for chunk {i}: {str(e)}")
            raise 