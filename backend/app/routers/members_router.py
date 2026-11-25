"""Danh bạ & hồ sơ đoàn viên — CRUD chỉ dành cho Bí thư; cán bộ phường chỉ xem."""
from typing import Optional
from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel
from sqlmodel import Session as DBSession, select

from ..auth import get_current_user, require_permission
from ..database import get_session
from ..models import AuditLog, Branch, Member, User

router = APIRouter(prefix="/members", tags=["members"])


class MemberIn(BaseModel):
    name: str
    phone: str = ""
    type: str = "local"  # local | working_far | transferred
    workplace: str = ""
    shift: str = ""


class MemberPatch(BaseModel):
    """Cập nhật từng phần — app chỉ gửi trường cần đổi (vd phone)."""
    name: Optional[str] = None
    phone: Optional[str] = None
    type: Optional[str] = None
    workplace: Optional[str] = None
    shift: Optional[str] = None


@router.get("", summary="Danh sách đoàn viên (cán bộ/bí thư)")
def list_members(branch_id: Optional[int] = None, user: User = Depends(get_current_user), db: DBSession = Depends(get_session)):
    if user.role == "ward_officer":
        stmt = select(Member)
        if branch_id:
            stmt = stmt.where(Member.branch_id == branch_id)
    elif user.role == "secretary":
        stmt = select(Member).where(Member.branch_id == user.branch_id)
    else:
        raise HTTPException(status.HTTP_403_FORBIDDEN, "Đoàn viên không có quyền xem danh bạ tổng thể.")
    rows = db.exec(stmt).all()
    return [
        {
            "id": m.id, "member_code": m.member_code, "name": m.name, "phone": m.phone,
            "type": m.type, "workplace": m.workplace, "shift": m.shift,
            "points": m.points, "makeup_count": m.makeup_count, "status": m.status,
        }
        for m in rows
    ]


@router.post("", summary="Thêm đoàn viên (Bí thư)", dependencies=[Depends(require_permission("member:create"))])
def create_member(body: MemberIn, user: User = Depends(get_current_user), db: DBSession = Depends(get_session)):
    n = len(db.exec(select(Member)).all()) + 1
    m = Member(branch_id=user.branch_id or 1, member_code=f"ĐV-DN-{n + 300:03d}", name=body.name,
               phone=body.phone, type=body.type, workplace=body.workplace, shift=body.shift)
    db.add(m)
    db.add(AuditLog(actor=user.full_name, action=f"Thêm đoàn viên mới {m.name} ({m.member_code})"))
    db.commit()
    db.refresh(m)
    return {"ok": True, "id": m.id, "member_code": m.member_code}


@router.patch("/{member_id}", summary="Sửa hồ sơ (Bí thư)", dependencies=[Depends(require_permission("member:update"))])
def update_member(member_id: int, body: MemberPatch, user: User = Depends(get_current_user), db: DBSession = Depends(get_session)):
    m = db.get(Member, member_id)
    if m is None or (m.branch_id != user.branch_id and user.role != "ward_officer"):
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Không tìm thấy đoàn viên.")
    for k, v in body.model_dump(exclude_unset=True).items():
        if v is not None:
            setattr(m, k, v)
    db.add(m)
    db.add(AuditLog(actor=user.full_name, action=f"Cập nhật hồ sơ {m.name}"))
    db.commit()
    return {"ok": True}


@router.delete("/{member_id}", summary="Xóa đoàn viên (Bí thư)", dependencies=[Depends(require_permission("member:delete"))])
def delete_member(member_id: int, user: User = Depends(get_current_user), db: DBSession = Depends(get_session)):
    m = db.get(Member, member_id)
    if m is None or m.branch_id != user.branch_id:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Không tìm thấy đoàn viên.")
    db.add(AuditLog(actor=user.full_name, action=f"Xóa đoàn viên {m.name} ({m.member_code})"))
    db.delete(m)
    db.commit()
    return {"ok": True}
