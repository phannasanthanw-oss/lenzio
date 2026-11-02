"""Router: Cameras — ดู, เพิ่ม, แก้ไข และลบกล้อง"""
from typing import Optional

import psycopg
from fastapi import APIRouter, HTTPException, Query

from core.database import db
from core.helpers import check_brand, sync_camera_lens
from schemas.models import CameraIn

router = APIRouter(prefix="/cameras", tags=["Cameras"])


@router.get("", summary="List cameras with rating (filter by brand, search by name)")
def list_cameras(
    brand: Optional[str] = None,
    q: Optional[str] = None,
    sort: str = Query("popular", pattern="^(popular|name|price|year)$"),
    limit: int = Query(100, ge=1, le=200),
    offset: int = Query(0, ge=0),
):
    order = {
        "popular": "review_count DESC, avg_rating DESC NULLS LAST, c.model_name",
        "name": "c.model_name",
        "price": "c.price_thb DESC",
        "year": "c.release_year DESC",
    }[sort]
    sql = (
        "SELECT c.*, ROUND(AVG(r.rating),1) AS avg_rating, COUNT(r.review_id) AS review_count "
        "FROM Camera c LEFT JOIN Review r ON r.camera_id=c.camera_id WHERE 1=1"
    )
    args = []
    if brand:
        sql += " AND c.brand=%s"
        args.append(brand)
    if q:
        sql += " AND c.model_name ILIKE %s"
        args.append(f"%{q}%")
    sql += f" GROUP BY c.camera_id ORDER BY {order} LIMIT %s OFFSET %s"
    with db() as cur:
        cur.execute(sql, args + [limit, offset])
        return cur.fetchall()


@router.get("/{camera_id}", summary="Camera detail with compatible lenses and reviews")
def get_camera(camera_id: int, user_id: Optional[int] = None):
    with db() as cur:
        cur.execute("SELECT * FROM Camera WHERE camera_id=%s", (camera_id,))
        cam = cur.fetchone()
        if not cam:
            raise HTTPException(404, "camera not found")

        cur.execute(
            "SELECT ROUND(AVG(rating),1) AS avg_rating, COUNT(*) AS review_count "
            "FROM Review WHERE camera_id=%s",
            (camera_id,),
        )
        cam.update(cur.fetchone())

        cur.execute(
            "SELECT l.lens_id, l.lens_name, l.brand, l.focal_min_mm, l.focal_max_mm, "
            "l.max_aperture, l.price_thb, l.image_url "
            "FROM Lens l JOIN Camera_Lens cl ON cl.lens_id=l.lens_id "
            "WHERE cl.camera_id=%s ORDER BY l.lens_name",
            (camera_id,),
        )
        cam["compatible_lenses"] = cur.fetchall()

        cam["is_favorite"] = False
        if user_id is not None:
            cur.execute("SELECT 1 FROM Favorite WHERE user_id=%s AND camera_id=%s", (user_id, camera_id))
            cam["is_favorite"] = cur.fetchone() is not None

        cur.execute(
            "SELECT r.review_id, u.display_name, r.rating, r.comment, r.like_count, r.created_at "
            "FROM Review r JOIN Users u ON u.user_id=r.user_id "
            "WHERE r.camera_id=%s ORDER BY r.created_at DESC LIMIT 20",
            (camera_id,),
        )
        cam["reviews"] = cur.fetchall()

    return cam


@router.get("/{camera_id}/lenses", summary="Lenses that fit this camera")
def camera_lenses(camera_id: int):
    with db() as cur:
        cur.execute(
            "SELECT l.* FROM Lens l JOIN Camera_Lens cl ON cl.lens_id=l.lens_id "
            "WHERE cl.camera_id=%s ORDER BY l.lens_name",
            (camera_id,),
        )
        return cur.fetchall()


@router.post("", status_code=201, summary="Add a camera")
def create_camera(body: CameraIn):
    check_brand(body.brand)
    data = body.model_dump()
    cols = ",".join(data)
    with db() as cur:
        try:
            cur.execute(
                f"INSERT INTO Camera ({cols}) VALUES ({','.join(['%s'] * len(data))}) RETURNING camera_id",
                list(data.values()),
            )
        except psycopg.errors.UniqueViolation:
            raise HTTPException(409, "model_name already exists")
        cid = cur.fetchone()["camera_id"]
        sync_camera_lens(cur, cid)
    return {"camera_id": cid, **data}


@router.put("/{camera_id}", summary="Update a camera")
def update_camera(camera_id: int, body: CameraIn):
    check_brand(body.brand)
    data = body.model_dump()
    sets = ",".join(f"{k}=%s" for k in data)
    with db() as cur:
        try:
            cur.execute(
                f"UPDATE Camera SET {sets} WHERE camera_id=%s",
                list(data.values()) + [camera_id],
            )
        except psycopg.errors.UniqueViolation:
            raise HTTPException(409, "model_name already exists")
        cur.execute("SELECT 1 FROM Camera WHERE camera_id=%s", (camera_id,))
        if not cur.fetchone():
            raise HTTPException(404, "camera not found")
        sync_camera_lens(cur, camera_id)
    return {"camera_id": camera_id, **data}


@router.delete("/{camera_id}", summary="Delete a camera and its dependent rows")
def delete_camera(camera_id: int):
    with db() as cur:
        cur.execute("SELECT 1 FROM Camera WHERE camera_id=%s", (camera_id,))
        if not cur.fetchone():
            raise HTTPException(404, "camera not found")
        # ลบข้อมูลที่เกี่ยวข้องทั้งหมดก่อน (ตามลำดับ foreign key)
        cur.execute("DELETE FROM Review WHERE recipe_id IN (SELECT recipe_id FROM Recipe WHERE camera_id=%s)", (camera_id,))
        cur.execute("DELETE FROM Review WHERE camera_id=%s", (camera_id,))
        cur.execute("DELETE FROM Recipe WHERE camera_id=%s", (camera_id,))
        cur.execute("DELETE FROM Favorite WHERE camera_id=%s", (camera_id,))
        cur.execute("DELETE FROM Camera_Lens WHERE camera_id=%s", (camera_id,))
        cur.execute("DELETE FROM Camera WHERE camera_id=%s", (camera_id,))
    return {"deleted": camera_id}

