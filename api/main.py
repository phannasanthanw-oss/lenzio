"""Lenzio API (FastAPI + PostgreSQL on Supabase).

Run:  uvicorn main:app --reload --port 8000
Docs: http://localhost:8000/docs   |   Admin: http://localhost:8000/admin
"""
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from core.database import lifespan
from routers import admin, cameras, favorites, home, lenses, recipes, reviews

app = FastAPI(
    title="Lenzio API",
    version="1.0",
    lifespan=lifespan,
    description="Cameras, lenses, shooting recipes and reviews for 5 mirrorless brands.",
)

app.add_middleware(CORSMiddleware, allow_origins=["*"], allow_methods=["*"], allow_headers=["*"])

# ลงทะเบียน routers ทั้งหมด
app.include_router(home.router)
app.include_router(cameras.router)
app.include_router(lenses.router)
app.include_router(recipes.router)
app.include_router(reviews.router)
app.include_router(favorites.router)
app.include_router(admin.router)
