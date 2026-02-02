from engine.paper import paper_trade
from engine.risk import check_risk

def trade(user, price):
    trade_size = user.balance * user.max_risk_pct
    check_risk(user, trade_size)
    return paper_trade(user, price)
