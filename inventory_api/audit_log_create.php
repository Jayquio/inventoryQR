<?php
require __DIR__ . '/db.php';

$in = json_input();
$username = $in['username'] ?? '';
$user_role = $in['user_role'] ?? '';
$action = $in['action'] ?? '';
$type = $in['type'] ?? '';
$details = $in['details'] ?? '';

if (!$username || !$action) {
    json_out(['ok' => false, 'error' => 'missing_fields'], 400);
}

try {
    $stmt = $pdo->prepare("INSERT INTO audit_logs (username, user_role, action, type, details) VALUES (?, ?, ?, ?, ?)");
    $stmt->execute([$username, $user_role, $action, $type, $details]);
    json_out(['ok' => true]);
} catch (Exception $e) {
    json_out(['ok' => false, 'error' => $e->getMessage()], 500);
}
