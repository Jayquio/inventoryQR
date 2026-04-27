<?php
require __DIR__ . '/db.php';
$in = json_input();

$name = trim($in['name'] ?? '');
$serialNumber = trim($in['serialNumber'] ?? '');
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
if (!in_array($type, ['instrument','reagent','consumable'], true)) $type = 'instrument';
if ($type === 'reagent' || $type === 'consumable') {
  $serialNumber = '';
}

function serial_exists($pdo, $serial) {
  $q = $pdo->prepare('SELECT 1 FROM instruments WHERE serial_number = ? LIMIT 1');
  $q->execute([$serial]);
  return (bool)$q->fetch();
}

function make_serial_prefix($name) {
  $letters = preg_replace('/[^A-Za-z0-9]/', '', strtoupper($name));
  if ($letters === '') return 'INST';
  return substr($letters, 0, min(4, strlen($letters)));
}

if ($type === 'instrument' && $serialNumber === '') {
  $prefix = make_serial_prefix($name);
  $datePart = date('Ymd');
  for ($i = 0; $i < 8; $i++) {
    $candidate = $prefix . '-' . $datePart . '-' . str_pad((string)random_int(0, 9999), 4, '0', STR_PAD_LEFT);
    if (!serial_exists($pdo, $candidate)) {
      $serialNumber = $candidate;
      break;
    }
  }
  if ($serialNumber === '') {
    json_out(['error' => 'serial_generation_failed'], 500);
  }
}

$chk = $pdo->prepare('SELECT name FROM instruments WHERE name = ?');
$chk->execute([$name]);
if ($chk->fetch()) json_out(['error' => 'name_exists'], 409);

$ins = $pdo->prepare('INSERT INTO instruments (`type`, name, serial_number, category, quantity, available, status, `condition`, location, last_maintenance)
                      VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)');
$ins->execute([$type, $name, $serialNumber ?: null, $category, $quantity, $available, $status, $condition, $location, $lastMaintenance ?: null]);

try {
  $qi = $pdo->prepare('INSERT INTO instrument_qr (instrument_name, type, payload) VALUES (?, ?, ?)');
  $qi->execute([$name, 'borrow',  'QR|type=borrow;name='  . $name]);
  $qi->execute([$name, 'receive', 'QR|type=receive;name=' . $name]);
  $qi->execute([$name, 'return',  'QR|type=return;name='  . $name]);
} catch (Throwable $e) {
  // ignore if instrument_qr table not present
}

json_out(['ok' => true]);
