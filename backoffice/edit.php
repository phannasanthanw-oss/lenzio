<?php
include "lib.php";
$t = current_table();
$cols = columns($pdo, $t);
$pk = pk_columns($pdo, $t);
$error = '';
$key = $_GET['pk'] ?? $_POST['pk'] ?? [];
if (!is_array($key) || array_diff($pk, array_keys($key))) { header("Location: index.php?t=$t"); exit; }

$where = implode(' AND ', array_map(fn($c) => qi($c) . " = :pk_$c", $pk));
$args = [];
foreach ($pk as $c) $args[":pk_$c"] = $key[$c];

if (isset($_POST['submit'])) {
    $data = posted_values($cols, $pk);   // primary keys are not edited
    try {
        if ($data) {
            $set = implode(', ', array_map(fn($k) => qi($k) . " = :v_$k", array_keys($data)));
            $st = $pdo->prepare("UPDATE " . qi($t) . " SET $set WHERE $where RETURNING *");
            $params = $args;
            foreach ($data as $k => $v) $params[":v_$k"] = $v;
            $st->execute($params);
            if ($row = $st->fetch()) resync($pdo, $t, $row);
        }
        header("Location: index.php?t=$t&msg=" . urlencode("Data updated successfully"));
        exit;
    } catch (PDOException $e) {
        $error = friendly_error($e);
    }
}

$st = $pdo->prepare("SELECT * FROM " . qi($t) . " WHERE $where");
$st->execute($args);
$row = $st->fetch();
if (!$row) { header("Location: index.php?t=$t&ok=0&msg=" . urlencode("ไม่พบแถวนี้")); exit; }
page_head("Edit", $t);
?>
<div class="text-center mb-4">
    <h3>Edit — <?= h(TABLES[$t]) ?> <small class="text-muted">(<?= h($t) ?>)</small></h3>
    <p class="text-muted">Click update after changing any information. Primary keys cannot be edited.</p>
</div>
<?php if ($error): ?><div class="alert alert-danger"><?= h($error) ?></div><?php endif; ?>
<div class="container d-flex justify-content-center">
    <form method="post" style="width:50vw; min-width:300px;">
        <input type="hidden" name="t" value="<?= h($t) ?>">
        <?php foreach ($pk as $c): ?><input type="hidden" name="pk[<?= h($c) ?>]" value="<?= h($key[$c]) ?>"><?php endforeach; ?>
        <?php foreach ($cols as $c): $n = $c['column_name']; $isPk = in_array($n, $pk); ?>
            <div class="mb-3">
                <label class="form-label"><?= h($n) ?> <small class="text-muted">(<?= h($c['data_type']) ?><?= $isPk ? ', PK' : '' ?>)</small></label>
                <?= field($c, $_POST[$n] ?? $row[$n], $isPk) ?>
            </div>
        <?php endforeach; ?>
        <div class="mb-3">
            <button type="submit" class="btn btn-success" name="submit">Update</button>
            <a href="index.php?t=<?= h($t) ?>" class="btn btn-danger">Cancel</a>
        </div>
    </form>
</div>
<?php page_foot();
