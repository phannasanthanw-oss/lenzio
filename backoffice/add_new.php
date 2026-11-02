<?php
include "lib.php";
$t = current_table();
$cols = columns($pdo, $t);
$error = '';

if (isset($_POST['submit'])) {
    $data = posted_values($cols);
    try {
        if ($data) {
            $names = implode(',', array_map('qi', array_keys($data)));
            $marks = implode(',', array_map(fn($k) => ':' . $k, array_keys($data)));
            $st = $pdo->prepare("INSERT INTO " . qi($t) . " ($names) VALUES ($marks) RETURNING *");
            $st->execute(array_combine(array_map(fn($k) => ':' . $k, array_keys($data)), array_values($data)));
        } else {
            $st = $pdo->query("INSERT INTO " . qi($t) . " DEFAULT VALUES RETURNING *");
        }
        resync($pdo, $t, $st->fetch());
        header("Location: index.php?t=$t&msg=" . urlencode("New record created successfully"));
        exit;
    } catch (PDOException $e) {
        $error = friendly_error($e);
    }
}
page_head("Add New", $t);
?>
<div class="text-center mb-4">
    <h3>Add New — <?= h(TABLES[$t]) ?> <small class="text-muted">(<?= h($t) ?>)</small></h3>
    <p class="text-muted">Complete the form below. Auto-numbered ids are filled in by the database.</p>
</div>
<?php if ($error): ?><div class="alert alert-danger"><?= h($error) ?></div><?php endif; ?>
<div class="container d-flex justify-content-center">
    <form method="post" style="width:50vw; min-width:300px;">
        <input type="hidden" name="t" value="<?= h($t) ?>">
        <?php foreach ($cols as $c): if ($c['is_identity'] === 'YES') continue; ?>
            <div class="mb-3">
                <label class="form-label"><?= h($c['column_name']) ?> <small class="text-muted">(<?= h($c['data_type']) ?><?= $c['is_nullable'] === 'NO' && $c['column_default'] === null ? ', required' : '' ?>)</small></label>
                <?= field($c, $_POST[$c['column_name']] ?? '') ?>
            </div>
        <?php endforeach; ?>
        <div class="mb-3">
            <button type="submit" class="btn btn-success" name="submit">Save</button>
            <a href="index.php?t=<?= h($t) ?>" class="btn btn-danger">Cancel</a>
        </div>
    </form>
</div>
<?php page_foot();
