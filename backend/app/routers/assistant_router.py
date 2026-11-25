"""Trợ lý ảo AI — hướng dẫn sử dụng chức năng của app, kèm shortcut điều hướng.

Người dùng hỏi (bằng tiếng Việt), server:
1. Lọc cơ sở tri thức (assistant_kb.py) CHỈ lấy chức năng vai trò đang hỏi có quyền —
   AI không được "chỉ đường" tới chức năng vượt quyền (tầng RBAC thứ 4).
2. Gọi Gemini (structured output) để chọn chức năng khớp câu hỏi, trả JSON
   {nav, answer, steps} — app vẽ câu trả lời + nút "Đi tới màn hình".
3. AI lỗi / hết quota / chưa cấu hình key → fallback tra từ khóa cục bộ,
   chatbot vẫn dùng được offline.
"""
import json
import os

import httpx
from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel

from ..assistant_kb import NAV_LABELS, fallback_answer, kb_for_role
from ..auth import get_current_user
from ..database import get_session
from ..models import User

router = APIRouter(prefix="/assistant", tags=["assistant"])

GEMINI_URL = "https://generativelanguage.googleapis.com/v1beta/models/{model}:generateContent"
GEMINI_MODELS = ["gemini-3.5-flash-lite", "gemini-flash-lite-latest", "gemini-2.5-flash-lite"]
GEMINI_TIMEOUT = 20.0

# Mọi key điều hướng hợp lệ app đã khai báo (app_shell.dart) — chặn AI trả mớ lạ
VALID_NAVS = sorted(NAV_LABELS.keys())

RESPONSE_SCHEMA = {
    "type": "OBJECT",
    "properties": {
        "nav": {"type": "STRING", "enum": VALID_NAVS + ["none"],
                "description": "Màn hình đích duy nhất khớp câu hỏi; 'none' nếu không xác định."},
        "answer": {"type": "STRING", "description": "Trả lời ngắn (1–2 câu, tiếng Việt), giải thích chức năng."},
        "steps": {"type": "ARRAY", "items": {"type": "STRING"},
                  "description": "Các bước thực hiện ngắn gọn, đánh số theo thứ tự."},
    },
    "required": ["nav", "answer", "steps"],
}


class AskIn(BaseModel):
    question: str


def _build_prompt(question: str, role: str, kb: list[dict]) -> list[dict]:
    kb_brief = [
        {"chuc_nang": e["title"], "man_hinh": e["nav"], "tom_tat": e["summary"], "cac_buoc": e["steps"]}
        for e in kb
    ]
    role_names = {
        "member": "Đoàn viên (công nhân KCN làm ca)",
        "secretary": "Bí thư chi đoàn khu phố (kiêm nhiệm)",
        "ward_officer": "Cán bộ Đoàn phường",
    }
    system = (
        "Bạn là Trợ lý ảo của app 'Đoàn Viên Số' — Phường Trấn Biên, thành phố Đồng Nai. "
        f"Người hỏi có vai trò: {role_names.get(role, role)} — chỉ được hướng dẫn các chức năng trong danh sách dưới đây. "
        "Nếu câu hỏi thuộc chức năng của vai trò khác, trả lời 'none' và giải thích chức năng đó thuộc vai trò khác. "
        "Luôn trả lời bằng tiếng Việt, ngắn gọn, đúng theo cac_buoc trong danh sách. "
        "Danh sách chức năng bạn được phép hướng dẫn:\n" + json.dumps(kb_brief, ensure_ascii=False)
    )
    return [
        {"role": "user", "parts": [{"text": system + "\n\nCâu hỏi: " + question}]},
    ]


def _ask_gemini(question: str, role: str) -> dict | None:
    key = os.environ.get("GEMINI_API_KEY")
    if not key:
        return None
    payload = {
        "contents": _build_prompt(question, role, kb_for_role(role)),
        "generationConfig": {
            "response_mime_type": "application/json",
            "response_schema": RESPONSE_SCHEMA,
            "temperature": 0.2,
        },
    }
    for model in GEMINI_MODELS:
        try:
            r = httpx.post(GEMINI_URL.format(model=model), params={"key": key},
                           json=payload, timeout=GEMINI_TIMEOUT)
            if r.status_code == 404:
                continue  # model không tồn tại → thử model dự phòng
            r.raise_for_status()
            data = r.json()
            text = data["candidates"][0]["content"]["parts"][0]["text"]
            out = json.loads(text)
            nav = out.get("nav") or "none"
            if nav not in VALID_NAVS:
                nav = "none"
            return {
                "answer": out.get("answer", ""),
                "steps": [s for s in out.get("steps", []) if isinstance(s, str)],
                "nav": None if nav == "none" else nav,
                "nav_label": NAV_LABELS.get(nav) if nav != "none" else None,
                "source": "gemini",
            }
        except Exception:
            continue
    return None


@router.post("/ask", summary="Hỏi trợ lý AI: hướng dẫn chức năng + shortcut điều hướng")
def ask(body: AskIn, user: User = Depends(get_current_user), db=Depends(get_session)):
    q = body.question.strip()
    if not q:
        raise HTTPException(status.HTTP_400_BAD_REQUEST, "Câu hỏi trống")
    if len(q) > 500:
        raise HTTPException(status.HTTP_400_BAD_REQUEST, "Câu hỏi quá dài (tối đa 500 ký tự)")

    result = _ask_gemini(q, user.role)
    if result is None:
        result = fallback_answer(q, user.role)
    return {"role": user.role, **result}
