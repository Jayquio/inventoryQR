<?php
require __DIR__ . '/db.php';
$in = json_input();

$originalName = trim($in['originalName'] ?? '');
$name = trim($in['name'] ?? '');
$type = strtolower(trim($in['type'] ?? 'instrument'));
$category = trim($in['category'] ?? '');
$quantity = (int)($in['quantity'] ?? 0);
$available = (int)($in['available'] ?? 0);
$status = trim($in['status'] ?? '');
$condition = trim($in['condition'] ?? '');
$location = trim($in['location'] ?? '');
$lastMaintenance = trim($in['lastMaintenance'] ?? '');

if ($originalName === '' || $name === '' || $quantity < 0 || $available < 0 || $available > $quantity) {
  json_out(['error' => 'invalid_fields'], 400);
}
if (!in_array($type, ['instrument','reagent'], true)) $type = 'instrument';

$sel = $pdo->prepare('SELECT name FROM instruments WHERE name = ?');
$sel->execute([$originalName]);
if (!$sel->fetch()) json_out(['error' => 'not_found'], 404);

if ($originalName !== $name) {
  $chk = $pdo->prepare('SELECT name FROM instruments WHERE name = ?');
  $chk->execute([$name]);
  if ($chk->fetch()) json_out(['error' => 'name_exists'], 409);
}

$upd = $pdo->prepare('UPDATE instruments
                      SET `type` = ?, name = ?, category = ?, quantity = ?, available = ?, status = ?, `condition` = ?, location = ?, last_maintenance = ?
                      WHERE name = ?');
$upd->execute([$type, $name, $category, $quantity, $available, $status, $condition, $location, $lastMaintenance ?: null, $originalName]);

if ($originalName !== $name) {
  try {
    $uq = $pdo->prepare('UPDATE instrument_qr SET instrument_name = ?, payload = REPLACE(payload, ?, ?) WHERE instrument_name = ?');
    $uq->execute([$name, 'name=' . $originalName, 'name=' . $name, $originalName]);
  } catch (Throwable $e) {
    // ignore if instrument_qr table not present
  }
}

json_out(['ok' => true]);
