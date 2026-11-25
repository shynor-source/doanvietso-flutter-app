"""Fixtures test — DB SQLite riêng biệt cho test, không đụng doanvien.db thật.

Theo docs FastAPI: dùng TestClient (in-process) + đặt DATABASE_URL TRƯỚC khi
import app để toàn bộ stack (engine, lifespan, watchdog) trỏ vào DB test.
"""
import os
import tempfile

# BẮT BUỘC đặt trước khi import app.database (engine đọc env ở import time)
_TEST_DB = tempfile.mkstemp(prefix="doanvien_test_", suffix=".db")[1]
os.environ["DATABASE_URL"] = f"sqlite:///{_TEST_DB}"

import pytest  # noqa: E402
from fastapi.testclient import TestClient  # noqa: E402

from app.main import app  # noqa: E402
from app.database import engine  # noqa: E402
from sqlmodel import Session, select  # noqa: E402
from app import models  # noqa: E402


@pytest.fixture(scope="session")
def client():
    """Lifespan chạy init_db + seed trên DB test (vì DATABASE_URL đã trỏ sang)."""
    with TestClient(app) as c:
        yield c


# --- Tài khoản demo của seed ---
PHONE = {"member": "0981112233", "secretary": "0912345678", "ward_officer": "0903334444"}
OTP = "246810"
_TOKEN_CACHE: dict[str, str] = {}


def auth_headers(client: TestClient, role: str) -> dict:
    """Đăng nhập 1 lần/vai trò rồi cache Bearer token."""
    if role not in _TOKEN_CACHE:
        r = client.post("/auth/login", json={"phone": PHONE[role], "otp": OTP})
        assert r.status_code == 200, f"login {role} thất bại: {r.text}"
        _TOKEN_CACHE[role] = r.json()["access_token"]
    return {"Authorization": f"Bearer {_TOKEN_CACHE[role]}"}


@pytest.fixture()
def db_session():
    """Truy cập DB test trực tiếp (cho các test cần can thiệp dữ liệu, vd TTL)."""
    with Session(engine) as s:
        yield s


def set_token_expired(db_session, token_str: str) -> None:
    """Đặt expires_at về quá khứ để mô phỏng token hết hạn."""
    from datetime import timedelta
    tok = db_session.exec(
        select(models.QrToken).where(models.QrToken.token == token_str)
    ).first()
    tok.expires_at = models.utcnow() - timedelta(seconds=1)
    db_session.add(tok)
    db_session.commit()


def member_points(db_session, member_id: int = 1) -> int:
    m = db_session.get(models.Member, member_id)
    return m.points
