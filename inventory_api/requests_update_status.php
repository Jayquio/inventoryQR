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
// (Keep legacy clients functional by checking declared username against users table.)
if (in_array($status, ['approved', 'rejected', 'returned'], true)) {
  $roleQ = $pdo->prepare('SELECT role FROM users WHERE username = ? LIMIT 1');
  $roleQ->execute([$user]);
  $roleRow = $roleQ->fetch();
  $role = strtolower(trim((string)($roleRow['role'] ?? '')));
  if (!in_array($role, ['admin', 'superadmin'], true)) {
    json_out(['error' => 'forbidden'], 403);
  }
}

if ($status === 'returned') {
  // Mark request as returned and record return timestamp.
  // Also (best-effort) increment instrument availability and record a transaction.
  $pdo->beginTransaction();
  try {
    $selReq = $pdo->prepare('SELECT instrument_name, status FROM requests WHERE id = ? FOR UPDATE');
    $selReq->execute([$id]);
    $reqRow = $selReq->fetch();
    if (!$reqRow) {
      $pdo->rollBack();
      json_out(['error' => 'not_found'], 404);
    }

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

    $instrument = $reqRow['instrument_name'];

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
      $avail++;
      $updInst = $pdo->prepare('UPDATE instruments SET available = ? WHERE name = ?');
      $updInst->execute([$avail, $instrument]);
    }
    $insTx = $pdo->prepare('INSERT INTO transactions (instrument_name, type, processed_by) VALUES (?, ?, ?)');
    $insTx->execute([$instrument, 'return', $user]);

    try {
      $upd = $pdo->prepare('UPDATE requests
                            SET status = ?,
                                returned_by = ?,
                                returned_at = ?,
                                rejected_by = NULL,
                                rejected_at = NULL
                            WHERE id = ?');
      $upd->execute([$status, $user, $now, $id]);
    } catch (Throwable $e) {
      // Backward compatible with older schema (no returned_* columns yet)
      $upd = $pdo->prepare('UPDATE requests
                            SET status = ?,
                                rejected_by = NULL,
                                rejected_at = NULL
                            WHERE id = ?');
      $upd->execute([$status, $id]);
    }

    $pdo->commit();
  } catch (Throwable $e) {
    $pdo->rollBack();
    json_out(['error' => 'update_failed'], 500);
  }
} elseif ($status === 'approved') {
  $pdo->beginTransaction();
  try {
    $selReq = $pdo->prepare('SELECT instrument_name, status FROM requests WHERE id = ? FOR UPDATE');
    $selReq->execute([$id]);
    $reqRow = $selReq->fetch();
    if (!$reqRow) { $pdo->rollBack(); json_out(['error' => 'not_found'], 404); }

    // ONLY decrement if moving FROM 'pending' TO 'approved'
    if ($reqRow['status'] === 'pending') {
      $instrument = $reqRow['instrument_name'];
      $selInst = $pdo->prepare('SELECT available FROM instruments WHERE name = ? FOR UPDATE');
      $selInst->execute([$instrument]);
      $instRow = $selInst->fetch();
      if (!$instRow) {
        $pdo->rollBack();
        json_out(['error' => 'instrument_not_found'], 404);
      }
      $avail = (int)$instRow['available'];
      if ($avail > 0) {
        $avail--;
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
    $pdo->commit();
  } catch (Throwable $e) {
    $pdo->rollBack();
    json_out(['error' => 'update_failed'], 500);
  }
} elseif ($status === 'rejected') {
  try {
    $upd = $pdo->prepare('UPDATE requests
                          SET status = ?, rejected_by = ?, rejected_at = ?,
                              approved_by = NULL, approved_at = NULL,
                              returned_by = NULL, returned_at = NULL
                          WHERE id = ?');
    $upd->execute([$status, $user, $now, $id]);
  } catch (Throwable $e) {
    $upd = $pdo->prepare('UPDATE requests
                          SET status = ?, rejected_by = ?, rejected_at = ?,
                              approved_by = NULL, approved_at = NULL
                          WHERE id = ?');
    $upd->execute([$status, $user, $now, $id]);
  }
} else {
  try {
    $upd = $pdo->prepare('UPDATE requests
                          SET status = ?,
                              approved_by = NULL, approved_at = NULL,
                              rejected_by = NULL, rejected_at = NULL,
                              returned_by = NULL, returned_at = NULL
                          WHERE id = ?');
    $upd->execute([$status, $id]);
  } catch (Throwable $e) {
    $upd = $pdo->prepare('UPDATE requests
                          SET status = ?,
                              approved_by = NULL, approved_at = NULL,
                              rejected_by = NULL, rejected_at = NULL
                          WHERE id = ?');
    $upd->execute([$status, $id]);
  }
}

if ($upd->rowCount() === 0) {
  $chk = $pdo->prepare('SELECT id FROM requests WHERE id = ?');
  $chk->execute([$id]);
  if ($chk->fetch()) {
    json_out(['ok' => true, 'unchanged' => true]);
  }
  json_out(['error' => 'not_found'], 404);
}
json_out(['ok' => true]);