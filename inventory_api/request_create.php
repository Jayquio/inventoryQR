<?php
require __DIR__ . '/db.php';

$in = json_input();

// Log incoming request for debugging (optional, can be removed)
// file_put_contents('request_log.txt', date('Y-m-d H:i:s') . ' ' . json_encode($in) . PHP_EOL, FILE_APPEND);

$student = trim($in['studentName'] ?? ($in['student_name'] ?? ''));
$purpose = trim($in['purpose'] ?? '');
$course = trim($in['course'] ?? '');
$neededAt = trim($in['neededAt'] ?? ($in['needed_at'] ?? ''));
$batchId = trim($in['batch_id'] ?? '');

// Ensure we have a list of items. 
// Support both the new 'items' array and the old single-field format.
$items = $in['items'] ?? [];
if (empty($items)) {
    $singleInstrument = trim($in['instrumentName'] ?? ($in['instrument_name'] ?? ''));
    if ($singleInstrument !== '') {
        $items = [
            [
                'instrumentName' => $singleInstrument,
                'quantity' => (int)($in['quantity'] ?? 1),
                'serialNumber' => trim($in['serialNumber'] ?? ($in['serial_number'] ?? '')),
            ]
        ];
    }
}

// Basic validation
if ($student === '') {
    json_out(['error' => 'missing_student_name', 'message' => 'Student name is required'], 400);
}

if (empty($items)) {
    json_out(['error' => 'missing_items', 'message' => 'At least one item is required'], 400);
}

// Course validation
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

// Date validation
if ($neededAt !== '') {
    $neededTs = strtotime($neededAt);
    if ($neededTs === false) {
        json_out(['error' => 'invalid_needed_at'], 400);
    }

    // Enforce 3-day buffer policy (today not counted).
    $todayMidnight = strtotime('today midnight');
    $minTs = $todayMidnight + (4 * 24 * 60 * 60); 
    
    if ($neededTs < $minTs) {
        json_out(['error' => 'needed_at_must_be_at_least_3_days_ahead_excluding_today'], 400);
    }
}

$pdo->beginTransaction();
$requestIds = [];

try {
    foreach ($items as $item) {
        $instrument = trim($item['instrumentName'] ?? ($item['instrument_name'] ?? ''));
        $quantity = (int)($item['quantity'] ?? 1);
        $serialNumber = trim($item['serialNumber'] ?? ($item['serial_number'] ?? ''));
        
        if ($instrument === '') continue;
        if ($quantity <= 0) $quantity = 1;

        // Ensure request references a valid instrument.
        $inst = $pdo->prepare('SELECT name, `type` FROM instruments WHERE name = ?');
        $inst->execute([$instrument]);
        $instRow = $inst->fetch();
        
        if (!$instRow) {
            $pdo->rollBack();
            json_out(['error' => 'instrument_not_found', 'details' => $instrument], 404);
        }
        
        $instrumentType = strtolower(trim($instRow['type'] ?? 'instrument'));

        // Persist serial number detail in purpose text when provided.
        $itemPurpose = $purpose;
        if ($serialNumber !== '' && $instrumentType !== 'reagent') {
            $itemPurpose = trim($itemPurpose . ' [SN: ' . $serialNumber . ']');
        }

        $sql = 'INSERT INTO requests (batch_id, student_name, instrument_name, quantity, purpose, course, needed_at) VALUES (?, ?, ?, ?, ?, ?, ?)';
        $stmt = $pdo->prepare($sql);
        $stmt->execute([
            $batchId ?: null, 
            $student, 
            $instrument, 
            $quantity, 
            $itemPurpose ?: null, 
            $course ?: null, 
            $neededAt ?: null
        ]);
        $requestIds[] = $pdo->lastInsertId();
    }

    if (empty($requestIds)) {
        $pdo->rollBack();
        json_out(['error' => 'no_valid_items_processed'], 400);
    }

    // Create Admin Notification
    try {
        $notifSql = "INSERT INTO notifications (title, message, type, recipient, course, priority) VALUES (?, ?, ?, ?, ?, ?)";
        $notifStmt = $pdo->prepare($notifSql);
        $itemCount = count($requestIds);
        $msg = "$student submitted a request for $itemCount item(s). Purpose: $purpose";
        $notifStmt->execute([
            'New Borrow Request',
            $msg,
            'request',
            'Admin',
            $course ?: null,
            'medium'
        ]);
    } catch (Throwable $e) {
        // Silently fail if notifications table is not ready yet
    }

    $pdo->commit();
    json_out(['ok' => true, 'request_ids' => $requestIds]);

} catch (Exception $e) {
    if ($pdo->inTransaction()) {
        $pdo->rollBack();
    }
    json_out(['error' => 'server_error', 'details' => $e->getMessage()], 500);
}
