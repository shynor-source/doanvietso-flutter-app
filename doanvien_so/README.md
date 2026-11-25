# ĐOÀN VIÊN SỐ — Ứng dụng Flutter (Android MVP)
**Hackathon Đồng Nai 2026 • Round 2 — kết nối backend thật (FastAPI) + phân quyền RBAC 3 lớp**

> Bản này là **triển khai mobile của bộ thiết kế** trong `../design/README.md` — cùng vai trò, cùng luồng, cùng design token. Bản web demo xem tại thư mục `design/`.
> **Cài thử nhanh nhất:** cài trực tiếp file APK `../doanvien_so_v2.3.apk` (Android 6+), không cần build.

---

## 1. Ứng dụng làm được gì (theo 3 vai trò — quyền phân tách rõ rệt)

| Vai trò | Tính năng chính |
|---|---|
| **Đoàn viên / Công nhân KCN** | Trang chủ cá nhân với điểm rèn luyện từ server • quét QR điểm danh (**token + geofence xác thực phía server, chống tái sử dụng**) • lịch hoạt động & đăng ký sự kiện • đơn xin sinh hoạt bù • E-Learning trắc nghiệm có chứng nhận • thi đua: điểm, huy hiệu, đổi voucher • bảng tin • **không có quyền** xem danh bạ toàn chi đoàn / quét QR quản lý |
| **Bí thư Chi đoàn** | Không gian quản lý chi đoàn (banner riêng) • phát / xoay mã QR động (TTL 55s, server phát hành) • điểm danh thủ công ngoại lệ • danh bạ: tìm kiếm, lọc, thêm ĐV, nhập Excel, chuyển sinh hoạt • **duyệt đơn sinh hoạt bù** • nộp báo cáo lên Đoàn phường • **không có quyền** xem dashboard toàn phường |
| **Cán bộ Đoàn Phường** | Dashboard phường (số liệu tổng hợp từ server) • quản lý chi đoàn trực thuộc: duyệt / nhắc nộp báo cáo • xuất báo cáo đúng thể thức • phát động hoạt động • thi đua & khen thưởng • **không có quyền** thao tác QR chi đoàn |

Phân quyền áp dụng **3 lớp**: ma trận capability trong `app_state.dart` → UI lọc theo vai trò (menu/tab/màn riêng) → **backend `require_permission` chặn 403** với thông báo tiếng Việt.

## 2. Kiến trúc & công nghệ

```
lib/
├── main.dart            — entry, AppStateScope (InheritedNotifier)
├── app_shell.dart       — khung app: header, bottom nav theo vai trò, điều hướng, toast
├── ui.dart              — design token + widget dùng chung (D, Pill, AppCard, HeroCard…)
├── services/api.dart    — ApiClient: HTTP + Bearer token, đăng nhập OTP
├── data/mock_data.dart  — dữ liệu mẫu (fallback khi offline / server không khả dụng)
├── state/app_state.dart — AppState (ChangeNotifier): nghiệp vụ + đồng bộ dữ liệu từ API
├── components/modals.dart — đổi vai trò, thông báo, quản trị hệ thống
└── screens/             — 11 màn hình bám 1:1 theo design React
```

- **Flutter 3 + Dart**, Material, package ngoài duy nhất: `http` (gọi API).
- **State tập trung**: một `AppState extends ChangeNotifier` qua `InheritedNotifier`.
- **Đồng bộ thông minh**: đăng nhập thành công → fetch `/members`, `/sessions`, `/requests`, `/ward/dashboard`, `/rewards/vouchers`, `/social/posts`; mỗi mutation (duyệt đơn, điểm danh, phát QR, duyệt báo cáo…) đẩy thẳng lên server; lỗi mạng → **fallback dữ liệu mẫu**, không crash.
- **Design token thống nhất** với bản web: primary `#161891`, dark `#0E1068`, light `#EEF0FB`, font **Be Vietnam Pro**.

## 3. Kết nối backend (FastAPI)

Backend chạy riêng tại `../backend/` (FastAPI + SQLModel + SQLite, chi tiết xem `../backend/README.md`).

```bash
# 1. Chạy backend (mặc định port 8000)
cd ../backend && .venv/bin/uvicorn app.main:app --port 8000

# 2. Chạy app trỏ tới server
flutter run --dart-define=API_BASE=http://10.0.2.2:8000   # emulator Android
# Máy thật: dùng IP LAN của máy chạy backend, ví dụ http://192.168.1.10:8000
```

- Không truyền `API_BASE` → mặc định `http://10.0.2.2:8000` (emulator); app vẫn chạy được **chế độ demo dữ liệu mẫu** nếu server không có.
- Tài khoản demo cho 3 vai trò (Bí thư / Đoàn viên / Cán bộ Phường) có sẵn sau khi
  backend tự seed dữ liệu mẫu. Thông tin đăng nhập **không công bố trên repo công khai**
  — ban tổ chức/giám khảo nhận riêng từ đội dự án.

## 4. Chạy & build

```bash
flutter pub get
flutter run                 # hoặc: flutter devices && flutter run -d <device-id>
flutter build apk --release # → build/app/outputs/flutter-apk/app-release.apk
```

Bản APK sẵn có ở thư mục gốc dự án: `doanvien_so_v2.3.apk` — cài trực tiếp, bật "Cài từ nguồn không xác định".
