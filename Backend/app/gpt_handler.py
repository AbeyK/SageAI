import openai

async def generate_meditation(text_input: str) -> str:
    response = openai.ChatCompletion.create(
        model="gpt-4o",
        messages=[
            {"role": "system", "content": "You are a calm, empathetic meditation guide."},
            {"role": "user", "content": text_input},
        ]
    )
    return response.choices[0].message.content 