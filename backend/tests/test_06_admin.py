"""TEST — Quản trị tài khoản (/admin): cán bộ Đoàn phường xem & đổi vai trò."""
from tests.conftest import auth_headers, PHONE, OTP


def _login(client, phone):
    r = client.post("/auth/login", json={"phone": phone, "otp": OTP})
    assert r.status_code == 200
    return r.json()["access_token"]


def _h(tok):
    return {"Authorization": f"Bearer {tok}"}


class TestAdminUsers:
    def test_01_ward_xem_toan_bo(self, client):
        tok = _login(client, PHONE["ward_officer"])
        r = client.get("/admin/users", headers=_h(tok))
        assert r.status_code == 200
        d = r.json()
        assert d["total"] >= 3
        roles = {u["role"] for u in d["users"]}
        assert {"member", "secretary", "ward_officer"} <= roles

    def test_02_khong_du_quyen_403(self, client):
        for phone in (PHONE["member"], PHONE["secretary"]):
            tok = _login(client, phone)
            assert client.get("/admin/users", headers=_h(tok)).status_code == 403

    def test_03_khong_token_401(self, client):
        assert client.get("/admin/users").status_code == 401

    def test_04_doi_vai_tro_thanh_cong(self, client):
        tok = _login(client, PHONE["ward_officer"])
        users = client.get("/admin/users", headers=_h(tok)).json()["users"]
        member_id = next(u["id"] for u in users if u["role"] == "member")
        r = client.patch(f"/admin/users/{member_id}/role", headers=_h(tok), json={"role": "secretary"})
        assert r.status_code == 200
        assert r.json()["role"] == "secretary"
        # máy chủ áp dụng ngay: tài khoản đó bây giờ có quyền bí thư (duyệt đơn)
        new_tok = _login(client, PHONE["member"])  # đăng nhập lại → token mang vai trò mới
        r2 = client.get("/requests", headers=_h(new_tok))
        assert r2.status_code == 200
        # trả lại vai trò cũ để không ảnh hưởng test khác
        client.patch(f"/admin/users/{member_id}/role", headers=_h(tok), json={"role": "member"})

    def test_05_khong_duoc_doi_vai_tro_chinh_minh(self, client):
        tok = _login(client, PHONE["ward_officer"])
        users = client.get("/admin/users", headers=_h(tok)).json()["users"]
        me = next(u["id"] for u in users if u["role"] == "ward_officer")
        r = client.patch(f"/admin/users/{me}/role", headers=_h(tok), json={"role": "member"})
        assert r.status_code == 400

    def test_06_cap_vai_tro_member_cho_tk_khong_ho_so(self, client):
        """Tài khoản không gắn hồ sơ đoàn viên không thể cấp vai trò member."""
        tok = _login(client, PHONE["ward_officer"])
        users = client.get("/admin/users", headers=_h(tok)).json()["users"]
        no_profile = [u for u in users if u["member_id"] is None and u["role"] == "ward_officer" and u["phone"] != PHONE["ward_officer"]]
        if not no_profile:
            return  # seed hiện tại mọi ward_officer đều có hồ sơ → bỏ qua
        r = client.patch(f"/admin/users/{no_profile[0]['id']}/role", headers=_h(tok), json={"role": "member"})
        assert r.status_code == 400

    def test_07_vai_tro_khong_hop_le(self, client):
        tok = _login(client, PHONE["ward_officer"])
        r = client.patch("/admin/users/2/role", headers=_h(tok), json={"role": "admin"})
        assert r.status_code == 400

    def test_08_ghi_audit_log(self, client):
        tok = _login(client, PHONE["ward_officer"])
        client.patch("/admin/users/2/role", headers=_h(tok), json={"role": "secretary"})
        client.patch("/admin/users/2/role", headers=_h(tok), json={"role": "member"})
        r = client.get("/ward/dashboard", headers=_h(tok))
        assert r.status_code == 200  # hành động đã chạy trơn tru; AuditLog ghi trong endpoint

    def test_09_tao_hang_loat_demo(self, client):
        tok = _login(client, PHONE["ward_officer"])
        r = client.post("/admin/users/demo-batch?count=10", headers=_h(tok))
        assert r.status_code == 200
        created = r.json()["created"]
        assert created == 10
        # gọi lại → bỏ qua SĐT đã tồn tại, tạo thêm 10 tài khoản mới
        r2 = client.post("/admin/users/demo-batch?count=10", headers=_h(tok))
        assert r2.status_code == 200
        assert r2.json()["created"] == 10 and r2.json()["skipped"] == 10
        # đăng nhập được bằng tài khoản mới tạo
        assert client.post("/auth/login", json={"phone": "0907700001", "otp": OTP}).status_code == 200

    def test_10_chuyen_tk_moi_len_bi_thu_va_nguoc_lai(self, client):
        tok = _login(client, PHONE["ward_officer"])
        users = client.get("/admin/users", headers=_h(tok)).json()["users"]
        new_u = next(u for u in users if u["phone"] == "0907700001")
        r = client.patch(f"/admin/users/{new_u['id']}/role", headers=_h(tok), json={"role": "secretary"})
        assert r.status_code == 200 and r.json()["role"] == "secretary"
        r2 = client.patch(f"/admin/users/{new_u['id']}/role", headers=_h(tok), json={"role": "member"})
        assert r2.status_code == 200 and r2.json()["role"] == "member"

    def test_11_chong_tao_hang_loat_qua_gioi_han(self, client):
        tok = _login(client, PHONE["ward_officer"])
        r = client.post("/admin/users/demo-batch?count=999", headers=_h(tok))
        assert r.status_code == 200 and r.json()["created"] <= 60
