import firebase_admin
from firebase_admin import credentials, auth
from fastapi import HTTPException, Security
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from app.config import settings

# Get credentials from settings
cred_dict = settings.get_firebase_credentials()

if not cred_dict:
    print(
        "WARNING: FIREBASE_CREDENTIALS environment variable not set. Firebase Auth will not work."
    )
    cred = None
else:
    try:
        cred = credentials.Certificate(cred_dict)
    except Exception as e:
        print(f"Error loading Firebase credentials: {e}. Firebase Auth will not work.")
        cred = None

if cred:
    try:
        firebase_admin.get_app()
    except ValueError:
        firebase_admin.initialize_app(cred)
    print("Firebase Admin SDK initialized.")
else:
    print("Firebase Admin SDK NOT initialized due to missing or invalid credentials.")

security = HTTPBearer()


async def verify_firebase_token(
    creds: HTTPAuthorizationCredentials = Security(security),
) -> dict:
    """
    FastAPI dependency to verify Firebase ID token from the Authorization header.
    Returns the decoded token (user payload) if valid.
    """
    if not creds or not creds.credentials:
        raise HTTPException(
            status_code=401,
            detail="Not authenticated: No token provided.",
            headers={"WWW-Authenticate": "Bearer"},
        )

    id_token = creds.credentials

    if not firebase_admin._apps:  # Check if Firebase app is initialized
        raise HTTPException(
            status_code=500,
            detail="Firebase Admin SDK not initialized. Cannot verify token.",
        )

    try:
        decoded_token = auth.verify_id_token(id_token)
        return decoded_token
    except firebase_admin.auth.ExpiredIdTokenError:
        raise HTTPException(
            status_code=401,
            detail="Token expired.",
            headers={
                "WWW-Authenticate": "Bearer error='invalid_token', error_description='Token expired'"
            },
        )
    except firebase_admin.auth.InvalidIdTokenError:
        raise HTTPException(
            status_code=401,
            detail="Invalid token.",
            headers={
                "WWW-Authenticate": "Bearer error='invalid_token', error_description='Invalid token'"
            },
        )
    except Exception as e:
        print(f"An unexpected error occurred during token verification: {e}")
        raise HTTPException(status_code=500, detail="Could not process token.")
