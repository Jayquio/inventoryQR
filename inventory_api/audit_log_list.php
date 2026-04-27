<?php
require __DIR__ . '/db.php';

try {
    $stmt = $pdo->query("SELECT * FROM audit_logs ORDER BY timestamp DESC LIMIT 100");
    $logs = $stmt->fetchAll();
    json_out(['ok' => true, 'data' => $logs]);
} catch (Exception $e) {
    json_out(['ok' => false, 'error' => $e->getMessage()], 500);
}
