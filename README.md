# SageAI Meditation Backend

A FastAPI backend for a meditation application that utilizes:
- OpenAI Whisper for speech-to-text
- GPT-4o for generating meditation content
- OpenAI TTS for text-to-speech

## Setup

1. Install dependencies:
```
pip install -r requirements.txt
```

2. Set your OpenAI API key:
```
export OPENAI_API_KEY=your_api_key_here
```

## Running the Application

Start the server:
```
uvicorn app.main:app --reload
```

The application will be available at http://localhost:8000

## API Endpoints

- **POST /transcribe**: Upload audio, get transcribed text
- **POST /generate**: Send text, get meditation guidance
- **POST /speak**: Send text, get audio response

## Testing

Run the tests:
```
pytest
```

## Docker

Build and run with Docker:
```
docker build -t sage-meditation-app .
docker run -p 8000:8000 -e OPENAI_API_KEY=your_api_key_here sage-meditation-app
``` 