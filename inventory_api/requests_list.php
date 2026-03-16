<?php
require __DIR__ . '/db.php';

$stmt = $pdo->query('SELECT id,
                            student_name AS studentName,
                            instrument_name AS instrumentName,
                            purpose,
                            course,
                            needed_at AS neededAt,
                            status,
                            returned_by AS returnedBy,
                            returned_at AS returnedAt
                     FROM requests
                     ORDER BY id DESC');

json_out(['ok' => true, 'data' => $stmt->fetchAll()]);
