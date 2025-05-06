from fastapi import FastAPI, WebSocket, WebSocketDisconnect
from fastapi.staticfiles import StaticFiles
from fastapi.responses import FileResponse
import json
import time
import os
from dotenv import load_dotenv
from app.services.meditation_service import MeditationService
from app.logger import get_logger

# Load environment variables
load_dotenv()

# Verify OpenAI API key is set
if not os.getenv("OPENAI_API_KEY"):
    raise ValueError("OPENAI_API_KEY environment variable is not set")

app = FastAPI()
logger = get_logger(__name__)
meditation_service = MeditationService()

# Mount static files
app.mount("/static", StaticFiles(directory="static"), name="static")

@app.get("/")
async def read_root():
    logger.info("Serving index.html")
    return FileResponse("static/index.html")

@app.websocket("/ws")
async def websocket_endpoint(websocket: WebSocket):
    await websocket.accept()
    logger.info("WebSocket connection accepted")
    
    try:
        while True:
            try:
                request_start = time.time()
                data = await websocket.receive_text()
                receive_time = time.time() - request_start
                
                message = json.loads(data)
                
                if message.get("type") == "text":
                    text = message.get("text", "").strip()
                    if not text:
                        continue
                        
                    logger.info(f"Received text after {receive_time:.2f}s: {text[:100]}...")
                    
                    try:
                        # Process request through meditation service
                        audio_bytes = await meditation_service.process_request(text)
                        
                        # Send response
                        send_start = time.time()
                        await websocket.send_bytes(audio_bytes)
                        send_time = time.time() - send_start
                        
                        total_time = time.time() - request_start
                        logger.info(f"Sent audio response in {send_time:.2f}s - Total request time: {total_time:.2f}s")
                    except Exception as e:
                        error_time = time.time() - request_start
                        logger.error(f"Error processing request after {error_time:.2f}s: {str(e)}")
                        await websocket.send_text(f"Error: {str(e)}")
                    
            except json.JSONDecodeError:
                logger.error("Invalid JSON received")
                continue
                
    except WebSocketDisconnect:
        logger.info("WebSocket disconnected")
    except Exception as e:
        logger.error(f"Error in WebSocket: {str(e)}") 