from datetime import datetime
from app.services.firebase_client import db

DAILY_LIMIT = 2000


def get_today_utc_str():
    """Return today's date as a string in UTC (YYYY-MM-DD)."""
    return datetime.utcnow().strftime("%Y-%m-%d")

async def is_rate_limited(user_id: str) -> bool:
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