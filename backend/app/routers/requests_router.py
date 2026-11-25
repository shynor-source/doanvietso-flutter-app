"""Đơn xin phép / sinh hoạt bù: đoàn viên tạo — bí thư duyệt (approve/reject/clarify)."""
from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel
from sqlmodel import Session as DBSession, select

from ..auth import get_current_user, require_permission
from ..database import get_session
from ..models import AuditLog, MakeupRequest, Member, User, utcnow

router = APIRouter(prefix="/requests", tags=["makeup-requests"])


class RequestIn(BaseModel):
    session_title: str
    reason: str
    proof: str = ""


class DecisionIn(BaseModel):
    action: str  # approve | reject | clarify
    note: str = ""


@router.get("", summary="Danh sách đơn (đoàn viên: của mình — bí thư: toàn chi đoàn)")
def list_requests(user: User = Depends(get_current_user), db: DBSession = Depends(get_session)):
    stmt = select(MakeupRequest)
    if user.role == "member":
        me = db.exec(select(Member).where(Member.user_id == user.id)).first()
        if me is None:
            return []
        stmt = stmt.where(MakeupRequest.member_id == me.id)
    rows = db.exec(stmt).all()
    return [{"id": r.id, "member_id": r.member_id, "session_title": r.session_title,
             "reason": r.reason, "proof": r.proof, "status": r.status, "created_at": r.created_at}
            for r in rows]


@router.post("", summary="Gửi đơn xin phép / sinh hoạt bù (Đoàn viên)",
             dependencies=[Depends(require_permission("request:create"))])
def create_request(body: RequestIn, user: User = Depends(get_current_user), db: DBSession = Depends(get_session)):
    me = db.exec(select(Member).where(Member.user_id == user.id)).first()
    if me is None:
        raise HTTPException(status.HTTP_400_BAD_REQUEST, "Tài khoản chưa gắn hồ sơ đoàn viên.")
    r = MakeupRequest(member_id=me.id, session_title=body.session_title, reason=body.reason, proof=body.proof)
    db.add(r)
    db.add(AuditLog(actor=me.name, action=f'Gửi đơn sinh hoạt bù "{r.session_title}" — lý do: {r.reason}'))
    db.commit()
    return {"ok": True, "id": r.id, "status": r.status}


@router.post("/{request_id}/decide", summary="Xét duyệt đơn (Bí thư)",
             dependencies=[Depends(require_permission("request:decide"))])
def decide(request_id: int, body: DecisionIn, user: User = Depends(get_current_user), db: DBSession = Depends(get_session)):
    r = db.get(MakeupRequest, request_id)
    if r is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Không tìm thấy đơn.")
    if body.action not in ("approve", "reject", "clarify"):
        raise HTTPException(status.HTTP_400_BAD_REQUEST, "Hành động phải là approve / reject / clarify.")
    prev_status = r.status  # chống duyệt lại nhiều lần để cộng điểm (leo thang)
    r.status = {"approve": "approved", "reject": "rejected", "clarify": "clarify"}[body.action]
    r.decided_by = user.id
    r.decision_note = body.note
    m = db.get(Member, r.member_id)
    if body.action == "approve" and m and prev_status != "approved":
        m.makeup_count += 1
        m.points += 10
        m.status = "active"
        db.add(m)
    db.add(r)
    db.add(AuditLog(actor=user.full_name, action=f'Đơn của {m.name if m else r.member_id} → {r.status}'))
    db.commit()
    return {"ok": True, "status": r.status, "note": "Đơn được duyệt: +10 điểm chuyên cần, ghi nhận sinh hoạt bù." if body.action == "approve" else ""}
