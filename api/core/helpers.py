"""Helper functions ที่ใช้ร่วมกันในหลาย router"""
from fastapi import HTTPException
from core.config import BRANDS


def check_brand(brand: str):
    """ตรวจสอบว่า brand อยู่ในรายการที่รองรับ"""
    if brand not in BRANDS:
        raise HTTPException(422, f"brand must be one of {BRANDS}")


def sync_camera_lens(cur, camera_id: int):
    """อัปเดตตาราง Camera_Lens: จับคู่กล้องกับเลนส์ที่มี brand และ mount เดียวกัน"""
    cur.execute("DELETE FROM Camera_Lens WHERE camera_id=%s", (camera_id,))
    cur.execute(
        "INSERT INTO Camera_Lens (camera_id, lens_id) "
        "SELECT c.camera_id, l.lens_id "
        "FROM Camera c JOIN Lens l ON c.mount=l.mount AND c.brand=l.brand "
        "WHERE c.camera_id=%s",
        (camera_id,),
    )

