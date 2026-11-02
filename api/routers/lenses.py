"""Router: Lenses — ดูรายการและรายละเอียดเลนส์"""
from typing import Optional

from fastapi import APIRouter, HTTPException, Query

from core.database import db

router = APIRouter(prefix="/lenses", tags=["Lenses"])


@router.get("", summary="List lenses with rating (filter by brand, search by name)")
def list_lenses(
    brand: Optional[str] = None,
    q: Optional[str] = None,
    limit: int = Query(100, ge=1, le=200),
    offset: int = Query(0, ge=0),
):
    sql = (
        "SELECT l.*, ROUND(AVG(r.rating),1) AS avg_rating, COUNT(r.review_id) AS review_count "
        "FROM Lens l LEFT JOIN Review r ON r.lens_id=l.lens_id WHERE 1=1"
    )
    args = []
    if brand:
        sql += " AND l.brand=%s"
        args.append(brand)
    if q:
        sql += " AND l.lens_name ILIKE %s"
        args.append(f"%{q}%")
    sql += " GROUP BY l.lens_id ORDER BY l.lens_name LIMIT %s OFFSET %s"
    with db() as cur:
        cur.execute(sql, args + [limit, offset])
        return cur.fetchall()


@router.get("/{lens_id}", summary="Lens detail with compatible cameras")
def get_lens(lens_id: int):
    with db() as cur:
        cur.execute("SELECT * FROM Lens WHERE lens_id=%s", (lens_id,))
        lens = cur.fetchone()
        if not lens:
            raise HTTPException(404, "lens not found")

        cur.execute(
            "SELECT c.camera_id, c.model_name, c.image_url "
            "FROM Camera c JOIN Camera_Lens cl ON cl.camera_id=c.camera_id "
            "WHERE cl.lens_id=%s ORDER BY c.model_name",
            (lens_id,),
        )
        lens["compatible_cameras"] = cur.fetchall()

    return lens

