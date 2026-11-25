"""TEST 4 — Hồ sơ đoàn viên, đơn sinh hoạt bù, báo cáo phường, hoạt động, thi đua, bảng tin."""
import pytest
from tests.conftest import auth_headers, db_session, member_points
from app import models
from sqlmodel import select


class TestMembers:
    def test_01_list_46_dv(self, client):
        r = client.get("/members", headers=auth_headers(client, "secretary"))
        assert r.status_code == 200
        assert len(r.json()) >= 46  # 46 seed + các bản ghi test tạo trước đó

    def test_02_member_bi_chan_danh_ba(self, client):
        r = client.get("/members", headers=auth_headers(client, "member"))
        assert r.status_code == 403

    def test_03_ward_xem_toan_phuong_loc_chi_doan(self, client):
        r = client.get("/members?branch_id=2", headers=auth_headers(client, "ward_officer"))
        assert r.status_code == 200
        assert all(m["branch_id"] == 2 if "branch_id" in m else True for m in r.json())

    def test_04_them_sua_xoa(self, client):
        r = client.post("/members", headers=auth_headers(client, "secretary"),
                        json={"name": "Nguyễn Test Thêm", "phone": "0900999888", "type": "working_far",
                              "workplace": "KCN Amata", "shift": "Ca đêm"})
        assert r.status_code == 200
        mid = r.json()["id"]
        r2 = client.patch(f"/members/{mid}", headers=auth_headers(client, "secretary"),
                          json={"phone": "0900999777"})
        assert r2.status_code == 200
        lst = client.get("/members", headers=auth_headers(client, "secretary")).json()
        assert any(m["id"] == mid and m["phone"] == "0900999777" for m in lst)
        assert client.delete(f"/members/{mid}", headers=auth_headers(client, "secretary")).status_code == 200


class TestRequests:
    def test_01_member_tao_don(self, client):
        r = client.post("/requests", headers=auth_headers(client, "member"),
                        json={"session_title": "SH tháng 12", "reason": "Trực ca 2 Changshin",
                              "proof": "Xác nhận quản đốc"})
        assert r.status_code == 200
        assert r.json()["status"] == "pending"

    def test_02_bi_thu_thay_toan_chi_doan(self, client):
        r = client.get("/requests", headers=auth_headers(client, "secretary"))
        assert r.status_code == 200
        assert len(r.json()) >= 3  # 2 đơn seed + 1 vừa tạo

    def test_03_member_chi_thay_don_cua_minh(self, client):
        r = client.get("/requests", headers=auth_headers(client, "member"))
        assert r.status_code == 200
        assert all(x["member_id"] == 1 for x in r.json())

    def test_04_duyet_cong_10_diem(self, client, db_session):
        # tạo đơn mới của member (member_id=1) rồi duyệt — deterministic
        rid = client.post("/requests", headers=auth_headers(client, "member"),
                          json={"session_title": "SH kỳ duyệt điểm", "reason": "Trực ca"}).json()["id"]
        before = member_points(db_session, 1)
        r = client.post(f"/requests/{rid}/decide", headers=auth_headers(client, "secretary"),
                        json={"action": "approve", "note": "Hợp lệ"})
        assert r.status_code == 200
        db_session.expire_all()
        assert member_points(db_session, 1) == before + 10  # phúc điểm +10
        assert db_session.get(models.MakeupRequest, rid).status == "approved"

    def test_05_yeu_cau_bo_sung(self, client):
        r = client.post("/requests/2/decide", headers=auth_headers(client, "secretary"),
                        json={"action": "clarify", "note": "Cần công văn tăng ca"})
        assert r.status_code == 200
        assert r.json()["status"] == "clarify"

    def test_06_action_sai(self, client):
        r = client.post("/requests/2/decide", headers=auth_headers(client, "secretary"),
                        json={"action": "hủy"})
        assert r.status_code == 400

    def test_06b_duyet_lai_khong_cong_diem_lan_2(self, client, db_session):
        """Chống leo thang: duyệt lại đơn đã duyệt KHÔNG được cộng thêm điểm."""
        before = member_points(db_session, 1)
        r = client.post("/requests/1/decide", headers=auth_headers(client, "secretary"),
                        json={"action": "approve"})
        assert r.status_code == 200
        db_session.expire_all()
        assert member_points(db_session, 1) == before  # không cộng nữa

    def test_07_don_khong_ton_tai(self, client):
        r = client.post("/requests/999/decide", headers=auth_headers(client, "secretary"),
                        json={"action": "approve"})
        assert r.status_code == 404


