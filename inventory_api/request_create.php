<?php
require __DIR__ . '/db.php';
$in = json_input();
$student = trim($in['studentName'] ?? ($in['student_name'] ?? ''));
$instrument = trim($in['instrumentName'] ?? ($in['instrument_name'] ?? ''));
$purpose = trim($in['purpose'] ?? '');
$course = trim($in['course'] ?? '');
$neededAt = trim($in['neededAt'] ?? ($in['needed_at'] ?? ''));

if ($student === '' || $instrument === '') json_out(['error' => 'missing_fields'], 400);

// Ensure request references a valid instrument.
$inst = $pdo->prepare('SELECT name FROM instruments WHERE name = ?');
$inst->execute([$instrument]);
if (!$inst->fetch()) json_out(['error' => 'instrument_not_found'], 404);

if ($course !== '') {
  $allowedCourses = [
    'BS Pharmacy',
    'BS Biology',
    'BS Radiologic Technology',
    'BS Medical Technology/Medical Laboratory Science',
    'BS Nursing',
  ];
  if (!in_array($course, $allowedCourses, true)) {
    json_out(['error' => 'invalid_course'], 400);
  }
}

if ($neededAt !== '' && strtotime($neededAt) === false) {
  json_out(['error' => 'invalid_needed_at'], 400);
}

$sql = 'INSERT INTO requests (student_name, instrument_name, purpose, course, needed_at) VALUES (?, ?, ?, ?, ?)';
$stmt = $pdo->prepare($sql);
$stmt->execute([$student, $instrument, $purpose ?: null, $course ?: null, $neededAt ?: null]);

json_out(['ok' => true, 'request_id' => $pdo->lastInsertId()]);
