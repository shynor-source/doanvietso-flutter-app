"""Quản trị tài khoản — Cán bộ Đoàn phường.

Phân quyền (rbac.py):
  - GET  /admin/users             → ward_officer (user:manage) — xem toàn bộ tài khoản
  - PATCH /admin/users/{id}/role  → ward_officer (user:manage) — đổi vai trò
Nguyên tắc:
  • Vai trò luôn do máy chủ gán — chức năng này là con đường quản trị chính thức
    (thay vì sửa DB trực tiếp), mọi thay đổi ghi AuditLog.
  • Không cho đổi vai trò của chính mình (tránh tự khóa quyền quản trị).
  • Đổi vai trò có hiệu lực ngay trên máy chủ (RBAC đọc user.role từ DB mỗi request);
    người dùng đăng nhập lại để ứng dụng cập nhật giao diện.
"""
from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel
from sqlmodel import Session as DBSession, select

from ..auth import get_current_user, hash_password, DEMO_PASSWORD, require_permission
from ..database import get_session
from ..models import AuditLog, Branch, Member, User
from .. import rbac

router = APIRouter(prefix="/admin", tags=["admin"])

ROLE_LABELS = {"member": "Đoàn viên", "secretary": "Bí thư chi đoàn", "ward_officer": "Cán bộ Đoàn phường"}


class RoleIn(BaseModel):
    role: str


@router.get("/users", summary="Danh sách toàn bộ tài khoản (Cán bộ Đoàn phường)",
            dependencies=[Depends(require_permission("user:manage"))])
def list_users(user: User = Depends(get_current_user), db: DBSession = Depends(get_session)):
    users = db.exec(select(User).order_by(User.id)).all()
    branches = {b.id: b.name for b in db.exec(select(Branch)).all()}
    members = {m.user_id: m for m in db.exec(select(Member).where(Member.user_id != None)).all()}  # noqa: E711
    out = []
    for u in users:
        m = members.get(u.id)
        out.append({
            "id": u.id,
            "full_name": u.full_name,
            "phone": u.phone,
            "role": u.role,
            "role_label": ROLE_LABELS.get(u.role, u.role),
            "branch": branches.get(u.branch_id, ""),
            "member_id": m.id if m else None,
            "member_code": m.member_code if m else None,
            "points": m.points if m else None,
            "member_type": m.type if m else None,
        })
    return {"users": out, "total": len(out)}


@router.patch("/users/{user_id}/role", summary="Đổi vai trò tài khoản (Cán bộ Đoàn phường)",
              dependencies=[Depends(require_permission("user:manage"))])
def set_role(user_id: int, body: RoleIn, user: User = Depends(get_current_user), db: DBSession = Depends(get_session)):
    if body.role not in rbac.ROLES:
        raise HTTPException(status.HTTP_400_BAD_REQUEST, "Vai trò phải là member / secretary / ward_officer.")
    target = db.get(User, user_id)
    if target is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Không tìm thấy tài khoản.")
    if target.id == user.id:
        raise HTTPException(status.HTTP_400_BAD_REQUEST, "Không thể đổi vai trò của chính mình.")
    if target.role == body.role:
        return {"ok": True, "role": target.role, "role_label": ROLE_LABELS[target.role], "note": "Tài khoản đã ở vai trò này."}
    # Chỉ cấp vai trò Đoàn viên cho tài khoản đã gắn hồ sơ đoàn viên
    # (chức năng đoàn viên — quét QR, đổi voucher — cần hồ sơ).
    if body.role == "member" and db.exec(select(Member).where(Member.user_id == target.id)).first() is None:
        raise HTTPException(status.HTTP_400_BAD_REQUEST, "Tài khoản chưa gắn hồ sơ đoàn viên — không thể cấp vai trò Đoàn viên.")
    prev = target.role
    target.role = body.role
    db.add(target)
    db.add(AuditLog(actor=user.full_name,
                    action=f"Đổi vai trò {target.full_name} ({target.phone}): {ROLE_LABELS.get(prev, prev)} → {ROLE_LABELS[body.role]}"))
    db.commit()
    return {"ok": True, "role": body.role, "role_label": ROLE_LABELS[body.role],
            "note": "Vai trò đã hiệu lực trên máy chủ — người dùng đăng nhập lại để cập nhật giao diện."}


