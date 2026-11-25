"""TEST 2 — Ma trận RBAC: mọi vai trò chỉ được gọi đúng nhóm chức năng của mình.

Với mỗi endpoint được bảo vệ, kiểm tra 2 chiều:
  - vai trò KHÔNG có quyền → 403 (kèm thông báo tiếng Việt)
  - vai trò CÓ quyền → không phải 403/401
"""
import pytest
from tests.conftest import auth_headers

# (method, path, vai_trò_bị_chặn_dự_kiến)
BLOCKED = [
    ("POST",   "/sessions",                                  ["member", "ward_officer"]),
    ("POST",   "/sessions/1/qr",                             ["member", "ward_officer"]),
    ("POST",   "/sessions/1/manual?member_id=3&reason=test", ["member", "ward_officer"]),
    ("PATCH",  "/sessions/1/close",                          ["member", "ward_officer"]),
    ("DELETE", "/sessions/1",                                ["member", "ward_officer"]),
    ("POST",   "/members",                                   ["member", "ward_officer"]),
    ("PATCH",  "/members/3",                                 ["member", "ward_officer"]),
    ("DELETE", "/members/46",                                ["member", "ward_officer"]),
    ("GET",    "/members",                                   ["member"]),
    ("POST",   "/requests",                                  ["secretary", "ward_officer"]),
    ("POST",   "/requests/1/decide",                         ["member", "ward_officer"]),
    ("GET",    "/ward/dashboard",                            ["member", "secretary"]),
    ("POST",   "/ward/branches/2/approve",                   ["member", "secretary"]),
    ("POST",   "/ward/branches/2/remind",                    ["member", "secretary"]),
    ("GET",    "/ward/report/export",                        ["member", "secretary"]),
    ("POST",   "/ward/reports",                              ["member", "ward_officer"]),
    ("POST",   "/ward/activities",                           ["member", "secretary"]),
    ("POST",   "/rewards/activities/1/register",             ["secretary", "ward_officer"]),
    ("POST",   "/rewards/vouchers/2/redeem",                 ["secretary", "ward_officer"]),
    ("POST",   "/social/posts/2/pin",                        ["member"]),
    ("DELETE", "/social/posts/3",                            ["member"]),
]

# Vai trò được PHÉP gọi (chỉ assert không 401/403)
ALLOWED = [
    ("POST",  "/sessions",                    "secretary"),
    ("POST",  "/sessions/1/qr",               "secretary"),
    ("POST",  "/sessions/1/manual?member_id=3&reason=test", "secretary"),
    ("POST",  "/members",                     "secretary"),
    ("GET",   "/members",                     "secretary"),
    ("GET",   "/members",                     "ward_officer"),
    ("POST",  "/requests",                    "member"),
    ("POST",  "/requests/1/decide",           "secretary"),
    ("GET",   "/ward/dashboard",              "ward_officer"),
    ("POST",  "/ward/branches/2/approve",     "ward_officer"),
    ("POST",  "/ward/branches/2/remind",      "ward_officer"),
    ("GET",   "/ward/report/export",          "ward_officer"),
    ("POST",  "/ward/reports",                "secretary"),
    ("POST",  "/ward/activities",             "ward_officer"),
    ("GET",   "/ward/activities",             "member"),
    ("GET",   "/ward/activities",             "secretary"),
    ("GET",   "/ward/activities",             "ward_officer"),
    ("POST",  "/rewards/activities/1/register", "member"),
    ("POST",  "/rewards/vouchers/2/redeem",   "member"),
    ("GET",   "/rewards/vouchers",            "member"),
    ("GET",   "/rewards/vouchers",            "secretary"),
    ("GET",   "/rewards/vouchers",            "ward_officer"),
    ("GET",   "/rewards/ranking",             "member"),
    ("POST",  "/social/posts",                "member"),
    ("POST",  "/social/posts",                "secretary"),
    ("POST",  "/social/posts",                "ward_officer"),
    ("POST",  "/social/posts/2/comment",      "member"),
    ("POST",  "/social/posts/2/pin",          "secretary"),
    ("POST",  "/social/posts/2/pin",          "ward_officer"),
    ("DELETE", "/social/posts/3",             "secretary"),
    ("DELETE", "/social/posts/3",             "ward_officer"),
    ("GET",   "/sessions",                    "member"),
    ("GET",   "/sessions",                    "secretary"),
    ("GET",   "/requests",                    "member"),
    ("GET",   "/requests",                    "secretary"),
]

BODY = {
    "POST /sessions": {"title": "Sinh hoạt test", "starts_at": "2026-12-20T20:00:00"},
    "POST /sessions/1/qr": {},
    "POST /sessions/1/manual?member_id=3&reason=test": {},
    "PATCH /sessions/1/close": {},
    "POST /members": {"name": "Test RBAC", "phone": "0900000001"},
    "PATCH /members/3": {"name": "Test Patch"},
    "POST /requests": {"session_title": "SH tháng 12", "reason": "Trực ca"},
    "POST /requests/1/decide": {"action": "approve"},
    "POST /ward/branches/2/approve": {},
    "POST /ward/branches/2/remind": {},
    "POST /ward/reports": {},
    "POST /ward/activities": {"title": "Hoạt động test", "starts_at": "2026-12-25T08:00:00"},
    "POST /rewards/activities/1/register": {},
    "POST /rewards/vouchers/2/redeem": {},
    "POST /social/posts": {"content": "Bài test"},
    "POST /social/posts/2/comment": {"content": "Bình luận test"},
    "POST /social/posts/2/pin": {},
}


@pytest.mark.parametrize("method,path,roles", BLOCKED)
def test_rbac_chan_dung_chieu(method, path, roles, client):
    for role in roles:
        r = client.request(method, path, headers=auth_headers(client, role), json=BODY.get(f"{method} {path}"))
        assert r.status_code == 403, f"{method} {path} với {role} — kỳ vọng 403, nhận {r.status_code}: {r.text}"
        assert "không có quyền" in r.json()["detail"] or "Chỉ" in r.json()["detail"]


@pytest.mark.parametrize("method,path,role", ALLOWED)
def test_rbac_cho_phep(method, path, role, client):
    r = client.request(method, path, headers=auth_headers(client, role), json=BODY.get(f"{method} {path}"))
    assert r.status_code not in (401, 403), f"{method} {path} với {role} bị chặn oan: {r.text}"


def test_rbac_chua_dang_nhap_bi_chan(client):
    for method, path in [("GET", "/members"), ("POST", "/sessions"), ("GET", "/ward/dashboard")]:
        r = client.request(method, path, json={})
        assert r.status_code == 401, f"{method} {path} không token phải 401"
