> วิธีรันแอป Flutter และ FastAPI ดู [README.md](README.md)# Lenzio — ระบบฐานข้อมูลกล้อง เลนส์ สูตรถ่ายภาพ และรีวิว

โปรเจกต์ Final Project วิชา 802244 Digital Database (มหาวิทยาลัยศิลปากร) และใช้เป็นแหล่งข้อมูลของแอป Flutter

- **ฐานข้อมูล:** PostgreSQL 7 ตาราง (5 Entity + 2 ตารางเชื่อม M:N) ทุกตาราง ≥ 50 แถว
- **Back-office (Web Application):** PHP + Apache — แสดง / เพิ่ม / แก้ไข / ลบ ข้อมูลครบทั้ง 7 ตาราง (`backoffice/`)
- **ตัวจัดการฐานข้อมูล:** Adminer (ใช้แทน phpMyAdmin สำหรับ PostgreSQL)
- **แอปมือถือ:** Flutter (`lenzio_app/`) เรียก REST API ของ FastAPI (`api/`)

```
Back-office (PHP)  ─┐
                    ├─►  PostgreSQL (7 ตาราง)     ◄── db/lenzio.sql
Flutter ► FastAPI  ─┘
```

## โปรแกรมที่ต้องติดตั้ง
- Docker Desktop (มี `docker compose`) — **จำเป็นสำหรับการติดตั้งแบบ Back-office**
- เบราว์เซอร์ (Chrome / Safari)
- (ไม่บังคับ) Python 3.10+ ถ้าต้องการสร้างไฟล์ `db/lenzio.sql` ใหม่ · Flutter SDK + Android Studio ถ้าต้องการรันแอปมือถือ

## วิธีติดตั้งและรัน Back-office (ทำตามได้บนเครื่องใหม่)
1. คัดลอกโปรเจกต์ (`git clone <repo-url>` แล้ว `cd` เข้าโฟลเดอร์)
2. สร้างไฟล์ `.env` จากตัวอย่าง แล้วตั้งรหัสผ่านฐานข้อมูลในเครื่อง (ตั้งเองได้ ใช้ภายใน Docker เท่านั้น):
   ```bash
   cp .env.example .env
   # แก้บรรทัด LOCAL_DB_PASSWORD=... ใน .env
   ```
3. รัน:
   ```bash
   docker compose up -d --build
   ```
   ครั้งแรก PostgreSQL จะสร้างตารางและนำเข้าข้อมูลจาก `db/lenzio.sql` โดยอัตโนมัติ (รอ ~30 วินาที)
4. เปิดใช้งาน
   | ระบบ | ที่อยู่ |
   | --- | --- |
   | Back-office | http://localhost:8090 |
   | Adminer | http://localhost:8081 — System: PostgreSQL · Server: `db` · User: `lenzio` · Password: ค่า `LOCAL_DB_PASSWORD` · Database: `lenzio` |
5. ปิด: `docker compose down` (ล้างข้อมูลด้วย: `docker compose down -v`)

> ถ้าพอร์ต 8090 / 8081 / 5433 ชนกับโปรแกรมอื่น ให้แก้เลขพอร์ตฝั่งซ้ายใน `docker-compose.yml`

## ไฟล์ฐานข้อมูล (SQL Export)
- `db/lenzio.sql` — สร้างตารางทั้งหมดพร้อม Primary/Foreign Key, CHECK และข้อมูลทุกตาราง
- `schema_pg.sql` — เฉพาะโครงสร้างตาราง
- `data/camera.csv`, `data/lens.csv` — ข้อมูลดิบที่รวบรวม
- นำเข้าด้วยตนเอง (ไม่ใช้ Docker): `psql -U <user> -d <db> -f db/lenzio.sql`

## ความสามารถของ Back-office
- เลือกตารางจากแท็บด้านบน แสดงข้อมูลเป็นหน้า (20 แถว) พร้อมช่องค้นหา
- **Add New** เพิ่มข้อมูล · ไอคอนดินสอ **แก้ไข** · ไอคอนถังขยะ **ลบ** (ต้องยืนยัน)
- ลบข้อมูลที่ถูกอ้างอิง (Foreign Key) ระบบแจ้งและถามก่อนว่าจะลบข้อมูลที่เกี่ยวข้องด้วยหรือไม่
- ตรวจเงื่อนไขของฐานข้อมูล (NOT NULL, UNIQUE, CHECK, FK) และแสดงข้อความแจ้ง
- ใช้ Prepared Statement และตรวจชื่อตาราง/คอลัมน์กับ Catalog ป้องกัน SQL Injection

## (ทางเลือก) ใช้ PostgreSQL บน Supabase ของตนเอง
1. สร้างโปรเจกต์ Supabase แล้วรัน `db/lenzio.sql` ใน SQL Editor
2. ใน `.env` ตั้ง `DB_HOST`, `DB_PORT`, `DB_USER`, `DB_PASSWORD`, `DB_NAME` ตามหน้า Connect ของโปรเจกต์ และ `DB_SSLMODE=require`
3. ในส่วน `web` ของ `docker-compose.yml` ใช้ค่าจาก `.env` แทน (`DB_HOST: ${DB_HOST}` ฯลฯ) แล้วรัน `docker compose up -d --build web`

## FastAPI และแอป Flutter (สำหรับวิชา Flutter)
```bash
cd api && pip install -r requirements.txt
python3 -m uvicorn main:app --reload --port 8000   # เอกสาร API: http://localhost:8000/docs
cd ../lenzio_app && flutter pub get && flutter run  # แอปเรียก http://10.0.2.2:8000 (Android emulator)
```
FastAPI อ่านค่าเชื่อมต่อฐานข้อมูลจากไฟล์ `.env` (`DB_HOST`, `DB_PORT`, `DB_USER`, `DB_PASSWORD`, `DB_NAME`)

## ความปลอดภัย
- ไม่มีรหัสผ่านหรือ secret ในซอร์สโค้ด: ทุกค่าอ่านจากตัวแปรสภาพแวดล้อม / ไฟล์ `.env` ซึ่งอยู่ใน `.gitignore`
- มีเพียง `.env.example` (ค่าตัวอย่าง) ใน Repository
- Back-office ยังไม่มีระบบล็อกอิน เหมาะสำหรับใช้งานในเครื่องเท่านั้น

## โครงสร้างโปรเจกต์
```
backoffice/     Web Application (PHP): index, add_new, edit, delete
db/             lenzio.sql (SQL export), make_sql.py (สคริปต์สร้างไฟล์)
data/           camera.csv, lens.csv
api/            FastAPI (สำหรับแอป Flutter)
lenzio_app/     แอป Flutter
docker-compose.yml, schema_pg.sql, .env.example
```

ผู้จัดทำ: Wongchada Phannasanthan (681310303)
