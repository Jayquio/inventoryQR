<?php
// 1. Force JSON header immediately
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

// 2. Suppress HTML error display (CRITICAL to prevent the "<br />" error)
ini_set('display_errors', 0);
ini_set('display_startup_errors', 0);
error_reporting(E_ALL);

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') { http_response_code(204); exit; }

// Ensure all server-side timestamps use Philippine time
@date_default_timezone_set('Asia/Manila');

// Start output buffering to prevent any accidental output before json_out
ob_start();

// Use environment variables for flexible configuration (Docker or local)
$host = getenv('DB_HOST') ?: 'localhost';
$port = getenv('DB_PORT') ?: '3306';
$dbname = getenv('DB_NAME') ?: 'medlab_inventory';
$dbuser = getenv('DB_USER') ?: 'root';
$dbpass = getenv('DB_PASS') ?: ''; // XAMPP default is empty

$dsn = "mysql:host=$host;port=$port;dbname=$dbname;charset=utf8mb4";
$user = $dbuser;
$pass = $dbpass;

try {
  $pdo = new PDO($dsn, $user, $pass, [
    PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
    PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
    PDO::ATTR_EMULATE_PREPARES => false,
  ]);
  
  // Proactively ensure notifications table exists (Bypass errors if permission restricted)
  try {
    $pdo->exec("CREATE TABLE IF NOT EXISTS `notifications` (
      `id` int(11) NOT NULL AUTO_INCREMENT,
      `title` varchar(255) NOT NULL,
      `message` text NOT NULL,
      `type` varchar(50) NOT NULL DEFAULT 'info',
      `recipient` varchar(128) NOT NULL DEFAULT 'All',
      `course` varchar(128) DEFAULT NULL,
      `is_read` tinyint(1) NOT NULL DEFAULT 0,
      `priority` varchar(20) NOT NULL DEFAULT 'medium',
      `is_override` tinyint(1) NOT NULL DEFAULT 0,
      `original_quantity` int(11) DEFAULT NULL,
      `override_quantity` int(11) DEFAULT NULL,
      `override_reason` text DEFAULT NULL,
      `request_id` int(11) DEFAULT NULL,
      `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
      PRIMARY KEY (`id`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;");
    
    // Ensure table structure updates (recipient as VARCHAR and request_id column)
    try {
      $pdo->exec("ALTER TABLE `notifications` MODIFY `recipient` VARCHAR(128) NOT NULL DEFAULT 'All'");
      $pdo->exec("ALTER TABLE `notifications` ADD COLUMN `request_id` int(11) DEFAULT NULL AFTER `override_reason` ");
    } catch (Throwable $e) {}
  } catch (Throwable $e) {
    // Silently continue if table creation fails
  }
} catch (Throwable $e) {
  // Clear any output buffer (like PHP warnings)
  if (ob_get_length()) ob_clean();
  http_response_code(500);
  echo json_encode(['ok' => false, 'error' => 'db_error', 'details' => $e->getMessage()]);
  exit;
}

// Helper function to ensure notifications table exists
function ensure_notifications_table($pdo) {
  $sql = "CREATE TABLE IF NOT EXISTS `notifications` (
    `id` int(11) NOT NULL AUTO_INCREMENT,
    `title` varchar(255) NOT NULL,
    `message` text NOT NULL,
    `type` varchar(50) NOT NULL DEFAULT 'info',
    `recipient` varchar(128) NOT NULL DEFAULT 'All',
    `course` varchar(128) DEFAULT NULL,
    `is_read` tinyint(1) NOT NULL DEFAULT 0,
    `priority` varchar(20) NOT NULL DEFAULT 'medium',
    `is_override` tinyint(1) NOT NULL DEFAULT 0,
    `original_quantity` int(11) DEFAULT NULL,
    `override_quantity` int(11) DEFAULT NULL,
    `override_reason` text DEFAULT NULL,
    `request_id` int(11) DEFAULT NULL,
    `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
    PRIMARY KEY (`id`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;";
  $pdo->exec($sql);
  
  // Ensure table structure updates (recipient as VARCHAR and request_id column)
  try {
    $pdo->exec("ALTER TABLE `notifications` MODIFY `recipient` VARCHAR(128) NOT NULL DEFAULT 'All'");
    $pdo->exec("ALTER TABLE `notifications` ADD COLUMN `request_id` int(11) DEFAULT NULL AFTER `override_reason` ");
  } catch (Throwable $e) {}
}

function json_input() {
  $raw = file_get_contents('php://input');
  $d = json_decode($raw, true);
  return is_array($d) ? $d : [];
}

function json_out($data, int $code = 200) {
  // Clear any output buffer (like PHP warnings)
  if (ob_get_length()) ob_clean();
  http_response_code($code);
  header('Content-Type: application/json');
  $out = json_encode($data);
  if ($out === false) {
      echo json_encode(['ok' => false, 'error' => 'json_encode_error', 'details' => json_last_error_msg()]);
  } else {
      echo $out;
  }
  exit;
}
