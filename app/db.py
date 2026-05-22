import os
from contextlib import contextmanager
from urllib.parse import quote_plus

from psycopg2 import pool
from psycopg2.extras import RealDictCursor

_pool = None


def is_configured() -> bool:
    if os.getenv("DATABASE_URL"):
        return True
    return bool(os.getenv("DB_HOST"))


def _connection_string() -> str:
    url = os.getenv("DATABASE_URL")
    if url:
        return url

    host = os.getenv("DB_HOST", "localhost")
    port = os.getenv("DB_PORT", "5432")
    name = os.getenv("DB_NAME", "todos")
    user = os.getenv("DB_USER", "todos")
    password = os.getenv("DB_PASSWORD", "")
    sslmode = os.getenv("DB_SSLMODE", "prefer")

    return (
        f"postgresql://{quote_plus(user)}:{quote_plus(password)}"
        f"@{host}:{port}/{name}?sslmode={sslmode}"
    )


def init_pool() -> None:
    global _pool
    if _pool is not None or not is_configured():
        return
    _pool = pool.ThreadedConnectionPool(
        minconn=1,
        maxconn=int(os.getenv("DB_POOL_SIZE", "5")),
        dsn=_connection_string(),
    )


def close_pool() -> None:
    global _pool
    if _pool is not None:
        _pool.closeall()
        _pool = None


@contextmanager
def connection():
    if _pool is None:
        raise RuntimeError("Database pool is not initialized")
    conn = _pool.getconn()
    try:
        yield conn
        conn.commit()
    except Exception:
        conn.rollback()
        raise
    finally:
        _pool.putconn(conn)


def ping() -> dict:
    if not is_configured():
        return {"configured": False, "connected": False, "error": "not configured"}
    try:
        with connection() as conn:
            with conn.cursor() as cur:
                cur.execute("SELECT 1")
                cur.fetchone()
        return {"configured": True, "connected": True, "error": None}
    except Exception as exc:
        return {"configured": True, "connected": False, "error": str(exc)}


def init_schema() -> None:
    with connection() as conn:
        with conn.cursor() as cur:
            cur.execute(
                """
                CREATE TABLE IF NOT EXISTS todos (
                    id SERIAL PRIMARY KEY,
                    task TEXT NOT NULL,
                    done BOOLEAN NOT NULL DEFAULT FALSE,
                    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
                )
                """
            )


def seed_defaults() -> None:
    with connection() as conn:
        with conn.cursor() as cur:
            cur.execute("SELECT COUNT(*) FROM todos")
            if cur.fetchone()[0] > 0:
                return
            cur.executemany(
                "INSERT INTO todos (task, done) VALUES (%s, %s)",
                [
                    ("Provision app VM", False),
                    ("Connect to DB VM", False),
                ],
            )


def list_todos() -> list[dict]:
    with connection() as conn:
        with conn.cursor(cursor_factory=RealDictCursor) as cur:
            cur.execute("SELECT id, task, done FROM todos ORDER BY id ASC")
            return [dict(row) for row in cur.fetchall()]


def add_todo(task: str) -> None:
    with connection() as conn:
        with conn.cursor() as cur:
            cur.execute(
                "INSERT INTO todos (task, done) VALUES (%s, FALSE)",
                (task,),
            )


def toggle_todo(todo_id: int) -> bool:
    with connection() as conn:
        with conn.cursor() as cur:
            cur.execute(
                "UPDATE todos SET done = NOT done WHERE id = %s RETURNING id",
                (todo_id,),
            )
            return cur.fetchone() is not None


def delete_todo(todo_id: int) -> bool:
    with connection() as conn:
        with conn.cursor() as cur:
            cur.execute("DELETE FROM todos WHERE id = %s RETURNING id", (todo_id,))
            return cur.fetchone() is not None
