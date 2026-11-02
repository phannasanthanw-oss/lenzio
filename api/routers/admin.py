"""Lenzio back-office: show / insert / update / delete rows of every table.

Page:      http://localhost:8000/admin
JSON API:  http://localhost:8000/admin/api/...
"""
import os
from typing import Any, Dict, Optional

import psycopg
from fastapi import APIRouter, HTTPException, Query
from fastapi.responses import FileResponse
from pydantic import BaseModel

from core.database import db

TABLES = ("camera", "lens", "users", "recipe", "review", "camera_lens", "favorite")
ADMIN_HTML_PATH = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "..", "admin.html"))

# rows that depend on a row, deleted first when the user chooses "delete with related data"
CASCADE = {
    "camera": [
        "DELETE FROM review WHERE recipe_id IN (SELECT recipe_id FROM recipe WHERE camera_id=%(id)s)",
        "DELETE FROM review WHERE camera_id=%(id)s",
        "DELETE FROM recipe WHERE camera_id=%(id)s",
        "DELETE FROM favorite WHERE camera_id=%(id)s",
        "DELETE FROM camera_lens WHERE camera_id=%(id)s",
    ],
    "lens": [
        "DELETE FROM review WHERE recipe_id IN (SELECT recipe_id FROM recipe WHERE lens_id=%(id)s)",
        "DELETE FROM review WHERE lens_id=%(id)s",
        "DELETE FROM recipe WHERE lens_id=%(id)s",
        "DELETE FROM camera_lens WHERE lens_id=%(id)s",
    ],
    "recipe": ["DELETE FROM review WHERE recipe_id=%(id)s"],
    "users": ["DELETE FROM review WHERE user_id=%(id)s", "DELETE FROM favorite WHERE user_id=%(id)s"],
}


class RowIn(BaseModel):
    data: Dict[str, Any] = {}


class RowPk(BaseModel):
    pk: Dict[str, Any]


class RowUpdate(BaseModel):
    pk: Dict[str, Any]
    data: Dict[str, Any] = {}


def ident(name: str) -> str:
    """Quote an identifier (only ever called with names that exist in the catalog)."""
    return '"' + name.replace('"', '""') + '"'


def fail(e: psycopg.Error):
    """Turn a database error into a readable HTTP error."""
    msg = (e.diag.message_primary if e.diag and e.diag.message_primary else str(e)).strip()
    detail = (e.diag.message_detail or "").strip() if e.diag else ""
    text = msg + (f" — {detail}" if detail else "")
    if isinstance(e, psycopg.errors.ForeignKeyViolation):
        raise HTTPException(409, "ติดความสัมพันธ์ระหว่างตาราง (foreign key): " + text)
    if isinstance(e, psycopg.errors.UniqueViolation):
        raise HTTPException(409, "ข้อมูลซ้ำ (ห้ามซ้ำ): " + text)
    if isinstance(e, (psycopg.errors.CheckViolation, psycopg.errors.NotNullViolation)):
        raise HTTPException(422, "ข้อมูลไม่ผ่านเงื่อนไขของตาราง: " + text)
    raise HTTPException(400, "บันทึกไม่ได้: " + text)


def table_info(cur, table: str):
    if table not in TABLES:
        raise HTTPException(404, "ไม่มีตารางนี้")
    cur.execute(
        "SELECT a.attname AS name FROM pg_index i "
        "JOIN pg_attribute a ON a.attrelid=i.indrelid AND a.attnum=ANY(i.indkey) "
        "WHERE i.indrelid=to_regclass(%s) AND i.indisprimary ORDER BY a.attnum",
        ("public." + table,),
    )
    pk = [r["name"] for r in cur.fetchall()]
    cur.execute(
        "SELECT column_name, data_type, is_nullable, is_identity, column_default "
        "FROM information_schema.columns WHERE table_schema='public' AND table_name=%s "
        "ORDER BY ordinal_position",
        (table,),
    )
    cols = [
        {
            "name": r["column_name"],
            "type": r["data_type"],
            "nullable": r["is_nullable"] == "YES",
            "identity": r["is_identity"] == "YES",
            "has_default": r["column_default"] is not None or r["is_identity"] == "YES",
            "pk": r["column_name"] in pk,
        }
        for r in cur.fetchall()
    ]
    if not cols:
        raise HTTPException(404, "ไม่พบตารางในฐานข้อมูล (ลองรัน schema_pg.sql ก่อน)")
    return cols, pk


def where_pk(pk, values):
    if set(values) != set(pk):
        raise HTTPException(422, "ต้องระบุ primary key ให้ครบ: " + ", ".join(pk))
    return " AND ".join(f"{ident(c)}=%s" for c in pk), [values[c] for c in pk]


