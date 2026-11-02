# Lenzio

แอปมือถือรวบรวมกล้อง เลนส์ สูตรถ่ายภาพ (Recipe) และรีวิว จาก 5 แบรนด์ (Sony, Fujifilm, Canon, Nikon, Panasonic)

- **Mobile app:** Flutter (`lenzio_app/`)
- **Backend:** FastAPI (`api/`) พร้อมหน้าเอกสาร `/docs`
- **Database:** PostgreSQL (โฮสต์บน Supabase) — สคริปต์สร้างตาราง `schema_pg.sql`, สคริปต์นำเข้าข้อมูล `import_data_pg.py`, ข้อมูลกล้อง/เลนส์ `data/*.csv`

```
Flutter app  --HTTP-->  FastAPI (port 8000)  --psycopg-->  PostgreSQL (Supabase)
```

## ตาราง (7 ตาราง)
`camera`, `lens`, `users`, `recipe`, `review`, `camera_lens` (กล้อง M:N เลนส์), `favorite` (ผู้ใช้ M:N กล้อง)

> หมายเหตุข้อมูล: camera/lens เป็นข้อมูลที่รวบรวมจริง ส่วน users/recipe/review/favorite สร้างขึ้นจำลองเพื่อการทดสอบ ราคาเป็นค่าประมาณ

## สิ่งที่ต้องติดตั้ง
- Python 3.10+ และ pip
- Flutter SDK + Android Studio (มี Android Emulator)
- บัญชี/โปรเจกต์ PostgreSQL (ตัวอย่างใช้ Supabase) หรือ PostgreSQL ในเครื่อง

## 1) ตั้งค่าฐานข้อมูล
1. สร้างโปรเจกต์ใน Supabase (หรือ PostgreSQL ของตัวเอง)
2. คัดลอก `.env.example` เป็น `.env` แล้วกรอกค่าเชื่อมต่อของตัวเอง (**ห้าม commit ไฟล์ `.env`**)
   ```
   DB_HOST=...
   DB_PORT=5432
   DB_USER=...
   DB_PASSWORD=...
   DB_NAME=postgres
   ```
3. สร้างตาราง: เปิด SQL Editor ของ Supabase แล้วรันเนื้อหาในไฟล์ `schema_pg.sql`
4. นำเข้าข้อมูล
   ```bash
   pip install "psycopg[binary,pool]" python-dotenv
   python3 import_data_pg.py
   ```
   (ผลที่ควรได้: camera 58, lens 60, users 60, recipe 60, review 90, camera_lens 696, favorite 60 แถว)

## 2) รัน FastAPI server
```bash
cd api
pip install -r requirements.txt
python3 -m uvicorn main:app --reload --port 8000
```
- เอกสาร API (Swagger): http://localhost:8000/docs
- ตัวอย่างเรียกทดสอบ: http://localhost:8000/cameras?limit=3

## 3) รันแอป Flutter
1. เปิด Android Emulator
2. ค่า `kApiBase` ในไฟล์ `lenzio_app/lib/main.dart` ใช้ `http://10.0.2.2:8000` (ที่อยู่ของเครื่องโฮสต์เมื่อมองจาก emulator)
3. รัน
   ```bash
   cd lenzio_app
   flutter pub get
   flutter run
   ```
> ต้องรัน FastAPI ค้างไว้ก่อนเปิดแอป

## หน้าในแอป
Home · กล้อง (รายการ/ค้นหา/กรอง/เรียง + รายละเอียด) · เลนส์ · Recipe · รีวิว (ดู/เขียน/กดไลก์)

## API หลัก
| Method | Path | หน้าที่ |
| --- | --- | --- |
| GET | `/home` | ข้อมูลหน้า Home |
| GET/POST | `/cameras` | รายการ / เพิ่มกล้อง |
| GET/PUT/DELETE | `/cameras/{id}` | รายละเอียด / แก้ / ลบ |
| GET | `/lenses`, `/lenses/{id}` | เลนส์ |
| GET | `/recipes`, `/recipes/{id}` | สูตรถ่ายภาพ |
| GET/POST | `/reviews` | รีวิว / เขียนรีวิว |
| POST | `/reviews/{id}/like` | ไลก์รีวิว |
| GET/POST/DELETE | `/favorites` | รายการโปรด |