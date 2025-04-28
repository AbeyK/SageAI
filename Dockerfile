FROM python:3.11-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY app/ app/
COPY tests/ tests/

ENV PYTHONPATH=/app

# Set OpenAI API key as an environment variable
# You should use a more secure way to pass this in production
# This will be overridden by fly secrets
ENV OPENAI_API_KEY=your_openai_api_key_here

# Use port 8080 to match fly.toml configuration
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8080"] 