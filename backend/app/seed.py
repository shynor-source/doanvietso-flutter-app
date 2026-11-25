"""Dữ liệu mẫu Vòng 2 — đồng bộ mockData.js/mock_data.dart của app."""
from datetime import datetime, timedelta, timezone

from sqlmodel import Session as DBSession, select

from . import auth
from .models import (
    Activity, AuditLog, Branch, Member, Post, Session as SessionModel,
    User, Voucher, WardReport,
)

UTC = timezone.utc


def seed(db: DBSession) -> None:
    if db.exec(select(User)).first() is not None:
        return  # đã seed

    # --- Chi đoàn ---
    branches = [
        Branch(id=1, name="Chi đoàn Khu phố 5", ward="Phường Trấn Biên", secretary_name="Nguyễn Văn An", type="Khu dân cư & CN KCN", total_members=46),
        Branch(id=2, name="Chi đoàn Khu phố 1", secretary_name="Lê Hoàng Minh", type="Khu dân cư", total_members=42),
        Branch(id=3, name="Chi đoàn Trường THCS Trấn Biên", secretary_name="Nguyễn Ngọc Ánh", type="Trường học", total_members=28),
        Branch(id=4, name="Chi đoàn DN KCN Trấn Biên", secretary_name="Lý Gia Bảo", type="Doanh nghiệp KCN", total_members=60),
        Branch(id=5, name="Chi đoàn Khu phố 6", secretary_name="Mai Văn Hải", type="Khu dân cư", total_members=40),
    ]
    db.add_all(branches)
    db.flush()

    # --- Tài khoản demo (thông tin đăng nhập không công bố trên repo công khai) ---
    pw = auth.hash_password(auth.DEMO_PASSWORD)
    users = [
        User(id=1, phone="0912345678", password_hash=pw, full_name="Nguyễn Văn An", role="secretary", branch_id=1),
        User(id=2, phone="0981112233", password_hash=pw, full_name="Trần Minh Quân", role="member", branch_id=1),
        User(id=3, phone="0903334444", password_hash=pw, full_name="Phan Thị Bích Thảo", role="ward_officer", branch_id=1),
    ]
    db.add_all(users)
    db.flush()  # Postgres: ghi user trước member (khóa ngoại user_id)

    # --- 46 đoàn viên Chi đoàn KP5 (31 local / 12 far / 3 transferred) ---
    roster = [
        ("ĐV-DN-001", "Trần Minh Quân", "working_far", "Cty Changshin – KCN Thạnh Phú", "Ca đêm (22h - 06h)", 95, 2),
        ("ĐV-DN-002", "Lê Thị Thu Thảo", "working_far", "Cty Taekwang Vina – KCN BH2", "Ca 2 (14h - 22h)", 88, 1),
        ("ĐV-DN-003", "Nguyễn Quốc Bảo", "working_far", "KCN Amata Biên Hòa", "Ca 3 luân phiên", 72, 0),
        ("ĐV-DN-004", "Phạm Thị Mỹ Linh", "working_far", "KCN Long Đức, Long Thành", "Ca 1 (06h - 14h)", 90, 2),
        ("ĐV-DN-005", "Hoàng Văn Dũng", "working_far", "KCN Nhơn Trạch 1", "Tăng ca kíp", 65, 1),
        ("ĐV-DN-006", "Vũ Thị Ánh Tuyết", "working_far", "KCN Sông Mây, Trảng Bom", "Ca 2", 78, 1),
        ("ĐV-DN-007", "Đặng Tuấn Khang", "working_far", "Cty Pouches Việt Nam – KCN Amata", "Ca 1", 82, 0),
        ("ĐV-DN-008", "Bùi Diễm Hương", "working_far", "Nhà máy may mặc KCN Bình Đốc", "Ca 3", 80, 1),
        ("ĐV-DN-009", "Đỗ Hữu Tài", "working_far", "KCN Sông Mây, Trảng Bom", "Ca đêm", 76, 2),
        ("ĐV-DN-010", "Ngô Thanh Tú", "working_far", "KCN Long Bình Tân", "Ca 2", 74, 0),
        ("ĐV-DN-011", "Lý Quốc Huy", "working_far", "KCN Nhơn Trạch 3", "Ca 1", 71, 0),
        ("ĐV-DN-012", "Dương Thúy Vi", "working_far", "Cty Hansoll – KCN BH2", "Ca 2", 85, 1),
        ("ĐV-DN-013", "Nguyễn Tấn Đạt", "transferred", "Đại học Đồng Nai (Chuyển đi)", "", 80, 0),
        ("ĐV-DN-014", "Trương Ngọc Hân", "transferred", "Chuyển về P. Quyết Thắng", "", 77, 0),
        ("ĐV-DN-015", "Võ Đình Trọng", "transferred", "Chuyển về TX. Long Khánh", "", 75, 0),
    ]
    for i in range(16, 47):
        roster.append((f"ĐV-DN-{i:03d}", f"Đoàn viên địa phương {i:02d}", "local", "Tại khu phố 5", "Tự do", 80 + i % 18, 0))
    # Bí thư + 30 đoàn viên tại địa phương thực danh (mẫu)
    real_locals = [
        ("Nguyễn Văn An (Bí thư)", "Hộ kinh doanh KP5", 98), ("Trần Thị Mai", "Giáo viên Mầm non KP5", 96),
        ("Lê Hoàng Nam", "UBND Phường Trấn Biên", 94), ("Phạm Hồng Nhung", "Tiệm thuốc Trấn Biên", 92),
        ("Đoàn Thanh Tùng", "Kỹ sư IT tự do", 95), ("Vũ Minh Hằng", "CĐ Y tế Đồng Nai", 88),
        ("Nguyễn Đăng Khoa", "Cửa hàng xe máy KP5", 87), ("Bùi Kim Oanh", "Kế toán tư nhân", 91),
        ("Đặng Quốc Anh", "Điện lực Biên Hòa", 93), ("Trịnh Thị Lan", "Trường Tiểu học Trấn Biên", 95),
        ("Phan Minh Trí", "Bưu điện Trấn Biên", 86), ("Lê Thùy Dung", "Agribank P. Trấn Biên", 97),
        ("Tạ Văn Bình", "Xưởng mộc gia đình KP5", 84), ("Cao Thị Yến", "Cửa hàng tạp hóa KP5", 89),
        ("Ngô Đức Thắng", "Công ty vận tải Biên Hòa", 82), ("Mai Phương Uyên", "Trung tâm Ngoại ngữ KP5", 94),
        ("Lâm Hoàng Phúc", "Co.opmart Trấn Biên", 88), ("Đoàn Thúy Nga", "Văn phòng Công chứng", 92),
        ("Phùng Văn Khôi", "Cửa hàng Viettel Trấn Biên", 87), ("Hồ Quỳnh Chi", "Nha khoa Nụ Cười Xinh", 90),
        ("Thái Bá Đạt", "Đại lý phân phối Bia KP5", 83), ("Vương Bảo Trâm", "Phòng Gym Trấn Biên", 91),
        ("Lương Thế Vinh", "Đồ họa freelance KP5", 86),
    ]
    roster = roster[:15] + [("ĐV-DN-%03d" % (16 + k), n, "local", w, "Hành chính", p, 0) for k, (n, w, p) in enumerate(real_locals)] + roster[15+23:]

    members = []
    for idx, (code, name, mtype, workplace, shift, points, makeups) in enumerate(roster[:46], start=1):
        members.append(Member(
            id=idx, user_id=2 if code == "ĐV-DN-001" else None, branch_id=1, member_code=code,
            name=name, phone="0900000000", type=mtype, workplace=workplace, shift=shift,
            points=points, makeup_count=makeups, status="warning" if points < 70 else "active",
        ))
    db.add_all(members)
    db.flush()
    db.get(Branch, 1).total_members = 46

    # --- Buổi sinh hoạt đang mở ---
    now = datetime.now(UTC)
    session = SessionModel(
        id=1, branch_id=1, title="Sinh hoạt Chi đoàn tháng 12: Thanh niên công nhân tiên phong Số hóa",
        starts_at=now + timedelta(days=4), location="Nhà văn hóa Khu phố 5", lat=10.9565, lng=106.8244,
        radius_m=100, is_open=True, created_by=1,
    )
    db.add(session)

    # --- Đơn sinh hoạt bù ---
    from .models import MakeupRequest
    db.add_all([
        MakeupRequest(id=1, member_id=2, session_title="Sinh hoạt tháng 11", reason="Trực ca 2 nhà máy Taekwang Vina", proof="Xác nhận của Quản đốc xưởng", status="pending"),
        MakeupRequest(id=2, member_id=9, session_title="Sinh hoạt tháng 11", reason="Tăng ca kíp KCN Nhơn Trạch", proof="Đơn công ty", status="pending"),
    ])

    # --- Báo cáo chi đoàn gửi phường (tháng 11) ---
    reports = [
        (1, 33, 46, "submitted"), (2, 36, 42, "submitted"), (3, 24, 28, "submitted"),
        (4, 37, 60, "submitted"), (5, 22, 40, "pending"),
    ]
    db.add_all([WardReport(branch_id=b, month="11/2026", attended=a, total=t, status=s) for b, a, t, s in reports])

    # --- Hoạt động + voucher + bảng tin ---
    db.add_all([
        Activity(id=1, title="Mùa hè xanh 2026 – Dạy văn hóa cho em", category="Tình nguyện", starts_at=now + timedelta(days=20), location="Khu phố 5", points=120, organizer="Đoàn Phường Trấn Biên", launched_by=3),
        Activity(id=2, title="Chiến dịch Tết an toàn giao thông", category="Tình nguyện", starts_at=datetime(2027, 1, 10, tzinfo=UTC), location="Trấn Biên", points=80, organizer="Đoàn Phường Trấn Biên", launched_by=3),
    ])
    db.add_all([
        Voucher(id=1, title="Voucher cà phê Highlands", discount="Giảm 30%", cost_points=200, stock=30),
        Voucher(id=2, title="Voucher xe OMG", discount="Giảm 15.000đ", cost_points=150, stock=50),
    ])
    db.add_all([
        Post(id=1, author_id=1, content="🔥 33/46 đoàn viên đã hoàn thành điểm danh buổi sinh hoạt tháng 11. Cảm ơn các bạn công nhân KCN đã tham gia dù vừa tan ca!", is_pinned=True),
        Post(id=2, author_id=2, content="Buổi e-learning 'Nghị quyết Đại hội Đoàn' rất hay, chị em công nhân nhà máy cùng nhau học sau ca 2 📚"),
        Post(id=3, author_id=3, content="🌳 PHÁT ĐỘNG: 'Mùa hè xanh 2026 – Dạy văn hóa cho em' toàn phường! Anh chị em đoàn viên đăng ký tham dự ngay từ bài viết này để được cộng điểm rèn luyện và nhận nhắc lịch trước giờ diễn ra nhé!", is_event=True, activity_id=1),
    ])
    db.add(AuditLog(actor="Hệ thống", action="Khởi tạo dữ liệu mẫu Vòng 2"))
    db.commit()
