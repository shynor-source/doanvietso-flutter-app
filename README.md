# Đoàn Viên Số — app Flutter + backend FastAPI

Hệ thống quản lý sinh hoạt Đoàn cho Đoàn Phường: một ứng dụng Android cho 3 vai trò
(Đoàn viên — Bí thư Chi đoàn — Cán bộ Đoàn Phường) kết nối backend API thật với phân
quyền RBAC 3 lớp và cơ chế điểm danh mã QR động chống gian lận.

```text
backend/     — FastAPI + SQLModel: 30 API endpoint, 15 bảng, RBAC 23 quyền
doanvien_so/ — Flutter app (11 màn hình, khớp 1:1 với bộ thiết kế)
render.yaml  — Blueprint deploy 1-click lên Render
DEPLOY.md    — Kế hoạch & hướng dẫn triển khai chi tiết
```

## Tính năng chính

| Vai trò | Khả năng |
|---|---|
| **Đoàn viên** | Quét QR điểm danh (+ điểm tự động), gửi đơn sinh hoạt bù kèm minh chứng, đổi voucher bằng điểm, đăng ký hoạt động, bảng tin |
| **Bí thư Chi đoàn** | Tạo buổi sinh hoạt & phát mã QR (TTL 55 giây, server tự xoay), CRUD danh bạ đoàn viên, duyệt đơn bù, điểm danh thủ công, nộp báo cáo lên phường |
| **Cán bộ Phường** | Dashboard tổng hợp toàn phường, duyệt/nhắc nộp báo cáo từng chi đoàn, phát động hoạt động, xuất báo cáo PDF/Excel, khen thưởng, kiểm duyệt bảng tin |

Phân quyền **3 lớp**: ma trận quyền trên backend (403 với thông báo tiếng Việt) → giao
diện render theo vai trò → JWT cấp sau xác thực OTP. Vai trò do máy chủ gán, người dùng
không tự chọn.

## Chạy backend cục bộ

```bash
cd backend
python3 -m venv .venv && .venv/bin/pip install -r requirements.txt
.venv/bin/uvicorn app.main:app --port 8000
# API:    http://localhost:8000
# Swagger: http://localhost:8000/docs   (tự sinh — demo được cho BGK)
# Health:  http://localhost:8000/health
```

CSDL: SQLite tự tạo + tự seed dữ liệu mẫu lần đầu (5 chi đoàn, 46 đoàn viên, buổi sinh
hoạt, đơn bù, báo cáo…). Chuyển PostgreSQL chỉ cần đặt `DATABASE_URL`.

## Chạy app Flutter

```bash
cd doanvien_so
flutter pub get
flutter run --dart-define=API_BASE=http://10.0.2.2:8000    # emulator Android
```

Chi tiết build APK release: xem `doanvien_so/README.md`.

## Biến môi trường triển khai thật

| Biến | Ý nghĩa |
|---|---|
| `DATABASE_URL` | Chuỗi kết nối PostgreSQL (`?sslmode=require`) — ví dụ Aiven |
| `DOANVIEN_SECRET` | Khóa ký JWT — đặt ngẫu nhiên ≥ 32 ký tự (thiếu → dùng khóa ngẫu nhiên theo phiên) |
| `DOANVIEN_DEMO_OTP` | OTP demo — đặt mã riêng, **không dùng giá trị mặc định** |
| `DOANVIEN_DEMO_PASSWORD` | Mật khẩu demo cho seed |
| `DOANVIEN_ALLOW_SEED` | `0` = không seed dữ liệu mẫu |

## Triển khai

Deploy qua **Render Blueprint** (kèm sẵn trong repo — Render tự đọc `render.yaml`):
Render chạy API, database là **Aiven for PostgreSQL** (free tier), uptime monitor
ping `/health` định kỳ để giữ service không ngủ. Chi tiết các phương án và so sánh
nền tảng: `DEPLOY.md`.

## Kiểm thử backend (110 case tự động)

```bash
cd backend && .venv/bin/python -m pytest tests/ -v
```

| File | Nội dung |
|---|---|
| `test_01_auth.py` | 11 case: đăng nhập OTP 3 vai trò, sai OTP/SĐT, thiếu trường, `/me`, token giả, `/health` |
| `test_02_rbac.py` | ~78 case: ma trận phân quyền 2 chiều — sai vai trò 403 tiếng Việt, đủ vai trò 200, chặn không-token |
| `test_03_sessions_qr.py` | 13 case: phát/xoay QR, token hết hạn, sai buổi, geofence trong/ngoài phạm vi, chống điểm danh trùng |
| `test_04_flows.py` | 29 case: CRUD hồ sơ, đơn bù (chống duyệt lại cộng điểm), dashboard, báo cáo, voucher, bảng tin |

## Bảo mật repo công khai

Thông tin đăng nhập tài khoản demo (SĐT/OTP/mật khẩu) không công bố trên repo — nhận
riêng từ đội dự án. OTP demo của app được truyền qua `--dart-define=DEMO_OTP` lúc build,
không nằm trong mã nguồn. Bản triển khai thật phải đặt giá trị mới qua biến môi trường.