def resync(cur, table, row):
    """camera_lens is derived data: a camera fits a lens when brand and mount match."""
    if table == "camera":
        cur.execute("DELETE FROM camera_lens WHERE camera_id=%s", (row["camera_id"],))
        cur.execute(
            "INSERT INTO camera_lens (camera_id, lens_id) SELECT c.camera_id, l.lens_id "
            "FROM camera c JOIN lens l ON c.mount=l.mount AND c.brand=l.brand "
            "WHERE c.camera_id=%s",
            (row["camera_id"],),
        )
    elif table == "lens":
        cur.execute("DELETE FROM camera_lens WHERE lens_id=%s", (row["lens_id"],))
        cur.execute(
            "INSERT INTO camera_lens (camera_id, lens_id) SELECT c.camera_id, l.lens_id "
            "FROM camera c JOIN lens l ON c.mount=l.mount AND c.brand=l.brand "
            "WHERE l.lens_id=%s",
            (row["lens_id"],),
        )


router = APIRouter(prefix="/admin", tags=["Back-office"])


@router.get("", include_in_schema=False)
@router.get("/", include_in_schema=False)
def page():
    return FileResponse(ADMIN_HTML_PATH, media_type="text/html")


@router.get("/api/schema", summary="Tables, columns, primary keys and row counts")
def schema():
    out = []
    try:
        with db() as cur:
            for t in TABLES:
                cols, pk = table_info(cur, t)
                cur.execute(f"SELECT COUNT(*) AS n FROM {ident(t)}")
                out.append({"name": t, "pk": pk, "columns": cols, "count": cur.fetchone()["n"]})
    except psycopg.Error as e:
        fail(e)
    return {"tables": out}


@router.get("/api/{table}", summary="Show rows (search + paging)")
def list_rows(
    table: str,
    q: Optional[str] = None,
    limit: int = Query(20, ge=1, le=500),
    offset: int = Query(0, ge=0),
):
    try:
        with db() as cur:
            cols, pk = table_info(cur, table)
            t = ident(table)
            where, args = "", []
            if q:
                where, args = f" WHERE {t}::text ILIKE %s", [f"%{q}%"]
            cur.execute(f"SELECT COUNT(*) AS n FROM {t}{where}", args)
            total = cur.fetchone()["n"]
            order = ", ".join(ident(c) for c in (pk or [cols[0]["name"]]))
            cur.execute(f"SELECT * FROM {t}{where} ORDER BY {order} LIMIT %s OFFSET %s", args + [limit, offset])
            rows = cur.fetchall()
    except psycopg.Error as e:
        fail(e)
    return {"total": total, "rows": rows}


@router.post("/api/{table}", status_code=201, summary="Insert a row")
def insert_row(table: str, body: RowIn):
    try:
        with db() as cur:
            cols, pk = table_info(cur, table)
            names = {c["name"]: c for c in cols}
            data = {}
            for k, v in body.data.items():
                if k not in names:
                    raise HTTPException(422, f"ไม่มีคอลัมน์ {k}")
                if names[k]["identity"] or v is None or v == "":
                    continue  # identity ids and empty boxes are filled in by the database
                data[k] = v
            t = ident(table)
            if data:
                cur.execute(
                    f"INSERT INTO {t} ({', '.join(ident(k) for k in data)}) "
                    f"VALUES ({', '.join(['%s'] * len(data))}) RETURNING *",
                    list(data.values()),
                )
            else:
                cur.execute(f"INSERT INTO {t} DEFAULT VALUES RETURNING *")
            row = cur.fetchone()
            resync(cur, table, row)
    except psycopg.Error as e:
        fail(e)
    return row


@router.put("/api/{table}", summary="Update a row")
def update_row(table: str, body: RowUpdate):
    try:
        with db() as cur:
            cols, pk = table_info(cur, table)
            names = {c["name"]: c for c in cols}
            where, wargs = where_pk(pk, body.pk)
            data = {}
            for k, v in body.data.items():
                if k not in names:
                    raise HTTPException(422, f"ไม่มีคอลัมน์ {k}")
                if names[k]["identity"] or k in pk:
                    continue  # primary keys are not edited
                if v == "":
                    if not names[k]["nullable"]:
                        continue
                    v = None
                data[k] = v
            if not data:
                raise HTTPException(422, "ไม่มีข้อมูลให้แก้ไข")
            cur.execute(
                f"UPDATE {ident(table)} SET {', '.join(ident(k) + '=%s' for k in data)} "
                f"WHERE {where} RETURNING *",
                list(data.values()) + wargs,
            )
            row = cur.fetchone()
            if not row:
                raise HTTPException(404, "ไม่พบแถวนี้")
            resync(cur, table, row)
    except psycopg.Error as e:
        fail(e)
    return row


@router.delete("/api/{table}", summary="Delete a row (cascade=true also deletes the rows that depend on it)")
def delete_row(table: str, body: RowPk, cascade: bool = False):
    try:
        with db() as cur:
            cols, pk = table_info(cur, table)
            where, wargs = where_pk(pk, body.pk)
            if cascade and table in CASCADE:
                for sql in CASCADE[table]:
                    cur.execute(sql, {"id": wargs[0]})
            cur.execute(f"DELETE FROM {ident(table)} WHERE {where}", wargs)
            if cur.rowcount == 0:
                raise HTTPException(404, "ไม่พบแถวนี้")
    except psycopg.Error as e:
        fail(e)
    return {"deleted": body.pk}

