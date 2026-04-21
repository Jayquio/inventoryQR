<?php
require __DIR__ . '/db.php';

// Authorization: only admin/superadmin can run this fix
$user = $_GET['user'] ?? '';
$roleQ = $pdo->prepare('SELECT role FROM users WHERE username = ? LIMIT 1');
$roleQ->execute([$user]);
$roleRow = $roleQ->fetch();
$role = strtolower(trim((string)($roleRow['role'] ?? '')));
if (!in_array($role, ['admin', 'superadmin'], true)) {
    die('Forbidden: Admin access required');
}

echo "Starting database schema fix...<br>";

function addColumn($pdo, $table, $column, $definition) {
    $check = $pdo->query("SHOW COLUMNS FROM `$table` LIKE '$column'");
    if ($check->fetch() === false) {
        echo "Adding column `$column` to table `$table`... ";
        $pdo->exec("ALTER TABLE `$table` ADD COLUMN `$column` $definition");
        echo "Done.<br>";
    } else {
        echo "Column `$column` already exists in table `$table`.<br>";
    }
}

try {
    // 1. Ensure `batch_id` exists in `requests`
    addColumn($pdo, 'requests', 'batch_id', 'VARCHAR(64) DEFAULT NULL');
    
    // 2. Ensure override columns exist in `requests`
    addColumn($pdo, 'requests', 'is_override', 'TINYINT(1) DEFAULT 0');
    addColumn($pdo, 'requests', 'original_quantity', 'INT DEFAULT 0');
    addColumn($pdo, 'requests', 'override_reason', 'TEXT DEFAULT NULL');

    echo "<br><b>Database schema is up to date!</b>";
} catch (Exception $e) {
    echo "<br><b>Error:</b> " . $e->getMessage();
}
