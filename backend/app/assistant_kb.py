"""Cơ sở tri thức cho Trợ lý ảo AI (assistant).

Mỗi mục mô tả MỘT chức năng của app: nó ở đâu (màn hình đích — nav),
ai được dùng (roles — đồng bộ ma trận RBAC backend/app/rbac.py),
dùng thế nào (steps), và từ khóa nhận diện (keywords).

Role → quyền: member | secretary | ward_officer.
nav là key màn hình app Flutter (app_shell.dart):
  member   : home, makeup, scan_qr, history, rewards, social, menu
  secretary: home, makeup, create_qr, members, reports, rewards, social, menu
  ward     : ward_dash, makeup, ward_branches, ward_reports, ward_rewards, rewards, social, menu
"""
KB = [
    # ===== CHUNG (mọi vai trò) =====
    {
        "id": "assistant_login",
        "title": "Đăng nhập / Đăng xuất & đổi vai trò",
        "roles": ["member", "secretary", "ward_officer"],
        "nav": "menu",
        "nav_label": "Mở màn Tiện ích",
        "summary": "Đăng nhập bằng số điện thoại + mã OTP; vai trò do hệ thống tự gán theo tài khoản. Đăng xuất và quản lý tài khoản ở màn Tiện ích.",
        "steps": [
            "Mở app → nhập số điện thoại đã đăng ký → bấm Đăng nhập",
            "Nhập mã OTP (demo: mã dùng chung được cấu hình sẵn) → Xác thực",
            "Hệ thống tự nhận vai trò: Đoàn viên / Bí thư chi đoàn / Cán bộ Đoàn phường — không tự chọn được",
            "Đăng xuất: tab Tiện ích → Hồ sơ → Đăng xuất",
        ],
        "keywords": ["đăng nhập", "đăng xuất", "otp", "mã xác thực", "vai trò", "đổi vai trò", "tài khoản", "đăng ký mới"],
    },
    {
        "id": "assistant_post",
        "title": "Đăng bài lên Bảng tin (kèm ảnh thật)",
        "roles": ["member", "secretary", "ward_officer"],
        "nav": "social",
        "nav_label": "Mở Bảng tin",
        "summary": "Mọi vai trò đều đăng được bài (+5 điểm cho đoàn viên), kèm ảnh từ thư viện/chụp camera, thích và bình luận.",
        "steps": [
            "Tab Bảng tin → bấm ô 'Đăng bài' phía trên danh sách",
            "Nhập nội dung → bấm 'Thư viện' (chọn ảnh có sẵn) hoặc 'Chụp ảnh' (camera) — ảnh tự nén trước khi gửi",
            "Gắn thẻ hoạt động đã tham gia (tùy chọn) → bấm Đăng bài",
            "Thích/bình luận: bấm ❤ hoặc 💬 dưới bài viết",
        ],
        "keywords": ["đăng bài", "bảng tin", "ảnh", "đăng ảnh", "bình luận", "like", "thích", "chia sẻ"],
    },
    {
        "id": "assistant_event",
        "title": "Xem & Đăng ký sự kiện từ Bảng tin",
        "roles": ["member", "secretary", "ward_officer"],
        "nav": "social",
        "nav_label": "Mở Bảng tin",
        "summary": "Bài phát động sự kiện có thẻ xanh 'Đăng ký tham dự' — bấm 1 lần là đăng ký và tự thêm vào Lịch cá nhân.",
        "steps": [
            "Tab Bảng tin → lọc 'Sự kiện mở đăng ký' để xem nhanh",
            "Tìm bài có thẻ xanh (VD: '+30 điểm • N đã đăng ký')",
            "Bấm 'Đăng ký tham dự (Thêm vào Lịch)' → thẻ đổi thành '✓ Đã có trong Lịch'",
            "Xem lại ở tab Lịch → 'Lịch của tôi'",
        ],
        "keywords": ["sự kiện", "đăng ký", "đăng ký tham dự", "phát động", "hoạt động", "mùa hè xanh", "chủ nhật xanh", "tết"],
    },
    {
        "id": "assistant_notification",
        "title": "Hộp thư & thông báo",
        "roles": ["member", "secretary", "ward_officer"],
        "nav": "menu",
        "nav_label": "Mở màn Tiện ích",
        "summary": "Biểu tượng chuông ở góc phải thanh tiêu đề — thông báo riêng cho từng vai trò (điểm danh, duyệt đơn, chứng chỉ, nhắc nộp báo cáo).",
        "steps": [
            "Bấm biểu tượng chuông ở góc phải trên (có số đỏ nếu có tin mới)",
            "Xem danh sách thông báo — các tin mới có dấu chấm xanh",
        ],
        "keywords": ["thông báo", "hộp thư", "chuông", "tin nhắn", "nhắc"],
    },
    {
        "id": "assistant_profile",
        "title": "Hồ sơ cá nhân & thông tin tài khoản",
        "roles": ["member", "secretary", "ward_officer"],
        "nav": "menu",
        "nav_label": "Mở màn Tiện ích",
        "summary": "Mã đoàn viên, đơn vị, ngày gia nhập, điểm rèn luyện, quản trị tài khoản, sao lưu/khôi phục dữ liệu cục bộ.",
        "steps": [
            "Tab Tiện ích → nhóm 'Tài khoản' → Hồ sơ",
            "Mục 'Quản trị & Bảo mật' chứa phân quyền, sao lưu dữ liệu offline",
        ],
        "keywords": ["hồ sơ", "tài khoản", "mã đoàn viên", "bảo mật", "sao lưu", "quản trị"],
    },

    # ===== RIÊNG ĐOÀN VIÊN =====
    {
        "id": "assistant_checkin",
        "title": "Điểm danh bằng mã QR (2 lớp: QR xoay + GPS)",
        "roles": ["member"],
        "nav": "scan_qr",
        "nav_label": "Mở màn Quét QR",
        "summary": "Tới đúng nơi tổ chức, quét mã QR bí thư đang chiếu. Mã đổi mỗi 55 giây, dùng 1 lần, phải nằm trong bán kính 100m.",
        "steps": [
            "Tab 'Quét QR' (hoặc trang chủ → nút Quét QR) → cho phép dùng camera",
            "Quét mã QR đang hiển thị trên màn hình Bí thư — hoặc bấm 'Nhập mã thủ công' nếu camera hỏng",
            "Giữ GPS bật — máy chủ kiểm tra khoảng cách tới điểm sinh hoạt",
            "Thành công: +5 điểm chuyên cần, hiện khoảng cách. Mã hết hạn (55s)/đã dùng → chờ mã mới",
        ],
        "keywords": ["điểm danh", "quét qr", "qr", "checkin", "check in", "sinh hoạt", "geofence", "gps", "vị trí"],
    },
    {
        "id": "assistant_schedule",
        "title": "Lịch hoạt động cá nhân",
        "roles": ["member"],
        "nav": "makeup",
        "nav_label": "Mở màn Lịch",
        "summary": "Gộp mọi hoạt động của bạn: Lịch của tôi, hoạt động mở đăng ký, đơn sinh hoạt bù.",
        "steps": [
            "Tab 'Lịch' → 3 mục: 'Lịch của tôi' • 'Đăng ký' • 'Đơn của tôi'",
            "Chọn ngày trong dải tuần phía trên để xem hoạt động",
            "Nút 'Điểm danh QR' trên từng hoạt động khi tới buổi",
            "Bấm 'Hủy lịch' để rút khỏi hoạt động chưa diễn ra",
        ],
        "keywords": ["lịch", "lịch cá nhân", "lịch của tôi", "hủy lịch", "xem lịch", "hoạt động sắp tới"],
    },
    {
        "id": "assistant_makeup",
        "title": "Xin sinh hoạt bù (cho người làm ca)",
        "roles": ["member"],
        "nav": "makeup",
        "nav_label": "Mở màn Lịch",
        "summary": "Không tới được buổi chính (làm ca, tăng ca) → gửi đơn xin sinh hoạt bù kèm minh chứng, chờ Bí thư duyệt (+10 điểm khi được duyệt).",
        "steps": [
            "Tab 'Lịch' → tab 'Đơn của tôi' → nút tạo đơn mới",
            "Chọn buổi, nhập lý do (làm ca đêm, công tác…), đính kèm minh chứng",
            "Gửi đơn → chờ Bí thư chi đoàn duyệt (theo dõi trạng thái ngay tại đây)",
            "Đơn được duyệt → +10 điểm, thông báo tới Hộp thư",
        ],
        "keywords": ["sinh hoạt bù", "đơn", "xin phép", "nghỉ", "làm ca", "ca đêm", "bù", "minh chứng", "duyệt đơn"],
    },
    {
        "id": "assistant_rewards",
        "title": "Thi đua, xếp hạng & đổi voucher",
        "roles": ["member"],
        "nav": "rewards",
        "nav_label": "Mở màn Thi đua",
        "summary": "Điểm rèn luyện là 'tiền tệ': đủ điểm đổi voucher thật (cà phê, xăng…), xem top đoàn viên tích cực, huy hiệu số.",
        "steps": [
            "Tab 'Tiện ích' → 'Thi đua & Đổi quà' (hoặc shortcut từ trang chủ)",
            "Mục 'Đổi thưởng': chọn voucher có đủ điểm → Đổi → nhận mã đổi voucher",
            "Mục 'Xếp hạng': xem top đoàn viên theo điểm",
            "Mục 'Huy hiệu': huy hiệu đạt được gắn trong hồ sơ",
        ],
        "keywords": ["thi đua", "điểm", "voucher", "đổi quà", "đổi thưởng", "xếp hạng", "huy hiệu", "khen thưởng", "quà"],
    },
    {
        "id": "assistant_elearning",
        "title": "E-Learning & chứng chỉ số",
        "roles": ["member"],
        "nav": "makeup",
        "nav_label": "Mở màn Lịch",
        "summary": "Học trực tuyến 'Kỹ năng số & Chuyển đổi số' rồi làm trắc nghiệm — được tính như một kỳ sinh hoạt, +10 điểm, cấp chứng chỉ có mã.",
        "steps": [
            "Tab 'Lịch' → tìm buổi E-Learning (trực tuyến)",
            "Bấm 'Tham gia trực tuyến' → học nội dung → làm bài trắc nghiệm",
            "Nộp bài → hệ thống cấp chứng chỉ điện tử (mã DN-EL-…), +10 điểm",
            "Chứng chỉ vào Lịch sử tham gia + thông báo Bí thư",
        ],
        "keywords": ["e-learning", "elearning", "học", "trắc nghiệm", "chứng chỉ", "online", "trực tuyến", "quiz"],
    },
    {
        "id": "assistant_history",
        "title": "Lịch sử tham gia & điểm rèn luyện",
        "roles": ["member"],
        "nav": "history",
        "nav_label": "Mở màn Lịch sử",
        "summary": "Lịch sử từng tháng: Có mặt / Sinh hoạt bù / Vắng, điểm từng kỳ, số lần sinh hoạt bù.",
        "steps": [
            "Tab 'Tiện ích' → 'Lịch sử tham gia' (hoặc từ trang chủ)",
            "Xem từng tháng: trạng thái + điểm rèn luyện nhận được",
        ],
        "keywords": ["lịch sử", "lịch sử tham gia", "điểm rèn luyện", "tình trạng tham gia", "quá trình"],
    },

    # ===== RIÊNG BÍ THƯ CHI ĐOÀN =====
    {
        "id": "assistant_create_session",
        "title": "Tạo buổi sinh hoạt & phát mã QR điểm danh",
        "roles": ["secretary"],
        "nav": "create_qr",
        "nav_label": "Mở màn Tạo QR",
        "summary": "Mở buổi sinh hoạt, phát mã QR động 2 lớp (tự xoay 55 giây, dùng 1 lần, geofence 100m) — chiếu lên máy chiếu cho đoàn viên quét.",
        "steps": [
            "Tab 'Quét QR' (vai trò Bí thư) → 'Tạo buổi sinh hoạt': tên, thời gian, địa điểm (GPS)",
            "Bấm phát mã QR → màn hình hiện QR lớn + đếm ngược 55s; bấm làm mới để vô hiệu mã cũ",
            "Theo dõi số đoàn viên đã điểm danh trên trang chủ",
            "Kết thúc buổi: bấm 'Chốt buổi'",
        ],
        "keywords": ["tạo buổi", "phát qr", "mã qr", "tạo qr", "sinh hoạt", "chốt buổi", "kết thúc", "mở qr"],
    },
    {
        "id": "assistant_manual_checkin",
        "title": "Điểm danh thủ công (ngoại lệ)",
        "roles": ["secretary"],
        "nav": "members",
        "nav_label": "Mở màn Danh sách đoàn viên",
        "summary": "Cho đoàn viên quên điện thoại / camera hỏng — điểm danh tay, bắt buộc ghi lý do (lưu vào nhật ký hệ thống).",
        "steps": [
            "Tab 'Chi đoàn' → chọn đoàn viên → 'Điểm danh thủ công'",
            "Ghi rõ lý do ngoại lệ (VD: quên điện thoại)",
            "Lượt điểm danh này được đánh dấu method='manual' trong nhật ký",
        ],
        "keywords": ["điểm danh thủ công", "thủ công", "ngoại lệ", "điểm danh tay", "quên điện thoại"],
    },
    {
        "id": "assistant_decide",
        "title": "Duyệt đơn xin sinh hoạt bù",
        "roles": ["secretary"],
        "nav": "makeup",
        "nav_label": "Mở màn Lịch (tab Duyệt đơn)",
        "summary": "Xét các đơn bù của đoàn viên chi đoàn mình: Duyệt (tự +10 điểm cho ĐV) / Từ chối / Yêu cầu làm rõ.",
        "steps": [
            "Tab 'Lịch' → tab 'Duyệt đơn' (hiện số đơn đang chờ)",
            "Đọc lý do + minh chứng → bấm Duyệt / Từ chối / Yêu cầu làm rõ",
            "Duyệt xong hệ thống tự cộng điểm và đếm lần sinh hoạt bù (không cộng lại nếu duyệt lần 2)",
        ],
        "keywords": ["duyệt đơn", "duyệt", "xét duyệt", "sinh hoạt bù", "đơn bù", "từ chối đơn"],
    },
    {
        "id": "assistant_members",
        "title": "Quản lý danh sách đoàn viên",
        "roles": ["secretary"],
        "nav": "members",
        "nav_label": "Mở màn Danh sách đoàn viên",
        "summary": "Xem/tìm/lọc 46 đoàn viên theo 3 nhóm (đang ở địa phương / đi làm xa KCN / chuyển sinh hoạt), thêm & xóa đoàn viên.",
        "steps": [
            "Tab 'Chi đoàn' → danh sách đoàn viên",
            "Thanh tìm kiếm + bộ lọc: Tại chỗ / Làm xa KCN / Chuyển SH",
            "Nút '+' để thêm đoàn viên mới; nút xóa ở từng hồ sơ",
        ],
        "keywords": ["đoàn viên", "danh sách", "danh bạ", "thêm đoàn viên", "xóa đoàn viên", "lọc", "chuyển sinh hoạt", "làm xa"],
    },
    {
        "id": "assistant_report",
        "title": "Báo cáo kỳ & nộp lên Đoàn phường",
        "roles": ["secretary"],
        "nav": "reports",
        "nav_label": "Mở màn Báo cáo",
        "summary": "Số liệu báo cáo tự sinh từ lượt điểm danh thật (không khai tay) — xem trước văn bản rồi nộp lên Đoàn phường.",
        "steps": [
            "Tab 'Báo cáo' → xem tổng hợp tháng (tổng ĐV, tỷ lệ tham dự)",
            "Kiểm tra các mục số liệu tự điền từ hệ thống điểm danh",
            "Bấm 'Nộp báo cáo kỳ' → cán bộ Đoàn phường sẽ thấy trong dashboard",
        ],
        "keywords": ["báo cáo", "nộp báo cáo", "báo cáo kỳ", "tổng hợp", "tỷ lệ sinh hoạt", "tháng"],
    },

    # ===== RIÊNG CÁN BỘ ĐOÀN PHƯỜNG =====
    {
        "id": "assistant_ward_dash",
        "title": "Tổng hợp toàn phường (Dashboard)",
        "roles": ["ward_officer"],
        "nav": "ward_dash",
        "nav_label": "Mở màn Tổng hợp",
        "summary": "Bức tranh 12 chi đoàn: tổng đoàn viên, tỷ lệ sinh hoạt từng tháng, hoạt động, tình hình nộp báo cáo kỳ.",
        "steps": [
            "Tab 'Tổng hợp' (trang chủ cán bộ) → xem các chỉ số toàn phường",
            "Các tab phụ: Tổng hợp / 12 CD / Báo cáo / Thi đua",
            "Bấm vào từng khối số liệu để xem chi tiết",
        ],
        "keywords": ["tổng hợp", "dashboard", "toàn phường", "số liệu", "thống kê", "bức tranh", "12 chi đoàn"],
    },
    {
        "id": "assistant_ward_branches",
        "title": "Theo dõi, duyệt & nhắc báo cáo từng chi đoàn",
        "roles": ["ward_officer"],
        "nav": "ward_branches",
        "nav_label": "Mở màn Quản lý Chi đoàn",
        "summary": "Xem chi tiết từng chi đoàn; chi đoàn chậm nộp → gửi nhắc qua Zalo; báo cáo đã nộp → phê duyệt.",
        "steps": [
            "Tab 'Chi đoàn' → chọn chi đoàn cần theo dõi",
            "Chi đoàn chậm nộp → bấm 'Nhắc nộp báo cáo' (gửi nhắc qua Zalo)",
            "Báo cáo đã nộp → bấm 'Duyệt báo cáo'",
            "Cũng xem nhanh ở tab Lịch → 'Duyệt chi đoàn'",
        ],
        "keywords": ["chi đoàn", "duyệt báo cáo", "nhắc", "nhắc nộp", "zalo", "phê duyệt", "chậm nộp"],
    },
    {
        "id": "assistant_ward_export",
        "title": "Xuất văn bản báo cáo đúng thể thức",
        "roles": ["ward_officer"],
        "nav": "ward_reports",
        "nav_label": "Mở màn Báo cáo Đoàn vụ",
        "summary": "Sinh công văn thể thức (Số: 18-BC/ĐTN, kính gửi Thành Đoàn Đồng Nai) với số liệu từng chi đoàn — in/trình ký trình bày cấp trên.",
        "steps": [
            "Tab 'Báo cáo' (cán bộ phường) → 'Xuất văn bản báo cáo'",
            "Xem trước văn bản: đầu đề, số ký hiệu, tỷ lệ từng chi đoàn, nơi ký CÁN BỘ ĐOÀN PHƯỜNG",
            "Bấm In / PDF để xuất bản in",
        ],
        "keywords": ["xuất báo cáo", "xuất văn bản", "công văn", "in", "pdf", "thể thức", "văn bản báo cáo"],
    },
    {
        "id": "assistant_launch",
        "title": "Phát động hoạt động thi đua toàn phường",
        "roles": ["ward_officer"],
        "nav": "makeup",
        "nav_label": "Mở màn Lịch (tab Phát động)",
        "summary": "Tạo hoạt động mới (tên, ngày, địa điểm, điểm thưởng 30–120) — đoàn viên đăng ký trực tiếp từ Bảng tin.",
        "steps": [
            "Tab 'Lịch' → tab 'Phát động'",
            "Nhập: tên hoạt động, ngày tổ chức, địa điểm, điểm thưởng",
            "Bấm 'Phát động đến 12 chi đoàn'",
            "Đăng thêm bài Bảng tin kèm sự kiện để đoàn viên bấm đăng ký ngay trong bài",
        ],
        "keywords": ["phát động", "hoạt động thi đua", "tạo hoạt động", "hoạt động mới", "điểm thưởng"],
    },
    {
        "id": "assistant_ward_reward",
        "title": "Xét khen thưởng / trao điểm đặc biệt",
        "roles": ["ward_officer"],
        "nav": "ward_rewards",
        "nav_label": "Mở màn Thi đua phường",
        "summary": "Cộng điểm đặc biệt, cấp danh hiệu/huy hiệu cho đoàn viên, chi đoàn tiêu biểu.",
        "steps": [
            "Tab 'Tiện ích' → 'Thi đua phường' (hoặc shortcut Xếp hạng chi đoàn)",
            "Chọn chi đoàn/đoàn viên → trao thưởng, cấp danh hiệu",
        ],
        "keywords": ["khen thưởng", "trao thưởng", "danh hiệu", "cộng điểm", "thi đua phường", "xét thưởng"],
    },
]

