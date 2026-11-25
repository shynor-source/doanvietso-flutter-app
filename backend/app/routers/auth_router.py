"""Đăng nhập + OTP mô phỏng (Vòng 2 MVP)."""
from pydantic import BaseModel
from fastapi import APIRouter, Depends, HTTPException, status
from sqlmodel import Session as DBSession, select

from ..auth import create_access_token, DEMO_OTP, DEMO_PASSWORD, verify_password, get_current_user
from ..database import get_session
from ..models import Member, User

router = APIRouter(prefix="/auth", tags=["auth"])


class LoginIn(BaseModel):
    phone: str
    otp: str


class OtpIn(BaseModel):
    phone: str


@router.post("/otp", summary="Gửi mã OTP (mô phỏng)")
def send_otp(body: OtpIn, db: DBSession = Depends(get_session)):
    user = db.exec(select(User).where(User.phone == body.phone)).first()
    if user is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Số điện thoại chưa đăng ký trong hệ thống.")
    return {"ok": True, "note": f"OTP demo (SMS/Zalo thật sẽ áp dụng production): {DEMO_OTP}"}


@router.post("/login", summary="Đăng nhập bằng OTP")
def login(body: LoginIn, db: DBSession = Depends(get_session)):
    user = db.exec(select(User).where(User.phone == body.phone)).first()
    if user is None or not verify_password(DEMO_PASSWORD, user.password_hash):
        raise HTTPException(status.HTTP_401_UNAUTHORIZED, "Sai số điện thoại hoặc mật khẩu hệ thống.")
    if body.otp != DEMO_OTP:
        raise HTTPException(status.HTTP_401_UNAUTHORIZED, "Mã OTP không đúng.")
    member = db.exec(select(Member).where(Member.user_id == user.id)).first()
    return {
        "access_token": create_access_token(user),
        "token_type": "bearer",
        "user": {
            "id": user.id, "phone": user.phone, "full_name": user.full_name,
            "role": user.role, "branch_id": user.branch_id,
            "member_code": member.member_code if member else None,
            "member_id": member.id if member else None,
        },
    }


@router.get("/me", summary="Thông tin tài khoản hiện tại")
def me(user: User = Depends(get_current_user), db: DBSession = Depends(get_session)):
    member = db.exec(select(Member).where(Member.user_id == user.id)).first()
    return {
        "id": user.id, "phone": user.phone, "full_name": user.full_name,
        "role": user.role, "branch_id": user.branch_id,
        "member": {"id": member.id, "code": member.member_code, "points": member.points} if member else None,
    }
