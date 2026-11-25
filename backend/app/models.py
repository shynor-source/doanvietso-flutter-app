"""SQLModel — mô hình dữ liệu Đoàn Viên Số (Vòng 2).

Thiết kế bám 1:1 mock data của app Flutter (mock_data.dart):
Chi đoàn Khu phố 5 — P. Tam Hiệp, 46 đoàn viên, 12 chi đoàn phường.
"""
from datetime import datetime, timezone
from typing import Optional
from sqlmodel import SQLModel, Field


def utcnow() -> datetime:
    return datetime.now(timezone.utc)


class User(SQLModel, table=True):
    id: Optional[int] = Field(default=None, primary_key=True)
    phone: str = Field(index=True, unique=True)
    password_hash: str
    full_name: str
    # member | secretary | ward_officer
    role: str = Field(index=True)
    branch_id: Optional[int] = Field(default=None, foreign_key="branch.id")


class Branch(SQLModel, table=True):
    id: Optional[int] = Field(default=None, primary_key=True)
    name: str  # "Chi đoàn Khu phố 5"
    ward: str = "Phường Tam Hiệp"
    secretary_name: str = ""
    type: str = "Khu dân cư"  # Khu dân cư | Trường học | Doanh nghiệp KCN ...
    total_members: int = 0


class Member(SQLModel, table=True):
    id: Optional[int] = Field(default=None, primary_key=True)
    user_id: Optional[int] = Field(default=None, foreign_key="user.id")
    branch_id: int = Field(foreign_key="branch.id", index=True)
    member_code: str = Field(index=True)  # ĐV-DN-001
    name: str
    phone: str = ""
    # local | working_far | transferred
    type: str = "local"
    workplace: str = ""
    shift: str = ""
    points: int = 0
    makeup_count: int = 0
    # active | warning
    status: str = "active"


class Session(SQLModel, table=True):
    """Buổi sinh hoạt — chỉ Bí thư tạo/đóng/xóa."""
    id: Optional[int] = Field(default=None, primary_key=True)
    branch_id: int = Field(foreign_key="branch.id", index=True)
    title: str
    starts_at: datetime
    location: str = "Nhà văn hóa Khu phố 5"
    lat: float = 10.9565
    lng: float = 106.8244
    radius_m: int = 100  # geofence
    is_open: bool = True  # đóng đăng ký / kết thúc = False
    created_by: int = Field(foreign_key="user.id")
    created_at: datetime = Field(default_factory=utcnow)


class QrToken(SQLModel, table=True):
    """Mã QR động — mỗi mã dùng 1 lần, tự hết hạn (55s)."""
    id: Optional[int] = Field(default=None, primary_key=True)
    session_id: int = Field(foreign_key="session.id", index=True)
    token: str = Field(index=True)
    issued_at: datetime = Field(default_factory=utcnow)
    expires_at: datetime
    used_by: Optional[int] = Field(default=None, foreign_key="member.id")


class CheckIn(SQLModel, table=True):
    id: Optional[int] = Field(default=None, primary_key=True)
    session_id: int = Field(foreign_key="session.id", index=True)
    member_id: int = Field(foreign_key="member.id", index=True)
    # qr | manual | offline
    method: str = "qr"
    distance_m: Optional[float] = None
    in_geofence: bool = True
    created_at: datetime = Field(default_factory=utcnow)


class MakeupRequest(SQLModel, table=True):
    """Đơn xin phép / sinh hoạt bù — đoàn viên tạo, bí thư duyệt."""
    id: Optional[int] = Field(default=None, primary_key=True)
    member_id: int = Field(foreign_key="member.id", index=True)
    session_title: str
    reason: str
    proof: str = ""  # minh chứng: xác nhận tăng ca, chứng chỉ E-Learning...
    # pending | approved | rejected | clarify
    status: str = Field(default="pending", index=True)
    decided_by: Optional[int] = Field(default=None, foreign_key="user.id")
    decision_note: str = ""
    created_at: datetime = Field(default_factory=utcnow)


class WardReport(SQLModel, table=True):
    """Báo cáo định kỳ chi đoàn → phường. Cán bộ phường duyệt."""
    id: Optional[int] = Field(default=None, primary_key=True)
    branch_id: int = Field(foreign_key="branch.id", index=True)
    month: str = "11/2026"
    attended: int = 0
    total: int = 0
    # pending | submitted | approved
    status: str = Field(default="pending", index=True)
    approved_by: Optional[int] = Field(default=None, foreign_key="user.id")


class Activity(SQLModel, table=True):
    """Hoạt động / phong trào. Cán bộ phường phát động toàn phường."""
    id: Optional[int] = Field(default=None, primary_key=True)
    title: str
    category: str = "Sự kiện Đoàn"
    starts_at: datetime
    location: str = ""
    points: int = 15
    organizer: str = ""  # "Đoàn Phường Tam Hiệp" | "BCH Chi đoàn KP5"
    launched_by: int = Field(foreign_key="user.id")
    created_at: datetime = Field(default_factory=utcnow)


class Registration(SQLModel, table=True):
    """Đoàn viên đăng ký hoạt động vào lịch cá nhân."""
    id: Optional[int] = Field(default=None, primary_key=True)
    activity_id: int = Field(foreign_key="activity.id", index=True)
    member_id: int = Field(foreign_key="member.id", index=True)
    created_at: datetime = Field(default_factory=utcnow)


class Post(SQLModel, table=True):
    """Bảng tin — cán bộ được ghim / xóa."""
    id: Optional[int] = Field(default=None, primary_key=True)
    author_id: int = Field(foreign_key="user.id")
    content: str
    is_event: bool = False
    is_pinned: bool = False
    activity_id: Optional[int] = Field(default=None, foreign_key="activity.id", index=True)
    created_at: datetime = Field(default_factory=utcnow)


class Comment(SQLModel, table=True):
    id: Optional[int] = Field(default=None, primary_key=True)
    post_id: int = Field(foreign_key="post.id", index=True)
    author_id: int = Field(foreign_key="user.id")
    content: str
    created_at: datetime = Field(default_factory=utcnow)


class AuditLog(SQLModel, table=True):
    id: Optional[int] = Field(default=None, primary_key=True)
    actor: str
    action: str
    created_at: datetime = Field(default_factory=utcnow)


class Voucher(SQLModel, table=True):
    id: Optional[int] = Field(default=None, primary_key=True)
    title: str
    discount: str
    cost_points: int
    stock: int = 50


class VoucherRedemption(SQLModel, table=True):
    id: Optional[int] = Field(default=None, primary_key=True)
    voucher_id: int = Field(foreign_key="voucher.id")
    member_id: int = Field(foreign_key="member.id")
    code: str
    created_at: datetime = Field(default_factory=utcnow)
