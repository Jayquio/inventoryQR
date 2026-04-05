<?php
require __DIR__ . '/db.php';

$in = json_input();
$username = trim($in['username'] ?? ($_POST['username'] ?? $_GET['username'] ?? ''));
$password = $in['password'] ?? ($_POST['password'] ?? $_GET['password'] ?? '');

if ($username === '' || $password === '') {
  json_out(['error' => 'missing_fields'], 400);
}

$stmt = $pdo->prepare('SELECT id, username, email, password, role FROM users WHERE username = ? OR email = ?');
$stmt->execute([$username, $username]);
$row = $stmt->fetch();

if (!$row || $password !== $row['password']) {
  json_out(['error' => 'invalid_credentials'], 401);
}

json_out(['ok' => true, 'username' => $row['username'], 'email' => $row['email'], 'role' => $row['role']]);