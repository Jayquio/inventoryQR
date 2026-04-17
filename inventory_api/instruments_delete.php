<?php
require_once 'db.php';

// Only allow POST requests for deletion
if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    json_out(['ok' => false, 'error' => 'Method not allowed'], 405);
}

$input = json_input();
$name = $input['name'] ?? '';

if (empty($name)) {
    json_out(['ok' => false, 'error' => 'Missing instrument name'], 400);
}

try {
    // 1. Check if the instrument exists
    $stmt = $pdo->prepare("SELECT id FROM instruments WHERE name = ?");
    $stmt->execute([$name]);
    $instrument = $stmt->fetch();

    if (!$instrument) {
        json_out(['ok' => false, 'error' => 'Instrument not found'], 404);
    }

    // 2. Optional: Check if there are active requests for this instrument
    // For now, we'll just delete it. In a real system, you might want to prevent 
    // deleting instruments that are currently borrowed.
    
    // 3. Delete the instrument
    $stmt = $pdo->prepare("DELETE FROM instruments WHERE name = ?");
    $stmt->execute([$name]);

    json_out(['ok' => true, 'message' => 'Instrument removed successfully']);
} catch (Throwable $e) {
    json_out(['ok' => false, 'error' => 'delete_failed', 'details' => $e->getMessage()], 500);
}
