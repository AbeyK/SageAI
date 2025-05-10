# Sage AI REST Backend

A FastAPI-based REST backend service that integrates with OpenAI's API to provide text-to-speech and chat completion capabilities.

## Features

- Text-to-Speech (TTS) using OpenAI's TTS API
- Chat completions using OpenAI's GPT models
- Asynchronous API endpoints for better performance
- Environment-based configuration
- Secure API key management

## Prerequisites

- Python 3.8 or higher
- OpenAI API key
- Virtual environment (recommended)

## Installation

1. Clone the repository:
```bash
git clone https://github.com/yourusername/sage-ai-rest-backend.git
cd sage-ai-rest-backend
```

2. Create and activate a virtual environment:
```bash
# On macOS/Linux
python -m venv venv
source venv/bin/activate

# On Windows
python -m venv venv
.\venv\Scripts\activate
```

3. Install dependencies:
```bash
pip install -r requirements.txt
```

4. Create a `.env` file in the root directory with your OpenAI API key:
```env
OPENAI_API_KEY=your_api_key_here
```

## Project Structure

```
sage-ai-rest-backend/
├── app/
│   ├── services/
│   │   └── openai_service.py    # OpenAI API integration
│   ├── config.py               # Configuration settings
│   └── main.py                 # FastAPI application
├── .env                        # Environment variables
├── .gitignore                 # Git ignore file
├── README.md                  # This file
└── requirements.txt           # Project dependencies
```

## Usage

1. Start the server:
```bash
uvicorn app.main:app --reload
```

The server will start at `http://localhost:8000`

2. API Endpoints:

### Text-to-Speech
```http
POST /api/v1/tts
Content-Type: application/json

{
    "text": "Text to convert to speech",
    "model": "tts-1-hd",
    "voice": "alloy"
}
```

### Chat Completion
```http
POST /api/v1/chat
Content-Type: application/json

{
    "messages": [
        {
            "role": "user",
            "content": "Your message here"
        }
    ],
    "model": "gpt-4"
}
```

## API Documentation

Once the server is running, you can access the interactive API documentation at:
- Swagger UI: `http://localhost:8000/docs`
- ReDoc: `http://localhost:8000/redoc`

## Development

### Running Tests
```bash
pytest
```

### Code Style
This project follows PEP 8 style guidelines. You can check your code style using:
```bash
flake8
```

## Environment Variables

| Variable | Description | Required |
|----------|-------------|----------|
| OPENAI_API_KEY | Your OpenAI API key | Yes |

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgments

- OpenAI for providing the API
- FastAPI for the web framework
- All contributors who have helped with the project 