"""TEST 1 — Xác thực & phiên đăng nhập (luồng: Đăng nhập OTP mọi vai trò)."""
from tests.conftest import auth_headers, PHONE, OTP


class TestAuth:
    def test_01_login_member_ok(self, client):
        r = client.post("/auth/login", json={"phone": PHONE["member"], "otp": OTP})
        assert r.status_code == 200
        d = r.json()
        assert d["access_token"]
        assert d["user"]["role"] == "member"
        assert d["user"]["member_id"] == 1  # Trần Minh Quân = hồ sơ ĐV-DN-001
        assert d["user"]["full_name"] == "Trần Minh Quân"

    def test_02_login_secretary_ok(self, client):
        r = client.post("/auth/login", json={"phone": PHONE["secretary"], "otp": OTP})
        assert r.status_code == 200
        assert r.json()["user"]["role"] == "secretary"

    def test_03_login_ward_ok(self, client):
        r = client.post("/auth/login", json={"phone": PHONE["ward_officer"], "otp": OTP})
        assert r.status_code == 200
        assert r.json()["user"]["role"] == "ward_officer"

    def test_04_login_sai_otp(self, client):
        r = client.post("/auth/login", json={"phone": PHONE["member"], "otp": "111111"})
        assert r.status_code == 401

    def test_05_login_sai_phone(self, client):
        r = client.post("/auth/login", json={"phone": "0999999999", "otp": OTP})
        assert r.status_code == 401

    def test_06_login_thieu_truong(self, client):
        r = client.post("/auth/login", json={"phone": PHONE["member"]})
        assert r.status_code == 422

    def test_07_me_can_token(self, client):
        r = client.get("/auth/me", headers=auth_headers(client, "secretary"))
        assert r.status_code == 200
        assert r.json()["role"] == "secretary"
        assert r.json()["full_name"] == "Nguyễn Văn An"
        assert r.json()["member"] is None  # bí thư chưa gắn hồ sơ đoàn viên

    def test_08_me_khong_token(self, client):
        r = client.get("/auth/me")
        assert r.status_code == 401

    def test_09_token_gia(self, client):
        r = client.get("/auth/me", headers={"Authorization": "Bearer fake.token.xxx"})
        assert r.status_code == 401

    def test_10_gui_otp_endpoint(self, client):
        r = client.post("/auth/otp", json={"phone": PHONE["member"]})
        assert r.status_code == 200
        assert "246810" in r.json()["note"]


def test_health_endpoint_no_auth(client):
    r = client.get("/health")
    assert r.status_code == 200 and r.json() == {"status": "ok"}
