<?php
require __DIR__ . '/db.php';

$studentFilter = $_GET['student_name'] ?? '';

// Check if override columns exist to maintain backward compatibility
$checkCols = $pdo->query("SHOW COLUMNS FROM requests LIKE 'is_override'");
$hasOverride = $checkCols->fetch() !== false;

$overrideFields = $hasOverride 
    ? "r.is_override AS isOverride, r.original_quantity AS originalQuantity, r.override_reason AS overrideReason,"
    : "0 AS isOverride, r.quantity AS originalQuantity, '' AS overrideReason,";

$sql = "SELECT r.id,
               r.batch_id AS batchId,
               r.student_name AS studentName,
               r.instrument_name AS instrumentName,
               r.quantity,
               r.purpose,
               r.course,
               r.needed_at AS neededAt,
               r.status,
               r.returned_by AS returnedBy,
               r.returned_at AS returnedAt,
               $overrideFields
               COALESCE(i.type, 'instrument') AS instrumentType
        FROM requests r
        LEFT JOIN instruments i ON i.name = r.instrument_name";

try {
    if ($studentFilter !== '') {
        $stmt = $pdo->prepare($sql . ' WHERE r.student_name = ? ORDER BY r.id DESC');
        $stmt->execute([$studentFilter]);
    } else {
        $stmt = $pdo->query($sql . ' ORDER BY r.id DESC');
    }

    json_out(['ok' => true, 'data' => $stmt->fetchAll(PDO::FETCH_ASSOC)]);
} catch (PDOException $e) {
    json_out(['ok' => false, 'error' => 'Query failed: ' . $e->getMessage()], 500);
}
