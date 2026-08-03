# Sage AI backend

FastAPI service behind the [Sage AI](../README.md) voice meditation app. Two endpoints, no session state, one 512 MB Fly.io machine.

The client carries the entire conversation plus a `percent_complete` integer on every request; the server picks the matching prompt phase and returns text plus base64 MP3. Nothing is stored between requests, so any machine can serve any request and a deploy loses nothing.

## Layout

```
main.py                       app factory, CORS, exception handlers, /health
app/
  config.py                   pydantic-settings; reads OPENAI_API_KEY, FIREBASE_CREDENTIALS
  logging_config.py           the wall-clock logger every stage reports into
  models/chat_models.py       ChatRequest · MeditateRequest · AudioResponse
  auth/firebase_auth.py       Bearer ID-token verification
  routers/
    chat.py                   POST /api/v1/chat      — the interview phase + its prompts
    meditation_router.py      POST /api/v1/meditate  — percent-driven meditation phases
  services/
    openai_service.py         chat completion, TTS, split_text_for_fast_tts, tts_parallel_stitch
    rate_limiter.py           30 sessions/user/day, Firestore-backed
    firebase_client.py        Firestore transcript writes (off the critical path)
static/                       pre-rendered intro + rate-limit clips
```

The prompts in `routers/` are the product, not configuration — the persona is a three-phase state machine (interview → hand-off → meditation parameterised 0–100%), and prompt changes shipped daily like any other deploy.

## Endpoints

Both require `Authorization: Bearer <firebase-id-token>` and return the same shape:

```jsonc
{ "text_response": "...", "audio_base64": "<mp3>" }
```

### `POST /api/v1/chat`

Interviews the user. `gpt-4o-mini`, then TTS via a 3-way parallel stitch (~1.6 s wall) because chat is optimised for speed. After 5 messages the system prompt is swapped for the hand-off prompt, which is forbidden from asking "are you ready?" — it must point at the app's own button.

```jsonc
{
  "messages": [{ "role": "user", "content": "Work has been a lot this week." }],
  "session_id": "optional-client-uuid"
}
```

### `POST /api/v1/meditate`

Generates the next phrase of the meditation. `gpt-4o-mini`, then a **single** TTS call — no stitch, because prosody continuity beats speed here and chunk seams reset the emotional register mid-session.

```jsonc
{
  "messages": [ /* full history */ ],
  "percent_complete": 40,       // 0 = intro, 1-99 = core, 100 = closing
  "session_id": "optional-client-uuid"
}
```

`percent_complete` selects the phase. The client pins it to 100 when under 70 seconds remain so the closing always lands before the bell.

### `GET /health`

Returns `{"status": "ok"}`. No credentials required — this is what the platform health check hits.

## Running locally

```bash
python3 -m venv venv && source venv/bin/activate
pip install -r requirements.txt
uvicorn main:app --reload --port 8000
```

Interactive docs at http://localhost:8000/docs

Configuration is two environment variables, both read from `.env` (see `app/config.py`):

| Variable | Required | Notes |
|---|---|---|
| `OPENAI_API_KEY` | for `/chat`, `/meditate` | absent → the service still boots and logs a warning; both endpoints then answer `503` |
| `FIREBASE_CREDENTIALS` | for auth, limits, transcripts | the service-account JSON **as a single-line string**, not a path |

Without either, `main:app` still starts and `/health` returns `{"status":"ok"}` — useful for checking the app wiring before you have credentials. Unauthenticated calls to `/chat` and `/meditate` are rejected at the dependency with `403`.

## Deploying

```bash
fly deploy                                   # uses ./Dockerfile
fly secrets set OPENAI_API_KEY=... FIREBASE_CREDENTIALS='{"type":"service_account",...}'
```

`fly.toml` pins `min_machines_running = 1`. That is deliberate and costs $3.19/month: with scale-to-zero the first request of each day paid boot plus imports plus client init — about 12 seconds — and testers read the stall as a broken app.

## Checks

```bash
ruff check .
mypy .        # config in mypy.ini
```

There is no test suite. At beta scale the harness was 150+ hand-run sessions with in-app feedback written to Firestore beside the exact transcript that produced it. The thing that should exist and doesn't is a ~30-case eval scoring tone, length, phase obedience and safety on every prompt change before deploy — judging voice by ear stops scaling past a few hundred users, and one tone regression reached users because of it.

## Known defect

`is_rate_limited()` returns `False` when `db is None` — that is, it fails open when *credentials are missing*. It does not fail open when Firestore is **down**: `doc_ref.get()` raises and the request 500s, so a vendor incident on a non-critical dependency would take chat down with it. The right behaviour is to degrade open on infrastructure errors and keep enforcing on everything else.
