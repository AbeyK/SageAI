import pytest
from app.whisper_handler import transcribe_audio

@pytest.mark.asyncio
async def test_transcribe_audio():
    result = await transcribe_audio("sample_audio.wav")
    assert isinstance(result, str)
    assert len(result) > 0 