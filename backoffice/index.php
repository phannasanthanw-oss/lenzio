<?php
include "lib.php";
$t = current_table();
$cols = columns($pdo, $t);
$pk = pk_columns($pdo, $t);
$per = 20;
$page = max(1, (int)($_GET['page'] ?? 1));
$q = trim($_GET['q'] ?? '');

$where = $q !== '' ? " WHERE " . qi($t) . "::text ILIKE :q" : '';
$st = $pdo->prepare("SELECT COUNT(*) FROM " . qi($t) . $where);
$q !== '' ? $st->execute([':q' => "%$q%"]) : $st->execute();
$total = (int)$st->fetchColumn();
$pages = max(1, (int)ceil($total / $per));
$page = min($page, $pages);

$order = implode(', ', array_map('qi', $pk));
$st = $pdo->prepare("SELECT * FROM " . qi($t) . $where . " ORDER BY $order LIMIT $per OFFSET " . (($page - 1) * $per));
$q !== '' ? $st->execute([':q' => "%$q%"]) : $st->execute();
$rows = $st->fetchAll();

page_head(TABLES[$t], $t);
if (isset($_GET['msg'])) {
    $type = ($_GET['ok'] ?? '1') === '1' ? 'success' : 'danger';
    echo '<div class="alert alert-' . $type . ' alert-dismissible fade show" role="alert">' . h($_GET['msg']) .
         '<button type="button" class="btn-close" data-bs-dismiss="alert" aria-label="Close"></button></div>';
}
?>
<div class="d-flex justify-content-between align-items-center mb-3">
    <a href="add_new.php?t=<?= h($t) ?>" class="btn btn-dark">Add New</a>
    <form class="d-flex" method="get">
        <input type="hidden" name="t" value="<?= h($t) ?>">
        <input class="form-control me-2" name="q" value="<?= h($q) ?>" placeholder="ค้นหาในตารางนี้...">
        <button class="btn btn-outline-primary">Search</button>
    </form>
</div>
<div class="table-responsive">
<table class="table table-hover text-center align-middle">
    <thead class="table-dark">
        <tr>
            <?php foreach ($cols as $c): ?><th scope="col"><?= h($c['column_name']) ?></th><?php endforeach; ?>
            <th scope="col">Action</th>
        </tr>
    </thead>
    <tbody>
    <?php foreach ($rows as $row):
        $key = http_build_query(['pk' => array_map(fn($c) => $row[$c], array_combine($pk, $pk))]); ?>
        <tr>
            <?php foreach ($cols as $c): $n = $c['column_name']; $v = $row[$n]; ?>
                <td class="cell" title="<?= h($v) ?>">
                    <?php if (str_ends_with($n, '_url') && $v): ?>
                        <img class="thumb" src="<?= h($v) ?>" alt="" loading="lazy" onerror="this.replaceWith(document.createTextNode('-'))">
                    <?php else: echo h($v); endif; ?>
                </td>
            <?php endforeach; ?>
            <td>
                <a href="edit.php?t=<?= h($t) ?>&<?= $key ?>" class="link-dark"><i class="fa-solid fa-pen-to-square fs-5 me-3"></i></a>
                <a href="delete.php?t=<?= h($t) ?>&<?= $key ?>" class="link-dark"><i class="fa-solid fa-trash fs-5"></i></a>
            </td>
        </tr>
    <?php endforeach; ?>
    <?php if (!$rows): ?><tr><td colspan="<?= count($cols) + 1 ?>" class="text-muted py-4">ไม่พบข้อมูล</td></tr><?php endif; ?>
    </tbody>
</table>
</div>
<div class="d-flex justify-content-between align-items-center mb-4">
    <span class="text-muted">แสดงหน้า <?= $page ?> / <?= $pages ?> (ทั้งหมด <?= $total ?> แถว)</span>
    <div>
        <?php $base = "index.php?t=" . urlencode($t) . "&q=" . urlencode($q) . "&page="; ?>
        <a class="btn btn-outline-secondary btn-sm <?= $page <= 1 ? 'disabled' : '' ?>" href="<?= $base . ($page - 1) ?>">← ก่อนหน้า</a>
        <a class="btn btn-outline-secondary btn-sm <?= $page >= $pages ? 'disabled' : '' ?>" href="<?= $base . ($page + 1) ?>">ถัดไป →</a>
    </div>
</div>
<?php page_foot();
