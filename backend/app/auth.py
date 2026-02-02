from fastapi import APIRouter, HTTPException
from jose import jwt
import requests
import base64
import hashlib
import os
import secrets
import uuid

from app.config import GOOGLE_CLIENT_ID, JWT_SECRET, JWT_ALGO
from app.models import GoogleLogin, PhoneLogin, PhoneRegister
from db.session import SessionLocal
from db.models import User

router = APIRouter()
GOOGLE_VERIFY = "https://oauth2.googleapis.com/tokeninfo"

PBKDF2_ITERS = 200_000


def _hash_password(password: str, salt_b64: str) -> str:
    salt = base64.b64decode(salt_b64.encode("utf-8"))
    dk = hashlib.pbkdf2_hmac("sha256", password.encode("utf-8"), salt, PBKDF2_ITERS)
    return base64.b64encode(dk).decode("utf-8")


def _new_salt_b64() -> str:
    return base64.b64encode(os.urandom(16)).decode("utf-8")

@router.post("/google")
def google_login(data: GoogleLogin):
    r = requests.get(GOOGLE_VERIFY, params={"id_token": data.id_token})
    if r.status_code != 200:
        raise HTTPException(401, "Invalid Google token")

    payload = r.json()
    if payload["aud"] != GOOGLE_CLIENT_ID:
        raise HTTPException(401, "Invalid audience")

    email = payload["email"]

    db = SessionLocal()
    try:
        user = db.query(User).filter(User.email == email).first()
        if not user:
            user = User(email=email)
            db.add(user)
            db.commit()
            db.refresh(user)
    finally:
        db.close()

    token = jwt.encode({"sub": email}, JWT_SECRET, algorithm=JWT_ALGO)
    return {"access_token": token}


@router.post("/register")
def register_phone(data: PhoneRegister):
    mobile = (data.mobile or "").strip()
    password = data.password or ""
    email = (data.email or "").strip() or None

    if len(mobile) < 6:
        raise HTTPException(status_code=400, detail="Invalid mobile")
    if len(password) < 6:
        raise HTTPException(status_code=400, detail="Password too short")

    db = SessionLocal()
    try:
        existing = db.query(User).filter(User.mobile == mobile).first()
        if existing:
            raise HTTPException(status_code=409, detail="Mobile already registered")

        if email:
            existing_email = db.query(User).filter(User.email == email).first()
            if existing_email:
                raise HTTPException(status_code=409, detail="Email already registered")

        salt_b64 = _new_salt_b64()
        pw_hash = _hash_password(password, salt_b64)
        user = User(email=email, mobile=mobile, password_hash=pw_hash, password_salt=salt_b64)
        db.add(user)
        db.commit()
        db.refresh(user)
    finally:
        db.close()

    token = jwt.encode({"sub": mobile}, JWT_SECRET, algorithm=JWT_ALGO)
    return {"access_token": token}


@router.post("/login")
def login_phone(data: PhoneLogin):
    mobile = (data.mobile or "").strip()
    password = data.password or ""

    if not mobile or not password:
        raise HTTPException(status_code=400, detail="Missing credentials")

    db = SessionLocal()
    try:
        user = db.query(User).filter(User.mobile == mobile).first()
        if not user or not user.password_hash or not user.password_salt:
            raise HTTPException(status_code=401, detail="Invalid credentials")

        candidate = _hash_password(password, user.password_salt)
        if not secrets.compare_digest(candidate, user.password_hash):
            raise HTTPException(status_code=401, detail="Invalid credentials")
    finally:
        db.close()

    token = jwt.encode({"sub": mobile}, JWT_SECRET, algorithm=JWT_ALGO)
    return {"access_token": token}


@router.post("/guest")
def guest_login():
    guest_id = f"guest_{uuid.uuid4().hex}"  # stored in DB; also used as JWT sub

    db = SessionLocal()
    try:
        user = User(guest_id=guest_id, is_guest=True)
        db.add(user)
        db.commit()
        db.refresh(user)
    finally:
        db.close()

    token = jwt.encode({"sub": guest_id}, JWT_SECRET, algorithm=JWT_ALGO)
    return {"access_token": token, "guest_id": guest_id}
