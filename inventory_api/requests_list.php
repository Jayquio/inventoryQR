<?php
require __DIR__ . '/db.php';

$studentFilter = $_GET['student_name'] ?? '';

$sql = 'SELECT id,
               student_name AS studentName,
               instrument_name AS instrumentName,
               purpose,
               course,
               needed_at AS neededAt,
               status,
               returned_by AS returnedBy,
               returned_at AS returnedAt
        FROM requests';

if ($studentFilter !== '') {
    $stmt = $pdo->prepare($sql . ' WHERE student_name = ? ORDER BY id DESC');
    $stmt->execute([$studentFilter]);
} else {
    $stmt = $pdo->query($sql . ' ORDER BY id DESC');
}

json_out(['ok' => true, 'data' => $stmt->fetchAll()]);
