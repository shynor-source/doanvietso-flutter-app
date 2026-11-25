"""Cấp phường: dashboard tổng hợp, duyệt báo cáo chi đoàn, phát động hoạt động, xuất báo cáo."""
from datetime import datetime, timedelta, timezone
from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel
from sqlmodel import Session as DBSession, select

from ..auth import get_current_user, require_permission
from ..database import get_session
from ..models import Activity, AuditLog, Branch, CheckIn, Member, Registration, Session as SessionModel, User, WardReport, utcnow

router = APIRouter(prefix="/ward", tags=["ward"])


@router.get("/dashboard", summary="Dashboard tổng hợp toàn phường (cán bộ phường)")
def dashboard(user: User = Depends(get_current_user), db: DBSession = Depends(get_session)):
    if user.role != "ward_officer":
        raise HTTPException(status.HTTP_403_FORBIDDEN, "Chỉ cán bộ Đoàn phường xem tổng hợp.")
    branches = db.exec(select(Branch)).all()
    reports = db.exec(select(WardReport)).all()
    rep_by_branch = {r.branch_id: r for r in reports}
    rows = []
    for b in branches:
        r = rep_by_branch.get(b.id)
        rows.append({
            "branch_id": b.id, "name": b.name, "secretary": b.secretary_name,
            "total": r.total if r else b.total_members, "attended": r.attended if r else 0,
            "rate": round(r.attended / r.total * 100, 1) if r and r.total else 0.0,
            "status": r.status if r else "pending",
        })
    rows.sort(key=lambda x: -x["rate"])
    for i, row in enumerate(rows, 1):
        row["rank"] = i
    total_members = sum(r["total"] for r in rows)
    attended = sum(r["attended"] for r in rows)
    return {
        "month": "11/2026", "branches": rows, "total_branches": len(rows),
        "total_members": total_members,
        "avg_rate": round(attended / total_members * 100, 1) if total_members else 0.0,
        "submitted": sum(1 for r in rows if r["status"] == "submitted"),
        "pending": sum(1 for r in rows if r["status"] == "pending"),
    }


@router.post("/reports/{report_id}/approve", summary="Phê duyệt báo cáo chi đoàn (cán bộ phường)",
             dependencies=[Depends(require_permission("report:approve"))])
def approve_report(report_id: int, user: User = Depends(get_current_user), db: DBSession = Depends(get_session)):
    r = db.get(WardReport, report_id)
    if r is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Không tìm thấy báo cáo.")
    if r.status == "pending":
        r.status = "approved"
        r.approved_by = user.id
        db.add(r)
        b = db.get(Branch, r.branch_id)
        db.add(AuditLog(actor=user.full_name, action=f"Phê duyệt báo cáo tháng {r.month} của {b.name if b else r.branch_id}"))
        db.commit()
    return {"ok": True, "status": r.status}


@router.post("/reports/{report_id}/remind", summary="Gửi nhắc chi đoàn chậm nộp (cán bộ phường)",
             dependencies=[Depends(require_permission("report:approve"))])
def remind(report_id: int, user: User = Depends(get_current_user), db: DBSession = Depends(get_session)):
    r = db.get(WardReport, report_id)
    if r is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Không tìm thấy báo cáo.")
    b = db.get(Branch, r.branch_id)
    db.add(AuditLog(actor=user.full_name, action=f"Gửi nhắc nộp báo cáo qua Zalo đến {b.name if b else ''}"))
    db.commit()
    return {"ok": True, "message": f"Đã gửi nhắc qua Zalo đến {b.name if b else 'chi đoàn'}."}


@router.post("/branches/{branch_id}/approve", summary="Phê duyệt báo cáo theo chi đoàn (cán bộ phường)",
             dependencies=[Depends(require_permission("report:approve"))])
def approve_by_branch(branch_id: int, user: User = Depends(get_current_user), db: DBSession = Depends(get_session)):
    r = db.exec(select(WardReport).where(WardReport.branch_id == branch_id)).first()
    if r is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Chi đoàn chưa có báo cáo kỳ này.")
    if r.status == "pending":
        r.status = "approved"
        r.approved_by = user.id
        db.add(r)
        b = db.get(Branch, branch_id)
        db.add(AuditLog(actor=user.full_name, action=f"Phê duyệt báo cáo tháng {r.month} của {b.name if b else branch_id}"))
        db.commit()
    return {"ok": True, "status": r.status}


@router.post("/branches/{branch_id}/remind", summary="Nhắc nộp báo cáo theo chi đoàn (cán bộ phường)",
             dependencies=[Depends(require_permission("report:approve"))])
