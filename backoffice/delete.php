<?php
include "lib.php";
$t = current_table();
$pk = pk_columns($pdo, $t);
$key = $_GET['pk'] ?? $_POST['pk'] ?? [];
if (!is_array($key) || array_diff($pk, array_keys($key))) { header("Location: index.php?t=$t"); exit; }

$where = implode(' AND ', array_map(fn($c) => qi($c) . " = :pk_$c", $pk));
$args = [];
foreach ($pk as $c) $args[":pk_$c"] = $key[$c];
$error = '';
$offerCascade = false;

if (isset($_POST['confirm'])) {   // deleting needs a POST confirmation, never a bare link
    try {
        $pdo->beginTransaction();
        // camera_lens is derived from brand + mount, so its rows go away with the camera / lens
        if ($t === 'camera' || $t === 'lens') {
            $pdo->prepare("DELETE FROM camera_lens WHERE " . qi($pk[0]) . " = :id")->execute([':id' => $key[$pk[0]]]);
        }
        if (isset($_POST['cascade']) && isset(CASCADE[$t])) {
            foreach (CASCADE[$t] as $sql) $pdo->prepare($sql)->execute([':id' => $key[$pk[0]]]);
        }
        $st = $pdo->prepare("DELETE FROM " . qi($t) . " WHERE $where");
        $st->execute($args);
        $pdo->commit();
        header("Location: index.php?t=$t&msg=" . urlencode("Record deleted successfully"));
        exit;
    } catch (PDOException $e) {
        if ($pdo->inTransaction()) $pdo->rollBack();
        $error = friendly_error($e);
        $offerCascade = $e->getCode() === '23503' && isset(CASCADE[$t]);
    }
}
page_head("Delete", $t);
?>
<div class="container d-flex justify-content-center">
    <form method="post" class="text-center" style="max-width:520px;">
        <input type="hidden" name="t" value="<?= h($t) ?>">
        <?php foreach ($pk as $c): ?><input type="hidden" name="pk[<?= h($c) ?>]" value="<?= h($key[$c]) ?>"><?php endforeach; ?>
        <h3 class="mb-3">ลบข้อมูลนี้ใช่ไหม?</h3>
        <p class="text-muted">ตาราง <b><?= h($t) ?></b> — <?= h(implode(', ', array_map(fn($c) => "$c = " . $key[$c], $pk))) ?></p>
        <?php if ($error): ?><div class="alert alert-danger text-start"><?= h($error) ?></div><?php endif; ?>
        <?php if ($offerCascade): ?>
            <div class="form-check mb-3 text-start">
                <input class="form-check-input" type="checkbox" name="cascade" id="cascade" checked>
                <label class="form-check-label" for="cascade">ลบข้อมูลที่อ้างอิงแถวนี้ (รีวิว / สูตร / รายการโปรด / กล้อง–เลนส์) ไปด้วย</label>
            </div>
        <?php endif; ?>
        <button type="submit" name="confirm" class="btn btn-danger"><?= $offerCascade ? 'Delete with related data' : 'Delete' ?></button>
        <a href="index.php?t=<?= h($t) ?>" class="btn btn-secondary">Cancel</a>
    </form>
</div>
<?php page_foot();
