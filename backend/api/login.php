<?php
require_once 'config.php';

$database = new Database();
$db = $database->getConnection();

$input = json_decode(file_get_contents("php://input"), true);

// Validation
if (empty($input['email']) || empty($input['password'])) {
    echo ApiResponse::validation(['email' => 'Email requis', 'password' => 'Mot de passe requis']);
    exit();
}

$email = filter_var($input['email'], FILTER_SANITIZE_EMAIL);
$password = $input['password'];

if (!filter_var($email, FILTER_VALIDATE_EMAIL)) {
    echo ApiResponse::validation(['email' => 'Format d\'email invalide']);
    exit();
}

try {
    $query = "SELECT id, nom, prenom, email, password, role, phone, department, fcm_token FROM users 
              WHERE email = :email AND status = 'active' LIMIT 1";
    $stmt = $db->prepare($query);
    $stmt->bindParam(':email', $email);
    $stmt->execute();

    if ($stmt->rowCount() === 0) {
        echo ApiResponse::error('Utilisateur non trouvé', 401);
        exit();
    }

    $user = $stmt->fetch(PDO::FETCH_ASSOC);

    if (!password_verify($password, $user['password'])) {
        echo ApiResponse::error('Mot de passe incorrect', 401);
        exit();
    }

    // Generate token (should be JWT in production)
    $token = bin2hex(random_bytes(32));

    // Update FCM token if sent
    if (!empty($input['fcm_token'])) {
        $updateQuery = "UPDATE users SET fcm_token = :fcm_token WHERE id = :id";
        $updateStmt = $db->prepare($updateQuery);
        $updateStmt->bindParam(':fcm_token', $input['fcm_token']);
        $updateStmt->bindParam(':id', $user['id']);
        $updateStmt->execute();
    }

    echo json_encode([
        'success' => true,
        'token' => $token,
        'user' => [
            'id' => (int)$user['id'],
            'nom' => $user['nom'],
            'prenom' => $user['prenom'],
            'email' => $user['email'],
            'role' => $user['role'],
            'phone' => $user['phone'],
            'department' => $user['department'],
        ]
    ]);

} catch (PDOException $e) {
    error_log('Login Error: ' . $e->getMessage());
    echo ApiResponse::error('Erreur serveur', 500);
}
?>
