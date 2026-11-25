---
name: hackathon-report
description: Tạo báo cáo/slide thuyết trình dự án hackathon chuẩn (tài liệu, deck HTML, kịch bản nói 5–10 phút) — cấu trúc 3 hồi Bài toán→Giải pháp→Tác động, bảng số liệu, ma trận phân quyền, luồng dữ liệu, hành trình người dùng. Dùng khi user yêu cầu làm slide báo cáo, deck thuyết trình, kịch bản pitch, hoặc tài liệu gửi đồng đội làm slide cho hackathon/demo.
---

# Hackathon report — cấu trúc chuẩn & cách trình bày

Nguồn nghiên cứu (đọc khi cần chi tiết):
- Hackathon Strategy Guide — Demo & Pitch: https://yarmoluk.github.io/hackathon-strategy-guide/chapters/09-demo-and-pitch/
- HackTribe — 5-minute pitch structure: https://hacktribe.co/blog/how-to-build-a-hackathon-pitch-deck-practical-5-minute-structure
- The Hackathon Playbook — Pitching/Submission: https://thehackathonplaybook.dev/playbook/pitching
- Hackbriven — Art of the Pitch: https://hackbriven.com/blogs/art-of-hackathon-pitching

## 1. Quy tắc vàng (từ nghiên cứu)

1. **Mở đầu bằng bài toán của thế giới, không phải giới thiệu team.** Cấu trúc "Hi, we're
   team X and we built…" là lỗi phổ biến nhất. Câu đầu phải làm người nghe gật gù.
2. **Hồi 3: Bài toán → Giải pháp → Tác động** (narrative arc). Chia thời lượng theo trọng
   số tiêu chí chấm của BTC — hỏi/suy đoán trước: điểm kỹ thuật cao → show prototype &
   quyết định kiến trúc; điểm tác động cao → user, evidence, lộ trình.
3. **Show, don't tell:** demo/sản phẩm trong 60–90 giây đầu của hồi Giải pháp, đừng dồn
   demo vào 30 giây cuối. Chỉ show "core loop" + 1 điểm khác biệt, tạo tò mò phần còn lại.
4. **Kiến trúc: 1 sơ đồ duy nhất** (user action → app → API → DB). Giám khảo kỹ thuật
   muốn biết "is this real?" — sơ đồ trung thực tạo độ tin cậy.
5. **Chỉ nói thành công và giá trị.** Không kể lỗi, không kể quá trình sai-đúng, không
   tự phơi bày điểm yếu; nếu bị hỏi khó thì trả lời ngắn, chuyển về giá trị sản phẩm.
6. **Không nhồi tính năng.** Mỗi slide ≤ 1 thông điệp; số liệu định lượng (users, tables,
   endpoints, tests) mạnh hơn tính từ ("nhanh", "hiện đại").
7. Luyện **đường demo** (chuỗi thao tác cụ thể, không phải "chức năng chung chung") ít
   nhất 3 lần sau feature freeze; chuẩn bị sẵn ảnh chụp màn hình dự phòng nếu live fail.

## 2. Khung nội dung chuẩn (bám 5 mục BTC thường yêu cầu)

Số thứ tự = thứ tự slide. Điều chỉnh theo trọng số chấm:

1. **Bài toán** — ai chịu, tốn kém gì, vì sao chưa được giải (1 slide).
2. **Giải pháp trong 1 màn hình** — 1 câu định nghĩa + bảng số liệu định lượng
   (stack, số module, số người dùng demo, số test…).
3. **Chức năng theo vai trò/người dùng** — cột riêng từng vai trò, mỗi vai trò ≤ 6 mục.
4. **Phân quyền/bảo mật** — nếu có RBAC: ma trận quyền × vai trò dạng bảng dấu ✅/❌,
   kèm số lớp bảo vệ (API guard → UI → token).
5. **Luồng dữ liệu** — 3–5 luồng chính, mỗi luồng 1 dòng mũi tên; luồng "điểm nhấn"
   (có cơ chế chống gian lận/bảo mật) nên tách riêng.
6. **Hành trình người dùng** — timeline 5–7 bước kể một kịch bản thực tế ("một kỳ
   sinh hoạt", "một ca khám bệnh"…); đây cũng là script demo.
7. **Công nghệ chính** — bảng "công nghệ | vì sao chọn"; nói lý do, đừng đọc tên thư viện.
8. **Kết quả & hướng phát triển** — artifact bàn giao (APK, API docs, test suite),
   con số đạt được, 2–3 hướng mở tiếp.
9. **Kịch bản demo** — tài khoản demo, chuỗi thao tác theo thứ tự, thời lượng.

## 3. Thời lượng tham khảo

- **5 phút:** Bài toán 0:30 → Giải pháp+số liệu 0:30 → Chức năng 1:00 → Phân quyền 0:45
  → Luồng dữ liệu 1:00 → Hành trình/demo 1:15 → Công nghệ 0:30.
- **10 phút:** thêm chi tiết luồng dữ liệu, demo live dài hơn, hướng phát triển (0:45).
- Tối đa ~10–12 slide cho 5 phút, ~16 cho 10 phút. Mỗi slide có "câu chốt" 1 dòng in đậm.

## 4. Định dạng bàn giao

- Tài liệu .md gọn để **gửi đồng đội tự làm slide** — viết theo khung mục 2, mỗi mục
  là **nguồn thông tin thuần**: bullet, bảng, số liệu, có thể chép thẳng vào slide.
  KHÔNG viết dạng kịch bản: không lời thoại, không "câu chốt nói thuộc lòng",
  không bảng định thời lượng từng slide, không chỉ dẫn cách nói/diễn.
- Nếu tự sinh deck: **1 file HTML tự chứa** (nav phím mũi tên/click, 16:9, không CDN bắt
  buộc) tại `docs/slides/`, ảnh chụp màn hình thật ở `docs/slides/img/`.
- Ngôn ngữ: theo ngôn ngữ dự án (dự án VN → tiếng Việt, thuật ngữ kỹ thuật giữ tiếng Anh).
