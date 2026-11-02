"""Router: หน้าแรก (Home) — ดึงข้อมูลสรุปสถิติ, กล้องยอดนิยม และ Recipe ล่าสุด"""
from fastapi import APIRouter
from core.database import db

router = APIRouter(tags=["Home"])


@router.get("/home", summary="Home page data")
def home():
    """คืนข้อมูล: ยอดรวมทั้งหมด, แบรนด์, กล้องยอดนิยม 6 อันดับ, Recipe ล่าสุด 6 รายการ"""
    with db() as cur:
        cur.execute("SELECT brand, COUNT(*) AS cameras FROM Camera GROUP BY brand ORDER BY brand")
        brands = cur.fetchall()

        cur.execute(
            "SELECT c.camera_id, c.model_name, c.brand, c.price_thb, c.image_url, "
            "ROUND(AVG(r.rating),1) AS avg_rating, COUNT(r.review_id) AS review_count "
            "FROM Camera c LEFT JOIN Review r ON r.camera_id=c.camera_id "
            "GROUP BY c.camera_id ORDER BY review_count DESC, avg_rating DESC NULLS LAST LIMIT 6"
        )
        top = cur.fetchall()

        cur.execute(
            "SELECT r.recipe_id, r.title, r.category, r.cover_image_url, c.model_name "
            "FROM Recipe r JOIN Camera c ON c.camera_id=r.camera_id ORDER BY r.recipe_id DESC LIMIT 6"
        )
        recipes = cur.fetchall()

        cur.execute(
            "SELECT (SELECT COUNT(*) FROM Camera) AS cameras, "
            "(SELECT COUNT(*) FROM Lens) AS lenses, "
            "(SELECT COUNT(*) FROM Recipe) AS recipes, "
            "(SELECT COUNT(*) FROM Review) AS reviews"
        )
        totals = cur.fetchone()

    return {"totals": totals, "brands": brands, "top_cameras": top, "latest_recipes": recipes}

