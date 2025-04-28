FROM python:3.9-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY app/ app/
COPY tests/ tests/

ENV PYTHONPATH=/app

# Set OpenAI API key as an environment variable
# You should use a more secure way to pass this in production
ENV OPENAI_API_KEY=your_openai_api_key_here

CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"] 