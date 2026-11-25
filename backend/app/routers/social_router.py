"""Bảng tin: mọi vai trò đăng bài/bình luận — chỉ cán bộ được ghim/xóa (moderate).

Ảnh đính kèm bài đăng: app gửi base64 trong JSON (không cần multipart), server lưu
trong DB (bền qua restart trên Render free) và phục vụ lại qua GET /social/posts/{id}/image.
"""
import base64

from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.responses import Response
from pydantic import BaseModel
from sqlmodel import Session as DBSession, select

from ..auth import get_current_user, require_permission
from ..database import get_session
from ..models import Activity, AuditLog, Comment, Post, User, utcnow

router = APIRouter(prefix="/social", tags=["social"])

MAX_IMAGE_B64 = 4_000_000  # ~3MB ảnh gốc sau base64 — chặn upload khổng lồ


class PostIn(BaseModel):
    content: str
    is_event: bool = False
    activity_id: int | None = None
    image: str | None = None  # base64 (không kèm tiền tố data:)
    mime: str | None = "image/jpeg"


class CommentIn(BaseModel):
    content: str


@router.get("/posts", summary="Bảng tin (bài ghim luôn lên đầu)")
def list_posts(db: DBSession = Depends(get_session)):
    posts = db.exec(select(Post).order_by(Post.created_at.desc())).all()
    posts.sort(key=lambda p: not p.is_pinned)
    out = []
    for p in posts:
        comments = db.exec(select(Comment).where(Comment.post_id == p.id)).all()
        author = db.get(User, p.author_id)
        activity = db.get(Activity, p.activity_id) if p.activity_id else None
        out.append({"id": p.id, "author_id": p.author_id, "author_name": author.full_name if author else "Ẩn danh",
                    "role": author.role if author else "member", "content": p.content, "is_event": p.is_event,
                    "is_pinned": p.is_pinned, "created_at": p.created_at, "comments": len(comments),
                    "activity_id": p.activity_id, "has_image": p.image_data is not None,
                    "activity": ({"id": activity.id, "title": activity.title, "category": activity.category,
                                  "starts_at": activity.starts_at, "location": activity.location,
                                  "points": activity.points, "organizer": activity.organizer} if activity else None)})
    return out


@router.post("/posts", summary="Đăng bài (mọi vai trò)")
def create_post(body: PostIn, user: User = Depends(get_current_user), db: DBSession = Depends(get_session)):
    image_data = image_mime = None
    if body.image:
        if len(body.image) > MAX_IMAGE_B64:
            raise HTTPException(status.HTTP_413_REQUEST_ENTITY_TOO_LARGE, "Ảnh quá lớn (tối đa ~3MB). Hãy chọn ảnh gọn hơn.")
        try:
            base64.b64decode(body.image, validate=True)  # kiểm tra base64 hợp lệ
        except Exception:
            raise HTTPException(status.HTTP_400_BAD_REQUEST, "Dữ liệu ảnh không hợp lệ.")
        image_data, image_mime = body.image, (body.mime or "image/jpeg")
    p = Post(author_id=user.id or 0, content=body.content, is_event=body.is_event, activity_id=body.activity_id,
             image_data=image_data, image_mime=image_mime)
    db.add(p)
    db.commit()
    db.refresh(p)
    db.add(AuditLog(actor=user.full_name, action="Đăng bài lên Bảng tin" + (" (kèm ảnh)" if image_data else "")))
    db.commit()
    return {"ok": True, "id": p.id, "has_image": image_data is not None}


@router.get("/posts/{post_id}/image", summary="Ảnh đính kèm của bài đăng (công khai, trả bytes ảnh)")
def get_post_image(post_id: int, db: DBSession = Depends(get_session)):
    p = db.get(Post, post_id)
    if p is None or not p.image_data:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Bài viết không có ảnh.")
    try:
        raw = base64.b64decode(p.image_data)
    except Exception:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Ảnh bị hỏng.")
    return Response(content=raw, media_type=p.image_mime or "image/jpeg",
                    headers={"Cache-Control": "public, max-age=86400"})


@router.post("/posts/{post_id}/comment", summary="Bình luận (mọi vai trò)")
def comment(post_id: int, body: CommentIn, user: User = Depends(get_current_user), db: DBSession = Depends(get_session)):
    if db.get(Post, post_id) is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Bài viết không tồn tại.")
    c = Comment(post_id=post_id, author_id=user.id or 0, content=body.content)
    db.add(c)
    db.commit()
    return {"ok": True}


@router.post("/posts/{post_id}/pin", summary="Ghim / bỏ ghim bài (cán bộ)",
             dependencies=[Depends(require_permission("post:moderate"))])
def pin_post(post_id: int, user: User = Depends(get_current_user), db: DBSession = Depends(get_session)):
    p = db.get(Post, post_id)
    if p is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Bài viết không tồn tại.")
    p.is_pinned = not p.is_pinned
    db.add(p)
    db.add(AuditLog(actor=user.full_name, action=f'{"Ghim" if p.is_pinned else "Bỏ ghim"} bài "{p.content[:30]}…"'))
    db.commit()
    return {"ok": True, "is_pinned": p.is_pinned}


@router.delete("/posts/{post_id}", summary="Xóa bài vi phạm (cán bộ)",
               dependencies=[Depends(require_permission("post:moderate"))])
def delete_post(post_id: int, user: User = Depends(get_current_user), db: DBSession = Depends(get_session)):
    p = db.get(Post, post_id)
    if p is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Bài viết không tồn tại.")
    for c in db.exec(select(Comment).where(Comment.post_id == post_id)).all():
        db.delete(c)
    db.delete(p)
    db.add(AuditLog(actor=user.full_name, action="Xóa một bài viết vi phạm trên Bảng tin"))
    db.commit()
    return {"ok": True}