class TestWard:
    def test_01_dashboard_so_lieu(self, client):
        r = client.get("/ward/dashboard", headers=auth_headers(client, "ward_officer"))
        assert r.status_code == 200
        d = r.json()
        assert d["total_branches"] == 5
        assert d["total_members"] >= 216  # 46+42+28+60+40 (+ bản ghi test)
        assert len(d["branches"]) == 5

    def test_02_bi_thu_nop_bao_cao(self, client):
        r = client.post("/ward/reports", headers=auth_headers(client, "secretary"))
        assert r.status_code == 200
        assert r.json()["total"] >= 46

    def test_03_duyet_bao_cao_pending(self, client, db_session):
        rep = db_session.exec(select(models.WardReport).where(models.WardReport.branch_id == 5)).first()
        assert rep.status == "pending"
        r = client.post("/ward/branches/5/approve", headers=auth_headers(client, "ward_officer"))
        assert r.status_code == 200
        db_session.expire_all()
        assert db_session.get(models.WardReport, rep.id).status == "approved"

    def test_04_duyet_lai_idempotent(self, client):
        r = client.post("/ward/branches/5/approve", headers=auth_headers(client, "ward_officer"))
        assert r.status_code == 200  # đã approved trước đó — không lỗi

    def test_05_nhac_nop(self, client):
        r = client.post("/ward/branches/3/remind", headers=auth_headers(client, "ward_officer"))
        assert r.status_code == 200
        assert "Zalo" in r.json()["message"]

    def test_06_xuat_bao_cao_the_thuc(self, client):
        r = client.get("/ward/report/export", headers=auth_headers(client, "ward_officer"))
        assert r.status_code == 200
        assert "BÁO CÁO TÌNH HÌNH SINH HOẠT" in r.text
        assert "ĐOÀN TNCS HỒ CHÍ MINH" in r.text

    def test_07_phat_dong_hoat_dong(self, client):
        r = client.post("/ward/activities", headers=auth_headers(client, "ward_officer"),
                        json={"title": "Ngày chủ nhật xanh", "category": "Tình nguyện",
                              "starts_at": "2026-12-27T07:30:00", "points": 30})
        assert r.status_code == 200
        aid = r.json()["id"]
        lst = client.get("/ward/activities", headers=auth_headers(client, "member")).json()
        assert aid in [a["id"] for a in lst]


class TestRewards:
    def test_01_voucher_du_du_lieu(self, client):
        r = client.get("/rewards/vouchers")
        assert r.status_code == 200
        assert len(r.json()) >= 2

    def test_02_xep_hang(self, client):
        r = client.get("/rewards/ranking")
        assert r.status_code == 200

    def test_03_doi_voucher_du_diem(self, client, db_session):
        # nạp điểm đủ tiêu chuẩn (mô phỏng đoàn viên tích cực qua nhiều kỳ)
        m = db_session.get(models.Member, 1)
        m.points = 300
        db_session.add(m)
        db_session.commit()
        r = client.post("/rewards/vouchers/2/redeem", headers=auth_headers(client, "member"))
        assert r.status_code == 200, r.text
        assert r.json()["code"].startswith("DV-")
        db_session.expire_all()
        m1 = db_session.get(models.Member, 1)
        v2 = db_session.get(models.Voucher, 2)
        assert m1.points == 300 - v2.cost_points
        assert v2.stock == 49  # 50 - 1

    def test_04_doi_khi_thieu_diem(self, client, db_session):
        m = db_session.get(models.Member, 1)
        m.points = 10
        db_session.add(m)
        db_session.commit()
        r = client.post("/rewards/vouchers/1/redeem", headers=auth_headers(client, "member"))
        assert r.status_code == 400
        assert "Không đủ điểm" in r.json()["detail"]


