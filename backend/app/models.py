from pydantic import BaseModel
from typing import Optional

class GoogleLogin(BaseModel):
    id_token: str


class PhoneRegister(BaseModel):
    mobile: str
    password: str
    email: Optional[str] = None


class PhoneLogin(BaseModel):
    mobile: str
    password: str
