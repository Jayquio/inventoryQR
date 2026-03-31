<?php
require __DIR__ . '/db.php';

$stmt = $pdo->query('SELECT id, username, role FROM users ORDER BY id ASC');
json_out(['ok' => true, 'data' => $stmt->fetchAll()]);
