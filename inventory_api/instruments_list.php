<?php
require __DIR__ . '/db.php';

try {
    $stmt = $pdo->query('SELECT `type`, name, serial_number AS serialNumber, category, quantity, available, status, `condition`, location, DATE_FORMAT(last_maintenance, "%Y-%m-%d") AS lastMaintenance FROM instruments ORDER BY name');
    json_out(['ok' => true, 'data' => $stmt->fetchAll()]);
} catch (PDOException $e) {
    json_out(['ok' => false, 'error' => 'Query failed: ' . $e->getMessage()], 500);
}
