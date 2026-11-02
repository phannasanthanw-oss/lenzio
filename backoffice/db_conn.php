<?php
// Connection settings come from environment variables (docker-compose / .env) - no passwords in source code.
$host = getenv('DB_HOST') ?: 'db';
$port = getenv('DB_PORT') ?: '5432';
$user = getenv('DB_USER') ?: 'lenzio';
$pass = getenv('DB_PASSWORD') ?: '';
$name = getenv('DB_NAME') ?: 'lenzio';
$ssl  = getenv('DB_SSLMODE') ?: 'prefer';

try {
    $pdo = new PDO("pgsql:host=$host;port=$port;dbname=$name;sslmode=$ssl", $user, $pass, [
        PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
        PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
    ]);
} catch (PDOException $e) {
    die("Connection failed: " . htmlspecialchars($e->getMessage()));
}
