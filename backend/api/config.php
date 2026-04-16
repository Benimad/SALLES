<?php
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');
header('Content-Type: application/json; charset=utf-8');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

class Database {
    private $host = 'localhost';
    private $db_name = 'gestion_salles';
    private $username = 'root';
    private $password = '';
    public $conn;

    public function getConnection() {
        $this->conn = null;
        try {
            $this->conn = new PDO(
                "mysql:host=" . $this->host . ";dbname=" . $this->db_name,
                $this->username,
                $this->password
            );
            $this->conn->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
            $this->conn->exec("set names utf8mb4");
        } catch(PDOException $e) {
            error_log('Database Error: ' . $e->getMessage());
            http_response_code(500);
            echo json_encode([
                'success' => false,
                'message' => 'Erreur de connexion à la base de données'
            ]);
            exit();
        }
        return $this->conn;
    }
}

class ApiResponse {
    public static function success($data = null, $message = 'Succès') {
        return json_encode([
            'success' => true,
            'message' => $message,
            'data' => $data
        ]);
    }

    public static function error($message = 'Erreur', $statusCode = 400) {
        http_response_code($statusCode);
        return json_encode([
            'success' => false,
            'message' => $message
        ]);
    }

    public static function validation($errors = []) {
        http_response_code(422);
        return json_encode([
            'success' => false,
            'message' => 'Erreur de validation',
            'errors' => $errors
        ]);
    }
}

class Auth {
    private $db;
    private $validTokens = [];

    public function __construct($conn) {
        $this->db = $conn;
        $this->loadValidTokens();
    }

    private function loadValidTokens() {
        // In production, store tokens in database or Redis
        // For now, we'll validate token format
    }

    public function getAuthenticatedUser() {
        $headers = getallheaders();
        $authHeader = $headers['Authorization'] ?? '';

        if (empty($authHeader)) {
            return null;
        }

        if (!preg_match('/Bearer\s+(.+)/', $authHeader, $matches)) {
            return null;
        }

        $token = $matches[1];
        
        // In production, look up token in database
        // For now, just validate format
        return $this->validateToken($token);
    }

    private function validateToken($token) {
        // Simple validation - in production use JWT or better token storage
        if (strlen($token) < 20) {
            return null;
        }
        return $token; // This should be looked up in DB
    }

    public static function isAdmin($role) {
        return $role === 'admin';
    }
}

// Helper function for database
function getDB() {
    static $db = null;
    if ($db === null) {
        $database = new Database();
        $db = $database->getConnection();
    }
    return $db;
}
?>

