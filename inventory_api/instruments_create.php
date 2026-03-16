<?php
require __DIR__ . '/db.php';
$in = json_input();

$name = trim($in['name'] ?? '');
$type = strtolower(trim($in['type'] ?? 'instrument'));
$category = trim($in['category'] ?? '');
$quantity = (int)($in['quantity'] ?? 0);
$available = (int)($in['available'] ?? 0);
$status = trim($in['status'] ?? '');
$condition = trim($in['condition'] ?? '');
$location = trim($in['location'] ?? '');
$lastMaintenance = trim($in['lastMaintenance'] ?? '');

if ($name === '' || $quantity < 0 || $available < 0 || $available > $quantity) {
  json_out(['error' => 'invalid_fields'], 400);
}
if (!in_array($type, ['instrument','reagent'], true)) $type = 'instrument';

$chk = $pdo->prepare('SELECT name FROM instruments WHERE name = ?');
$chk->execute([$name]);
if ($chk->fetch()) json_out(['error' => 'name_exists'], 409);

$ins = $pdo->prepare('INSERT INTO instruments (`type`, name, category, quantity, available, status, `condition`, location, last_maintenance)
                      VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)');
$ins->execute([$type, $name, $category, $quantity, $available, $status, $condition, $location, $lastMaintenance ?: null]);

try {
  $qi = $pdo->prepare('INSERT INTO instrument_qr (instrument_name, type, payload) VALUES (?, ?, ?)');
  $qi->execute([$name, 'borrow',  'QR|type=borrow;name='  . $name]);
  $qi->execute([$name, 'receive', 'QR|type=receive;name=' . $name]);
  $qi->execute([$name, 'return',  'QR|type=return;name='  . $name]);
} catch (Throwable $e) {
  // ignore if instrument_qr table not present
}

json_out(['ok' => true]);
