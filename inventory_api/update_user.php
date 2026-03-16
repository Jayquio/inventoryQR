<?php
require __DIR__ . '/db.php';

$in = json_input();
$username = trim($in['username'] ?? '');
$password = $in['password'] ?? null;
$role     = isset($in['role']) ? strtolower(trim($in['role'])) : null;

if ($username === '') json_out(['error' => 'missing_username'], 400);
// Normalize legacy 'staff' to 'teacher' and then validate
if ($role === 'staff') {
  error_log("Normalized role 'staff' to 'teacher' for user '$username'");
  $role = 'teacher';
}
if ($role !== null && !in_array($role, ['admin','teacher','student'], true)) json_out(['error' => 'invalid_role'], 400);

$stmt = $pdo->prepare('SELECT id FROM users WHERE username = ?');
$stmt->execute([$username]);
if (!$stmt->fetch()) json_out(['error' => 'not_found'], 404);

$fields = [];
$params = [];
if ($password !== null && $password !== '') {
  $fields[] = 'password = ?';
  $params[] = $password;
}
if ($role !== null && $role !== '') {
  $fields[] = 'role = ?';
  $params[] = $role;
}
if (empty($fields)) json_out(['error' => 'nothing_to_update'], 400);

$params[] = $username;
$sql = 'UPDATE users SET ' . implode(', ', $fields) . ' WHERE username = ?';
$upd = $pdo->prepare($sql);
$upd->execute($params);

json_out(['ok' => true]);
