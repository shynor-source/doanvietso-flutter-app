"""Buổi sinh hoạt + mã QR động + điểm danh (geofence).

Phân quyền:
  - POST /sessions            → secretary (tạo buổi)
  - PATCH/DELETE /sessions    → secretary
  - POST /sessions/{id}/qr    → secretary (phát / làm mới mã)
  - POST /sessions/{id}/checkin → member (quét QR + GPS)
  - POST /sessions/{id}/manual  → secretary (điểm danh ngoại lệ)
"""
import math
import secrets
from datetime import datetime, timedelta, timezone
from typing import Optional

from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel
from sqlmodel import Session as DBSession, select

from ..auth import get_current_user, require_permission
from ..database import get_session
from ..models import AuditLog, CheckIn, Member, QrToken, Session as SessionModel, User, utcnow

router = APIRouter(prefix="/sessions", tags=["sessions"])

QR_TTL_S = 55  # mã tự hết hạn sau 55 giây


class SessionIn(BaseModel):
    title: str
    starts_at: datetime
    location: str = "Nhà văn hóa Khu phố 5"
    lat: float = 10.9565
    lng: float = 106.8244
    radius_m: int = 100


class CheckInIn(BaseModel):
    token: str
    lat: float
    lng: float


def _distance_m(lat1: float, lng1: float, lat2: float, lng2: float) -> float:
    r = 6371000.0
    p1, p2 = math.radians(lat1), math.radians(lat2)
    dp = math.radians(lat2 - lat1)
    dl = math.radians(lng2 - lng1)
    a = math.sin(dp / 2) ** 2 + math.cos(p1) * math.cos(p2) * math.sin(dl / 2) ** 2
    return 2 * r * math.asin(math.sqrt(a))


def _active_token(db: DBSession, session_id: int) -> Optional[QrToken]:
    now = utcnow()
    toks = db.exec(
        select(QrToken).where(QrToken.session_id == session_id).order_by(QrToken.issued_at.desc())
    ).all()
    for t in toks:
        if t.expires_at.replace(tzinfo=timezone.utc) > now and t.used_by is None:
            return t
    return None


@router.get("", summary="Danh sách buổi sinh hoạt của chi đoàn")
def list_sessions(user: User = Depends(get_current_user), db: DBSession = Depends(get_session)):
    stmt = select(SessionModel).order_by(SessionModel.starts_at)
    if user.role != "ward_officer":
        stmt = stmt.where(SessionModel.branch_id == user.branch_id)  # đoàn viên/bí thư chỉ thấy chi đoàn mình
    sessions = db.exec(stmt).all()
    out = []
    for s in sessions:
        item = {
            "id": s.id, "title": s.title, "starts_at": s.starts_at, "location": s.location,
            "is_open": s.is_open, "radius_m": s.radius_m,
        }
        # Token trả cho mọi vai trò cùng chi đoàn — đó chính là nội dung QR
        # đang hiển thị trên màn hình bí thư mà đoàn viên quét bằng camera.
        # An toàn: TTL 55s + chống tái sử dụng (used_by) ở bước checkin.
        tok = _active_token(db, s.id or 0)
        item["current_qr_token"] = tok.token if tok else None
        item["qr_expires_in_s"] = max(0, int((tok.expires_at.replace(tzinfo=timezone.utc) - utcnow()).total_seconds())) if tok else 0
        checked = db.exec(select(CheckIn).where(CheckIn.session_id == s.id)).all()
        item["checked_in"] = len(checked)
        out.append(item)
    return out


@router.post("", summary="Tạo buổi sinh hoạt (Bí thư)", dependencies=[Depends(require_permission("session:create"))])
def create_session(body: SessionIn, user: User = Depends(get_current_user), db: DBSession = Depends(get_session)):
    # Chuẩn hóa naive datetime → UTC (client có thể gửi ISO không múi giờ)
    starts = body.starts_at if body.starts_at.tzinfo else body.starts_at.replace(tzinfo=timezone.utc)
    s = SessionModel(branch_id=user.branch_id or 1, title=body.title, starts_at=starts,
                     location=body.location, lat=body.lat, lng=body.lng, radius_m=body.radius_m, created_by=user.id or 0)
    db.add(s)
    db.commit()
    db.refresh(s)
    db.add(AuditLog(actor=user.full_name, action=f'Tạo buổi sinh hoạt "{s.title}"'))
    db.commit()
    return {"ok": True, "id": s.id}


@router.patch("/{session_id}/close", summary="Đóng buổi / đóng đăng ký (Bí thư)",
              dependencies=[Depends(require_permission("session:close"))])
def close_session(session_id: int, user: User = Depends(get_current_user), db: DBSession = Depends(get_session)):
    s = db.get(SessionModel, session_id)
    if s is None or s.branch_id != user.branch_id:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Không tìm thấy buổi sinh hoạt.")
    s.is_open = False
    db.add(AuditLog(actor=user.full_name, action=f'Đóng buổi sinh hoạt "{s.title}"'))
    db.commit()
    return {"ok": True}


@router.delete("/{session_id}", summary="Xóa buổi sinh hoạt (Bí thư)",
               dependencies=[Depends(require_permission("session:delete"))])
