from fastapi import APIRouter, Depends, Header, HTTPException
from jose import jwt
from sqlalchemy.orm import Session

from app.config import JWT_ALGO, JWT_SECRET
from db.models import Trade, User
from db.session import SessionLocal

router = APIRouter()


def db():
    s = SessionLocal()
    try:
        yield s
    finally:
        s.close()


def get_user(token: str, session: Session) -> User:
    try:
        payload = jwt.decode(token, JWT_SECRET, algorithms=[JWT_ALGO])
    except Exception:
        raise HTTPException(status_code=401, detail="Invalid token")

    sub = payload.get("sub")
    if not sub:
        raise HTTPException(status_code=401, detail="Invalid token")

    user = (
        session.query(User)
        .filter((User.email == sub) | (User.mobile == sub) | (User.guest_id == sub))
        .first()
    )
    if not user:
        raise HTTPException(status_code=401, detail="User not found")
    return user


@router.get("/summary")
def summary(auth: str = Header(...), session: Session = Depends(db)):
    user = get_user(auth, session)

    trades_count = session.query(Trade).filter(Trade.user_id == user.id).count()
    pnl = float(user.balance) - float(user.starting_balance)

    return {
        "email": user.email,
        "mobile": getattr(user, "mobile", None),
        "guest_id": getattr(user, "guest_id", None),
        "is_guest": bool(getattr(user, "is_guest", False)),
        "balance": float(user.balance),
        "starting_balance": float(user.starting_balance),
        "pnl": pnl,
        "max_risk_pct": float(user.max_risk_pct),
        "paper": bool(user.paper),
        "trades_count": int(trades_count),
    }
