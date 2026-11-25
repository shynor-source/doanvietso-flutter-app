"""Đoàn Viên Số — FastAPI backend (Vòng 2).

Chạy:  uvicorn app.main:app --reload  (tại thư mục backend/)
Docs:  http://localhost:8000/docs
"""
import asyncio
import os
import logging
from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from sqlmodel import Session as DBSession, select

from .database import get_session, init_db, engine, fix_postgres_sequences
from .seed import seed
from .models import QrToken, Session as SessionModel, utcnow

from .routers import (
    auth_router, members_router, requests_router, rewards_router,
    sessions_router, social_router, ward_router,
)


async def _qr_watchdog():
    """Vòng xoay mã QR server-side mỗi 10s: vô hiệu hóa token hết hạn và
    phát hành token mới cho buổi sinh hoạt đang mở (TTL 55s)."""
    import secrets
    from datetime import timedelta
    QR_TTL_S = 55
    while True:
        try:
            with DBSession(engine) as db:
                now = utcnow()
                expired = db.exec(select(QrToken).where(QrToken.expires_at < now)).all()
                rotated = False
                for t in expired:
                    if t.used_by is None:
                        db.delete(t)  # token hết hạn & chưa dùng: xóa (FK-int trên Postgres)
                        rotated = True
                # Buổi đang mở mà thiếu token hợp lệ → phát hành mã mới
                open_sessions = db.exec(select(SessionModel).where(SessionModel.is_open == True)).all()  # noqa: E712
                for s in open_sessions:
                    has_valid = db.exec(
                        select(QrToken).where(
                            QrToken.session_id == s.id,
                            QrToken.expires_at > now,
                            QrToken.used_by == None,  # noqa: E711
                        )
                    ).first()
                    if has_valid is None:
                        token = f"KP5-{s.starts_at.strftime('%Y%m')}-{secrets.token_hex(2).upper()}"
                        db.add(QrToken(session_id=s.id, token=token, issued_at=now,
                                       expires_at=now + timedelta(seconds=QR_TTL_S)))
                        rotated = True
                if rotated:
                    db.commit()
        except Exception:  # noqa: BLE001 — vòng nền không được chết
            pass
        await asyncio.sleep(10)


@asynccontextmanager
async def lifespan(app: FastAPI):
    init_db()
    # Seed dữ liệu mẫu: bỏ qua khi đặt DOANVIEN_ALLOW_SEED=0 (triển khai thật)
    if os.environ.get("DOANVIEN_ALLOW_SEED", "1") != "0":
        with DBSession(engine) as db:
            seed(db)
    fix_postgres_sequences()  # PostgreSQL: seed dùng id tường minh → đẩy sequence lên
    task = asyncio.create_task(_qr_watchdog())
    yield
    task.cancel()


app = FastAPI(
    title="Đoàn Viên Số — API",
    description=(
        "Backend Vòng 2: phân quyền 3 vai trò (member / secretary / ward_officer), "
        "mã QR động chống gian lận (TTL 55s + geofence), duyệt sinh hoạt bù, "
        "dashboard phường & xuất báo cáo."
    ),
    version="2.0.0",
    lifespan=lifespan,
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # MVP: mở rộng; production khóa theo domain
    allow_methods=["*"],
    allow_headers=["*"],
)

for r in (auth_router, sessions_router, members_router, requests_router, ward_router, rewards_router, social_router):
    app.include_router(r.router)


@app.get("/", tags=["health"])
def health():
    return {"app": "Đoàn Viên Số API", "status": "ok", "round": 2}


@app.get("/health", tags=["health"], summary="Health check cho uptime monitor (không đụng DB)")
def health_ping():
    """Endpoint siêu nhẹ để uptime monitor (UptimeRobot…) ping giữ service không ngủ.
    Không chạm CSDL, không auth — phản hồi trong vài ms."""
    return {"status": "ok"}


# Không ghi log access cho /health (monitor ping 5 phút/lần → tránh spam log)
class _SkipHealthLog(logging.Filter):
    def filter(self, record: logging.LogRecord) -> bool:
        return "GET /health" not in record.getMessage().split("?")[0]


logging.getLogger("uvicorn.access").addFilter(_SkipHealthLog())
