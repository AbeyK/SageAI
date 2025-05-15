from fastapi import FastAPI, Request, status
from fastapi.responses import JSONResponse
from fastapi.exceptions import RequestValidationError
from fastapi.middleware.cors import CORSMiddleware
import logging # Import logging
from app.logging_config import setup_logging # Import setup_logging
from app.routers import chat, meditation_router # Added import

# Configure logging
setup_logging()
logger = logging.getLogger("meditation_app") # Get our configured logger

app = FastAPI(
    title="Meditation Companion API",
    description="API for the voice-to-voice meditation companion app.",
    version="0.1.0",
)

# Add CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Allow all origins for now
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.get("/health", tags=["Health"])
async def health_check():
    """Check the health of the API."""
    return {"status": "ok"}

# Global Exception Handler
@app.exception_handler(Exception)
async def generic_exception_handler(request: Request, exc: Exception):
    # Log the exception for debugging (in a real app, use a proper logger)
    # print(f"Unhandled exception for request {request.url.path}: {exc}")
    logger.error(f"Unhandled exception for request {request.url.path}", exc_info=True)
    return JSONResponse(
        status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
        content={"detail": "An unexpected internal server error occurred."},
    )

# Handler for Pydantic validation errors (optional, but good practice)
@app.exception_handler(RequestValidationError)
async def validation_exception_handler(request: Request, exc: RequestValidationError):
    # Log the validation errors (exc.errors() gives detailed info)
    # print(f"Validation error for request {request.url.path}: {exc.errors()}")
    logger.warning(f"Validation error for request {request.url.path}: {exc.errors()}")
    return JSONResponse(
        status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
        content={"detail": "Validation Error", "errors": exc.errors()},
    )

# Placeholder for future routers
app.include_router(chat.router, prefix="/api/v1")
app.include_router(meditation_router.router, prefix="/api/v1", tags=["meditation"])

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000) 