<?php
require __DIR__ . '/db.php';
$in = json_input();
$id = (int)($in['id'] ?? 0);

if ($id <= 0) json_out(['error' => 'invalid_id'], 400);

$del = $pdo->prepare('DELETE FROM requests WHERE id = ?');
$del->execute([$id]);

if ($del->rowCount() === 0) json_out(['error' => 'not_found'], 404);
json_out(['ok' => true]);
