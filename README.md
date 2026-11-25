# Repo deploy — Đoàn Viên Số (app Flutter + backend FastAPI)

Repo này chứa **mã nguồn triển khai**: ứng dụng Android (Flutter) và backend API
(FastAPI). Repo thiết kế UI tách riêng tại `shynor-source/doanvienso`.

```text
backend/     — FastAPI + SQLModel: phân quyền 3 vai trò, QR điểm danh TTL 55s + geofence
doanvien_so/ — Flutter app (Android APK ~50MB)
render.yaml  — Blueprint deploy 1-click lên Render
DEPLOY.md    — Kế hoạch deploy chi tiết (Render + Aiven Postgres + UptimeRobot)
```

## Chạy backend cục bộ

```bash
cd backend
python -m venv .venv && .venv/bin/pip install -r requirements.txt
.venv/bin/uvicorn app.main:app --port 8000   # Swagger: /docs — health: /health
```

CSDL: SQLite tự tạo + seed dữ liệu mẫu lần đầu. Đổi sang PostgreSQL chỉ cần
`DATABASE_URL=postgres://...` (Aiven/Neon…).

Biến môi trường triển khai thật (bắt buộc đặt mới, không dùng giá trị mặc định):

| Biến | Ý nghĩa |
|---|---|
| `DATABASE_URL` | Chuỗi kết nối Postgres (`?sslmode=require`) |
| `DOANVIEN_SECRET` | Khóa ký JWT — đặt ngẫu nhiên ≥ 32 ký tự |
| `DOANVIEN_DEMO_OTP` | OTP demo — đặt mã riêng, KHÔNG để giá trị mặc định |
| `DOANVIEN_DEMO_PASSWORD` | Mật khẩu demo cho seed |
| `DOANVIEN_ALLOW_SEED` | `0` = không seed dữ liệu mẫu |

## Chạy app Flutter

```bash
cd doanvien_so
flutter pub get
flutter run --dart-define=API_BASE=http://10.0.2.2:8000   # emulator
# bản release cho server thật:
flutter build apk --release \
  --dart-define=API_BASE=https://<render-app>.onrender.com \
  --dart-define=DEMO_OTP=<mã-otp-của-bản-demo>
```

OTP demo **không nằm trong mã nguồn** — truyền qua `--dart-define=DEMO_OTP` khi build.

## Kiểm thử backend

```bash
cd backend && .venv/bin/python -m pytest tests/ -v
```

## Bảo mật repo công khai

Thông tin đăng nhập của tài khoản demo (SĐT/OTP/mật khẩu) không công bố trên repo —
nhận riêng từ đội dự án; bản triển khai thật phải đặt giá trị mới qua biến môi trường.
