# DEPLOY — Triển khai Đoàn Viên Số

> **Trạng thái: ĐÃ DEPLOY.** API chạy trên Render (Blueprint `render.yaml`), database
> PostgreSQL trên Aiven free tier, uptime monitor ping `/health` 5 phút/lần.
> Kết quả research nền tảng bên dưới giữ lại làm tài liệu tham khảo.

## Ràng buộc

- Chi phí 0đ, **không ngủ** (không spin-down), không giới hạn băng thông đáng kể.
- Stack: FastAPI + SQLite (1 file) + watchdog asyncio chạy nền; Flutter APK 50MB.

## So sánh free tier đã research (snapdeploy.dev, render.com, Oracle docs)

| Nền tảng | Free tier | Ngủ? | Thẻ? | Kết luận |
|---|---|---|---|---|
| **Oracle Cloud Always Free** | VM ARM A1: 4 OCPU/24GB RAM (hoặc 2×AMD micro) | **Không** | Cần thẻ (chỉ để xác minh) | ✅ **Chuẩn nhất** |
| Render | 750h/tháng, 512MB | **Ngủ sau 15 phút** | Không | ❌ Demo bị đông lạnh |
| Railway | $5/30 ngày → $1 tín dụng/tháng | Không (tự chọn) | Không | ⚠️ Hết tín dụng là chết |
| Koyeb | 1 service 512MB | **Ngủ sau 1h** | Thẻ ($29 hold) | ❌ |
| Fly.io | Không còn free tier từ 10/2024 | — | Thẻ | ❌ |
| **Cloudflare Tunnel** | Free, không mở port, HTTPS | Phụ thuộc máy gốc | Không (cần domain, trừ quick tunnel) | ✅ Phương án demo nhanh |
| Tailscale Funnel | Free, URL `ts.net` ổn định, không cần domain | Phụ thuộc máy gốc | Không | ✅ Phương án demo nhanh |

## Khuyến nghị

### Phương án A (đang dùng) — Combo Render + Aiven + UptimeRobot (0đ) Render free có spin-down sau 15 phút idle — dùng monitor ping liên tục
để giữ sống; SQLite tạm trên Render thay bằng Aiven Postgres free để dữ liệu không mất.

1. **Aiven for PostgreSQL (free, không cần thẻ):** tạo service → lấy connection string
   `postgres://user:pass@host:port/db?sslmode=require`. Giới hạn biết trước: 1GB storage
   (dư sức cho ~216 ĐV), 1 CPU/1GB RAM, **max_connections=20** → chạy uvicorn 1 worker,
   pool mặc định (5+10) nằm gọn trong giới hạn. Dùng vô thời hạn; Aiven có thể tắt service
   "không hoạt động" (có thông báo) — app trên Render kết nối liên tục nên không dính.
2. **Render (free, 750 giờ/tháng — đủ chạy 24/7 cho 1 service):**
   - Connect repo GitHub → new Web Service (Python).
   - Build: `pip install -r requirements.txt`
   - Start: `uvicorn app.main:app --host 0.0.0.0 --port $PORT --workers 1`
   - Env vars: `DATABASE_URL=<Aiven string>`, `DOANVIEN_SECRET=<khóa mới>`,
     `DOANVIEN_DEMO_OTP=<mới>`, `DOANVIEN_DEMO_PASSWORD=<mới>`, `DOANVIEN_ALLOW_SEED=0`,
     `GEMINI_API_KEY=<key miễn phí từ https://aistudio.google.com/apikey>` (bật Trợ lý AI —
     model gemini-3.5-flash-lite, free tier 500 request/ngày; không đặt key thì trợ lý
     tự chuyển sang chế độ tra cứu từ khóa nội bộ, vẫn dùng được).
3. **UptimeRobot (free: 50 monitor, ping 5 phút/lần):** HTTP monitor ping
   `https://<render-app>.onrender.com/health` — endpoint siêu nhẹ không đụng DB
   (đã có sẵn, trả `{"status":"ok"}` trong vài ms, không spam access log).
4. Lưu ý khi dùng combo này:
   - Render free **random restart** — dữ liệu nằm ở Aiven nên không mất; chỉ mất cache state.
   - Có thể chọn region gần nhau (Singapore) cho cả 2 để giảm latency.
   - Điểm danh QR vẫn hoạt động tốt: watchdog chạy trong lifespan của worker duy nhất.

### Phương án B — Chuẩn nhất, không phụ thuộc monitor (0đ): Oracle Cloud Always Free

1. Đăng ký Free Tier (cần thẻ xác minh, không tính phí) → tạo VM **A1.Flex ARM**
   (4 OCPU/24GB — dư sức), chọn region ít người (Singapore/Osaka dễ có slot hơn).
2. Trên VM: clone repo → `pip install -r requirements.txt` →
   `DOANVIEN_SECRET=<khóa-mới> uvicorn app.main:app --host 0.0.0.0 --port 8000`
   chạy dưới systemd; Caddy/Nginx làm TLS tự động (HTTPS).
3. Đặt biến môi trường mới: `DOANVIEN_SECRET`, `DOANVIEN_DEMO_OTP`, `DOANVIEN_DEMO_PASSWORD`
   (có thể trỏ `DATABASE_URL` sang Aiven Postgres để DB tách khỏi VM).
4. Firewall: chỉ mở 80/443; SQLite giữ trong `backend/` (backup bằng cron `sqlite3 .backup`)
   hoặc dùng luôn Aiven Postgres như phương án A.

### Phương án C — Demo ngay từ máy nhà (0đ, 10 phút): Tailscale Funnel / Cloudflare Tunnel

1. Backend chạy trên máy hiện tại → `tailscale funnel 8000` (URL `ts.net` ổn định) hoặc
   `cloudflared tunnel --url http://localhost:8000` (URL random mỗi lần chạy).
2. Build APK với `--dart-define=API_BASE=https://<url>`.
3. Tunnel chỉ sống khi máy gốc bật — phù hợp demo buổi thuyết trình.

### Phát hành APK (50MB)

- **GitHub Releases** (repo công khai đã có) — không giới hạn dung lượng file, link tải
  ổn định, miễn phí. Cloudflare Pages free chỉ cho file ≤ 25MB → không chứa được APK.
- Ghi link Release vào `design/README.md` thay placeholder `[ĐIỀN LINK FILE APK]`.

## Lưu ý kỹ thuật khi ra internet công khai

1. **HTTPS bắt buộc** cho API Base nếu chạy trên máy thật (Android chặn HTTP cleartext
   từ API 28; nếu bắt buộc phải dùng HTTP LAN thì thêm
   `android:usesCleartextTraffic="true"` vào AndroidManifest — chỉ nên làm cho demo nội bộ).
2. Đổi hết OTP/mật khẩu/khóa JWT qua biến môi trường (đã hỗ trợ sẵn trong `app/auth.py`).
3. `/docs` (Swagger) công khai là bình thường, nhưng có thể tắt bằng cách không mount
   FastAPI docs nếu muốn bề mặt tấn công nhỏ hơn.
4. Watchdog QR chạy trong lifespan của uvicorn — chạy 1 worker duy nhất để tránh
   nhiều watchdog chồng nhau.
