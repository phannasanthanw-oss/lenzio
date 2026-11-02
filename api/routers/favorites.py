"""Router: Favorites — ดู, เพิ่ม และลบกล้องในรายการโปรด"""
import psycopg
from fastapi import APIRouter, HTTPException

from core.database import db
from schemas.models import FavoriteIn

router = APIRouter(prefix="/favorites", tags=["Favorites"])


@router.get("", summary="Cameras a user added to favorites")
def list_favorites(user_id: int):
    with db() as cur:
        cur.execute(
            "SELECT c.camera_id, c.model_name, c.brand, c.sensor_format, c.image_url "
            "FROM Favorite f JOIN Camera c ON c.camera_id=f.camera_id "
            "WHERE f.user_id=%s ORDER BY c.model_name",
            (user_id,),
        )
        return cur.fetchall()


@router.post("", status_code=201, summary="Add a camera to favorites")
def add_favorite(body: FavoriteIn):
    with db() as cur:
        try:
            cur.execute(
                "INSERT INTO Favorite (user_id, camera_id) VALUES (%s,%s) ON CONFLICT DO NOTHING",
                (body.user_id, body.camera_id),
            )
        except psycopg.errors.ForeignKeyViolation:
            raise HTTPException(404, "user or camera does not exist")
    return body.model_dump()


@router.delete("/{user_id}/{camera_id}", summary="Remove a camera from favorites")
def remove_favorite(user_id: int, camera_id: int):
    with db() as cur:
        cur.execute("DELETE FROM Favorite WHERE user_id=%s AND camera_id=%s", (user_id, camera_id))
    return {"deleted": True}

