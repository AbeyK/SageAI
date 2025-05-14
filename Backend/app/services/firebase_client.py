import firebase_admin
from firebase_admin import credentials, firestore
from app.config import settings

# Get credentials from settings (as dict)
cred_dict = settings.get_firebase_credentials()

if not cred_dict:
    print("WARNING: FIREBASE_CREDENTIALS environment variable not set. Firestore will not work.")
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
    print("Firebase Admin SDK NOT initialized for Firestore due to missing or invalid credentials.")

db = firestore.client() if cred else None 