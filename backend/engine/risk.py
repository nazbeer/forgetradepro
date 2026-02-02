def check_risk(user, trade_size):
    max_allowed = user.balance * user.max_risk_pct
    if trade_size > max_allowed:
        raise Exception("Risk limit exceeded")
