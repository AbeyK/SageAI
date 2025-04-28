import pytest
from app.gpt_handler import generate_meditation

@pytest.mark.asyncio
async def test_generate_meditation():
    result = await generate_meditation("How can I relax today?")
    assert isinstance(result, str)
    assert "breathe" in result.lower() or "relax" in result.lower() 