<?php
require __DIR__ . '/db.php';
$in = json_input();

$id = (int)($in['id'] ?? 0);
$new_quantity = (int)($in['quantity'] ?? 0);
$user = trim($in['user'] ?? 'system');
$reason = trim($in['reason'] ?? '');

if ($id <= 0 || $new_quantity <= 0) {
  json_out(['error' => 'invalid_input'], 400);
}

// Authorization: only admin/superadmin can override request quantity
$roleQ = $pdo->prepare('SELECT role FROM users WHERE username = ? LIMIT 1');
$roleQ->execute([$user]);
$roleRow = $roleQ->fetch();
$role = strtolower(trim((string)($roleRow['role'] ?? '')));
if (!in_array($role, ['admin', 'superadmin'], true)) {
  json_out(['error' => 'forbidden'], 403);
}

$pdo->beginTransaction();
try {
  $selReq = $pdo->prepare('SELECT status, instrument_name, student_name, course, quantity FROM requests WHERE id = ? FOR UPDATE');
  $selReq->execute([$id]);
  $reqRow = $selReq->fetch();
  
  if (!$reqRow) {
    $pdo->rollBack();
    json_out(['error' => 'not_found'], 404);
  }

  $original_quantity = (int)($reqRow['quantity'] ?? 1);

  // Only allow updating quantity for pending requests to avoid complex stock management
  if ($reqRow['status'] !== 'pending') {
    $pdo->rollBack();
    json_out(['error' => 'only_pending_requests_can_be_overridden'], 409);
  }

  $instrument = $reqRow['instrument_name'];
  $selInst = $pdo->prepare('SELECT quantity FROM instruments WHERE name = ? FOR UPDATE');
  $selInst->execute([$instrument]);
  $instRow = $selInst->fetch();
  
  if (!$instRow) {
    $pdo->rollBack();
    json_out(['error' => 'instrument_not_found'], 404);
  }

  if ($new_quantity > (int)$instRow['quantity']) {
    $pdo->rollBack();
    json_out(['error' => 'quantity_exceeds_total_stock'], 400);
  }

  $upd = $pdo->prepare('UPDATE requests SET quantity = ?, is_override = 1, original_quantity = ?, override_reason = ? WHERE id = ?');
  $upd->execute([$new_quantity, $original_quantity, $reason, $id]);

  // Notify borrower about admin quantity override
  try {
    $borrower = trim((string)($reqRow['student_name'] ?? ''));
    if ($borrower !== '') {
      $instrument = (string)($reqRow['instrument_name'] ?? 'instrument');
      $course = $reqRow['course'] ?? null;
      $commentSuffix = $reason !== '' ? " Reason: $reason." : '';

      $pdo->prepare("UPDATE notifications SET is_read = 1 WHERE request_id = ? AND recipient = ?")
          ->execute([$id, $borrower]);

      $notifSql = "INSERT INTO notifications (title, message, type, recipient, priority, course, is_override, original_quantity, override_quantity, override_reason, request_id) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)";
      $notifStmt = $pdo->prepare($notifSql);
      $msg = "Admin adjusted your request for $instrument from $original_quantity to $new_quantity.$commentSuffix";
      $notifStmt->execute([
        'Request Quantity Updated',
        $msg,
        'warning',
        $borrower,
        'high',
        $course,
        1,
        $original_quantity,
        $new_quantity,
        $reason !== '' ? $reason : null,
        $id,
      ]);
    }
  } catch (Throwable $e) {}
  
  $pdo->commit();
  json_out(['ok' => true]);
} catch (Throwable $e) {
  $pdo->rollBack();
  json_out(['error' => 'update_failed', 'msg' => $e->getMessage()], 500);
}