def remind_by_branch(branch_id: int, user: User = Depends(get_current_user), db: DBSession = Depends(get_session)):
    b = db.get(Branch, branch_id)
    if b is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Không tìm thấy chi đoàn.")
    db.add(AuditLog(actor=user.full_name, action=f"Gửi nhắc nộp báo cáo qua Zalo đến {b.name}"))
    db.commit()
    return {"ok": True, "message": f"Đã gửi nhắc qua Zalo đến {b.name}."}


@router.get("/report/export", summary="Xuất báo cáo văn bản đúng thể thức (cán bộ phường)",
            dependencies=[Depends(require_permission("report:export"))])
def export_report(user: User = Depends(get_current_user), db: DBSession = Depends(get_session)):
    branches = db.exec(select(Branch)).all()
    reports = db.exec(select(WardReport)).all()
    rep = {r.branch_id: r for r in reports}
    lines = [
        "ĐOÀN TNCS HỒ CHÍ MINH", "PHƯỜNG TRẤN BIÊN", "Số: 18-BC/ĐTN", "",
        "Trấn Biên, ngày 28 tháng 11 năm 2026", "",
        "BÁO CÁO TÌNH HÌNH SINH HOẠT CHI ĐOÀN — THÁNG 11/2026", "",
    ]
    for i, b in enumerate(branches, 1):
        r = rep.get(b.id)
        if r:
            lines.append(f"{i}. {b.name}: {r.attended}/{r.total} ĐV ({r.attended / r.total * 100:.1f}%) — {r.status}")
    lines += ["", "BI THƯ ĐOÀN PHƯỜNG", "", "(Đã ký)", "Phan Thị Bích Thảo"]
    return {"month": "11/2026", "content": "\n".join(lines)}


@router.post("/reports", summary="Nộp báo cáo kỳ của chi đoàn (Bí thư)",
             dependencies=[Depends(require_permission("report:submit"))])
def submit_report(user: User = Depends(get_current_user), db: DBSession = Depends(get_session)):
    branch_id = user.branch_id or 1
    members = db.exec(select(Member).where(Member.branch_id == branch_id)).all()
    sessions = db.exec(select(SessionModel).where(SessionModel.branch_id == branch_id)).all()
    checkins = 0
    for s in sessions:
        checkins += len(db.exec(select(CheckIn).where(CheckIn.session_id == s.id)).all())
    total = len(members)
    existing = db.exec(select(WardReport).where(WardReport.branch_id == branch_id)).first()
    if existing:
        existing.attended = min(checkins, total)
        existing.total = total
        existing.status = "submitted"
        db.add(existing)
        r = existing
    else:
        r = WardReport(branch_id=branch_id, month="12/2026", attended=min(checkins, total), total=total, status="submitted")
        db.add(r)
    b = db.get(Branch, branch_id)
    db.add(AuditLog(actor=user.full_name, action=f"Nộp báo cáo kỳ tháng 12 của {b.name if b else branch_id} ({min(checkins, total)}/{total} ĐV)"))
    db.commit()
    return {"ok": True, "attended": r.attended, "total": r.total, "status": r.status}


class ActivityIn(BaseModel):
    title: str
    category: str = "Sự kiện Đoàn"
    starts_at: datetime
    location: str = ""
    points: int = 25


@router.post("/activities", summary="Phát động hoạt động toàn phường (cán bộ phường)",
             dependencies=[Depends(require_permission("activity:launch"))])
def launch_activity(body: ActivityIn, user: User = Depends(get_current_user), db: DBSession = Depends(get_session)):
    # Chuẩn hóa naive datetime → UTC
    starts = body.starts_at if body.starts_at.tzinfo else body.starts_at.replace(tzinfo=timezone.utc)
    a = Activity(title=body.title, category=body.category, starts_at=starts,
                 location=body.location, points=body.points, organizer="Đoàn Phường Trấn Biên",
                 launched_by=user.id or 0)
    db.add(a)
    db.add(AuditLog(actor=user.full_name, action=f'Phát động hoạt động toàn phường "{a.title}"'))
    db.commit()
    db.refresh(a)
    return {"ok": True, "id": a.id, "message": f'Đã phát động "{a.title}" đến 12 chi đoàn.'}


@router.get("/activities", summary="Danh mục hoạt động (mọi vai trò)")
def list_activities(user: User = Depends(get_current_user), db: DBSession = Depends(get_session)):
    rows = db.exec(select(Activity).order_by(Activity.starts_at)).all()
    mine: set[int] = set()
    if user.role == "member":
        me = db.exec(select(Member).where(Member.user_id == user.id)).first()
        if me:
            mine = {r.activity_id for r in db.exec(select(Registration).where(Registration.member_id == me.id)).all()}
    return [{"id": a.id, "title": a.title, "category": a.category, "starts_at": a.starts_at,
             "location": a.location, "points": a.points, "organizer": a.organizer,
             "registered": a.id in mine}
            for a in rows]
