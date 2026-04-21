<?php
require __DIR__ . '/db.php';
$in = json_input();

$id = (int)($in['id'] ?? 0);
$status = strtolower(trim($in['status'] ?? ''));
$allowed = ['pending','approved','rejected','returned']; // matches app + SQL enum

if ($id <= 0 || !in_array($status, $allowed, true)) {
  json_out(['error' => 'invalid_input'], 400);
}

$user = trim($in['user'] ?? 'system');
$now = date('Y-m-d H:i:s');

// Authorization: only admin/superadmin can update request lifecycle statuses.
if (in_array($status, ['approved', 'rejected', 'returned'], true)) {
  $roleQ = $pdo->prepare('SELECT role FROM users WHERE username = ? LIMIT 1');
  $roleQ->execute([$user]);
  $roleRow = $roleQ->fetch();
  $role = strtolower(trim((string)($roleRow['role'] ?? '')));
  if (!in_array($role, ['admin', 'superadmin'], true)) {
    json_out(['error' => 'forbidden'], 403);
  }
}

// Fetch request details for notifications and processing
$selReq = $pdo->prepare('SELECT r.instrument_name, r.student_name, r.status, r.quantity as req_qty, COALESCE(i.type, "instrument") AS instrument_type FROM requests r LEFT JOIN instruments i ON i.name = r.instrument_name WHERE r.id = ?');
$selReq->execute([$id]);
$reqRow = $selReq->fetch();
if (!$reqRow) {
  json_out(['error' => 'not_found'], 404);
}

$borrower = $reqRow['student_name'];
$instrument = $reqRow['instrument_name'];
$reqQty = (int)($reqRow['req_qty'] ?? 1);
$instrumentType = strtolower(trim((string)($reqRow['instrument_type'] ?? 'instrument')));