# Danh sách tên Việt để sinh tài khoản demo đa dạng (deterministic theo chỉ số)
_HO = ["Nguyễn", "Trần", "Lê", "Phạm", "Hoàng", "Phan", "Vũ", "Đặng", "Bùi", "Đỗ", "Ngô", "Dương"]
_DEM = ["", "Văn", "Thị", "Hoài", "Quốc", "Thị Thu", "Văn Công", "Ngọc", "Thanh", "Minh"]
_TEN = ["Bảo", "Hà", "Hùng", "Lan", "Nam", "Thảo", "Tâm", "Vy", "Phúc", "Yến", "Kiên", "Mai",
        "Dũng", "Nhung", "Quân", "Trang", "Sơn", "Ngọc Anh", "Khánh", "Linh", "Tuấn", "Hương",
        "Đạt", "Ly", "Long", "Thắm", "Hiếu", "Vy", "Cường", "Xuyến"]
_NOI_LAM = ["Cty Changshin – KCN Thạnh Phú", "Cty Taekwang Vina – KCN BH2", "KCN Amata Biên Hòa",
            "Cty Hwaseung Vina – KCN Nhơn Trạch", "Công ty may Long Thành", "KCN Biên Hòa 2"]
_CA = ["Ca ngày (07h - 15h)", "Ca 2 (14h - 22h)", "Ca đêm (22h - 06h)", "Ca 3 luân phiên"]


@router.post("/users/demo-batch", summary="Tạo nhanh tài khoản đoàn viên (Cán bộ Đoàn phường — phục vụ trình diễn)",
             dependencies=[Depends(require_permission("user:manage"))])
def create_demo_batch(count: int = 24, user: User = Depends(get_current_user), db: DBSession = Depends(get_session)):
    """Sinh N tài khoản đoàn viên + hồ sơ, idempotent (bỏ qua SĐT đã tồn tại).
    SĐT: 0907700001… — mật khẩu = mật khẩu demo chung. Loại phân bổ đa dạng.
    """
    count = max(1, min(count, 60))
    pw = hash_password(DEMO_PASSWORD)
    branches = db.exec(select(Branch)).all()
    if not branches:
        raise HTTPException(status.HTTP_400_BAD_REQUEST, "Chưa có chi đoàn trong hệ thống.")
    # SĐT đã tồn tại
    phones = {u.phone for u in db.exec(select(User)).all()}
    # Mã ĐV tiếp theo
    max_no = 0
    for m in db.exec(select(Member)).all():
        try:
            max_no = max(max_no, int(m.member_code.split("-")[-1]))
        except ValueError:
            pass
    types = ["local", "working_far", "working_far", "local", "transferred", "local"]
    created, skipped = 0, 0
    i = 1
    while created < count and i <= count * 3:
        phone = f"0907700{i:03d}"  # 0907700001…0907700060 (10 số)
        if phone in phones:
            skipped += 1
            i += 1
            continue
        name = f"{_HO[i % len(_HO)]} {_DEM[(i * 3) % len(_DEM)]} {_TEN[(i * 7) % len(_TEN)]}".replace("  ", " ")
        u = User(phone=phone, password_hash=pw, full_name=name, role="member", branch_id=branches[i % len(branches)].id)
        db.add(u)
        db.flush()
        max_no += 1
        t = types[i % len(types)]
        m = Member(
            user_id=u.id, branch_id=u.branch_id, member_code=f"ĐV-DN-{max_no:03d}", name=name, phone=phone,
            type=t, workplace=_NOI_LAM[i % len(_NOI_LAM)] if t == "working_far" else "",
            shift=_CA[i % len(_CA)] if t == "working_far" else "Ca ngày (07h - 15h)",
            points=[120, 95, 88, 72, 65, 110, 54, 140, 37, 82][i % 10], makeup_count=i % 3, status="active",
        )
        db.add(m)
        created += 1
        i += 1
    db.add(AuditLog(actor=user.full_name, action=f"Tạo hàng loạt {created} tài khoản đoàn viên demo"))
    db.commit()
    return {"ok": True, "created": created, "skipped": skipped,
            "note": f"Đã tạo {created} tài khoản (SĐT 0907700xxx — mật khẩu demo chung)."}
