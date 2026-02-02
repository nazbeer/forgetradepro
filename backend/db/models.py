from sqlalchemy import Boolean, Column, DateTime, Float, ForeignKey, Integer, String, func
from db.session import Base

class User(Base):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True)
    email = Column(String, unique=True, index=True, nullable=True)
    mobile = Column(String, unique=True, index=True, nullable=True)
    guest_id = Column(String, unique=True, index=True, nullable=True)
    is_guest = Column(Boolean, default=False)
    password_hash = Column(String, nullable=True)
    password_salt = Column(String, nullable=True)
    balance = Column(Float, default=10000)
    starting_balance = Column(Float, default=10000)
    max_risk_pct = Column(Float, default=0.01)
    paper = Column(Boolean, default=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())


class Trade(Base):
    __tablename__ = "trades"

    id = Column(Integer, primary_key=True)
    user_id = Column(Integer, ForeignKey("users.id"), index=True, nullable=False)
    symbol = Column(String, default="BTCUSDT")
    qty = Column(Float, nullable=False)
    price = Column(Float, nullable=False)
    trade_type = Column(String, default="paper")
    created_at = Column(DateTime(timezone=True), server_default=func.now())
