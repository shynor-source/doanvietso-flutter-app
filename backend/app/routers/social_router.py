"""Bảng tin: mọi vai trò đăng bài/bình luận — chỉ cán bộ được ghim/xóa (moderate)."""
from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel
from sqlmodel import Session as DBSession, select

from ..auth import get_current_user, require_permission
from ..database import get_session
from ..models import AuditLog, Comment, Post, User, utcnow

router = APIRouter(prefix="/social", tags=["social"])


class PostIn(BaseModel):
    content: str
    is_event: bool = False


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
        out.append({"id": p.id, "author_id": p.author_id, "author_name": author.full_name if author else "Ẩn danh",
                    "role": author.role if author else "member", "content": p.content, "is_event": p.is_event,
                    "is_pinned": p.is_pinned, "created_at": p.created_at, "comments": len(comments)})
    return out


@router.post("/posts", summary="Đăng bài (mọi vai trò)")
def create_post(body: PostIn, user: User = Depends(get_current_user), db: DBSession = Depends(get_session)):
    p = Post(author_id=user.id or 0, content=body.content, is_event=body.is_event)
    db.add(p)
    db.commit()
    db.refresh(p)
    return {"ok": True, "id": p.id}


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
