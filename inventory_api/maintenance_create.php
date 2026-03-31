<?php
require __DIR__ . '/db.php';
$in = json_input();

$instrumentName = trim($in['instrument_name'] ?? '');
$technician     = trim($in['technician'] ?? '');
$type           = trim($in['type'] ?? '');
$notes          = trim($in['notes'] ?? '');
$status         = trim($in['status'] ?? 'Completed');
$performedAt    = trim($in['performed_at'] ?? '');

if ($instrumentName === '' || $technician === '' || $type === '') {
    json_out(['error' => 'missing_fields'], 400);
}

$allowedStatuses = ['Completed', 'Pending', 'In Progress'];
if (!in_array($status, $allowedStatuses, true)) {
    json_out(['error' => 'invalid_status'], 400);
}

// Validate instrument exists
$inst = $pdo->prepare('SELECT name FROM instruments WHERE name = ?');
$inst->execute([$instrumentName]);
if (!$inst->fetch()) {
    json_out(['error' => 'instrument_not_found'], 404);
}

if ($performedAt === '') {
    $performedAt = date('Y-m-d');
}

$sql = 'INSERT INTO maintenance (instrument_name, technician, type, notes, status, performed_at) VALUES (?, ?, ?, ?, ?, ?)';
$stmt = $pdo->prepare($sql);
$stmt->execute([$instrumentName, $technician, $type, $notes ?: null, $status, $performedAt]);

// Also update last_maintenance on the instrument
$upd = $pdo->prepare('UPDATE instruments SET last_maintenance = ? WHERE name = ? AND (last_maintenance IS NULL OR last_maintenance < ?)');
$upd->execute([$performedAt, $instrumentName, $performedAt]);

json_out(['ok' => true, 'maintenance_id' => $pdo->lastInsertId()]);
