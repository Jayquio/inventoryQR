<?php
require __DIR__ . '/db.php';
$in = json_input();
$type = strtolower(trim($in['type'] ?? ''));
$instrument = trim($in['instrument_name'] ?? '');
$processedBy = trim($in['processed_by'] ?? '');

if (!in_array($type, ['receive','return'], true) || $instrument === '' || $processedBy === '') json_out(['error' => 'invalid_input'], 400);

$pdo->beginTransaction();
try {
  $sel = $pdo->prepare('SELECT quantity, available FROM instruments WHERE name = ? FOR UPDATE');
  $sel->execute([$instrument]);
  $row = $sel->fetch();
  if (!$row) { $pdo->rollBack(); json_out(['error' => 'instrument_not_found'], 404); }

  $qty = (int)$row['quantity'];
  $avail = (int)$row['available'];

  if ($type === 'receive') {
    if ($avail <= 0) { $pdo->rollBack(); json_out(['error' => 'no_available_to_decrement'], 409); }
    $avail--;
  } else {
    if ($avail >= $qty) { $pdo->rollBack(); json_out(['error' => 'already_full'], 409); }
    $avail++;
  }

  $upd = $pdo->prepare('UPDATE instruments SET available = ? WHERE name = ?');
  $upd->execute([$avail, $instrument]);

  $ins = $pdo->prepare('INSERT INTO transactions (instrument_name, type, processed_by) VALUES (?, ?, ?)');
  $ins->execute([$instrument, $type, $processedBy]);

  $pdo->commit();
  json_out(['ok' => true, 'available' => $avail]);
} catch (Throwable $e) {
  $pdo->rollBack();
  json_out(['error' => 'tx_failed'], 500);
}