"""Xác thực: JWT HS256 (thư viện chuẩn) + OTP mô phỏng + hash PBKDF2 (stdlib)."""
import base64
import hashlib
import hmac
import json
import os
import secrets
import time
from typing import Optional

from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from sqlmodel import Session as DBSession, select

from .database import get_session
from .models import User, utcnow

# Khóa ký JWT: luôn đặt DOANVIEN_SECRET qua biến môi trường khi chạy thật.
# Nếu không đặt, hệ thống dùng khóa ngẫu nhiên theo phiên (token chết khi restart — an toàn mặc định).
SECRET_KEY = os.environ.get("DOANVIEN_SECRET") or secrets.token_hex(32)
if not os.environ.get("DOANVIEN_SECRET"):
    print("[cảnh báo] DOANVIEN_SECRET chưa đặt — dùng khóa ngẫu nhiên theo phiên (token sẽ hết khi restart).")
JWT_ALG = "HS256"
TOKEN_TTL_S = 12 * 3600

bearer = HTTPBearer(auto_error=False)

# OTP mô phỏng (Vòng 2 MVP): cấu hình qua biến môi trường khi triển khai thật (production: Zalo ZNS)
DEMO_OTP = os.environ.get("DOANVIEN_DEMO_OTP", "246810")
# Mật khẩu demo dùng nội bộ khi seed; không được client gửi/kiểm tra
DEMO_PASSWORD = os.environ.get("DOANVIEN_DEMO_PASSWORD", "doanvien2026")


def hash_password(password: str, salt: Optional[bytes] = None) -> str:
    salt = salt or secrets.token_bytes(16)
    dk = hashlib.pbkdf2_hmac("sha256", password.encode(), salt, 120_000)
    return f"pbkdf2${salt.hex()}${dk.hex()}"


def verify_password(password: str, stored: str) -> bool:
    try:
        _, salt_hex, dk_hex = stored.split("$")
        dk = hashlib.pbkdf2_hmac("sha256", password.encode(), bytes.fromhex(salt_hex), 120_000)
        return hmac.compare_digest(dk.hex(), dk_hex)
    except ValueError:
        return False


def _b64(data: bytes) -> str:
    return base64.urlsafe_b64encode(data).rstrip(b"=").decode()


def _b64decode(data: str) -> bytes:
    return base64.urlsafe_b64decode(data + "=" * (-len(data) % 4))


def create_access_token(user: User) -> str:
    payload = {
        "sub": str(user.id),
        "role": user.role,
        "name": user.full_name,
        "branch_id": user.branch_id,
        "iat": int(time.time()),
        "exp": int(time.time()) + TOKEN_TTL_S,
    }
    header = _b64(json.dumps({"alg": JWT_ALG, "typ": "JWT"}).encode())
    body = _b64(json.dumps(payload).encode())
    sig = _b64(hmac.new(SECRET_KEY.encode(), f"{header}.{body}".encode(), hashlib.sha256).digest())
    return f"{header}.{body}.{sig}"


def decode_token(token: str) -> dict:
    try:
        header, body, sig = token.split(".")
        expect = _b64(hmac.new(SECRET_KEY.encode(), f"{header}.{body}".encode(), hashlib.sha256).digest())
        if not hmac.compare_digest(sig, expect):
            raise ValueError("Sai chữ ký")
        payload = json.loads(_b64decode(body))
        if payload.get("exp", 0) < time.time():
            raise ValueError("Token hết hạn")
        return payload
    except Exception as exc:  # noqa: BLE001
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail=f"Token không hợp lệ: {exc}") from exc


def get_current_user(cred: Optional[HTTPAuthorizationCredentials] = Depends(bearer), db: DBSession = Depends(get_session)) -> User:
    if cred is None:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Chưa đăng nhập.")
    payload = decode_token(cred.credentials)
    user = db.get(User, int(payload["sub"]))
    if user is None:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Tài khoản không tồn tại.")
    return user


def require_permission(permission: str):
    """Dependency factory: chặn theo ma trận RBAC."""

    def checker(user: User = Depends(get_current_user)) -> User:
        from . import rbac

        rbac.ensure(user.role, permission)
        return user

    return checker
