"""Lenzio: import Camera/Lens from CSV and generate synthetic data -> Supabase (PostgreSQL).

Setup (once):
    pip install "psycopg[binary]" python-dotenv
    copy .env.example to .env and fill in your Supabase values

Usage (from the lenzio folder):
    python3 import_data_pg.py            # needs data/camera.csv and data/lens.csv
    python3 import_data_pg.py --dry-run  # check files + generation, no database

Camera and Lens are REAL data (scraped / collected).
Users, Recipe, Review, Favorite are SYNTHETIC (generated here) and
Camera_Lens is DERIVED (same brand and same mount).
"""
import csv
import os
import random
import sys

from dotenv import load_dotenv

load_dotenv()  # reads .env in this folder (never commit .env to GitHub)

DB = dict(host=os.getenv("DB_HOST"),
          port=int(os.getenv("DB_PORT", "5432")),
          user=os.getenv("DB_USER"),
          password=os.getenv("DB_PASSWORD"),
          dbname=os.getenv("DB_NAME", "postgres"),
          sslmode="require")

random.seed(244)
DRY = "--dry-run" in sys.argv


def read(path):
    with open(path, encoding="utf-8-sig", newline="") as f:
        rows = [r for r in csv.DictReader(f) if (r.get("model_name") or r.get("lens_name") or "").strip()]
    for r in rows:
        for k, v in r.items():
            r[k] = (v or "").strip()
    return rows


def num(v, cast=float):
    return cast(v) if v != "" else None


cams = read("data/camera.csv")
lenses = read("data/lens.csv")
assert len(cams) >= 50, f"camera rows = {len(cams)}"
assert len(lenses) >= 50, f"lens rows = {len(lenses)}"
for r in lenses:
    assert not r["max_aperture"].startswith("f"), f"max_aperture must be a number: {r['lens_name']}"

# ---------- synthetic data ----------
NAMES = ["มะลิ", "ภูผา", "ใบเตย", "ตะวัน", "ฟ้าใส", "น้ำฝน", "กานต์", "พิมพ์", "ต้นกล้า", "ปลายฟ้า",
         "แพรวา", "ธัญญา", "ก้อง", "นนท์", "เมษา", "ไผ่", "ข้าวหอม", "มีน", "โอปอล", "ภีม"]
users = [(f"{NAMES[i % len(NAMES)]}{i // len(NAMES) + 1:02d}", f"https://i.pravatar.cc/150?img={i % 70 + 1}")
         for i in range(60)]

CATS = {
    "ภาพบุคคล": ("2.0", "1/250", 200, ["พอร์เทรตแสงธรรมชาติ", "พอร์เทรตหน้าต่าง", "พอร์เทรตริมถนน"]),
    "วิวทิวทัศน์": ("8.0", "1/125", 100, ["วิวภูเขายามเช้า", "ทะเลสงบ", "ทุ่งหญ้าพระอาทิตย์ตก"]),
    "อาหาร": ("2.8", "1/125", 400, ["อาหารแสงข้างหน้าต่าง", "กาแฟมุมสูง", "ขนมหวานโคลสอัพ"]),
    "กลางคืน": ("1.8", "1/60", 3200, ["ไฟเมืองยามค่ำ", "ถนนตลาดนัดกลางคืน", "ท้องฟ้าดาว"]),
}
COVER_TEXT = {"ภาพบุคคล": "Portrait", "วิวทิวทัศน์": "Landscape", "อาหาร": "Food", "กลางคืน": "Night"}
cats = list(CATS)
cam_by_mount = {}
for c in cams:
    cam_by_mount.setdefault((c["brand"], c["mount"]), []).append(c)
lens_by_mount = {}
for l in lenses:
    lens_by_mount.setdefault((l["brand"], l["mount"]), []).append(l)
keys = [k for k in cam_by_mount if k in lens_by_mount]

recipes = []  # (title, cat, camera_name, lens_name, ap, shutter, iso, desc, cover)
for i in range(60):
    cat = cats[i % 4]
    ap, sh, iso, titles = CATS[cat]
    k = keys[i % len(keys)]
    cam = random.choice(cam_by_mount[k])
    lens = random.choice(lens_by_mount[k])
    title = f"{random.choice(titles)} #{i + 1}"
    desc = f"สูตรตัวอย่างสำหรับ{cat} ใช้ {cam['model_name']} คู่กับ {lens['lens_name']}"
    cover = "https://placehold.co/600x400.png?text=" + COVER_TEXT[cat]
    recipes.append((title, cat, cam["model_name"], lens["lens_name"], ap, sh, iso, desc, cover))

