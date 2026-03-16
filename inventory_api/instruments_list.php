<?php
require __DIR__ . '/db.php';

$stmt = $pdo->query('SELECT `type`, name, category, quantity, available, status, `condition`, location, DATE_FORMAT(last_maintenance, "%Y-%m-%d") AS lastMaintenance FROM instruments ORDER BY name');
json_out(['ok' => true, 'data' => $stmt->fetchAll()]);
