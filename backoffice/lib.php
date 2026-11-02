<?php
include "db_conn.php";

const TABLES = [
    'camera'      => 'กล้อง',
    'lens'        => 'เลนส์',
    'users'       => 'ผู้ใช้',
    'recipe'      => 'สูตรถ่ายภาพ',
    'review'      => 'รีวิว',
    'camera_lens' => 'กล้อง–เลนส์ (M:N)',
    'favorite'    => 'รายการโปรด (M:N)',
];

// rows that depend on a row; removed first when the user chooses "delete with related data"
const CASCADE = [
    'camera' => [
        "DELETE FROM review WHERE recipe_id IN (SELECT recipe_id FROM recipe WHERE camera_id = :id)",
        "DELETE FROM review WHERE camera_id = :id",
        "DELETE FROM recipe WHERE camera_id = :id",
        "DELETE FROM favorite WHERE camera_id = :id",
        "DELETE FROM camera_lens WHERE camera_id = :id",
    ],
    'lens' => [
        "DELETE FROM review WHERE recipe_id IN (SELECT recipe_id FROM recipe WHERE lens_id = :id)",
        "DELETE FROM review WHERE lens_id = :id",
        "DELETE FROM recipe WHERE lens_id = :id",
        "DELETE FROM camera_lens WHERE lens_id = :id",
    ],
    'recipe' => ["DELETE FROM review WHERE recipe_id = :id"],
    'users'  => ["DELETE FROM review WHERE user_id = :id", "DELETE FROM favorite WHERE user_id = :id"],
];

function h($s) { return htmlspecialchars((string)$s, ENT_QUOTES, 'UTF-8'); }

// table name must be one of the 7 known tables (never taken straight from the URL)
function current_table() {
    $t = $_GET['t'] ?? $_POST['t'] ?? 'camera';
    return array_key_exists($t, TABLES) ? $t : 'camera';
}

function columns(PDO $pdo, $t) {
    $st = $pdo->prepare("SELECT column_name, data_type, is_nullable, is_identity, column_default
                         FROM information_schema.columns WHERE table_schema='public' AND table_name=:t
                         ORDER BY ordinal_position");
    $st->execute([':t' => $t]);
    return $st->fetchAll();
}

function pk_columns(PDO $pdo, $t) {
    $st = $pdo->prepare("SELECT a.attname FROM pg_index i
                         JOIN pg_attribute a ON a.attrelid=i.indrelid AND a.attnum=ANY(i.indkey)
                         WHERE i.indrelid=to_regclass(:t) AND i.indisprimary ORDER BY a.attnum");
    $st->execute([':t' => "public.$t"]);
    return array_column($st->fetchAll(), 'attname');
}

function qi($name) { return '"' . str_replace('"', '""', $name) . '"'; }

// camera_lens is derived data: a camera fits a lens when brand and mount match
function resync(PDO $pdo, $t, $row) {
    if ($t === 'camera') {
        $pdo->prepare("DELETE FROM camera_lens WHERE camera_id=:i")->execute([':i' => $row['camera_id']]);
        $pdo->prepare("INSERT INTO camera_lens (camera_id, lens_id) SELECT c.camera_id, l.lens_id FROM camera c
                       JOIN lens l ON c.mount=l.mount AND c.brand=l.brand WHERE c.camera_id=:i")->execute([':i' => $row['camera_id']]);
    } elseif ($t === 'lens') {
        $pdo->prepare("DELETE FROM camera_lens WHERE lens_id=:i")->execute([':i' => $row['lens_id']]);
        $pdo->prepare("INSERT INTO camera_lens (camera_id, lens_id) SELECT c.camera_id, l.lens_id FROM camera c
                       JOIN lens l ON c.mount=l.mount AND c.brand=l.brand WHERE l.lens_id=:i")->execute([':i' => $row['lens_id']]);
    }
}

function friendly_error(PDOException $e) {
    $code = $e->getCode();
    $msg = $e->errorInfo[2] ?? $e->getMessage();
    if ($code === '23503') return "ติดความสัมพันธ์ระหว่างตาราง (foreign key): $msg";
    if ($code === '23505') return "ข้อมูลซ้ำ (ห้ามซ้ำ): $msg";
    if ($code === '23514' || $code === '23502') return "ข้อมูลไม่ผ่านเงื่อนไขของตาราง: $msg";
    return "บันทึกไม่ได้: $msg";
}

function page_head($title, $t = null) { ?>
<!DOCTYPE html>
<html lang="th">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title><?= h($title) ?> | Lenzio Back-office</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.1/css/all.min.css">
    <style>.thumb{height:34px;width:48px;object-fit:cover;border-radius:6px}.cell{max-width:240px;overflow:hidden;text-overflow:ellipsis;white-space:nowrap}</style>
</head>
<body>
    <nav class="navbar navbar-light justify-content-center fs-3 mb-3" style="background-color:#1e3a8a;color:white;">
        Lenzio Back-office
    </nav>
    <div class="container-fluid px-4">
        <ul class="nav nav-pills mb-3">
            <?php foreach (TABLES as $k => $label): ?>
                <li class="nav-item"><a class="nav-link <?= $k === $t ? 'active' : '' ?>" href="index.php?t=<?= h($k) ?>"><?= h($label) ?></a></li>
            <?php endforeach; ?>
        </ul>
<?php }

function page_foot() { ?>
    </div>
    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.bundle.min.js"></script>
</body>
</html>
<?php }

// one form field per column, chosen from the column data type
function field(array $c, $value = null, $disabled = false) {
    $n = $c['column_name']; $type = $c['data_type'];
    $req = ($c['is_nullable'] === 'NO' && $c['column_default'] === null && $c['is_identity'] !== 'YES') ? 'required' : '';
    $dis = $disabled ? 'disabled' : '';
    $v = h($value);
    if ($type === 'text') return "<textarea class='form-control' rows='3' name='" . h($n) . "' $req $dis>$v</textarea>";
    if (in_array($type, ['integer', 'bigint', 'smallint'])) return "<input type='number' step='1' class='form-control' name='" . h($n) . "' value='$v' $req $dis>";
    if ($type === 'numeric') return "<input type='number' step='any' class='form-control' name='" . h($n) . "' value='$v' $req $dis>";
    if (str_starts_with($type, 'timestamp')) {
        $v = h($value ? str_replace(' ', 'T', substr($value, 0, 16)) : '');
        return "<input type='datetime-local' class='form-control' name='" . h($n) . "' value='$v' $req $dis>";
    }
    return "<input type='text' class='form-control' name='" . h($n) . "' value='$v' $req $dis>";
}

// empty text boxes become NULL (or are skipped when the database has a default)
function posted_values(array $cols, $skipPk = []) {
    $data = [];
    foreach ($cols as $c) {
        $n = $c['column_name'];
        if ($c['is_identity'] === 'YES' || in_array($n, $skipPk)) continue;
        if (!array_key_exists($n, $_POST)) continue;
        $v = trim($_POST[$n]);
        if ($v === '') {
            if ($c['column_default'] !== null && $c['is_nullable'] === 'NO') continue;
            $v = null;
        }
        $data[$n] = $v;
    }
    return $data;
}
