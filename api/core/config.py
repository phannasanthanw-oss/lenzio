"""โหลด environment variables จากไฟล์ .env และกำหนดค่าการตั้งค่าต่างๆ"""
import os
from dotenv import load_dotenv

# อ่านไฟล์ .env จากโฟลเดอร์ lenzio/ (ระดับเดียวกับ api/)
load_dotenv(os.path.join(os.path.dirname(__file__), "..", "..", ".env"))

DB = dict(
    host=os.getenv("DB_HOST"),
    port=int(os.getenv("DB_PORT", "5432")),
    user=os.getenv("DB_USER"),
    password=os.getenv("DB_PASSWORD"),
    dbname=os.getenv("DB_NAME", "postgres"),
    sslmode="require",
)

BRANDS = ("Sony", "Fujifilm", "Canon", "Nikon", "Panasonic")