class TestSocial:
    def test_01_bai_ghim_len_dau(self, client):
        r = client.get("/social/posts")
        assert r.status_code == 200
        posts = r.json()
        assert posts[0]["is_pinned"] is True

    def test_02_dang_bai_va_binh_luan(self, client):
        r = client.post("/social/posts", headers=auth_headers(client, "member"),
                        json={"content": "Buổi e-learning rất bổ ích!"})
        assert r.status_code == 200
        pid = r.json()["id"]
        r2 = client.post(f"/social/posts/{pid}/comment", headers=auth_headers(client, "secretary"),
                         json={"content": "Cố lên em nhé!"})
        assert r2.status_code == 200

    def test_03_member_khong_ghim_duoc(self, client):
        r = client.post("/social/posts/1/pin", headers=auth_headers(client, "member"))
        assert r.status_code == 403

    def test_04_ghim_va_thu_tu(self, client):
        # ghim là TOGGLE: tạo bài mới (chưa ghim) → ghim 1 lần → lên đầu
        pid = client.post("/social/posts", headers=auth_headers(client, "secretary"),
                          json={"content": "Bài cần ghim lên đầu"}).json()["id"]
        r = client.post(f"/social/posts/{pid}/pin", headers=auth_headers(client, "secretary"))
        assert r.status_code == 200 and r.json()["is_pinned"] is True
        posts = client.get("/social/posts").json()
        assert posts[0]["id"] == pid  # ghim luôn đầu

    def test_05_member_khong_xoa_duoc(self, client):
        r = client.delete("/social/posts/2", headers=auth_headers(client, "member"))
        assert r.status_code == 403

    def test_06_xoa_bai_vipham(self, client):
        r = client.post("/social/posts", headers=auth_headers(client, "member"),
                        json={"content": "Bài cần gỡ (test moderation)"})
        pid = r.json()["id"]
        assert client.delete(f"/social/posts/{pid}", headers=auth_headers(client, "secretary")).status_code == 200
        ids = [p["id"] for p in client.get("/social/posts").json()]
        assert pid not in ids


class TestUploadAnhBaiDang:
    """Đăng bài kèm ảnh thật (base64) — lưu DB, phục vụ lại bytes qua GET image."""

    def _login(self, client):
        return auth_headers(client, "member")

    def test_01_dang_bai_kem_anh(self, client):
        h = self._login(client)
        tiny_png = ("iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJ"
                    "AAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==")
        r = client.post("/social/posts", headers=h, json={"content": "Bài kèm ảnh", "image": tiny_png, "mime": "image/png"})
        assert r.status_code == 200 and r.json()["has_image"] is True
        pid = r.json()["id"]
        # ảnh phục vụ lại đúng loại nội dung
        r2 = client.get(f"/social/posts/{pid}/image")
        assert r2.status_code == 200 and r2.headers["content-type"].startswith("image/png") and r2.content
        # list posts đánh dấu has_image
        posts = client.get("/social/posts").json()
        assert next(p for p in posts if p["id"] == pid)["has_image"] is True

    def test_02_bai_khong_anh(self, client):
        h = self._login(client)
        r = client.post("/social/posts", headers=h, json={"content": "Bài không ảnh"})
        pid = r.json()["id"]
        assert r.json()["has_image"] is False
        assert client.get(f"/social/posts/{pid}/image").status_code == 404

    def test_03_anh_qua_lon_bi_choi(self, client):
        h = self._login(client)
        big = "A" * 4_500_000
        r = client.post("/social/posts", headers=h, json={"content": "x", "image": big})
        assert r.status_code == 413

    def test_04_base64_sai_bi_choi(self, client):
        h = self._login(client)
        r = client.post("/social/posts", headers=h, json={"content": "x", "image": "không-phải-base64!!"})
        assert r.status_code == 400
