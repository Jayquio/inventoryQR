<?php
require __DIR__ . '/db.php';

$in = json_input();
$id = $in['id'] ?? null;
$username = $in['username'] ?? null;
$all = $in['all'] ?? false;

try {
    if ($all && $username) {
        // Fetch the user's role
        $roleStmt = $pdo->prepare("SELECT role FROM users WHERE username = :username LIMIT 1");
        $roleStmt->execute([':username' => $username]);
        $userRole = $roleStmt->fetchColumn();

        if ($userRole === 'admin' || $userRole === 'superadmin') {
            // Admins mark everything as read
            $stmt = $pdo->prepare("UPDATE notifications SET is_read = 1");
            $stmt->execute();
        } else {
            // Others mark only their relevant notifications
            $roleCapitalized = ucfirst($userRole); // 'Teacher' or 'Student'
            $stmt = $pdo->prepare("UPDATE notifications SET is_read = 1 WHERE recipient = :username OR recipient = 'All' OR recipient = :role OR recipient = :roleCap");
            $stmt->execute([
                ':username' => $username,
                ':role' => $userRole,
                ':roleCap' => $roleCapitalized
            ]);
        }
        json_out(['ok' => true, 'message' => 'All notifications marked as read']);
    } elseif ($id && $username) {
        // Mark a specific notification as read, ensuring it belongs to the user or their role
        $roleStmt = $pdo->prepare("SELECT role FROM users WHERE username = :username LIMIT 1");
        $roleStmt->execute([':username' => $username]);
        $userRole = $roleStmt->fetchColumn();
        $roleCap = ucfirst($userRole);

        if ($userRole === 'admin' || $userRole === 'superadmin') {
            $stmt = $pdo->prepare("UPDATE notifications SET is_read = 1 WHERE id = :id");
            $stmt->execute([':id' => $id]);
        } else {
            $stmt = $pdo->prepare("UPDATE notifications SET is_read = 1 WHERE id = :id AND (recipient = :username OR recipient = 'All' OR recipient = :role OR recipient = :roleCap)");
            $stmt->execute([
                ':id' => $id,
                ':username' => $username,
                ':role' => $userRole,
                ':roleCap' => $roleCap
            ]);
        }
        json_out(['ok' => true, 'message' => 'Notification marked as read']);
    } elseif ($id) {
        // Fallback for when username isn't provided (legacy/admin)
        $stmt = $pdo->prepare("UPDATE notifications SET is_read = 1 WHERE id = :id");
        $stmt->execute([':id' => $id]);
        json_out(['ok' => true, 'message' => 'Notification marked as read']);
    } else {
        json_out(['ok' => false, 'error' => 'missing_parameters'], 400);
    }
} catch (PDOException $e) {
    json_out(['ok' => false, 'error' => $e->getMessage()], 500);
}
