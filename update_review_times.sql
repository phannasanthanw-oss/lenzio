-- Spread the 90 seeded reviews over the last 30 days so the app shows "2 วันที่แล้ว" etc.
UPDATE review SET created_at = now() - (random() * interval '30 days');
