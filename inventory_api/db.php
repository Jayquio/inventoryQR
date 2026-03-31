<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') { http_response_code(204); exit; }

// Ensure all server-side timestamps use Philippine time
@date_default_timezone_set('Asia/Manila');

// Use environment variables for flexible configuration (Docker or local)
$host = getenv('DB_HOST') ?: 'localhost';
$dbname = getenv('DB_NAME') ?: 'medlab_inventory';
$dbuser = getenv('DB_USER') ?: 'root';
$dbpass = getenv('DB_PASS') ?: ''; // XAMPP default is empty

$dsn = "mysql:host=$host;dbname=$dbname;charset=utf8mb4";
$user = $dbuser;
$pass = $dbpass;

try {
  $pdo = new PDO($dsn, $user, $pass, [
    PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
    PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
  ]);
} catch (Throwable $e) {
  http_response_code(500);
  echo json_encode(['error' => 'db_error']);
  exit;
}

function json_input() {
  $raw = file_get_contents('php://input');
  $d = json_decode($raw, true);
  return is_array($d) ? $d : [];
}

function json_out($data, int $code = 200) {
  http_response_code($code);
  echo json_encode($data);
  exit;
}