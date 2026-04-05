<?php
require __DIR__ . '/db.php';

$in = json_input();
$username = trim($in['username'] ?? ($_POST['username'] ?? $_GET['username'] ?? ''));
$email    = trim($in['email'] ?? ($_POST['email'] ?? $_GET['email'] ?? ''));
$password = $in['password'] ?? ($_POST['password'] ?? $_GET['password'] ?? '');
$role     = strtolower(trim($in['role'] ?? ($_POST['role'] ?? $_GET['role'] ?? '')));

// Normalize legacy 'staff' to 'teacher' for a smooth transition
if ($role === 'staff') {
  error_log("Normalized role 'staff' to 'teacher' for user '$username'");
  $role = 'teacher';
}

// Validate strictly against the new roles
if ($username === '' || $password === '' || !in_array($role, ['admin','teacher','student'], true)) {
  json_out(['error' => 'missing_or_invalid_fields'], 400);
}

// Admin is exempt from email requirement, but others must have a JMC email
if ($role !== 'admin' && ($email === '' || !str_ends_with($email, '@jmc.edu.ph'))) {
    json_out(['error' => 'invalid_jmc_email'], 400);
}

$stmt = $pdo->prepare('SELECT id FROM users WHERE username = ?');
$stmt->execute([$username]);
if ($stmt->fetch()) {
  json_out(['error' => 'username_taken'], 409);
}

if ($email !== '') {
    $stmt = $pdo->prepare('SELECT id FROM users WHERE email = ?');
    $stmt->execute([$email]);
    if ($stmt->fetch()) {
        json_out(['error' => 'email_taken'], 409);
    }
}

$ins = $pdo->prepare('INSERT INTO users (username, password, role, email) VALUES (?, ?, ?, ?)');
$ins->execute([$username, $password, $role, $email]);

json_out(['ok' => true, 'id' => $pdo->lastInsertId(), 'username' => $username, 'role' => $role, 'email' => $email]);
