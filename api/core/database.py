"""Connection pool และ context manager สำหรับเชื่อมต่อฐานข้อมูล PostgreSQL"""
from contextlib import asynccontextmanager, contextmanager

from psycopg.rows import dict_row
# pyrefly: ignore[missing-import]
from psycopg_pool import ConnectionPool

from core.config import DB

# เปิด connection pool ไว้ล่วงหน้า (1-5 connections) เพื่อลดเวลาในการต่อฐานข้อมูลแต่ละครั้ง
pool = ConnectionPool(conninfo="", kwargs={**DB, "row_factory": dict_row}, min_size=1, max_size=5, open=False)


@asynccontextmanager
async def lifespan(app):
    """เปิด pool เมื่อ app เริ่ม และปิดเมื่อ app หยุด"""
    pool.open()
    yield
    pool.close()


@contextmanager
def db():
    """Yield cursor พร้อม commit อัตโนมัติ หรือ rollback เมื่อเกิด error"""
    with pool.connection() as conn:
        with conn.cursor() as cur:
            yield cur

