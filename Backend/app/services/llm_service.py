import os
from openai import OpenAI
from app.logger import get_logger

logger = get_logger(__name__)

class LLMService:
    def __init__(self):
        self.client = OpenAI(api_key=os.getenv("OPENAI_API_KEY"))
        self.system_prompt = "You are Sage, a calm meditation guide. Keep responses concise and clear."

    async def get_response(self, user_text: str) -> str:
        """
        Get a response from the LLM for the given user text.
        
        Args:
            user_text (str): The user's input text
            
        Returns:
            str: The LLM's response text
            
        Raises:
            Exception: If there's an error getting the response
        """
        try:
            response = self.client.chat.completions.create(
                model="gpt-3.5-turbo",
                messages=[
                    {"role": "system", "content": self.system_prompt},
                    {"role": "user", "content": user_text},
                ],
            )
            
            return response.choices[0].message.content
            
        except Exception as e:
            logger.error(f"Error getting LLM response: {str(e)}")
            raise 