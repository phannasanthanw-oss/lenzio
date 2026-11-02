"""Router: Recipes — ดูรายการและรายละเอียดสูตรถ่ายภาพ"""
from typing import Optional

from fastapi import APIRouter, HTTPException, Query

from core.database import db

router = APIRouter(prefix="/recipes", tags=["Recipes"])


@router.get("", summary="List shooting recipes (filter by category or camera)")
def list_recipes(
    category: Optional[str] = None,
    camera_id: Optional[int] = None,
    limit: int = Query(100, ge=1, le=200),
):
    sql = (
        "SELECT r.*, c.model_name AS camera_name, l.lens_name "
        "FROM Recipe r "
        "JOIN Camera c ON c.camera_id=r.camera_id "
        "JOIN Lens l ON l.lens_id=r.lens_id WHERE 1=1"
    )
    args = []
    if category:
        sql += " AND r.category=%s"
        args.append(category)
    if camera_id:
        sql += " AND r.camera_id=%s"
        args.append(camera_id)
    with db() as cur:
        cur.execute(sql + " ORDER BY r.recipe_id LIMIT %s", args + [limit])
        return cur.fetchall()


@router.get("/{recipe_id}", summary="Recipe detail with camera, lens and reviews")
def get_recipe(recipe_id: int):
    with db() as cur:
        cur.execute(
            "SELECT r.*, c.model_name AS camera_name, c.image_url AS camera_image_url, "
            "l.lens_name, l.image_url AS lens_image_url "
            "FROM Recipe r "
            "JOIN Camera c ON c.camera_id=r.camera_id "
            "JOIN Lens l ON l.lens_id=r.lens_id "
            "WHERE r.recipe_id=%s",
            (recipe_id,),
        )
        rec = cur.fetchone()
        if not rec:
            raise HTTPException(404, "recipe not found")

        cur.execute(
            "SELECT r.review_id, u.display_name, r.rating, r.comment, r.like_count, r.created_at "
            "FROM Review r JOIN Users u ON u.user_id=r.user_id "
            "WHERE r.recipe_id=%s ORDER BY r.created_at DESC",
            (recipe_id,),
        )
        rec["reviews"] = cur.fetchall()

    return rec

