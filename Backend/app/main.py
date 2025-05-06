from fastapi import FastAPI, WebSocket
from fastapi.staticfiles import StaticFiles
from fastapi.responses import FileResponse
from app.llm import stream_llm_to_tts
from app.logger import get_logger

app = FastAPI()
logger = get_logger(__name__)

# Mount static files
app.mount("/static", StaticFiles(directory="static"), name="static")

@app.get("/")
async def root():
    logger.info("Serving index.html")
    return FileResponse("static/index.html")

@app.websocket("/ws")
async def websocket_endpoint(ws: WebSocket):
    client_id = id(ws)
    logger.info(f"New WebSocket connection request from client {client_id}")
    
    await ws.accept()
    logger.info(f"WebSocket connection accepted for client {client_id}")
    
    try:
        async for text in ws.iter_text():
            logger.info(f"Received text from client {client_id}: {text[:100]}...")
            try:
                async for chunk in stream_llm_to_tts(text):
                    # Send as binary data
                    await ws.send_bytes(chunk)
                    logger.debug(f"Sent audio chunk to client {client_id} (size: {len(chunk)} bytes)")
            except Exception as e:
                logger.error(f"Error processing text for client {client_id}: {str(e)}")
                await ws.send_text(f"Error: {str(e)}")
    except Exception as e:
        logger.error(f"WebSocket error for client {client_id}: {str(e)}")
    finally:
        logger.info(f"WebSocket connection closed for client {client_id}") 