COMMENTS = ["ใช้งานดีมาก คุ้มราคา", "โฟกัสไวและแม่นยำ", "น้ำหนักกำลังดี พกพาง่าย", "สีสวยตรงใจ",
            "ภาพนิ่งคมชัด วิดีโอก็ดี", "เหมาะกับมือใหม่", "แบตอยู่ได้นานพอสมควร", "สูตรนี้ลองแล้วได้ผลจริง"]

# ---------- database ----------
if DRY:
    print(f"OK dry-run: cameras={len(cams)} lenses={len(lenses)} users={len(users)} recipes={len(recipes)} "
          f"mount-groups={len(keys)}")
    sys.exit(0)

import psycopg  # noqa: E402

missing = [k for k in ("DB_HOST", "DB_USER", "DB_PASSWORD") if not os.getenv(k)]
if missing:
    sys.exit(f"Missing in .env: {', '.join(missing)}")

conn = psycopg.connect(**DB)
cur = conn.cursor()
# empty all tables and restart the id counters from 1
cur.execute("TRUNCATE favorite, camera_lens, review, recipe, users, lens, camera RESTART IDENTITY")

cur.executemany(
    "INSERT INTO camera (model_name,brand,sensor_format,megapixels,video_spec,iso_min,iso_max,mount,"
    "release_year,price_thb,image_url) VALUES (%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s)",
    [(c["model_name"], c["brand"], c["sensor_format"], num(c["megapixels"]), c["video_spec"],
      num(c["iso_min"], lambda x: int(float(x))), num(c["iso_max"], lambda x: int(float(x))), c["mount"],
      num(c["release_year"], lambda x: int(float(x))), num(c["price_thb"]), c["image_url"] or None)
     for c in cams])
cur.executemany(
    "INSERT INTO lens (lens_name,brand,mount,focal_min_mm,focal_max_mm,max_aperture,weight_g,release_year,"
    "price_thb,image_url) VALUES (%s,%s,%s,%s,%s,%s,%s,%s,%s,%s)",
    [(l["lens_name"], l["brand"], l["mount"], num(l["focal_min_mm"], int), num(l["focal_max_mm"], int),
      num(l["max_aperture"]), num(l["weight_g"], int), num(l["release_year"], lambda x: int(float(x))),
      num(l["price_thb"]), l["image_url"] or None) for l in lenses])
cur.executemany("INSERT INTO users (display_name,avatar_url) VALUES (%s,%s)", users)

cur.execute("SELECT model_name,camera_id FROM camera"); cid = dict(cur.fetchall())
cur.execute("SELECT lens_name,lens_id FROM lens"); lid = dict(cur.fetchall())
cur.executemany(
    "INSERT INTO recipe (title,category,camera_id,lens_id,aperture,shutter_speed,iso,description,cover_image_url) "
    "VALUES (%s,%s,%s,%s,%s,%s,%s,%s,%s)",
    [(r[0], r[1], cid[r[2]], lid[r[3]], r[4], r[5], r[6], r[7], r[8]) for r in recipes])

cur.execute("INSERT INTO camera_lens (camera_id,lens_id) SELECT c.camera_id,l.lens_id "
            "FROM camera c JOIN lens l ON c.mount=l.mount AND c.brand=l.brand")

cam_ids, lens_ids = list(cid.values()), list(lid.values())
cur.execute("SELECT recipe_id FROM recipe"); rec_ids = [x[0] for x in cur.fetchall()]
reviews = []
for i in range(90):
    kind = i % 3
    target = [None, None, None]
    target[kind] = random.choice([cam_ids, lens_ids, rec_ids][kind])
    reviews.append((random.randint(1, len(users)), *target, random.choice([3, 4, 4, 5, 5]),
                    random.choice(COMMENTS), random.randint(0, 40)))
cur.executemany("INSERT INTO review (user_id,camera_id,lens_id,recipe_id,rating,comment,like_count) "
                "VALUES (%s,%s,%s,%s,%s,%s,%s)", reviews)

favs = set()
while len(favs) < 60:
    favs.add((random.randint(1, len(users)), random.choice(cam_ids)))
cur.executemany("INSERT INTO favorite (user_id,camera_id) VALUES (%s,%s)", sorted(favs))
conn.commit()

for t in ("camera", "lens", "users", "recipe", "review", "camera_lens", "favorite"):
    cur.execute(f"SELECT COUNT(*) FROM {t}")
    print(f"{t:12s} {cur.fetchone()[0]} rows")
conn.close()
