"""TEST 3 — QR động + Geofence + chống gian lận (theo OWASP Mobile / case QRIS):
mã động TTL ngắn, mỗi mã 1 lần, chặn dùng mã cũ, chặn ngoài phạm vi, chặn phiên đóng.
"""
import pytest
from tests.conftest import auth_headers, set_token_expired
from app import models

GEO_OK = {"lat": 10.95672, "lng": 106.8244}      # ~35m từ NVH KP5 (10.9565, 106.8244)
GEO_FAR = {"lat": 10.910, "lng": 106.780}        # ~5.5km — ngoài bán kính 100m


class TestQrGeofence:
    def test_01_bí_thu_phat_qr(self, client):
        r = client.post("/sessions/1/qr", headers=auth_headers(client, "secretary"))
        assert r.status_code == 200
        d = r.json()
        assert d["token"].startswith("KP5-")
        assert d["expires_in_s"] == 55

    def test_02_xoay_lan_2_khac_token(self, client):
        r1 = client.post("/sessions/1/qr", headers=auth_headers(client, "secretary"))
        r2 = client.post("/sessions/1/qr", headers=auth_headers(client, "secretary"))
        assert r1.json()["token"] != r2.json()["token"]

    def test_03_danh_sach_session_co_token(self, client):
        r = client.get("/sessions", headers=auth_headers(client, "secretary"))
        assert r.status_code == 200
        open_sessions = [s for s in r.json() if s["is_open"]]
        assert open_sessions and open_sessions[0]["current_qr_token"]

    def test_04_checkin_trong_pham_vi_thanh_cong(self, client, db_session):
        tok = client.post("/sessions/1/qr", headers=auth_headers(client, "secretary")).json()["token"]
        before = db_session.get(models.Member, 1).points
        r = client.post("/sessions/1/checkin", headers=auth_headers(client, "member"), json={"token": tok, **GEO_OK})
        assert r.status_code == 200, r.text
        assert r.json()["distance_m"] <= 100
        db_session.expire_all()
        after = db_session.get(models.Member, 1).points
        assert after == before + 5  # +5 điểm chuyên cần

    def test_05_checkin_lai_bao_da_diem_danh(self, client):
        tok = client.post("/sessions/1/qr", headers=auth_headers(client, "secretary")).json()["token"]
        r = client.post("/sessions/1/checkin", headers=auth_headers(client, "member"), json={"token": tok, **GEO_OK})
        assert r.status_code == 400
        assert "đã điểm danh" in r.json()["detail"]

    def test_06_replay_token_da_dung(self, client):
        """Chống tái sử dụng mã (anti-replay): mã cũ đã bị vô hiệu khi xoay."""
        old = client.post("/sessions/1/qr", headers=auth_headers(client, "secretary")).json()["token"]
        client.post("/sessions/1/qr", headers=auth_headers(client, "secretary"))  # xoay → mã old vô hiệu
        r = client.post("/sessions/1/checkin", headers=auth_headers(client, "member"), json={"token": old, **GEO_OK})
        assert r.status_code == 400
        # Mã đã bị xoá khi xoay mã mới (chống phát lại) → không còn hợp lệ
        assert "1 lần" in r.json()["detail"] or "hết hạn" in r.json()["detail"] or "không đúng buổi" in r.json()["detail"]

    def test_07_token_het_han(self, client, db_session):
        tok = client.post("/sessions/1/qr", headers=auth_headers(client, "secretary")).json()["token"]
        set_token_expired(db_session, tok)
        client.post("/sessions/1/qr", headers=auth_headers(client, "secretary"))  # cần member chưa điểm danh được thì thôi
        r = client.post("/sessions/1/checkin", headers=auth_headers(client, "member"), json={"token": tok, **GEO_OK})
        assert r.status_code in (400, 403)

    def test_08_token_sai_buoi(self, client):
        client.post("/sessions/1/qr", headers=auth_headers(client, "secretary"))
        r = client.post("/sessions/1/checkin", headers=auth_headers(client, "member"),
                        json={"token": "KP5-999999-FFFF", **GEO_OK})
        assert r.status_code == 400
        assert "không đúng buổi" in r.json()["detail"]

    def test_09_ngoai_pham_vi_5km_bi_chan(self, client):
        tok = client.post("/sessions/1/qr", headers=auth_headers(client, "secretary")).json()["token"]
        r = client.post("/sessions/1/checkin", headers=auth_headers(client, "member"), json={"token": tok, **GEO_FAR})
        assert r.status_code == 403
        assert "cách điểm sinh hoạt" in r.json()["detail"]

    def test_10_diem_danh_thu_cong_bí_thu(self, client):
        r = client.post("/sessions/1/manual?member_id=3&reason=Quên điện thoại",
                        headers=auth_headers(client, "secretary"))
        assert r.status_code == 200

    def test_11_tao_buoi_moi(self, client):
        r = client.post("/sessions", headers=auth_headers(client, "secretary"),
                        json={"title": "Sinh hoạt tháng 1", "starts_at": "2027-01-10T20:00:00"})
        assert r.status_code == 200
        assert r.json()["id"]

    def test_12_dong_buoi(self, client):
        r = client.post("/sessions", headers=auth_headers(client, "secretary"),
                        json={"title": "Buổi đóng test", "starts_at": "2027-01-11T20:00:00"})
        sid = r.json()["id"]
        assert client.patch(f"/sessions/{sid}/close", headers=auth_headers(client, "secretary")).status_code == 200
        # mã QR cho buổi đóng → 400
        r2 = client.post(f"/sessions/{sid}/qr", headers=auth_headers(client, "secretary"))
        assert r2.status_code == 400
        # xóa buổi → 200, list không còn
        assert client.delete(f"/sessions/{sid}", headers=auth_headers(client, "secretary")).status_code == 200
        lst = client.get("/sessions", headers=auth_headers(client, "secretary")).json()
        assert sid not in [s["id"] for s in lst]

    def test_13_member_khong_the_phat_qr(self, client):
        r = client.post("/sessions/1/qr", headers=auth_headers(client, "member"))
        assert r.status_code == 403
