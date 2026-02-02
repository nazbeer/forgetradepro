from fastapi import APIRouter, Depends, Header, HTTPException
from jose import jwt
from sqlalchemy.orm import Session

from app.config import JWT_SECRET, JWT_ALGO
from db.session import SessionLocal
from db.models import Trade, User
from engine.trader import trade

router = APIRouter()

def db():
    s = SessionLocal()
    try:
        yield s
    finally:
        s.close()

def get_user(token: str, db: Session):
    try:
        payload = jwt.decode(token, JWT_SECRET, algorithms=[JWT_ALGO])
    except Exception:
        raise HTTPException(status_code=401, detail="Invalid token")

    sub = payload.get("sub")
    if not sub:
        raise HTTPException(status_code=401, detail="Invalid token")

    user = (
        db.query(User)
        .filter((User.email == sub) | (User.mobile == sub) | (User.guest_id == sub))
        .first()
    )
    if not user:
        raise HTTPException(status_code=401, detail="User not found")
    return user

@router.post("/paper")
def paper_trade(auth: str = Header(...), db: Session = Depends(db)):
    user = get_user(auth, db)
    result = trade(user, price=30000)

    t = Trade(
        user_id=user.id,
        symbol="BTCUSDT",
        qty=float(result["qty"]),
        price=float(result["price"]),
        trade_type=str(result.get("type", "paper")),
    )
    db.add(t)
    db.commit()

    return {**result, "balance": user.balance}
