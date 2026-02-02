from fastapi import APIRouter, HTTPException
import requests

router = APIRouter()

BINANCE_BASE = "https://api.binance.com"


@router.get("/price/{symbol}")
def price(symbol: str):
    r = requests.get(
        f"{BINANCE_BASE}/api/v3/ticker/price",
        params={"symbol": symbol.upper()},
        timeout=10,
    )
    if r.status_code != 200:
        raise HTTPException(status_code=502, detail=f"Market data error: {r.text}")

    data = r.json()
    return {"symbol": data.get("symbol"), "price": float(data.get("price"))}


@router.get("/candles/{symbol}")
def candles(symbol: str, interval: str = "1m", limit: int = 60):
    limit = max(1, min(int(limit), 1000))
    r = requests.get(
        f"{BINANCE_BASE}/api/v3/klines",
        params={"symbol": symbol.upper(), "interval": interval, "limit": limit},
        timeout=10,
    )
    if r.status_code != 200:
        raise HTTPException(status_code=502, detail=f"Market data error: {r.text}")

    klines = r.json()
    points = []
    for k in klines:
        # kline format: [openTime, open, high, low, close, volume, closeTime, ...]
        points.append(
            {
                "t": int(k[0]),
                "open": float(k[1]),
                "high": float(k[2]),
                "low": float(k[3]),
                "close": float(k[4]),
            }
        )

    return {"symbol": symbol.upper(), "interval": interval, "points": points}
