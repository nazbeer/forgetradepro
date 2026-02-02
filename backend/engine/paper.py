def paper_trade(user, price):
    qty = (user.balance * user.max_risk_pct) / price
    user.balance -= qty * price
    return {
        "type": "paper",
        "qty": qty,
        "price": price
    }
