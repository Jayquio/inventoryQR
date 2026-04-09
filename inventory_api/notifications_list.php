<?php
require __DIR__ . '/db.php';

$recipient = $_GET['recipient'] ?? 'All';
$limit = (int)($_GET['limit'] ?? 50);

try {
    if ($recipient === 'All') {
        $stmt = $pdo->prepare("SELECT * FROM notifications ORDER BY created_at DESC LIMIT ?");
        $stmt->execute([$limit]);
    } else {
        $stmt = $pdo->prepare("SELECT * FROM notifications WHERE recipient = ? OR recipient = 'All' ORDER BY created_at DESC LIMIT ?");
        $stmt->execute([$recipient, $limit]);
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
    json_out(['ok' => false, 'error' => $e->getMessage()], 500);
}
