"""Router: Reviews — ดู, เพิ่ม, ลบรีวิว และกด Like"""
from typing import Optional

import psycopg
from fastapi import APIRouter, HTTPException, Query

from core.database import db
from schemas.models import ReviewIn

router = APIRouter(prefix="/reviews", tags=["Reviews"])


@router.get("", summary="List reviews with product info (filter by type, camera, lens or recipe)")
def list_reviews(
    type: Optional[str] = Query(None, pattern="^(camera|lens|recipe)$"),
    camera_id: Optional[int] = None,
    lens_id: Optional[int] = None,
    recipe_id: Optional[int] = None,
    limit: int = Query(50, ge=1, le=200),
):
    sql = (
        "SELECT r.review_id, r.user_id, u.display_name, u.avatar_url, "
        "r.camera_id, r.lens_id, r.recipe_id, r.rating, r.comment, r.like_count, r.created_at, "
        "CASE WHEN r.camera_id IS NOT NULL THEN 'camera' "
        "     WHEN r.lens_id IS NOT NULL THEN 'lens' "
        "     ELSE 'recipe' END AS target_type, "
        "COALESCE(c.model_name, l.lens_name, rc.title) AS target_name, "
        "COALESCE(c.image_url, l.image_url, rc.cover_image_url) AS target_image_url "
        "FROM Review r JOIN Users u ON u.user_id=r.user_id "
        "LEFT JOIN Camera c ON c.camera_id=r.camera_id "
        "LEFT JOIN Lens l ON l.lens_id=r.lens_id "
        "LEFT JOIN Recipe rc ON rc.recipe_id=r.recipe_id WHERE 1=1"
    )
    args = []
    if type:
        sql += f" AND r.{type}_id IS NOT NULL"
    for col, val in (("camera_id", camera_id), ("lens_id", lens_id), ("recipe_id", recipe_id)):
        if val is not None:
            sql += f" AND r.{col}=%s"
            args.append(val)
    with db() as cur:
        cur.execute(sql + " ORDER BY r.created_at DESC, r.review_id DESC LIMIT %s", args + [limit])
        return cur.fetchall()


@router.post("", status_code=201, summary="Add a review (exactly one target)")
def create_review(body: ReviewIn):
    targets = [t for t in (body.camera_id, body.lens_id, body.recipe_id) if t is not None]
    if len(targets) != 1:
        raise HTTPException(422, "give exactly one of camera_id, lens_id, recipe_id")
    with db() as cur:
        try:
            cur.execute(
                "INSERT INTO Review (user_id,camera_id,lens_id,recipe_id,rating,comment) "
                "VALUES (%s,%s,%s,%s,%s,%s) RETURNING review_id",
                (body.user_id, body.camera_id, body.lens_id, body.recipe_id, body.rating, body.comment),
            )
        except psycopg.errors.ForeignKeyViolation:
            raise HTTPException(404, "user, camera, lens or recipe does not exist")
        return {"review_id": cur.fetchone()["review_id"], **body.model_dump()}


@router.delete("/{review_id}", summary="Delete a review")
def delete_review(review_id: int):
    with db() as cur:
        cur.execute("DELETE FROM Review WHERE review_id=%s", (review_id,))
        if cur.rowcount == 0:
            raise HTTPException(404, "review not found")
    return {"deleted": review_id}


@router.post("/{review_id}/like", summary="Like a review (+1)")
def like_review(review_id: int):
    with db() as cur:
        cur.execute(
            "UPDATE Review SET like_count = like_count + 1 WHERE review_id=%s RETURNING like_count",
            (review_id,),
        )
        row = cur.fetchone()
        if not row:
            raise HTTPException(404, "review not found")
        return {"review_id": review_id, "like_count": row["like_count"]}