if ($status === 'returned') {
  $pdo->beginTransaction();
  try {
    // Idempotent: returning an already returned request should be a no-op.
    if ($reqRow['status'] === 'returned') {
      $pdo->commit();
      json_out(['ok' => true, 'unchanged' => true]);
    }

    // Only approved requests can be transitioned to returned.
    if ($reqRow['status'] !== 'approved') {
      $pdo->rollBack();
      json_out(['error' => 'invalid_transition'], 409);
    }

    if ($instrumentType === 'reagent') {
      $pdo->rollBack();
      json_out(['error' => 'reagent_is_consumed_not_returnable'], 409);
    }

    // Lock instrument row and increment availability up to quantity
    $selInst = $pdo->prepare('SELECT quantity, available FROM instruments WHERE name = ? FOR UPDATE');
    $selInst->execute([$instrument]);
    $instRow = $selInst->fetch();
    if (!$instRow) {
      $pdo->rollBack();
      json_out(['error' => 'instrument_not_found'], 404);
    }

    $qty = (int)$instRow['quantity'];
    $avail = (int)$instRow['available'];
    if ($avail < $qty) {
      $avail += $reqQty;
      if ($avail > $qty) $avail = $qty;
      $updInst = $pdo->prepare('UPDATE instruments SET available = ? WHERE name = ?');
      $updInst->execute([$avail, $instrument]);
    }
    $insTx = $pdo->prepare('INSERT INTO transactions (instrument_name, type, processed_by) VALUES (?, ?, ?)');
    $insTx->execute([$instrument, 'return', $user]);

    $upd = $pdo->prepare('UPDATE requests 
                          SET status = ?, returned_by = ?, returned_at = ?, 
                              rejected_by = NULL, rejected_at = NULL 
                          WHERE id = ?');
    $upd->execute([$status, $user, $now, $id]);

    // Create User Notification for Return
    try {
      // Mark old as read
      $pdo->prepare("UPDATE notifications SET is_read = 1 WHERE request_id = ? AND recipient = ?")->execute([$id, $borrower]);

      $notifSql = "INSERT INTO notifications (title, message, type, recipient, priority, request_id) VALUES (?, ?, ?, ?, ?, ?)";
      $notifStmt = $pdo->prepare($notifSql);
      $msg = "Instrument '$instrument' has been successfully returned and confirmed by admin on $now.";
      $notifStmt->execute(['Instrument Returned', $msg, 'info', $borrower, 'medium', $id]);
    } catch (Throwable $e) {}

    $pdo->commit();
  } catch (Throwable $e) {
    $pdo->rollBack();
    json_out(['error' => 'update_failed', 'details' => $e->getMessage()], 500);
  }
} elseif ($status === 'approved') {
  $pdo->beginTransaction();
  try {
    // ONLY decrement if moving FROM 'pending' TO 'approved'
    if ($reqRow['status'] === 'pending') {
      $selInst = $pdo->prepare('SELECT available FROM instruments WHERE name = ? FOR UPDATE');
      $selInst->execute([$instrument]);
      $instRow = $selInst->fetch();
      if (!$instRow) { $pdo->rollBack(); json_out(['error' => 'instrument_not_found'], 404); }
      
      $avail = (int)$instRow['available'];
      if ($avail >= $reqQty) {
        $avail -= $reqQty;
        $updInst = $pdo->prepare('UPDATE instruments SET available = ? WHERE name = ?');
        $updInst->execute([$avail, $instrument]);
      } else {
        $pdo->rollBack();
        json_out(['error' => 'no_available_stock'], 409);
      }
    }

    $upd = $pdo->prepare('UPDATE requests 
                          SET status = ?, approved_by = ?, approved_at = ?, 
                              rejected_by = NULL, rejected_at = NULL, 
                              returned_by = NULL, returned_at = NULL 
                          WHERE id = ?');
    $upd->execute([$status, $user, $now, $id]);

    // Create User Notification for Approval
    try {
      // Mark old as read
      $pdo->prepare("UPDATE notifications SET is_read = 1 WHERE request_id = ? AND recipient = ?")->execute([$id, $borrower]);

      $notifSql = "INSERT INTO notifications (title, message, type, recipient, priority, request_id) VALUES (?, ?, ?, ?, ?, ?)";
      $notifStmt = $pdo->prepare($notifSql);
      $msg = "Your request for $reqQty unit(s) of $instrument has been APPROVED.";
      $notifStmt->execute(['Request Approved', $msg, 'success', $borrower, 'high', $id]);
    } catch (Throwable $e) {}

    $pdo->commit();
  } catch (Throwable $e) {
    $pdo->rollBack();
    json_out(['error' => 'update_failed', 'details' => $e->getMessage()], 500);
  }
} elseif ($status === 'rejected') {
  try {
    $upd = $pdo->prepare('UPDATE requests 
                          SET status = ?, rejected_by = ?, rejected_at = ?, 
                              approved_by = NULL, approved_at = NULL, 
                              returned_by = NULL, returned_at = NULL 
                          WHERE id = ?');
    $upd->execute([$status, $user, $now, $id]);

    // Create User Notification for Rejection
    try {
      // Mark old as read
      $pdo->prepare("UPDATE notifications SET is_read = 1 WHERE request_id = ? AND recipient = ?")->execute([$id, $borrower]);

      $notifSql = "INSERT INTO notifications (title, message, type, recipient, priority, request_id) VALUES (?, ?, ?, ?, ?, ?)";
      $notifStmt = $pdo->prepare($notifSql);
      $msg = "Your request for $reqQty unit(s) of $instrument has been REJECTED.";
      $notifStmt->execute(['Request Rejected', $msg, 'error', $borrower, 'high', $id]);
    } catch (Throwable $e) {}
  } catch (Throwable $e) {
    json_out(['error' => 'update_failed'], 500);
  }
} else {
  // Handle other statuses (e.g. back to pending)
  $upd = $pdo->prepare('UPDATE requests 
                        SET status = ?, 
                            approved_by = NULL, approved_at = NULL, 
                            rejected_by = NULL, rejected_at = NULL, 
                            returned_by = NULL, returned_at = NULL 
                        WHERE id = ?');
  $upd->execute([$status, $id]);
}

json_out(['ok' => true]);
