<?php
require __DIR__ . '/db.php';
ensure_notifications_table($pdo);

$recipient = $_GET['recipient'] ?? 'All';
$username = $_GET['username'] ?? '';
$limit = (int)($_GET['limit'] ?? 50);
if ($limit < 1) {
    $limit = 50;
}
if ($limit > 200) {
    $limit = 200;
}

/**
 * Emit ISO-8601 with +08:00 so Flutter sorts/parses consistently (avoids mixed
 * "YYYY-MM-DD HH:MM:SS" vs client ISO strings in one list).
 */
function format_notification_timestamp(?string $sqlDatetime): string
{
    if ($sqlDatetime === null || $sqlDatetime === '') {
        $now = new DateTime('now', new DateTimeZone('Asia/Manila'));

        return $now->format(DateTime::ATOM);
    }
    $dt = DateTime::createFromFormat('Y-m-d H:i:s', $sqlDatetime, new DateTimeZone('Asia/Manila'));
    if ($dt === false) {
        $ts = strtotime($sqlDatetime);
        if ($ts === false) {
            return $sqlDatetime;
        }
        $dt = new DateTime('@' . $ts);
        $dt->setTimezone(new DateTimeZone('Asia/Manila'));
    }

    return $dt->format(DateTime::ATOM);
}

try {
    if ($recipient === 'Admin' || $recipient === 'Superadmin') {
        $stmt = $pdo->prepare("SELECT * FROM notifications WHERE recipient IN ('Admin', 'All') ORDER BY created_at DESC LIMIT :limit");
        $stmt->bindValue(':limit', $limit, PDO::PARAM_INT);
        $stmt->execute();
    } else {
        $stmt = $pdo->prepare("SELECT * FROM notifications WHERE recipient = :recipient OR recipient = 'All' OR recipient = :username ORDER BY created_at DESC LIMIT :limit");
        $stmt->bindValue(':recipient', $recipient, PDO::PARAM_STR);
        $stmt->bindValue(':username', $username, PDO::PARAM_STR);
        $stmt->bindValue(':limit', $limit, PDO::PARAM_INT);
        $stmt->execute();
    }

    $data = $stmt->fetchAll(PDO::FETCH_ASSOC);

    $formatted = array_map(function ($n) {
        return [
            'id' => $n['id'],
            'title' => $n['title'],
            'message' => $n['message'],
            'type' => $n['type'],
            'recipient' => $n['recipient'],
            'course' => $n['course'],
            'read' => (bool)$n['is_read'],
            'priority' => $n['priority'],
            'timestamp' => format_notification_timestamp($n['created_at'] ?? null),
            'isOverride' => isset($n['is_override']) ? (bool)$n['is_override'] : false,
            'originalQuantity' => isset($n['original_quantity']) ? (int)$n['original_quantity'] : null,
            'overrideQuantity' => isset($n['override_quantity']) ? (int)$n['override_quantity'] : null,
            'overrideReason' => $n['override_reason'] ?? null,
            'requestId' => $n['request_id'] ?? null,
        ];
    }, $data);

    json_out(['ok' => true, 'data' => $formatted]);
} catch (PDOException $e) {
    if ($e->getCode() == '42S02') {
        json_out(['ok' => true, 'data' => []]);
    }
    json_out(['ok' => false, 'error' => $e->getMessage()], 500);
}
