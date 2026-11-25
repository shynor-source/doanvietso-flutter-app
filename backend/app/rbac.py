"""RBAC — ma trận phân quyền Vòng 2, đồng bộ 1:1 với app Flutter (app_state.dart).

Mỗi vai trò CHỈ được thực thi đúng nhóm chức năng của mình:
  member        : quét QR, đăng ký hoạt động, gửi đơn bù, đổi voucher
  secretary     : quản lý buổi sinh hoạt, phát QR, CRUD hồ sơ, duyệt đơn, nộp báo cáo
  ward_officer  : phát động toàn phường, duyệt chi đoàn, khen thưởng, xuất báo cáo
"""
from fastapi import HTTPException, status

ROLES = ("member", "secretary", "ward_officer")

# role -> tập quyền
PERMISSIONS: dict[str, set[str]] = {
    "member": {
        "session:checkin",
        "activity:register",
        "request:create",
        "voucher:redeem",
        "post:create",
        "post:comment",
    },
    "secretary": {
        "session:create", "session:update", "session:delete", "session:close",
        "qr:issue",
        "member:create", "member:update", "member:delete", "member:import",
        "request:decide",
        "report:submit",
        "post:create", "post:comment", "post:moderate",
    },
    "ward_officer": {
        "activity:launch",
        "report:approve",
        "report:export",
        "reward:grant",
        "post:create", "post:comment", "post:moderate",
        "branch:view",
    },
}


def can(role: str, permission: str) -> bool:
    return permission in PERMISSIONS.get(role, set())


def ensure(role: str, permission: str) -> None:
    if not can(role, permission):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail=f"Vai trò '{role}' không có quyền '{permission}'.",
        )