NAV_LABELS = {
    "home": "Trang chủ", "makeup": "Lịch", "scan_qr": "Quét QR", "history": "Lịch sử tham gia",
    "rewards": "Thi đua & Đổi quà", "social": "Bảng tin", "menu": "Tiện ích",
    "create_qr": "Tạo QR điểm danh", "members": "Danh sách đoàn viên", "reports": "Báo cáo",
    "ward_dash": "Tổng hợp phường", "ward_branches": "Quản lý Chi đoàn",
    "ward_reports": "Báo cáo Đoàn vụ", "ward_rewards": "Thi đua phường",
}


def kb_for_role(role: str) -> list[dict]:
    """Chỉ trả về các chức năng vai trò này CÓ QUYỀN dùng — tầng RBAC thứ 4 của trợ lý AI."""
    return [e for e in KB if role in e["roles"]]


def fallback_answer(question: str, role: str) -> dict:
    """Khi AI không khả dụng (hết quota / lỗi mạng / chưa có key): tra từ khóa cục bộ."""
    q = question.strip().lower()
    best, best_score = None, 0
    for e in kb_for_role(role):
        score = sum(1 for kw in e["keywords"] if kw in q)
        if q and (q in e["title"].lower() or q in e["summary"].lower()):
            score += 2
        if score > best_score:
            best, best_score = e, score
    if not best:
        return {
            "answer": "Mình chưa tìm đúng chức năng. Bạn có thể hỏi ngắn gọn như: "
                      "'điểm danh qr', 'xin sinh hoạt bù', 'đăng bài', 'đổi voucher', 'duyệt đơn', 'xuất báo cáo'…",
            "steps": [], "nav": None, "nav_label": None, "source": "fallback",
        }
    return {
        "answer": best["summary"],
        "steps": best["steps"],
        "nav": best["nav"],
        "nav_label": best.get("nav_label") or NAV_LABELS.get(best["nav"]),
        "source": "fallback",
    }
