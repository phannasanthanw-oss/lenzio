"""Pydantic schemas (โมเดลรับข้อมูล) สำหรับ Camera, Review และ Favorite"""
from typing import Optional
from pydantic import BaseModel, Field


class CameraIn(BaseModel):
    """ข้อมูลที่ต้องการเมื่อสร้างหรืออัปเดตกล้อง"""
    model_name: str = Field(..., max_length=100)
    brand: str
    sensor_format: Optional[str] = None
    megapixels: Optional[float] = None
    video_spec: Optional[str] = None
    iso_min: Optional[int] = None
    iso_max: Optional[int] = None
    mount: Optional[str] = None
    release_year: Optional[int] = None
    price_thb: Optional[float] = None
    image_url: Optional[str] = Field(None, max_length=255)


class ReviewIn(BaseModel):
    """ข้อมูลที่ต้องการเมื่อสร้างรีวิว (ต้องระบุ camera_id, lens_id หรือ recipe_id อย่างใดอย่างหนึ่ง)"""
    user_id: int
    camera_id: Optional[int] = None
    lens_id: Optional[int] = None
    recipe_id: Optional[int] = None
    rating: int = Field(..., ge=1, le=5)
    comment: Optional[str] = None


class FavoriteIn(BaseModel):
    """ข้อมูลที่ต้องการเมื่อเพิ่มกล้องในรายการโปรด"""
    user_id: int
    camera_id: int

