<?php
require __DIR__ . '/db.php';
$in = json_input();
$student = trim($in['studentName'] ?? ($in['student_name'] ?? ''));
$instrument = trim($in['instrumentName'] ?? ($in['instrument_name'] ?? ''));
$purpose = trim($in['purpose'] ?? '');
$course = trim($in['course'] ?? '');
$neededAt = trim($in['neededAt'] ?? ($in['needed_at'] ?? ''));

if ($student === '' || $instrument === '') json_out(['error' => 'missing_fields'], 400);

$sql = 'INSERT INTO requests (student_name, instrument_name, purpose, course, needed_at) VALUES (?, ?, ?, ?, ?)';
$stmt = $pdo->prepare($sql);
$stmt->execute([$student, $instrument, $purpose ?: null, $course ?: null, $neededAt ?: null]);

json_out(['ok' => true, 'request_id' => $pdo->lastInsertId()]);
