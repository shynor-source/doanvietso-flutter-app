"""TEST — Trợ lý AI (/assistant/ask): hướng dẫn chức năng theo vai trò + fallback KB."""
from tests.conftest import auth_headers, PHONE, OTP


def _login(client, phone):
    r = client.post("/auth/login", json={"phone": phone, "otp": OTP})
    assert r.status_code == 200
    return {"Authorization": f"Bearer {r.json()['access_token']}"}


class TestAssistant:
    def test_01_can_token(self, client):
        r = client.post("/assistant/ask", json={"question": "cách điểm danh qr"})
        assert r.status_code == 401

    def test_02_cau_hoi_trong(self, client):
        r = client.post("/assistant/ask", headers=_login(client, PHONE["member"]), json={"question": "  "})
        assert r.status_code == 400

    def test_03_cau_hoi_qua_dai(self, client):
        r = client.post("/assistant/ask", headers=_login(client, PHONE["member"]), json={"question": "a" * 501})
        assert r.status_code == 400

    def test_04_fallback_member_diem_danh(self, client, monkeypatch):
        """Không có GEMINI_API_KEY → fallback tra từ khóa, trả đúng màn quét QR."""
        monkeypatch.delenv("GEMINI_API_KEY", raising=False)
        r = client.post("/assistant/ask", headers=_login(client, PHONE["member"]),
                        json={"question": "làm sao quét qr điểm danh sinh hoạt?"})
        assert r.status_code == 200
        d = r.json()
        assert d["source"] == "fallback"
        assert d["nav"] == "scan_qr"
        assert d["nav_label"]
        assert len(d["steps"]) >= 2

    def test_05_fallback_secretary_duyet_don(self, client, monkeypatch):
        monkeypatch.delenv("GEMINI_API_KEY", raising=False)
        r = client.post("/assistant/ask", headers=_login(client, PHONE["secretary"]),
                        json={"question": "duyệt đơn xin sinh hoạt bù ở đâu?"})
        assert r.status_code == 200
        d = r.json()
        assert d["nav"] == "makeup"
        assert "Duyệt" in d["answer"] or len(d["steps"]) >= 2

    def test_06_rbac_kb_theo_vai_tro(self, client, monkeypatch):
        """Đoàn viên hỏi chức năng chỉ cán bộ có → không 'chỉ đường' vượt quyền."""
        monkeypatch.delenv("GEMINI_API_KEY", raising=False)
        r = client.post("/assistant/ask", headers=_login(client, PHONE["member"]),
                        json={"question": "xuất văn bản báo cáo đúng thể thức công văn"})
        assert r.status_code == 200
        d = r.json()
        assert d["nav"] != "ward_reports"  # không dẫn đoàn viên tới màn của cán bộ

    def test_07_ward_export(self, client, monkeypatch):
        monkeypatch.delenv("GEMINI_API_KEY", raising=False)
        r = client.post("/assistant/ask", headers=_login(client, PHONE["ward_officer"]),
                        json={"question": "tôi muốn xuất văn bản báo cáo công văn"})
        assert r.status_code == 200
        assert r.json()["nav"] == "ward_reports"
