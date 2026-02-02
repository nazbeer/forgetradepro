from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.auth import router as auth
from app.trading import router as trading
from app.market import router as market
from app.analytics import router as analytics
from db.session import Base, engine

Base.metadata.create_all(bind=engine)

app = FastAPI(title="ForgeTrade Backend")

app.add_middleware(
	CORSMiddleware,
	allow_origins=["*"],
	allow_credentials=True,
	allow_methods=["*"],
	allow_headers=["*"],
)


@app.get("/")
def welcome():
    return {"message": "Welcome to ForgeTrade Backend"}


@app.get("/health")
def health_check():
    return {"status": "ok"}

app.include_router(auth, prefix="/auth")
app.include_router(trading, prefix="/trade")
app.include_router(market, prefix="/market")
app.include_router(analytics, prefix="/analytics")
