<?php
require __DIR__ . '/db.php';

$instrumentFilter = $_GET['instrument_name'] ?? '';

$sql = 'SELECT id,
               instrument_name AS instrumentName,
               technician,
               type,
               notes,
               status,
               DATE_FORMAT(performed_at, "%Y-%m-%d") AS performedAt,
               created_at AS createdAt
        FROM maintenance';

if ($instrumentFilter !== '') {
    $stmt = $pdo->prepare($sql . ' WHERE instrument_name = ? ORDER BY performed_at DESC, id DESC');
    $stmt->execute([$instrumentFilter]);
} else {
    $stmt = $pdo->query($sql . ' ORDER BY performed_at DESC, id DESC');
}

json_out(['ok' => true, 'data' => $stmt->fetchAll()]);
