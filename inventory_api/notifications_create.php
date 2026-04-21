<?php
require __DIR__ . '/db.php';
ensure_notifications_table($pdo);

$in = json_input();
$title = $in['title'] ?? 'Update';
$message = $in['message'] ?? '';
$type = $in['type'] ?? 'info';
$recipient = $in['recipient'] ?? 'All';
$priority = $in['priority'] ?? 'medium';
$course = $in['course'] ?? null;
$is_override = isset($in['is_override']) ? (int)$in['is_override'] : 0;
$original_quantity = $in['original_quantity'] ?? null;
$override_quantity = $in['override_quantity'] ?? null;
$override_reason = $in['override_reason'] ?? null;

$stmt = $pdo->prepare("INSERT INTO notifications (title, message, type, recipient, priority, course, is_override, original_quantity, override_quantity, override_reason) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)");
$stmt->execute([$title, $message, $type, $recipient, $priority, $course, $is_override, $original_quantity, $override_quantity, $override_reason]);

json_out(['ok' => true, 'id' => $pdo->lastInsertId()]);
