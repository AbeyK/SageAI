import firebase_admin
from firebase_admin import credentials, firestore
from app.config import settings
import datetime
import asyncio
import time
import logging

# Get credentials from settings (as dict)
cred_dict = settings.get_firebase_credentials()

if not cred_dict:
    print(
        "WARNING: FIREBASE_CREDENTIALS environment variable not set. Firestore will not work."
    )
    cred = None
else:
    try:
        cred = credentials.Certificate(cred_dict)
    except Exception as e:
        print(f"Error loading Firebase credentials: {e}. Firestore will not work.")
        cred = None

if cred:
    try:
        firebase_admin.get_app()
    except ValueError:
        firebase_admin.initialize_app(cred)
    print("Firebase Admin SDK initialized for Firestore.")
else:
    print(
        "Firebase Admin SDK NOT initialized for Firestore due to missing or invalid credentials."
    )

db = firestore.client() if cred else None

async def log_conversation_to_firestore(user_id: str, endpoint: str, messages: list, llm_response: str, session_id: str):
    logger = logging.getLogger("meditation_app")
    start_time = time.time()
    logger.info(f"[Firestore][{start_time}] log_conversation_to_firestore called for user_id={user_id}, session_id={session_id}")
    if db is None:
        logger.warning(f"[Firestore][{time.time() - start_time:.3f}s] Firestore not initialized; skipping log.")
        return
    doc_ref = db.collection("sessions").document(user_id).collection("meditations").document(session_id)
    data = {
        "user_id": user_id,
        "endpoint": endpoint,
        "messages": messages,
        "llm_response": llm_response,
        "session_id": session_id,
        "timestamp": datetime.datetime.utcnow(),
    }
    logger.info(f"[Firestore][{time.time() - start_time:.3f}s] Prepared Firestore data for logging.")
    loop = asyncio.get_event_loop()
    before_write = time.time()
    await loop.run_in_executor(None, lambda: doc_ref.set(data))
    after_write = time.time()
    logger.info(f"[Firestore][{after_write - start_time:.3f}s] Firestore write complete. Write duration: {after_write - before_write:.3f}s")
