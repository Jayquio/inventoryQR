<?php
require __DIR__ . '/db.php';
ensure_notifications_table($pdo);

$recipient = $_GET['recipient'] ?? 'All';
$limit = (int)($_GET['limit'] ?? 50);

try {
    if ($recipient === 'All') {
        $stmt = $pdo->prepare("SELECT * FROM notifications ORDER BY created_at DESC LIMIT $limit");
        $stmt->execute();
    } else {
        $stmt = $pdo->prepare("SELECT * FROM notifications WHERE recipient = :recipient OR recipient = 'All' ORDER BY created_at DESC LIMIT $limit");
        $stmt->bindValue(':recipient', $recipient, PDO::PARAM_STR);
        $stmt->execute();
    }
    
    $data = $stmt->fetchAll(PDO::FETCH_ASSOC);
    
    // Format data for frontend (camelCase)
    $formatted = array_map(function($n) {
        return [
            'id' => $n['id'],
            'title' => $n['title'],
            'message' => $n['message'],
            'type' => $n['type'],
            'recipient' => $n['recipient'],
            'course' => $n['course'],
            'read' => (bool)$n['is_read'],
            'priority' => $n['priority'],
            'timestamp' => $n['created_at']
        ];
    }, $data);

    json_out(['ok' => true, 'data' => $formatted]);
} catch (PDOException $e) {
    // Graceful Bypass: If the table doesn't exist, return an empty list instead of crashing.
    if ($e->getCode() == '42S02') {
        json_out(['ok' => true, 'data' => []]);
    }
    json_out(['ok' => false, 'error' => $e->getMessage()], 500);
}
