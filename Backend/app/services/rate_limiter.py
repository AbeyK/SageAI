from datetime import datetime
from app.services.firebase_client import db

DAILY_LIMIT = 30

# List of user IDs who are never rate limited
RATE_LIMIT_WHITELIST = [
    "GIEuNV2sZQOOlY9Cr7BdsyfAO2D3",  # abeytest@test.com
    "53KOwwwNTCNOyPz9GW6nRPG6y092",  # hello@abeyk.com
    "ejCo89kfL7Ykca3oNCapcPZHXuA3",  # hassanjkhan6@gmail.com
    # Add user IDs here that should never be rate limited
    # Example: "user123", "admin@example.com", "test_user_id"
]


def get_today_utc_str():
    """Return today's date as a string in UTC (YYYY-MM-DD)."""
    return datetime.utcnow().strftime("%Y-%m-%d")


async def is_rate_limited(user_id: str) -> bool:
    # Check if user is in the whitelist
    if user_id in RATE_LIMIT_WHITELIST:
        return False

    if db is None:
        return False

    today = get_today_utc_str()
    doc_ref = db.collection("rate_limits").document(user_id)
    doc = doc_ref.get()
    if doc.exists:
        data = doc.to_dict()
        if data.get("date") == today:
            if data.get("count", 0) >= DAILY_LIMIT:
                return True
            else:
                doc_ref.update({"count": data.get("count", 0) + 1})
                return False
        else:
            # New day, reset count
            doc_ref.set({"date": today, "count": 1})
            return False
    else:
        # First request ever
        doc_ref.set({"date": today, "count": 1})
        return False
