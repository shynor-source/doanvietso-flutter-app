# HỆ THỐNG "ĐOÀN VIÊN SỐ" — THÀNH PHỐ ĐỒNG NAI 2026
## Tài liệu mô tả hệ thống (chức năng — phân quyền — luồng dữ liệu — luồng hoạt động — kiến trúc — công nghệ)

> Tài liệu này viết cho người đọc **lần đầu nghe về hệ thống**, kể cả không chuyên công nghệ.
> Đọc xong là nắm được: hệ thống **làm gì**, **ai được làm gì**, **dữ liệu chạy thế nào**,
> **người dùng đi từng bước ra sao**, và hệ thống **được ghép từ những gì**.

---

## MỤC LỤC

1. [Đặt vấn đề & tổng quan](#1-đặt-vấn-đề--tổng-quan)
2. [Các chức năng chính của hệ thống](#2-các-chức-năng-chính-của-hệ-thống)
3. [Phân quyền người dùng (RBAC)](#3-phân-quyền-người-dùng-rbac)
4. [Luồng dữ liệu (Data Flow)](#4-luồng-dữ-liệu-data-flow)
5. [Luồng hoạt động người dùng (User Flow)](#5-luồng-hoạt-động-người-dùng-user-flow)
6. [Kiến trúc hệ thống](#6-kiến-trúc-hệ-thống)
7. [Công nghệ chính (Tech Stack)](#7-công-nghệ-chính-tech-stack)
8. [Mô hình dữ liệu (bảng trong cơ sở dữ liệu)](#8-mô-hình-dữ-liệu)
9. [Danh mục API của máy chủ](#9-danh-mục-api-của-máy-chủ)
10. [Giới hạn hiện tại & hướng phát triển](#10-giới-hạn-hiện-tại--hướng-phát-triển)

---

# 1. ĐẶT VẤN ĐỀ & TỔNG QUAN

## 1.1. Hệ thống giải quyết vấn đề gì?

Tại Đồng Nai, rất nhiều đoàn thanh niên là **công nhân làm việc tại các khu công nghiệp (KCN)**
với ca kíp xoay vòng (có người làm ca đêm 22h–06h). Việc tổ chức sinh hoạt Đoàn và **điểm danh**
gặp ba khó khăn cố hữu:

| Khó khăn hiện tại | Hệ quả |
|---|---|
| Điểm danh giấy, kêu tên | Mất thời gian, dễ sai, không tổng hợp nổi |
| Công nhân làm ca không tới được buổi sinh hoạt chính | Không có cơ chế "sinh hoạt bù" bài bản, mất động lực tham gia |
| Bí thư chi đoàn tổng hợp bằng tay | Báo cáo chậm, sai số cao, cán bộ phường không nhìn được bức tranh toàn phường |
| Hoạt động thi đua phát động bằng loa/tin nhắn | Không ai biết ai đã đăng ký, không đếm được lực lượng |

**"Đoàn Viên Số"** là một hệ thống **một ứng dụng điện thoại (Flutter) + một máy chủ (FastAPI)** giải quyết
trọn vẹn chuỗi trên: **điểm danh bằng mã QR động 2 lớp kèm kiểm tra vị trí (geofence)** →
**sinh hoạt bù bằng đơn xin xét duyệt trực tuyến** → **tích điểm rèn luyện & đổi voucher** →
**bảng tin phát động sự kiện và đăng ký trực tiếp** → **báo cáo tổng hợp tự động từ dữ liệu thật**.

## 1.2. Ba vai trò trong một hệ thống

Hệ thống phục vụ **3 vai trò** (mỗi vai trò là một "thế giới" riêng trong app, không trộn lẫn):

| Vai trò | Ai là người này | Màn hình chính |
|---|---|---|
| **Đoàn viên (member)** | Công nhân, học sinh, sinh viên trong chi đoàn | Trang chủ cá nhân, Quét QR, Thi đua, Bảng tin, Lịch |
| **Bí thư Chi đoàn (secretary)** | Người điều hành 1 chi đoàn (ví dụ Chi đoàn Khu phố 5) | Trang chủ điều hành, Tạo QR, Danh sách ĐV, Xét duyệt đơn, Báo cáo |
| **Cán bộ Đoàn Phường (ward_officer)** | Người quản toàn phường (12 chi đoàn) | Tổng hợp toàn phường, Chi đoàn, Bảng tin, Tiện ích |

**Nguyên tắc vàng của phân quyền:** vai trò **không do người dùng tự chọn** — máy chủ
xác thực số điện thoại → trả về vai trò → **app dựng đúng giao diện của vai trò đó**.
Cùng một nút bấm, đoàn viên bấm thì chạy, cán bộ không hề thấy nút đó.

## 1.3. Bản chất kỹ thuật trong một câu

> **Một app Flutter** chạy trên Android (điểm danh, thi đua, bảng tin…)
> **nói chuyện với một máy chủ FastAPI** (trên Render) **và một cơ sở dữ liệu PostgreSQL** (trên Aiven);
> dữ liệu cùng lúc tồn tại **trên máy (offline-first)** và **trên máy chủ (chuẩn thống nhất)**,
> app tự đồng bộ khi có mạng.

---

# 2. CÁC CHỨC NĂNG CHÍNH CỦA HỆ THỐNG

Phần này liệt kê đủ các nhóm chức năng. Chức năng **nào chỉ ai được dùng** sẽ nói kỹ ở Phần 3.

## 2.1. Điểm danh bằng mã QR động 2 lớp (chức năng "trái tim" của hệ thống)

Đây không phải loại QR tĩnh in trên giấy. Mã QR của buổi sinh hoạt:

- **Tự xoay (rotate) mỗi ~55 giây** do máy chủ tự phát hành token mới (vòng nền `_qr_watchdog` chạy mỗi 10 giây: vô hiệu token hết hạn, phát token mới cho buổi đang mở).
- **Mỗi mã chỉ dùng đúng 1 lần** — người sau quét mã vừa bị người trước dùng rồi sẽ bị từ chối → chặn chụp màn hình QR gửi qua Zalo cho người ở nhà "giúp điểm danh".
- **Kèm kiểm tra vị trí (geofence)**: app đoàn viên gửi kèm tọa độ GPS; máy chủ tính khoảng cách tới điểm tổ chức buổi sinh hoạt (mặc định bán kính 100 m, lưu trong bảng `session`). Ở ngoài bán kính → từ chối kèm thông báo "Bạn cách điểm sinh hoạt X m".
- **Chặn điểm danh trùng**: mỗi đoàn viên chỉ điểm danh 1 lần cho 1 buổi.
- Điểm danh QR thành công → **+5 điểm chuyên cần** (cộng trực tiếp trên máy chủ), ghi AuditLog có khoảng cách.

Ngoài QR, còn đường lối **điểm danh thủ công (ngoại lệ)** do Bí thư thực hiện cho đoàn viên đặc biệt (quên điện thoại, QR hỏng…) — bắt buộc ghi lý do, và lý do này lưu vào nhật ký hệ thống (AuditLog).

## 2.2. Sinh hoạt bù — đơn xin xét duyệt trực tuyến

- Đoàn viên không tới được buổi chính (làm ca, công tác…) → tạo **đơn xin sinh hoạt bù** trong app: chọn buổi, nhập lý do, kèm minh chứng (ảnh/ghi chú).
- Đơn đi thẳng vào máy chủ (bảng `makeup_request`) → Bí thư chi đoàn mở màn "Duyệt đơn" xem và quyết **Duyệt / Từ chối / Yêu cầu làm rõ**.
- Duyệt xong: hệ thống tự **cộng điểm**, cập nhật số lần sinh hoạt bù, và đoàn viên nhận thông báo trong Hộp thư. Có cơ chế **chống duyệt lại nhiều lần để cộng điểm lặp** (chỉ lần duyệt đầu mới cộng).

## 2.3. Thi đua — điểm rèn luyện, xếp hạng, huy hiệu, voucher

Trung tâm "vui" của hệ thống, tạo động lực cho đoàn viên:

- **Điểm rèn luyện** là "tiền tệ" của hệ thống, cộng tự động từ hành vi thật: điểm danh QR +5, sinh hoạt bù được duyệt +10, hoàn thành E-Learning +10, đăng bài lên Bảng tin +5, tham gia hoạt động được phát động (tùy hoạt động: 30–120 điểm…).
- **Xếp hạng**: Top đoàn viên tích cực (theo điểm, lấy từ máy chủ) và bảng xếp hạng 12 chi đoàn toàn phường (tỷ lệ sinh hoạt từng tháng) — chỉ cán bộ phường thấy đầy đủ.
- **Huy hiệu số (digital badges)**: ví dụ "Thanh niên Tiên phong Số" — đạt được khi điểm danh QR 3 kỳ liên tiếp & hoàn thành E-Learning; huy hiệu gắn trong hồ sơ đoàn viên.
- **Đổi voucher thật bằng điểm**: danh mục voucher do phường niêm yết (ví dụ cà phê Highlands giảm 30% — 200 điểm; xăng/xe giảm 15.000đ — 150 điểm…). Đổi thành công: **trừ điểm trên máy chủ, sinh mã đổi voucher, giảm tồn kho** — dữ liệu tiêu hao thật, không "điểm ảo".

## 2.4. E-Learning — học số & trắc nghiệm

- Đoàn viên vào mục E-Learning → học nội dung "Kỹ năng số & Chuyển đổi số Đồng Nai" → làm **bài trắc nghiệm**.
- Hoàn thành → phát **chứng chỉ điện tử** có mã (ví dụ `DN-EL-2026-8831`), **+10 điểm**, ghi vào lịch sử rèn luyện và thông báo tới Bí thư.
- Là một hình thức "sinh hoạt bù số": người làm ca đêm có thể học và được công nhận như một kỳ sinh hoạt.

## 2.5. Bảng tin cộng đồng + nhận sự kiện & đăng ký trực tiếp

Bảng tin là mạng xã hội nội bộ của Đoàn phường:

- **Đăng bài** (kèm ảnh, gắn thẻ hoạt động) — mọi vai trò; **+5 điểm** mỗi bài cho đoàn viên.
- **Thích (like) và Bình luận** — tương tác thật, dữ liệu bình luận lưu trên máy chủ.
- **Bài ghim** luôn lên đầu bảng tin (thông báo quan trọng của phường).
- **Phát động sự kiện kèm thẻ "Đăng ký tham dự"**: cán bộ Đoàn phường khi đăng bài có thể bật chế độ "kèm sự kiện" — bài viết sinh một **thẻ sự kiện** hiển thị: tên sự kiện, ngày giờ, địa điểm, số điểm thưởng, số người đã đăng ký. Đoàn viên **bấm nút ngay trong bài** → hệ thống ghi **Registration (đăng ký) trên máy chủ**, tự **thêm sự kiện vào Lịch cá nhân** của đoàn viên, nút đổi thành "✓ Đã có trong Lịch" và **số "đã đăng ký" tăng thật** để mọi người thấy lực lượng. Đây chính là vòng khép kín "phát động → đăng ký → điểm danh → cộng điểm".
- **Kiểm duyệt nội dung**: cán bộ/bí thư được xóa bài vi phạm, ghim/bỏ ghim — mọi hành động đều vào AuditLog.

## 2.6. Lịch hoạt động cá nhân

- Gộp mọi thứ liên quan tới thời gian của đoàn viên: **Lịch của tôi** (sự kiện đã đăng ký, buổi sinh hoạt, e-learning), **Đăng ký (3)** (đơn/chờ), **Đơn của tôi**.
- Mỗi mục có nút **Điểm danh QR** (khi tới buổi) và **Hủy lịch**.
- Đăng ký sự kiện từ Bảng tin tự động xuất hiện ở đây — không cần thao tác thứ hai.

## 2.7. Quản lý danh sách đoàn viên

- Bí thư & cán bộ phường xem danh sách đoàn viên theo chi đoàn: tên, mã đoàn viên (ĐV-DN-xxx), loại (tại chỗ / làm xa KCN / chuyển sinh hoạt), nơi làm việc, ca làm, điểm, số lần bù, trạng thái.
- Bí thư được **thêm / xóa** đoàn viên; có màn lọc nhanh (tìm tên, lọc theo loại).
- Thông tin này là nền cho mọi báo cáo & xếp hạng.

## 2.8. Báo cáo & tổng hợp cấp phường

- **Bí thư nộp báo cáo kỳ** (báo cáo chi đoàn tháng) — hệ thống **tự đếm lượt điểm danh thật** từ bảng `checkin` để điền số liệu, không cho nhập tay số ảo.
- **Cán bộ phường**: thấy Dashboard toàn phường (số chi đoàn, tổng đoàn viên, tỷ lệ sinh hoạt, số hoạt động…), xem từng chi đoàn, **duyệt / nhắc nộp** báo cáo (nút "gửi nhắc qua Zalo"), và **xuất văn bản báo cáo đúng thể thức** (mẫu công văn có số ký hiệu, đầu đề, chữ ký) — hệ thống sinh sẵn nội dung văn bản từ dữ liệu thật.

## 2.9. Hộp thư & thông báo

- Mỗi vai trò có **Hộp thư riêng** (chuông ở góc header): thông báo điểm danh, đơn được duyệt, chứng chỉ đạt được, bài mới của cán bộ, nhắc nộp báo cáo…
- Thông báo toast (dải chữ nổi phía trên) **tự tắt sau 4 giây** — không che màn hình.

## 2.10. Nhật ký hệ thống (AuditLog)

Mọi hành động "quản trị" đều được ghi vết ai – làm gì – khi nào:
tạo buổi sinh hoạt, phát mã QR, điểm danh thủ công, duyệt/từ chối đơn, nộp báo cáo, phê duyệt báo cáo, phát động hoạt động, ghim/xóa bài, nhắc chi đoàn…
→ đáp ứng yêu cầu **truy xuất nguồn gốc** của quản lý tổ chức (ai làm gì đều có dấu vết).

## 2.11. Chế độ ngoại tuyến (Offline-first)

- Mất mạng vẫn xem được lịch, hồ sơ, bài đã tải; vẫn điểm danh được → lượt điểm danh **lưu chờ trên máy**, khi có mạng **tự đồng bộ lên máy chủ** và cộng điểm (thông báo "Đã đồng bộ X lượt điểm danh ngoại tuyến").
- Lý do quan trọng: công nhân trong KCN có vùng sóng yếu.

## 2.12. Đăng nhập bằng OTP

- Không mật khẩu: nhập số điện thoại → hệ thống gửi mã OTP (môi trường demo mã OTP được cấu hình chung qua biến môi trường; môi trường thật gửi qua SMS/Zalo) → xác thực đúng → nhận phiên làm việc (JWT) + vai trò.
- Có cơ chế tự nhận diện vai trò khi chờ máy chủ (số điện thoại đã biết thuộc vai trò nào) để giao diện không "đứng hình" khi mạng chậm.

---

# 3. PHÂN QUYỀN NGƯỜI DÙNG (RBAC)

## 3.1. Cơ chế phân quyền — 3 lớp phòng tuyến

Hệ thống dùng **RBAC (Role-Based Access Control)** — phân quyền theo vai trò, thực thi ở **3 lớp**:

```
LỚP 1 — Ma trận quyền trên máy chủ (backend/app/rbac.py)
        Mỗi vai trò có một bộ "khóa" (permission string).
        Mỗi API endpoint khai báo cần "khóa" nào mới được gọi.
        → Sai khóa = chặn ngay ở cửa (HTTP 403) dù gọi trực tiếp bằng tool.

LỚP 2 — Giao diện theo vai trò (app Flutter)
        App nhận vai trò từ máy chủ rồi DỰNG đúng màn hình/tab/nút của vai trò đó.
        Nút mà vai trò không có quyền → KHÔNG ĐƯỢC VẼ RA màn hình (không phải nút mờ).

LỚP 3 — Điều kiện dữ liệu trên từng bản ghi
        Cùng một API nhưng dữ liệu nhìn thấy khác nhau theo vai trò
        (ví dụ danh sách đơn: đoàn viên chỉ thấy đơn của mình,
         bí thư thấy toàn bộ đơn chi đoàn mình).
```

Kết quả: **không thể "lách" giao diện** để làm việc vượt quyền — bị chặn ở lớp 1; và người dùng
**không bao giờ thấy** nút vô nghĩa của vai trò khác — không bị nhầm ở lớp 2.

## 3.2. Ma trận quyền chính thức (đúng như trong mã nguồn `backend/app/rbac.py`)

| Quyền (permission) | Đoàn viên | Bí thư Chi đoàn | Cán bộ Đoàn Phường | Giải nghĩa |
|---|:---:|:---:|:---:|---|
| `session:checkin` | ✅ | — | — | Quét QR điểm danh |
| `activity:register` | ✅ | — | — | Đăng ký tham dự hoạt động |
| `request:create` | ✅ | — | — | Gửi đơn xin sinh hoạt bù |
| `voucher:redeem` | ✅ | — | — | Đổi voucher bằng điểm |
| `post:create` | ✅ | ✅ | ✅ | Đăng bài Bảng tin |
| `post:comment` | ✅ | ✅ | ✅ | Bình luận |
| `session:create/update/delete/close` | — | ✅ | — | Quản lý buổi sinh hoạt |
| `qr:issue` | — | ✅ | — | Phát / xoay mã QR động |
| `member:create/update/delete/import` | — | ✅ | — | Quản lý danh sách đoàn viên chi đoàn |
| `request:decide` | — | ✅ | — | Duyệt / từ chối đơn sinh hoạt bù |
| `report:submit` | — | ✅ | — | Nộp báo cáo kỳ chi đoàn |
| `post:moderate` | — | ✅ | ✅ | Ghim / xóa bài vi phạm |
| `activity:launch` | — | — | ✅ | Phát động hoạt động toàn phường |
| `report:approve` | — | — | ✅ | Phê duyệt báo cáo chi đoàn |
| `report:export` | — | — | ✅ | Xuất văn bản báo cáo đúng thể thức |
| `reward:grant` | — | — | ✅ | Trao thưởng / cộng điểm đặc biệt |
| `branch:view` | — | — | ✅ | Xem dữ liệu toàn phường (12 chi đoàn) |

## 3.3. Chi tiết theo từng vai trò — cùng màn hình, khác quyền lợi

### 3.3.1. ĐOÀN VIÊN (member) — "người tham gia"

**5 tab dưới cùng:** Trang chủ • Lịch • Quét QR • Bảng tin • Tiện ích.

| Chức năng | Mô tả & giới hạn của riêng đoàn viên |
|---|---|
| Trang chủ | Chỉ thấy **dữ liệu cá nhân mình**: điểm rèn luyện, mã đoàn viên, ngày gia nhập, lịch sử tham gia từng tháng, huy hiệu đã đạt, suất đổi voucher gợi ý theo điểm |
| Quét QR | Chỉ **dùng** mã QR do bí thư phát (có thể nhập mã thủ công nếu camera không quét được) — không có chức năng phát mã |
| Lịch | Chỉ lịch **cá nhân mình**: "Lịch của tôi", "Đăng ký", "Đơn của tôi" |
| Bảng tin | Đăng bài (+5đ), like, bình luận; **không thấy hàng "Kèm nút Đăng ký tham dự"** khi soạn bài (chỉ cán bộ phát động sự kiện được); **không có nút ghim/xóa** bài của người khác; vẫn nhận & bấm đăng ký sự kiện của cán bộ |
| Đơn sinh hoạt bù | Chỉ tạo đơn **cho chính mình** và xem **đơn của mình**; không có quyền duyệt đơn của ai |
| Thi đua / Đổi thưởng | Xem top đoàn viên tích cực; **đổi voucher bằng điểm của mình** (không đủ điểm → máy chủ từ chối); hoàn thành E-Learning lấy chứng chỉ |
| Điểm danh | QR + GPS; bị chặn khi: sai buổi, mã hết hạn (55s), mã đã dùng, ngoài geofence, đã điểm danh rồi |
| Hộp thư | Nhận thông báo về mình: điểm danh, đơn được duyệt, chứng chỉ, bài phát động |

### 3.3.2. BÍ THƯ CHI ĐOÀN (secretary) — "người điều hành 1 chi đoàn"

**5 tab:** Trang chủ (điều hành) • Lịch • Quét QR (tạo mã) • Bảng tin • Tiện ích.

| Chức năng | Mô tả & giới hạn riêng |
|---|---|
| Trang chủ điều hành | Số liệu **cả chi đoàn mình**: x/46 đoàn viên đã điểm danh, tỷ lệ sinh hoạt từng tháng, trạng thái nộp báo cáo, danh sách đơn đang chờ duyệt |
| Tạo & xoay QR | Khởi tạo buổi sinh hoạt, **phát mã QR động 2 lớp** cho buổi; mỗi lần bấm = sinh mã mới và **vô hiệu mã cũ**; chốt buổi (close) khi kết thúc |
| Danh sách đoàn viên | Xem **toàn bộ chi đoàn mình** (46 ĐV: tại chỗ / làm xa KCN / chuyển SH); **thêm / xóa** đoàn viên; **điểm danh thủ công** ngoại lệ (bắt buộc ghi lý do — lưu AuditLog) |
| Xét duyệt đơn | Thấy **toàn bộ đơn của chi đoàn**; quyết Duyệt / Từ chối / Yêu cầu làm rõ; hệ thống tự cộng điểm khi duyệt (chống duyệt lặp) |
| Nộp báo cáo kỳ | Số liệu báo cáo **tự sinh từ lượt điểm danh thật** — không tự khai; nộp lên Đoàn phường |
| Bảng tin | Đăng bài, bình luận, **ghim / xóa bài** trong chi đoàn (quyền `post:moderate`); **không** phát động sự kiện toàn phường (không có hàng "Kèm nút Đăng ký" — chức năng đó của cán bộ phường) |
| Giới hạn | KHÔNG thấy dữ liệu 11 chi đoàn khác; KHÔNG duyệt báo cáo cấp phường; KHÔNG phát động hoạt động toàn phường |

### 3.3.3. CÁN BỘ ĐOÀN PHƯỜNG (ward_officer) — "người quản toàn phường"

**5 tab:** Tổng hợp • Lịch • Chi đoàn • Bảng tin • Tiện ích.

| Chức năng | Mô tả & giới hạn riêng |
|---|---|
| Tổng hợp toàn phường | Dashboard "xịn nhất hệ thống": 12 chi đoàn, tổng đoàn viên, tỷ lệ sinh hoạt toàn phường từng tháng (Tháng 09/10/11), số hoạt động; bảng xếp hạng chi đoàn; tình hình nộp báo cáo kỳ (x/12 đã nộp) |
| Chi đoàn | Xem chi tiết **từng chi đoàn** trong toàn phường; nút **nhắc nộp báo cáo** (gửi nhắc qua Zalo) và **duyệt báo cáo** từng chi đoàn |
| Phát động hoạt động | Tạo hoạt động thi đua toàn phường (tên, ngày, địa điểm, điểm thưởng) → hoạt động xuất hiện trên máy chủ; có thể **đăng bài Bảng tin kèm sự kiện** để đoàn viên **bấm đăng ký trực tiếp** trong bài |
| Bảng tin | Toàn quyền kiểm duyệt: ghim thông báo quan trọng lên đầu, **xóa bài vi phạm** toàn phường; đăng bài thường (tổng kết) hoặc bài phát động sự kiện — **bật/tắt tùy ý** hàng "Kèm nút Đăng ký tham dự" |
| Xuất văn bản | Sinh **văn bản báo cáo đúng thể thức** (Số: 18-BC/ĐTN, đầu đề ĐOÀN TNCS HỒ CHÍ MINH – PHƯỜNG TRẤN BIÊN, liệt kê tỷ lệ từng chi đoàn, nơi ký) từ dữ liệu thật |
| Trao thưởng | Cộng điểm đặc biệt / cấp danh hiệu, huy hiệu cho đoàn viên tiêu biểu |
| Giới hạn | KHÔNG tạo QR của một chi đoàn cụ thể (QR là việc của bí thư từng chi đoàn); KHÔNG duyệt đơn sinh hoạt bù của chi đoàn (việc của bí thư) |

### 3.3.4. Bảng so sánh nhanh "chức năng giống nhau nhưng khác nhau thế nào"

| Chức năng | Đoàn viên | Bí thư | Cán bộ Phường |
|---|---|---|---|
| **Đăng bài Bảng tin** | Được, +5đ | Được (+5đ nếu là hồ sơ ĐV) | Được; thêm chế độ **kèm thẻ sự kiện "Đăng ký tham dự"** |
| **Nút "Đăng ký tham dự" trong bài soạn** | ❌ Không thấy hàng này | ❌ Không thấy | ✅ Bật/tắt được — bật = bài phát động sự kiện |
| **Danh sách đơn sinh hoạt bù** | Chỉ đơn của mình | Toàn bộ đơn chi đoàn mình | ❌ Không có màn duyệt đơn |
| **Danh sách đoàn viên** | ❌ Không có | Chi đoàn mình (46 ĐV) + thêm/xóa | Toàn phường (12 chi đoàn, 600+ ĐV) — chỉ xem |
| **Điểm danh** | Quét QR (+GPS) | Phát mã QR + điểm danh thủ công ngoại lệ | ❌ Không tham gia điểm danh |
| **Ghim / xóa bài** | ❌ | ✅ trong chi đoàn | ✅ toàn phường |
| **Báo cáo** | ❌ | Nộp báo cáo kỳ chi đoàn | Duyệt, nhắc, xuất văn bản cấp phường |
| **Đổi voucher** | ✅ (trừ điểm mình) | Xem danh mục | Xem danh mục (quản lý niêm yết) |
| **Thi đua / Xếp hạng** | Top ĐV tích cực + huy hiệu của mình | Tỷ lệ chi đoàn mình | Xếp hạng 12 chi đoàn toàn phường + trao thưởng |

---

# 4. LUỒNG DỮ LIỆU (DATA FLOW)

## 4.1. Hai kho dữ liệu song song — "máy giữ chuẩn, máy giữ nhanh"

```
   ┌─────────────────────────────┐          ┌──────────────────────────────────┐
   │  DỮ LIỆU TRÊN MÁY (app)     │          │  DỮ LIỆU TRÊN MÁY CHỦ (chuẩn)    │
   │  Flutter + bộ dữ liệu mẫu   │  ◄─────► │  PostgreSQL (Aiven)              │
   │  dùng được khi MẤT MẠNG     │  đồng bộ │  15 bảng: user, member, session, │
   └─────────────────────────────┘          │  qr_token, checkin, request, …   │
                                            └──────────────────────────────────┘
```

- App khởi động **luôn có dữ liệu dùng được ngay** (không treo màn trắng khi mạng chậm).
- Khi đăng nhập thành công qua máy chủ, app **kéo dữ liệu thật về đè lên dữ liệu mẫu**: danh sách đoàn viên, buổi sinh hoạt, đơn, hoạt động, bảng tin, xếp hạng…
- Mỗi thao tác "viết" (điểm danh, gửi đơn, duyệt đơn, đăng ký sự kiện, đổi voucher, bình luận…) app **làm 2 việc**: cập nhật giao diện **ngay** (người dùng thấy phản hồi tức thì) và **gửi lệnh lên máy chủ** để ghi vào cơ sở dữ liệu chuẩn. Nếu gửi thất bại, app hiện cảnh báo "chưa đồng bộ được với máy chủ — dữ liệu đang lưu cục bộ" và giữ trạng thái chờ đồng bộ lại.

## 4.2. Luồng dữ liệu của từng chức năng chính

### 4.2.1. Đăng nhập

```
App: nhập SĐT → [POST /auth/otp] → máy chủ tạo/gửi mã OTP
App: nhập OTP → [POST /auth/login] → máy chủ:
        ✔ xác thực OTP
        ✔ tra số điện thoại → tìm User (ai, vai trò gì, chi đoàn nào)
        ✔ phát JWT (chìa khóa phiên)
        ✔ trả về: {token, user{role, member_id, full_name}}
App: lưu token + vai trò + id hồ sơ
     → dựng đúng giao diện vai trò
     → kéo dữ liệu thật (danh sách ĐV, buổi, đơn, bảng tin, hạng…) về máy
```

Vai trò đi vào **mọi** quyết định phía sau: app trao token vào header `Authorization` mỗi lần gọi API;
máy chủ giải token, biết ai → tra ma trận quyền → cho/chặn.

### 4.2.2. Điểm danh QR (luồng dữ liệu "2 lớp")

```
BÊN PHÁT (Bí thư):  bấm "Phát mã QR" → [POST /sessions/{id}/qr]
                    → máy chủ sinh token ngẫu nhiên, hết hạn sau 55s
                    → app vẽ thành QR trên màn hình chiếu/treo

MÁY CHỦ (nền):      vòng nền mỗi 10s: xoá token hết hạn chưa dùng,
                    phát token mới cho buổi đang mở → mã luôn "tươi"

BÊN QUÉT (ĐV):      app camera đọc mã → lấy token + GPS hiện tại
                    → [POST /sessions/{id}/checkin {token, lat, lng}]
                    → máy chủ kiểm tra TUẦN TỰ:
                        1) buổi còn mở?
                        2) token đúng buổi này?
                        3) token còn hạn (55s)?
                        4) token chưa ai dùng?
                        5) khoảng cách GPS ≤ bán kính geofence (100m)?
                        6) đoàn viên chưa điểm danh buổi này?
                    → đủ 6 điều kiện: ghi CheckIn, ĐÁNH DẤU token ĐÃ DÙNG
                      (mã chết ngay tại đây), +5 điểm, ghi AuditLog
                    → trả về khoảng cách + lời chúc điểm danh
```

**Vì sao gọi "2 lớp"?** Lớp 1 là **mã xoay theo thời gian** (chặn chụp ảnh gửi người khác);
lớp 2 là **vị trí GPS** (chặn đứng ở quán cà phê cách 2 km quét "hộ").
Mỗi mã dùng 1 lần: mã bị sao chép cũng vô dụng ngay sau lượt dùng đầu tiên.

### 4.2.3. Sinh hoạt bù (đơn xét duyệt)

```
ĐV tạo đơn → [POST /requests] → bảng makeup_request (trạng thái: pending)
Bí thư mở danh sách đơn → [GET /requests] (chỉ thấy đơn chi đoàn mình)
   → Duyệt: [POST /requests/{id}/decide {action: approve}]
        → trạng thái approved (khoá vĩnh viễn — duyệt lần 2 không cộng điểm thêm)
        → cộng điểm, đếm lần sinh hoạt bù, ghi AuditLog
   → Từ chối / Yêu cầu làm rõ → trạng thái tương ứng, có phản hồi cho ĐV
```

### 4.2.4. Phát động sự kiện từ Bảng tin → đăng ký (vòng khép kín)

```
Cán bộ phường: bấm "Phát động hoạt động" → [POST /ward/activities]
        → máy chủ tạo Activity (tên, thời gian, địa điểm, điểm thưởng)
Cán bộ đăng bài kèm sự kiện → [POST /social/posts {content, is_event, activity_id}]
        → máy chủ lưu Post gắn với Activity
Đoàn viên mở Bảng tin → [GET /social/posts]
        → bài sự kiện trả kèm đầy đủ thông tin hoạt động
        → app vẽ thẻ sự kiện: ngày badge, "+30 điểm • N đã đăng ký", địa điểm
ĐV bấm "Đăng ký tham dự (Thêm vào Lịch)"
        → [POST /rewards/activities/{id}/register] (yêu cầu quyền activity:register)
        → máy chủ: chặn đăng ký trùng → ghi Registration
        → app: toast xác nhận, thẻ đổi xanh "✓ Đã có trong Lịch",
               đếm "đã đăng ký +1", sự kiện tự vào Lịch cá nhân
(Chốt hạ: tới ngày sự kiện, đoàn viên điểm danh/tham gia → cộng điểm thưởng như phát động)
```

### 4.2.5. Đổi voucher

```
ĐV chọn voucher → [POST /rewards/vouchers/{id}/redeem] (quyền voucher:redeem)
   máy chủ: điểm đủ chưa? còn tồn kho?
   → trừ điểm thật, giảm tồn kho thật, sinh mã đổi voucher, ghi AuditLog
   → trả về mã + số điểm còn lại
```

### 4.2.6. Báo cáo kỳ (dữ liệu tự sinh)

```
Bí thư bấm "Nộp báo cáo kỳ" → [POST /ward/reports]
   máy chủ tự đếm: tổng ĐV chi đoàn, tổng lượt CheckIn qua các buổi
   → điền vào WardReport (không cho nhập tay) → trạng thái "submitted"
Cán bộ phường: Dashboard tổng hợp từ toàn bộ WardReport
   → duyệt [POST /ward/reports/{id}/approve] / nhắc [POST /ward/branches/{id}/remind]
   → xuất văn bản [GET /ward/report/export] — sinh công văn thể thức từ dữ liệu thật
```

### 4.2.7. Đồng bộ ngoại tuyến

```
Mất mạng: app ghi lượt điểm danh vào "hàng chờ" trên máy
Có mạng:  app đẩy hàng chờ lên máy chủ → cộng điểm trên máy chủ
          → thông báo "Đã đồng bộ X lượt điểm danh ngoại tuyến (+10 điểm)"
```

---

# 5. LUỒNG HOẠT ĐỘNG NGƯỜI DÙNG (USER FLOW)

## 5.1. Luồng chung: từ cài app tới màn hình làm việc

```
[1] Cài app → mở app → màn Đăng nhập
[2] Nhập số điện thoại → bấm Đăng nhập
[3] Nhập mã OTP → xác thực
[4] Máy chủ xác nhận → app hiện "Xác thực OTP thành công"
[5] App tự nhận diện vai trò → vào đúng "thế giới" của vai trò
     • Đoàn viên      → Trang chủ cá nhân
     • Bí thư          → Trang chủ điều hành chi đoàn
     • Cán bộ phường   → Tổng hợp toàn phường
[6] Dùng hệ thống theo các luồng dưới đây
[7] Đăng xuất (mục Tiện ích → Hồ sơ → Đăng xuất) — token bị huỷ, quay về màn Đăng nhập
```

## 5.2. USER FLOW — ĐOÀN VIÊN (một kỳ sinh hoạt trọn vẹn)

```
BƯỚC 1 — Chuẩn bị
  Mở app → Trang chủ cá nhân:
    • thẻ điểm rèn luyện, mã đoàn viên (ĐV-DN-001)
    • trạng thái kỳ sinh hoạt đang diễn ra
    • lịch sử các tháng: Có mặt / Sinh hoạt bù / Vắng
  Vào tab "Lịch" xem buổi sinh hoạt sắp tới (thời gian, địa điểm).

BƯỚC 2 — Tới buổi sinh hoạt
  Đến đúng nơi tổ chức (nhà văn hóa Khu phố 5) trong khung giờ.
  Mở tab "Quét QR" → app xin quyền camera.

BƯỚC 3 — Điểm danh
  Quét mã QR đang hiển thị trên màn hình của Bí thư.
  App gửi mã + vị trí GPS lên máy chủ.
  → THÀNH CÔNG: toast "Điểm danh thành công! +5 điểm chuyên cần"
                + khoảng cách (ví dụ "cách 12 m") → điểm tăng ngay.
  → THẤT BẠI có thông báo cụ thể: mã hết hạn (chờ 55s mã mới),
    mã đã dùng, ngoài bán kính geofence ("Di chuyển vào phạm vi"),
    hoặc đã điểm danh rồi.

BƯỚC 4 — Sau buổi (nếu đã tham gia)
  Vào "Bảng tin" → thấy bài tổng kết/bài phát động của cán bộ.
  • Thích, bình luận cảm nhận (bình luận lưu lên máy chủ).
  • Đăng bài chia sẻ khoảnh khắc + ảnh → +5 điểm.
  • Thấy bài phát động sự kiện (thẻ xanh "+30 điểm • N đã đăng ký")
    → bấm "Đăng ký tham dự (Thêm vào Lịch)"
    → toast xác nhận → sự kiện xuất hiện trong tab "Lịch".

BƯỚC 5 — Khi không thể tham gia
  Tab "Lịch" → "Đơn của tôi" → tạo đơn xin sinh hoạt bù:
    chọn buổi, nhập lý do (làm ca đêm…), đính kèm minh chứng → gửi.
  Chờ Bí thư duyệt (xem trạng thái ngay trong "Đơn của tôi").

BƯỚC 6 — Tích lũy & hưởng thụ
  Tab "Tiện ích" → Thi đua & điểm:
    • xem top đoàn viên tích cực, huy hiệu đạt được
    • hoàn thành E-Learning (học + trắc nghiệm) → chứng chỉ có mã, +10 điểm
    • đủ điểm → "Đổi voucher" (ví dụ cà phê Highlands -30%) → nhận mã đổi
  Hộp thư đọc thông báo: đơn được duyệt, chứng chỉ, bài mới của cán bộ.
```

## 5.3. USER FLOW — BÍ THƯ CHI ĐOÀN (điều hành một buổi sinh hoạt)

```
BƯỚC 1 — Chuẩn bị buổi sinh hoạt
  Trang chủ điều hành → xem tình trạng: x/46 ĐV, tỷ lệ tháng này,
  đơn chờ duyệt, báo cáo kỳ.
  Tạo/mở buổi sinh hoạt tháng (tên buổi, thời gian, địa điểm).
  App xin quyền vị trí để lưu tọa độ điểm tổ chức (geofence 100 m).

BƯỚC 2 — Phát mã QR tại buổi họp
  Bấm "Tạo mã QR điểm danh" → màn hình hiện QR lớn (chiếu máy chiếu/treo).
  QR tự đổi mã mỗi ~55 giây (có đếm ngược trên màn hình).
  Mỗi đoàn viên quét một lượt — mã dùng ngay xong là chết.

BƯỚC 3 — Theo dõi điểm danh trực tiếp
  Trang chủ cập nhật số đoàn viên đã điểm danh theo thời gian thực.
  Trường hợp ngoại lệ (quên điện thoại, camera hỏng):
    → "Điểm danh thủ công" → chọn đoàn viên → BẮT BUỘC nhập lý do
    → lưu vào nhật ký (AuditLog) để minh bạch.

BƯỚC 4 — Xử lý đơn sinh hoạt bù
  Mở "Duyệt đơn" → đọc lý do + minh chứng của từng đoàn viên:
    • Duyệt   → hệ thống tự cộng điểm + đếm lần bù
    • Từ chối → kèm lý do trả về cho đoàn viên
    • Yêu cầu làm rõ → đoàn viên bổ sung

BƯỚC 5 — Chốt buổi & quản trị danh sách
  "Chốt buổi" (kết thúc phiên QR).
  Thêm/xóa đoàn viên khi có biến động nhân sự.

BƯỚC 6 — Nộp báo cáo kỳ lên Đoàn phường
  Màn Báo cáo → xem số liệu tự sinh (tổng ĐV, tỷ lệ tham dự từ điểm danh thật)
  → xem trước văn bản (đúng thể thức, có chữ ký) → "Nộp báo cáo kỳ".
  Cán bộ phường sẽ thấy báo cáo này trong dashboard.
```

## 5.4. USER FLOW — CÁN BỘ ĐOÀN PHƯỜNG (quản toàn phường)

```
BƯỚC 1 — Nhìn bức tranh toàn phường
  Mở app → màn "Tổng hợp":
    • 12 chi đoàn trực thuộc • tổng đoàn viên
    • tỷ lệ sinh hoạt toàn phường theo tháng (09/10/11/2026)
    • tình hình nộp báo cáo kỳ: x/12 chi đoàn đã nộp
  Tab "Chi đoàn": bấm vào từng chi đoàn xem chi tiết;
    • chi đoàn nào chậm nộp → bấm "Nhắc nộp báo cáo" (gửi nhắc qua Zalo)
    • báo cáo đã nộp → "Duyệt báo cáo".

BƯỚC 2 — Phát động hoạt động thi đua
  "Phát động hoạt động": nhập tên, ngày tổ chức, địa điểm, điểm thưởng.
  → máy chủ tạo hoạt động toàn phường ("Đã phát động … đến 12 chi đoàn").

BƯỚC 3 — Đưa hoạt động tới đoàn viên qua Bảng tin
  Tab "Bảng tin" → soạn bài phát động → bật hàng
  "Kèm nút Đăng ký tham dự (Đẩy về Lịch)" → điền tên sự kiện/ngày/khung giờ/địa điểm
  → Đăng bài.
  Bài xuất hiện với thẻ sự kiện xanh: điểm thưởng, số người đăng ký, nút đăng ký.
  (Cũng có thể đăng bài thường — tổng kết hoạt động — bằng cách tắt toggle này.)

BƯỚC 4 — Theo dõi lực lượng đăng ký
  Mở lại bài → số "đã đăng ký" tăng thật khi đoàn viên bấm đăng ký
  (dữ liệu từ bảng Registration trên máy chủ).

BƯỚC 5 — Kiểm duyệt & truyền thông nội bộ
  Ghim thông báo quan trọng lên đầu bảng tin.
  Xóa bài vi phạm (hành động ghi AuditLog).
  Bình luận tương tác với chi đoàn.

BƯỚC 6 — Tổng hợp & xuất văn bản báo cáo
  Cuối tháng: xem dashboard tổng hợp → "Xuất văn bản báo cáo"
  → hệ thống sinh công văn thể thức (Số: 18-BC/ĐTN…) với số liệu từng chi đoàn
  → dùng để in/trình ký/phê trình cấp trên.
  Trao thưởng / cộng điểm đặc biệt cho đoàn viên tiêu biểu.
```

## 5.5. Sơ đồ tổng quát vai trò × luồng

```
ĐOÀN VIÊN:        Đăng nhập → Quét QR điểm danh → (+ đơn bù) → Bảng tin
                  (đọc/đăng/đăng ký sự kiện) → Thi đua/E-Learning → Đổi voucher

BÍ THƯ:           Đăng nhập → Tạo buổi → Phát QR (xoay 55s) → Theo dõi ĐD
                  → ĐD thủ công (ngoại lệ) → Duyệt đơn bù → Nộp báo cáo kỳ

CÁN BỘ PHƯỜNG:    Đăng nhập → Dashboard 12 chi đoàn → Nhắc/Duyệt báo cáo
                  → Phát động hoạt động → Đăng bài kèm sự kiện → Kiểm duyệt
                  → Xuất văn bản → Trao thưởng
```

---

# 6. KIẾN TRÚC HỆ THỐNG

## 6.1. Sơ đồ tổng thể

```
┌─────────────────────────── ANDROID APP (Flutter) ───────────────────────────┐
│  UI theo vai trò (12 màn hình)                                              │
│    login • member_home • scan_qr • schedule • social • rewards • menu       │
│    secretary_home • create_qr • members • report • ward_dashboard          │
│  AppState (trung tâm trạng thái): dữ liệu hiện tại + thông báo + nhật ký    │
│  ApiClient (gọi REST, giữ JWT, timeout, offline fallback)                   │
└───────────────┬─────────────────────────────────────────┬───────────────────┘
                │ HTTPS/JSON (Authorization: Bearer JWT)  │ SQLite nội bộ (hàng chờ offline)
                ▼                                         ▼
┌─────────────────────────── MÁY CHỦ (FastAPI trên Render) ───────────────────┐
│  auth_router    : OTP, login (JWT), /me                                     │
│  sessions_router: buổi sinh hoạt, QR động, checkin (geofence), manual        │
│  requests_router: đơn sinh hoạt bù + xét duyệt                              │
│  rewards_router : voucher, hoạt động, đăng ký, xếp hạng                     │
│  social_router  : bảng tin, bình luận, ghim/xóa, bài sự kiện                │
│  ward_router    : dashboard, báo cáo, duyệt/nhắc, xuất văn bản, phát động    │
│  members_router : danh sách & quản lý đoàn viên                             │
│  rbac.py        : ma trận quyền — chặn ở mọi endpoint                       │
│  _qr_watchdog   : vòng nền xoay mã QR mỗi 10 giây                           │
│  /health        : GET+HEAD cho uptime monitor (không đụng DB)               │
└───────────────┬─────────────────────────────────────────────────────────────┘
                ▼
┌─────────────────────────── CƠ SỞ DỮ LIỆU (PostgreSQL trên Aiven) ───────────┐
│  15 bảng: user, branch, member, session, qr_token, checkin,                 │
│  makeup_request, ward_report, activity, registration, post, comment,        │
│  voucher, voucher_redemption, audit_log                                     │
└─────────────────────────────────────────────────────────────────────────────┘
```

## 6.2. Những quyết định kiến trúc đáng chú ý (và lý do)

| Quyết định | Lý do |
|---|---|
| **Offline-first**: app có dữ liệu nền trên máy | Công nhân KCN vùng sóng yếu — không được treo màn hình trắng |
| **QR xoay server-side** (watchdog mỗi 10s, TTL 55s) | Chặn mọi hình thức "số điểm danh" bằng ảnh QR cũ — mã chết trước khi kịp lan truyền |
| **Token dùng 1 lần** (đánh dấu `used_by` ngay khi điểm danh) | Chặn chia sẻ mã qua mạng xã hội |
| **Geofence trên máy chủ** (GPS gửi theo lượt điểm danh, server tính khoảng cách) | App không tự chốt kết luận — máy chủ mới là trọng tài |
| **RBAC 3 lớp** (API → UI → dữ liệu bản ghi) | Chặn cả người "mò API" lẫn nhầm giao diện; thất bại an toàn (fail-safe) |
| **Số liệu báo cáo tự sinh từ bảng checkin** | Không cho "khai báo điểm danh trên giấy tờ" |
| **AuditLog cho mọi hành động quản trị** | Truy xuất nguồn gốc — văn hóa minh bạch của tổ chức Đoàn |
| **`migrate_db` tự thêm cột khi triển khai** | Server chạy trên DB cũ vẫn nâng cấp được không mất dữ liệu |
| **`/health` chấp nhận GET + HEAD, không chạm DB** | Cho uptime monitor ping 5 phút/lần không tốn tài nguyên DB |
| **Bảo mật thông tin nhạy cảm qua biến môi trường** (`JWT_SECRET`, `OTP`, `API_BASE`) | Repo công khai nhưng không lộ OTP/secret — cấu hình lúc build/chạy |

## 6.3. Triển khai (deployment) hiện tại

```
• App Android: APK release (versionName 2.5.0) — biên dịch với
  --dart-define=API_BASE=<địa chỉ máy chủ> --dart-define=DEMO_OTP=…

• Máy chủ: Render (free tier) — tự deploy mỗi lần push nhánh main
  (lưu ý free tier "ngủ" khi vắng khách: lần gọi đầu sau 30–60 giây mới tỉnh)

• Cơ sở dữ liệu: Aiven PostgreSQL (free tier)

• Giám sát: UptimeRobot ping /health 5 phút/lần (HEAD) → giữ server luôn tỉnh
  + cảnh báo downtime qua email
```

---

# 7. CÔNG NGHỆ CHÍNH (TECH STACK)

## 7.1. Ứng dụng di động (Frontend)

| Công nghệ | Vai trò |
|---|---|
| **Flutter / Dart** | Toàn bộ UI Android: 12 màn hình, widget hoá, thùng UI riêng (màu/bo góc/đổ bóng thống nhất giống bản thiết kế React gốc) |
| **State management tự viết** (`AppState` + `AppStateScope`) | Một kho dữ liệu trung tâm cho cả app; thay đổi dữ liệu = vẽ lại đúng phần màn hình cần thiết |
| **`flutter analyze` sạch lỗi** | Đảm bảo chất lượng code trước mỗi bản build |
| **Build Dart-define** | Nhúng cấu hình (địa chỉ máy chủ, OTP demo) lúc biên dịch — không lưu cứng trong code |

## 7.2. Máy chủ (Backend)

| Công nghệ | Vai trò |
|---|---|
| **Python 3.12 + FastAPI** | Khung API REST hiện đại: tự sinh tài liệu tương tác tại `/docs` (Swagger) |
| **SQLModel / SQLAlchemy** | ORM: 15 bảng dữ liệu, migration tự động (`migrate_db`), chuẩn hoá chuỗi kết nối Postgres |
| **Pydantic** | Kiểm tra dữ liệu vào (mọi body request) |
| **JWT (python-jose)** | Phiên đăng nhập không trạng thái — token tự mang thông tin ai/vai trò |
| **uvicorn[standard]** | Máy chủ ASGI chạy FastAPI (Render) |
| **asyncio watchdog** | Vòng nền xoay mã QR mỗi 10 giây |
| **pytest — hơn 110 test** | Bao phủ: xác thực, RBAC (403 theo từng quyền), QR (hết hạn/dùng lại/geofence), luồng đơn, luồng báo cáo, bảng tin |

## 7.3. Cơ sở dữ liệu & hạ tầng

| Công nghệ | Vai trò |
|---|---|
| **PostgreSQL (Aiven cloud, free tier)** | CSDL chuẩn sản xuất; xử lý đúng đặc thù Postgres (chuỗi FK, sequence, timezone UTC) — các lỗi khác biệt SQLite↔Postgres đã được tìm & sửa trên môi trường thật |
| **SQLite** (chế độ phát triển/test) | Chạy nhanh không cần server — cùng một code ORM, đổi chuỗi kết nối là chuyển |
| **Render** | Hosting máy chủ, CI/CD tự động từ GitHub |
| **UptimeRobot** | Ping `/health` mỗi 5 phút — giữ máy chủ tỉnh & cảnh báo sập |
| **Git / GitHub** | Quản lý mã nguồn, mỗi tính năng một commit mô tả rõ |

## 7.4. Thiết kế & quy trình

| Thành phần | Vai trò |
|---|---|
| **Bộ thiết kế React + Tailwind gốc** (`design/`) | Nguồn mẫu giao diện — app Flutter tái hiện 1:1 từng màn hình, từng màu, từng cụm chữ |
| **Figma plugin** | Dựng lại mockup màn hình từ cấu trúc React vào Figma để bàn giao thiết kế |
| **Tài liệu nội bộ** (`DEPLOY.md`, hướng dẫn test…) | Vận hành & kiểm thử cho người không chuyên |

---

# 8. MÔ HÌNH DỮ LIỆU

15 bảng của PostgreSQL — liệt kê theo nhóm chức năng:

**Nhóm tài khoản & tổ chức**
- `user` — tài khoản đăng nhập: số điện thoại, họ tên thật, vai trò, chi đoàn tham chiếu
- `branch` — chi đoàn: tên, phường, bí thư, loại (khu dân cư / trường học / DN KCN), tổng đoàn viên
- `member` — hồ sơ đoàn viên: mã ĐV-DN-xxx, loại (tại chỗ/làm xa KCN/chuyển SH), nơi làm việc, ca làm, điểm, số lần bù, trạng thái; gắn với `user` (đoàn viên có tài khoản) hoặc không (hồ sơ nợ tài khoản)

**Nhóm điểm danh**
- `session` — buổi sinh hoạt: tên, thời gian, địa điểm, **tọa độ + bán kính geofence**, trạng thái mở/đóng
- `qr_token` — mã QR động: chuỗi token, phát lúc, **hết hạn sau 55s**, **used_by** (ai đã dùng)
- `checkin` — lượt điểm danh: phương thức (qr/manual), khoảng cách GPS, có trong geofence

**Nhóm sinh hoạt bù & báo cáo**
- `makeup_request` — đơn xin bù: buổi, lý do, minh chứng, trạng thái (pending/approved/rejected/clarify)
- `ward_report` — báo cáo kỳ chi đoàn: tháng, số điểm danh/số ĐV (tự đếm), trạng thái (submitted/approved)

**Nhóm thi đua & thưởng**
- `activity` — hoạt động thi đua: tên, loại, thời gian, địa điểm, điểm thưởng, người phát động
- `registration` — đăng ký tham dự (mỗi đoàn viên 1 hoạt động chỉ 1 dòng — chặn trùng)
- `voucher` — voucher thưởng: tên, giảm giá, giá điểm, tồn kho
- `voucher_redemption` — lượt đổi voucher: ai, voucher nào, mã đổi, thời điểm

**Nhóm cộng đồng & hệ thống**
- `post` — bài Bảng tin: tác giả, nội dung, ghim, **is_event + activity_id** (bài phát động sự kiện)
- `comment` — bình luận
- `audit_log` — nhật ký hệ thống: ai, hành động gì, khi nào

---

# 9. DANH MỤC API CỦA MÁY CHỦ

Tất cả endpoint đều qua RBAC (chặn 403 nếu thiếu quyền). Xem bản tương tác tại `<server>/docs`.

| Nhóm | Endpoint | Quyền cần | Làm gì |
|---|---|---|---|
| **Xác thực** | `POST /auth/otp` | công khai | Gửi mã OTP |
| | `POST /auth/login` | công khai | Đăng nhập → JWT + vai trò |
| | `GET /auth/me` | đã đăng nhập | Thông tin tài khoản hiện tại |
| **Buổi & QR** | `GET /sessions` | đã đăng nhập | Danh sách buổi của chi đoàn (kèm token QR đang hiệu lực + giây còn lại) |
| | `POST /sessions` | `session:create` | Tạo buổi sinh hoạt |
| | `DELETE /sessions/{id}` | `session:delete` | Xoá buổi |
| | `POST /sessions/{id}/qr` | `qr:issue` | Phát / xoay mã QR (55s, dùng 1 lần) |
| | `POST /sessions/{id}/checkin` | `session:checkin` | Điểm danh QR + GPS (6 điều kiện) |
| | `POST /sessions/{id}/manual` | `session:create` | Điểm danh thủ công (có lý do) |
| **Đơn bù** | `GET /requests` | đã đăng nhập | Đoàn viên: đơn mình • Bí thư: đơn cả chi đoàn |
| | `POST /requests` | `request:create` | Gửi đơn sinh hoạt bù |
| | `POST /requests/{id}/decide` | `request:decide` | Duyệt / từ chối / làm rõ |
| **Thi đua & thưởng** | `GET /rewards/vouchers` | mọi vai trò | Danh mục voucher |
| | `GET /rewards/activities` | mọi vai trò | Hoạt động (kèm trạng thái mình đã đăng ký chưa) |
| | `GET /rewards/ranking` | mọi vai trò | Top đoàn viên theo điểm |
| | `POST /rewards/activities/{id}/register` | `activity:register` | Đăng ký hoạt động (chặn trùng) |
| | `POST /rewards/vouchers/{id}/redeem` | `voucher:redeem` | Đổi voucher (trừ điểm, giảm kho, sinh mã) |
| **Bảng tin** | `GET /social/posts` | công khai đọc | Bảng tin (ghim lên đầu; bài sự kiện trả kèm hoạt động) |
| | `POST /social/posts` | `post:create` | Đăng bài (có thể gắn sự kiện) |
| | `POST /social/posts/{id}/comment` | `post:comment` | Bình luận |
| | `POST /social/posts/{id}/pin` | `post:moderate` | Ghim / bỏ ghim |
| | `DELETE /social/posts/{id}` | `post:moderate` | Xóa bài vi phạm |
| **Cấp phường** | `GET /ward/dashboard` | `branch:view` | Dashboard tổng hợp 12 chi đoàn |
| | `POST /ward/reports` | `report:submit` | Bí thư nộp báo cáo kỳ (tự đếm từ checkin) |
| | `POST /ward/reports/{id}/approve` | `report:approve` | Duyệt báo cáo |
| | `POST /ward/reports/{id}/remind` | `report:approve` | Gửi nhắc qua Zalo |
| | `POST /ward/branches/{id}/remind` | `report:approve` | Nhắc nộp theo chi đoàn |
| | `GET /ward/report/export` | `report:export` | Xuất văn bản thể thức (công văn) |
| | `POST /ward/activities` | `activity:launch` | Phát động hoạt động toàn phường |
| | `GET /ward/activities` | mọi vai trò | Danh mục hoạt động (kèm trạng thái đăng ký) |
| **Đoàn viên** | `GET /members` | cán bộ/bí thư | Danh sách đoàn viên |
| | `POST /members` | `member:create` | Thêm đoàn viên |
| | `DELETE /members/{id}` | `member:delete` | Xóa đoàn viên |
| **Hệ thống** | `GET /health` | công khai (GET+HEAD) | Kiểm tra sống — không đụng DB |

---

# 10. GIỚI HẠN HIỆN TẠI & HƯỚNG PHÁT TRIỂN

**Đã biết và chấp nhận trong bản demo:**
- Máy chủ Render free tier "ngủ" khi vắng khách → lần mở đầu chậm 30–60 giây (UptimeRobot giảm thiểu).
- Camera máy ảo không quét được QR thật — trên điện thoại thật quét bình thường (app vẫn có đường nhập mã thủ công).
- Chưa hoàn thiện 100%: Đăng ký tài khoản mới (màn "Đăng ký mới"), nút "In/PDF" báo cáo chưa nối tới thư viện in thật; một số thông báo mock trong tab Thi đua chưa đi qua máy chủ.
- Phiên đăng nhập chưa giữ lại nếu người dùng tắt hẳn app từ nhiều tác vụ (đăng nhập lại nhanh bằng OTP).

**Hướng phát triển tự nhiên tiếp theo:**
- Gửi OTP thật qua SMS/Zalo ZNS; đẩy thông báo qua Zalo OA.
- In/PDF báo cáo trực tiếp trên điện thoại; xuất Excel danh sách đoàn viên.
- App iOS (Flutter đa nền tảng — build thêm là chạy).
- Thống kê dự đoán (đoán tỷ lệ tham dự, cảnh báo đoàn viên có nguy cơ rớt tiêu chí).
- Phần thưởng số mở rộng: phối hợp doanh nghiệp KCN thêm voucher thật.

---

*Hệ thống "Đoàn Viên Số" — Đồng Nai 2026 • App Flutter (v2.5.0) + FastAPI + PostgreSQL*
