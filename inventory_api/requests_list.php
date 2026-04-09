<?php
require __DIR__ . '/db.php';

$studentFilter = $_GET['student_name'] ?? '';

$sql = 'SELECT r.id,
               student_name AS studentName,
               instrument_name AS instrumentName,
               r.quantity,
               r.purpose,
               r.course,
               r.needed_at AS neededAt,
               r.status,
               r.returned_by AS returnedBy,
               r.returned_at AS returnedAt,
               r.is_override AS isOverride,
               r.original_quantity AS originalQuantity,
               r.override_reason AS overrideReason,
               COALESCE(i.type, \'instrument\') AS instrumentType
        FROM requests r
        LEFT JOIN instruments i ON i.name = r.instrument_name';

if ($studentFilter !== '') {
    $stmt = $pdo->prepare($sql . ' WHERE r.student_name = ? ORDER BY r.id DESC');
    $stmt->execute([$studentFilter]);
} else {
    $stmt = $pdo->query($sql . ' ORDER BY r.id DESC');
}

json_out(['ok' => true, 'data' => $stmt->fetchAll()]);
