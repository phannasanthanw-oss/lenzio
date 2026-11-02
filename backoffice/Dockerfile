FROM php:8.2-apache

# ติดตั้ง Extension สำหรับเชื่อมต่อ PostgreSQL (PDO)
RUN apt-get update && apt-get install -y --no-install-recommends libpq-dev \
    && docker-php-ext-install pdo pdo_pgsql pgsql \
    && rm -rf /var/lib/apt/lists/*

# เปิดใช้งาน mod_rewrite ของ Apache
RUN a2enmod rewrite
