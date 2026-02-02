import os


# IMPORTANT:
# - Do NOT embed OAuth client secrets in the macOS app.
# - Prefer setting these via environment variables (or a local .env that is gitignored).

GOOGLE_CLIENT_ID = os.getenv("GOOGLE_CLIENT_ID", "YOUR_GOOGLE_CLIENT_ID")
GOOGLE_CLIENT_SECRET = os.getenv("GOOGLE_CLIENT_SECRET", "")

JWT_SECRET = os.getenv("JWT_SECRET", "CHANGE_ME_SUPER_SECRET")
JWT_ALGO = os.getenv("JWT_ALGO", "HS256")
