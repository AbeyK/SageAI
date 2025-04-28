import pytest
from app.tts_handler import text_to_speech

@pytest.mark.asyncio
async def test_text_to_speech():
    result = await text_to_speech("Breathe deeply and relax.")
    assert isinstance(result, bytes)
    assert len(result) > 1000  # Audio content should not be empty 