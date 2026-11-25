"""Kết nối CSDL (SQLite cho MVP, đổi DATABASE_URL để dùng PostgreSQL)."""
import os

from sqlmodel import Session, SQLModel, create_engine

DATABASE_URL = os.environ.get("DATABASE_URL", "sqlite:///./doanvien.db")

# Chuẩn hóa scheme: Aiven/Heroku cấp "postgres://" — SQLAlchemy cần "postgresql://"
if DATABASE_URL.startswith("postgres://"):
    DATABASE_URL = "postgresql://" + DATABASE_URL[len("postgres://") :]

engine = create_engine(
    DATABASE_URL,
    connect_args={"check_same_thread": False} if DATABASE_URL.startswith("sqlite") else {},
)


def fix_postgres_sequences():
    """Sau khi seed chèn bản ghi với id tường minh, sequence tự tăng của PostgreSQL
    không được đẩy lên → insert mới sẽ trùng khóa. Căn chỉnh lại toàn bộ."""
    from sqlalchemy import text
    if engine.dialect.name != "postgresql":
        return
    with engine.begin() as conn:
        for table in SQLModel.metadata.tables.values():
            cols = [c.name for c in table.primary_key.columns]
            if cols != ["id"]:
                continue
            name = f'"{table.name}"'
            conn.execute(text(
                "SELECT setval(pg_get_serial_sequence(:t, 'id'), "
                f"COALESCE((SELECT MAX(id) FROM {name}), 0) + 1, false)"
            ), {"t": name})


def get_session():
    with Session(engine) as session:
        yield session


def init_db():
    SQLModel.metadata.create_all(engine)
