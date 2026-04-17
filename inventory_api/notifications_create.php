<?php
require __DIR__ . '/db.php';
ensure_notifications_table($pdo);

$in = json_input();
$title = $in['title'] ?? 'Notice';
$message = $in['message'] ?? '';
$type = $in['type'] ?? 'info';
$recipient = $in['recipient'] ?? 'All';
$priority = $in['priority'] ?? 'medium';

$stmt = $pdo->prepare("INSERT INTO notifications (title, message, type, recipient, priority) VALUES (?, ?, ?, ?, ?)");
$stmt->execute([$title, $message, $type, $recipient, $priority]);

json_out(['ok' => true]);
