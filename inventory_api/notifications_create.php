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
    $request_id = isset($in['request_id']) ? (int)$in['request_id'] : null;

    // Optional: Mark old notifications for the same request as read/stale
    if ($request_id && $recipient !== 'All') {
        $pdo->prepare("UPDATE notifications SET is_read = 1 WHERE request_id = ? AND recipient = ?")
            ->execute([$request_id, $recipient]);
    }

    $stmt = $pdo->prepare("INSERT INTO notifications (title, message, type, recipient, priority, course, is_override, original_quantity, override_quantity, override_reason, request_id) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)");
    $stmt->execute([$title, $message, $type, $recipient, $priority, $course, $is_override, $original_quantity, $override_quantity, $override_reason, $request_id]);
    json_out(['ok' => true, 'id' => $pdo->lastInsertId()]);
