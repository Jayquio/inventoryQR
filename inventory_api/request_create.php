<?php
require __DIR__ . '/db.php';
$in = json_input();
$student = trim($in['studentName'] ?? ($in['student_name'] ?? ''));
$instrument = trim($in['instrumentName'] ?? ($in['instrument_name'] ?? ''));
$quantity = (int)($in['quantity'] ?? 1);
$purpose = trim($in['purpose'] ?? '');
$serialNumber = trim($in['serialNumber'] ?? ($in['serial_number'] ?? ''));
$course = trim($in['course'] ?? '');
$neededAt = trim($in['neededAt'] ?? ($in['needed_at'] ?? ''));

if ($student === '' || $instrument === '') json_out(['error' => 'missing_fields'], 400);
if ($quantity <= 0) $quantity = 1;
if ($serialNumber !== '' && mb_strlen($serialNumber) > 64) json_out(['error' => 'invalid_serial_number'], 400);

// Ensure request references a valid instrument.
$inst = $pdo->prepare('SELECT name, `type` FROM instruments WHERE name = ?');
$inst->execute([$instrument]);
$instRow = $inst->fetch();
if (!$instRow) json_out(['error' => 'instrument_not_found'], 404);
$instrumentType = strtolower(trim($instRow['type'] ?? 'instrument'));

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

// Enforce 3-day buffer policy (today not counted).
if ($neededAt !== '') {
  $neededTs = strtotime($neededAt);
  if ($neededTs !== false) {
    // Current date at midnight
    $todayMidnight = strtotime('today midnight');
    // First available date is 4 days from today's midnight (Today + 3 days buffer)
    $minTs = $todayMidnight + (4 * 24 * 60 * 60); 
    
    if ($neededTs < $minTs) {
      json_out(['error' => 'needed_at_must_be_at_least_3_days_ahead_excluding_today'], 400);
    }
  }
}

// Persist serial number detail in purpose text when provided.
if ($serialNumber !== '' && $instrumentType !== 'reagent') {
  $purpose = trim($purpose . ' [SN: ' . $serialNumber . ']');
}

$sql = 'INSERT INTO requests (student_name, instrument_name, quantity, purpose, course, needed_at) VALUES (?, ?, ?, ?, ?, ?)';
$stmt = $pdo->prepare($sql);
$stmt->execute([$student, $instrument, $quantity, $purpose ?: null, $course ?: null, $neededAt ?: null]);

json_out(['ok' => true, 'request_id' => $pdo->lastInsertId()]);