def delete_session(session_id: int, user: User = Depends(get_current_user), db: DBSession = Depends(get_session)):
    s = db.get(SessionModel, session_id)
    if s is None or s.branch_id != user.branch_id:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Không tìm thấy buổi sinh hoạt.")
    db.delete(s)
    db.add(AuditLog(actor=user.full_name, action=f'Xóa buổi sinh hoạt "{s.title}"'))
    db.commit()
    return {"ok": True}


@router.post("/{session_id}/qr", summary="Phát / làm mới mã QR động (Bí thư)",
             dependencies=[Depends(require_permission("qr:issue"))])
def issue_qr(session_id: int, user: User = Depends(get_current_user), db: DBSession = Depends(get_session)):
    s = db.get(SessionModel, session_id)
    if s is None or s.branch_id != user.branch_id:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Không tìm thấy buổi sinh hoạt.")
    if not s.is_open:
        raise HTTPException(status.HTTP_400_BAD_REQUEST, "Buổi đã đóng — không thể phát mã.")
    # Vô hiệu các mã cũ của buổi này (chống ảnh chụp màn hình)
    for t in db.exec(select(QrToken).where(QrToken.session_id == session_id)).all():
        t.used_by = t.used_by or -1  # -1 = hết hiệu lực do xoay mã
    token = f"KP5-{s.starts_at.strftime('%Y%m')}-{secrets.token_hex(2).upper()}"
    tok = QrToken(session_id=session_id, token=token, issued_at=utcnow(),
                  expires_at=utcnow() + timedelta(seconds=QR_TTL_S))
    db.add(tok)
    db.commit()
    return {"token": token, "expires_in_s": QR_TTL_S, "note": "Mã cũ đã vô hiệu — mỗi mã dùng 1 lần."}


@router.post("/{session_id}/checkin", summary="Đoàn viên quét QR điểm danh (kiểm tra geofence)",
             dependencies=[Depends(require_permission("session:checkin"))])
def check_in(session_id: int, body: CheckInIn, user: User = Depends(get_current_user), db: DBSession = Depends(get_session)):
    s = db.get(SessionModel, session_id)
    if s is None or not s.is_open:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Buổi sinh hoạt không tồn tại hoặc đã kết thúc.")
    member = db.exec(select(Member).where(Member.user_id == user.id)).first()
    if member is None:
        raise HTTPException(status.HTTP_400_BAD_REQUEST, "Tài khoản không gắn với hồ sơ đoàn viên nào.")

    tok = db.exec(select(QrToken).where(QrToken.token == body.token)).first()
    now = utcnow()
    if tok is None or tok.session_id != session_id:
        raise HTTPException(status.HTTP_400_BAD_REQUEST, "Mã QR không đúng buổi sinh hoạt này.")
    if tok.expires_at.replace(tzinfo=timezone.utc) < now:
        raise HTTPException(status.HTTP_400_BAD_REQUEST, "Mã QR đã hết hạn — vui lòng chờ mã mới (55s).")
    if tok.used_by is not None:
        raise HTTPException(status.HTTP_400_BAD_REQUEST, "Mã QR đã được sử dụng (mỗi mã dùng 1 lần).")

    dist = _distance_m(body.lat, body.lng, s.lat, s.lng)
    ok_geo = dist <= s.radius_m
    if not ok_geo:
        raise HTTPException(
            status.HTTP_403_FORBIDDEN,
            f"Bạn cách điểm sinh hoạt {int(dist)}m (giới hạn {s.radius_m}m). Di chuyển vào phạm vi để điểm danh.",
        )
    existed = db.exec(select(CheckIn).where(CheckIn.session_id == session_id, CheckIn.member_id == member.id)).first()
    if existed:
        raise HTTPException(status.HTTP_400_BAD_REQUEST, "Bạn đã điểm danh buổi này rồi.")
    tok.used_by = member.id
    ci = CheckIn(session_id=session_id, member_id=member.id, method="qr", distance_m=round(dist), in_geofence=True)
    db.add_all([tok, ci])
    member.points += 5
    db.add_all([member, AuditLog(actor=member.name, action=f"Điểm danh QR buổi '{s.title}' (cách {int(dist)}m)")])
    db.commit()
    return {"ok": True, "distance_m": round(dist), "message": "Điểm danh thành công! +5 điểm chuyên cần."}


@router.post("/{session_id}/manual", summary="Điểm danh thủ công ngoại lệ (Bí thư)",
             dependencies=[Depends(require_permission("session:create"))])
def manual_checkin(session_id: int, member_id: int, reason: str, user: User = Depends(get_current_user), db: DBSession = Depends(get_session)):
    s = db.get(SessionModel, session_id)
    if s is None or s.branch_id != user.branch_id:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Không tìm thấy buổi sinh hoạt.")
    m = db.get(Member, member_id)
    if m is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Không tìm thấy đoàn viên.")
    db.add(CheckIn(session_id=session_id, member_id=member_id, method="manual", in_geofence=True))
    db.add(AuditLog(actor=user.full_name, action=f"Điểm danh thủ công cho {m.name} — lý do: {reason}"))
    db.commit()
    return {"ok": True}
