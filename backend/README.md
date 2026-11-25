# Đoàn Viên Số — API Backend

Backend FastAPI cho ứng dụng **Đoàn Viên Số** — ma trận phân quyền 3 vai trò đồng bộ 1:1
với app Flutter, cơ chế điểm danh QR động chống gian lận, chạy trên Render + PostgreSQL
(Aiven) qua Render Blueprint (`render.yaml` ở thư mục gốc repo).

## Chạy

```bash
cd backend
python3 -m venv .venv
.venv/bin/pip install -r requirements.txt
.venv/bin/uvicorn app.main:app --reload
# API:     http://localhost:8000 — Swagger: /docs — Health: /health
```

CSDL: SQLite tự tạo + **tự seed dữ liệu mẫu** khi chạy lần đầu (5 chi đoàn, 46 đoàn viên,
buổi sinh hoạt, đơn bù, báo cáo phường… — seed tự nhận diện đã có nên chạy lại không
trùng lặp; đặt `DOANVIEN_ALLOW_SEED=0` để tắt). Chuyển PostgreSQL chỉ cần đặt
`DATABASE_URL=postgres://…?sslmode=require` — scheme `postgres://` tự chuẩn hóa thành
`postgresql://` bên trong.

## Endpoint sức khỏe (cho uptime monitor)

- `GET /health` — siêu nhẹ, không đụng CSDL, không cần token → monitor (UptimeRobot)
  ping giữ service không ngủ, không spam access log.
- `GET /` — thông tin tổng quát API.

## Biến môi trường

| Biến | Mặc định | Ý nghĩa |
|---|---|---|
| `DATABASE_URL` | `sqlite:///./doanvien.db` | Kết nối CSDL (PostgreSQL khi triển khai thật) |
| `DOANVIEN_SECRET` | khóa ngẫu nhiên theo phiên | Khóa ký JWT — đặt cố định trên server thật |
| `DOANVIEN_DEMO_OTP` | có giá trị demo | Mã OTP demo — **đặt mã riêng khi triển khai** |
| `DOANVIEN_DEMO_PASSWORD` | có giá trị demo | Mật khẩu tài khoản demo trong seed |
| `DOANVIEN_ALLOW_SEED` | `1` | `0` = không seed dữ liệu mẫu

## Tài khoản mẫu

Dữ liệu mẫu do `seed.py` tự tạo khi chạy lần đầu (5 chi đoàn, 46 đoàn viên, 3 tài khoản
đủ 3 vai trò). Thông tin đăng nhập của tài khoản demo **không công bố trên repo công
khai** — ban tổ chức/giám khảo nhận riêng từ đội dự án; có thể cấu hình lại qua biến
môi trường khi triển khai.

## Kiến trúc phân quyền

- `app/rbac.py` — ma trận permission 3 vai trò (`session:create`, `qr:issue`, `request:decide`, `report:approve`, `post:moderate`…). Endpoint gắn guard bằng `Depends(require_permission(...))` → sai vai trò nhận **403** kèm thông báo tiếng Việt.
- `app/auth.py` — JWT HS256 + PBKDF2 (thuần stdlib, không cần passlib/jose); OTP mô phỏng cấu hình qua biến môi trường (production: Zalo ZNS), JWT HS256 + PBKDF2 thuần stdlib.
- `app/models.py` — SQLModel (SQLite/PostgreSQL): User, Branch, Member, Session, **QrToken (TTL 55s)**, CheckIn, MakeupRequest, WardReport, Activity, Registration, Post/Comment, Voucher, AuditLog.
- `app/main.py` — lifespan watchdog quét dọn QR hết hạn mỗi 10s (chống ảnh chụp màn hình dùng lại).

## Cơ chế chống gian lận điểm danh (trọng tâm Vòng 2)

1. **Mã QR một-lần-đọc**: `POST /sessions/{id}/qr` cấp mã mới & vô hiệu toàn bộ mã cũ của buổi đó.
2. **TTL 55 giây**: mã hết hạn tự chết, đoàn viên phải chờ mã mới.
3. **Geofence server-side**: tính khoảng cách Haversine thực trên tọa độ GPS client — ngoài bán kính (mặc định 100m) nhận **403** kèm khoảng cách vi phạm.
4. **Chống double check-in**: mỗi đoàn viên mỗi buổi chỉ điểm danh 1 lần.
5. Mọi thao tác nhạy cảm đều ghi **AuditLog** (ai, làm gì, khi nào).

## Endpoint chính

| Nhóm | Endpoint | Vai trò |
|---|---|---|
| Auth | `POST /auth/otp`, `POST /auth/login`, `GET /auth/me` | công khai |
| Buổi sinh hoạt | `GET/POST /sessions`, `PATCH …/close`, `DELETE …/{id}` | bí thư |
| QR | `POST /sessions/{id}/qr` | bí thư |
| Điểm danh | `POST /sessions/{id}/checkin` (QR+GPS), `POST …/manual` | đoàn viên / bí thư |
| Danh bạ | `GET/POST /members`, `PATCH/DELETE /members/{id}` | bí thư (phường chỉ GET) |
| Đơn bù | `GET/POST /requests`, `POST /requests/{id}/decide` | đoàn viên tạo — bí thư duyệt |
| Phường | `GET /ward/dashboard`, `POST /ward/reports/{id}/approve`, `/remind`, `GET /ward/report/export`, `GET/POST /ward/activities` | phường |
| Thi đua | `GET /rewards/ranking`, `POST /rewards/activities/{id}/register`, `POST /rewards/vouchers/{id}/redeem` | đoàn viên |
| Bảng tin | `GET/POST /social/posts`, `POST …/comment` | mọi vai trò |
| Kiểm duyệt | `POST /social/posts/{id}/pin`, `DELETE /social/posts/{id}` | cán bộ (bí thư + phường) |

## Bộ kiểm thử tự động (110 case)

```bash
cd backend
.venv/bin/python -m pytest tests/ -v
```

Bộ test dùng FastAPI TestClient (in-process) + SQLite test DB riêng, không đụng dữ liệu thật:
| File | Nội dung |
|---|---|
| `test_01_auth.py` | 11 case: đăng nhập OTP 3 vai trò, sai OTP/SĐT, thiếu trường, `/me`, token giả |
| `test_02_rbac.py` | ~78 case: ma trận phân quyền 2 chiều — vai trò bị chặn nhận 403 (thông báo tiếng Việt), vai trò được phép gọi thành công, chặn không-token |
| `test_03_sessions_qr.py` | 13 case: phát/xoay QR (mỗi mã 1 lần), token hết hạn, token sai buổi, geofence trong/ngoài phạm vi 100m, chống điểm danh trùng, điểm danh thủ công, tạo/đóng/xóa buổi |
| `test_04_flows.py` | 29 case: CRUD hồ sơ, đơn bù (duyệt +10 điểm, chống duyệt lại cộng điểm), dashboard 5 chi đoàn, nộp/duyệt/nhắc báo cáo, xuất văn bản thể thức, phát động & đăng ký hoạt động, voucher (đủ/thiếu điểm, trừ tồn), bảng tin (ghim/xóa kiểm duyệt) |
