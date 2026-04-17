<?php
require __DIR__ . '/db.php';
$in = json_input();
$name = trim($in['name'] ?? '');

if ($name === '') {
    json_out(['error' => 'invalid_name'], 400);
}

// Optional: check if related transactions or requests exist. 
// We will just do a standard delete or a cascading delete if foreign keys are set.
$del = $pdo->prepare('DELETE FROM instruments WHERE name = ?');
$del->execute([$name]);

if ($del->rowCount() === 0) json_out(['error' => 'not_found'], 404);
json_out(['ok' => true]);
