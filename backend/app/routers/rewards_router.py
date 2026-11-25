"""Thi đua: hoạt động tình nguyện, xếp hạng, đổi voucher (chỉ đoàn viên đổi)."""
from secrets import token_hex
from fastapi import APIRouter, Depends, HTTPException, status
from sqlmodel import Session as DBSession, select

from ..auth import get_current_user
from ..database import get_session
from ..models import Member, Registration, User, Voucher, VoucherRedemption, utcnow

router = APIRouter(prefix="/rewards", tags=["rewards"])


@router.get("/vouchers", summary="Danh sách voucher (mọi vai trò)")
def vouchers(db: DBSession = Depends(get_session)):
    rows = db.exec(select(Voucher)).all()
    return [{"id": v.id, "title": v.title, "discount": v.discount, "cost_points": v.cost_points, "stock": v.stock} for v in rows]


@router.get("/activities", summary="Danh mục hoạt động thi đua (mọi vai trò)")
def activities(db: DBSession = Depends(get_session)):
    return []


@router.get("/ranking", summary="Top đoàn viên tích cực (mọi vai trò)")
def ranking(db: DBSession = Depends(get_session)):
    members = db.exec(select(Member).order_by(Member.points.desc()).limit(5)).all()
    return [{"member_code": m.member_code, "name": m.name, "points": m.points} for m in members]


@router.post("/activities/{activity_id}/register", summary="Đăng ký hoạt động (Đoàn viên)",
             dependencies=[Depends(get_current_user)])
def register(activity_id: int, user: User = Depends(get_current_user), db: DBSession = Depends(get_session)):
    if user.role != "member":
        raise HTTPException(status.HTTP_403_FORBIDDEN, "Chỉ đoàn viên đăng ký hoạt động vào lịch cá nhân.")
    me = db.exec(select(Member).where(Member.user_id == user.id)).first()
    if me is None:
        raise HTTPException(status.HTTP_400_BAD_REQUEST, "Tài khoản chưa gắn hồ sơ đoàn viên.")
    existed = db.exec(select(Registration).where(Registration.activity_id == activity_id, Registration.member_id == me.id)).first()
    if existed:
        raise HTTPException(status.HTTP_400_BAD_REQUEST, "Bạn đã đăng ký hoạt động này rồi.")
    db.add(Registration(activity_id=activity_id, member_id=me.id))
    db.commit()
    return {"ok": True, "message": "Đã thêm vào Lịch cá nhân."}


@router.post("/vouchers/{voucher_id}/redeem", summary="Đổi voucher (Đoàn viên)")
def redeem(voucher_id: int, user: User = Depends(get_current_user), db: DBSession = Depends(get_session)):
    if user.role != "member":
        raise HTTPException(status.HTTP_403_FORBIDDEN, "Chỉ đoàn viên được đổi voucher.")
    me = db.exec(select(Member).where(Member.user_id == user.id)).first()
    v = db.get(Voucher, voucher_id)
    if me is None or v is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Không tìm thấy voucher hoặc hồ sơ.")
    if me.points < v.cost_points:
        raise HTTPException(status.HTTP_400_BAD_REQUEST, f"Không đủ điểm — cần {v.cost_points}, bạn có {me.points}.")
    if v.stock <= 0:
        raise HTTPException(status.HTTP_400_BAD_REQUEST, "Voucher đã hết.")
    me.points -= v.cost_points
    v.stock -= 1
    code = f"DV-{token_hex(4).upper()}"
    db.add(VoucherRedemption(voucher_id=v.id, member_id=me.id, code=code))
    db.add_all([me, v])
    db.commit()
    return {"ok": True, "code": code, "remaining_points": me.points}
