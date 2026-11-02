"""Generate db/lenzio.sql (schema + data) with the Python standard library only.

Run from the project root:   python3 db/make_sql.py
Camera/Lens come from data/*.csv (collected data); Users/Recipe/Review/Favorite are synthetic
(random.seed(244)); Camera_Lens is derived (same brand + same mount).
"""
import csv
import os
import random

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
random.seed(244)


def read(name):
    with open(os.path.join(ROOT, "data", name), encoding="utf-8-sig", newline="") as f:
        rows = [r for r in csv.DictReader(f) if (r.get("model_name") or r.get("lens_name") or "").strip()]
    return [{k: (v or "").strip() for k, v in r.items()} for r in rows]


def q(v):
    if v is None or v == "":
        return "NULL"
    if isinstance(v, (int, float)):
        return str(v)
    return "'" + str(v).replace("'", "''") + "'"


def n(v, cast=float):
    return cast(v) if v != "" else None


def ins(table, cols, rows):
    out = []
    for r in rows:
        out.append(f"INSERT INTO {table} ({','.join(cols)}) OVERRIDING SYSTEM VALUE VALUES ({','.join(q(x) for x in r)});")
    return out


cams, lenses = read("camera.csv"), read("lens.csv")
NAMES = ["มะลิ", "ภูผา", "ใบเตย", "ตะวัน", "ฟ้าใส", "น้ำฝน", "กานต์", "พิมพ์", "ต้นกล้า", "ปลายฟ้า",
         "แพรวา", "ธัญญา", "ก้อง", "นนท์", "เมษา", "ไผ่", "ข้าวหอม", "มีน", "โอปอล", "ภีม"]
users = [(i + 1, f"{NAMES[i % 20]}{i // 20 + 1:02d}", f"https://i.pravatar.cc/150?img={i % 70 + 1}") for i in range(60)]
CATS = {
    "ภาพบุคคล": ("2.0", "1/250", 200, ["พอร์เทรตแสงธรรมชาติ", "พอร์เทรตหน้าต่าง", "พอร์เทรตริมถนน"]),
    "วิวทิวทัศน์": ("8.0", "1/125", 100, ["วิวภูเขายามเช้า", "ทะเลสงบ", "ทุ่งหญ้าพระอาทิตย์ตก"]),
    "อาหาร": ("2.8", "1/125", 400, ["อาหารแสงข้างหน้าต่าง", "กาแฟมุมสูง", "ขนมหวานโคลสอัพ"]),
    "กลางคืน": ("1.8", "1/60", 3200, ["ไฟเมืองยามค่ำ", "ถนนตลาดนัดกลางคืน", "ท้องฟ้าดาว"]),
}
cats = list(CATS)
cam_by, lens_by = {}, {}
for i, c in enumerate(cams, 1):
    c["id"] = i
    cam_by.setdefault((c["brand"], c["mount"]), []).append(c)
for i, l in enumerate(lenses, 1):
    l["id"] = i
    lens_by.setdefault((l["brand"], l["mount"]), []).append(l)
keys = [k for k in cam_by if k in lens_by]
recipes = []
for i in range(60):
    cat = cats[i % 4]
    ap, sh, iso, titles = CATS[cat]
    k = keys[i % len(keys)]
    cam, lens = random.choice(cam_by[k]), random.choice(lens_by[k])
    title = f"{random.choice(titles)} #{i + 1}"
    desc = f"สูตรตัวอย่างสำหรับ{cat} ใช้ {cam['model_name']} คู่กับ {lens['lens_name']}"
    recipes.append((i + 1, title, cat, cam["id"], lens["id"], ap, sh, iso, desc, f"https://picsum.photos/seed/lenzio{i + 1}/600/400"))
COMMENTS = ["ใช้งานดีมาก คุ้มราคา", "โฟกัสไวและแม่นยำ", "น้ำหนักกำลังดี พกพาง่าย", "สีสวยตรงใจ",
            "ภาพนิ่งคมชัด วิดีโอก็ดี", "เหมาะกับมือใหม่", "แบตอยู่ได้นานพอสมควร", "สูตรนี้ลองแล้วได้ผลจริง"]
cam_ids, lens_ids, rec_ids = [c["id"] for c in cams], [l["id"] for l in lenses], [r[0] for r in recipes]
reviews = []
for i in range(90):
    kind = i % 3
    t = [None, None, None]
    t[kind] = random.choice([cam_ids, lens_ids, rec_ids][kind])
    reviews.append((i + 1, random.randint(1, 60), *t, random.choice([3, 4, 4, 5, 5]), random.choice(COMMENTS), random.randint(0, 40)))
favs = set()
while len(favs) < 60:
    favs.add((random.randint(1, 60), random.choice(cam_ids)))
cl = [(c["id"], l["id"]) for c in cams for l in lenses if c["mount"] == l["mount"] and c["brand"] == l["brand"]]

sql = [open(os.path.join(ROOT, "schema_pg.sql"), encoding="utf-8").read(), "\nBEGIN;"]
sql += ins("camera", "camera_id model_name brand sensor_format megapixels video_spec iso_min iso_max mount release_year price_thb image_url".split(),
           [(c["id"], c["model_name"], c["brand"], c["sensor_format"], n(c["megapixels"]), c["video_spec"], n(c["iso_min"], lambda x: int(float(x))),
             n(c["iso_max"], lambda x: int(float(x))), c["mount"], n(c["release_year"], lambda x: int(float(x))), n(c["price_thb"]), c["image_url"]) for c in cams])
sql += ins("lens", "lens_id lens_name brand mount focal_min_mm focal_max_mm max_aperture weight_g release_year price_thb image_url".split(),
           [(l["id"], l["lens_name"], l["brand"], l["mount"], n(l["focal_min_mm"], int), n(l["focal_max_mm"], int), n(l["max_aperture"]),
             n(l["weight_g"], int), n(l["release_year"], lambda x: int(float(x))), n(l["price_thb"]), l["image_url"]) for l in lenses])
sql += ins("users", ["user_id", "display_name", "avatar_url"], users)
sql += ins("recipe", "recipe_id title category camera_id lens_id aperture shutter_speed iso description cover_image_url".split(), recipes)
sql += ins("review", "review_id user_id camera_id lens_id recipe_id rating comment like_count".split(), reviews)
sql += ins("camera_lens", ["camera_id", "lens_id"], cl)
sql += ins("favorite", ["user_id", "camera_id"], sorted(favs))
# identity counters continue after the imported ids
for t, col in [("camera", "camera_id"), ("lens", "lens_id"), ("users", "user_id"), ("recipe", "recipe_id"), ("review", "review_id")]:
    sql.append(f"SELECT setval(pg_get_serial_sequence('{t}','{col}'), (SELECT MAX({col}) FROM {t}));")
sql.append("COMMIT;\n")
out = os.path.join(ROOT, "db", "lenzio.sql")
open(out, "w", encoding="utf-8").write("\n".join(sql))
print("wrote", out, "camera", len(cams), "lens", len(lenses), "camera_lens", len(cl), "review", len(reviews), "favorite", len(favs))
