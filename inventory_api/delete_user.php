<?php
require __DIR__ . '/db.php';

$in = json_input();
$username = trim($in['username'] ?? ($_POST['username'] ?? $_GET['username'] ?? ''));

if ($username === '') json_out(['error' => 'missing_username'], 400);

$del = $pdo->prepare('DELETE FROM users WHERE username = ?');
$del->execute([$username]);

if ($del->rowCount() === 0) json_out(['error' => 'not_found'], 404);
json_out(['ok' => true]);