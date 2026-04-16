<?php
require_once 'config.php';

$db = getDB();

try {
    $input = json_decode(file_get_contents('php://input'), true);

    if (empty($input['user_id']) || empty($input['current_password']) || empty($input['new_password'])) {
        echo ApiResponse::validation(['message' => 'Champs requis manquants']);
        exit();
    }

    $userId = intval($input['user_id']);
    $currentPassword = $input['current_password'];
    $newPassword = $input['new_password'];

    if (strlen($newPassword) < 6) {
        echo ApiResponse::error('Le nouveau mot de passe doit contenir au moins 6 caractères');
        exit();
    }

    // Verify current password
    $stmt = $db->prepare("SELECT password FROM users WHERE id = :id");
    $stmt->bindParam(':id', $userId, PDO::PARAM_INT);
    $stmt->execute();
    $user = $stmt->fetch(PDO::FETCH_ASSOC);

    if (!$user || !password_verify($currentPassword, $user['password'])) {
        echo ApiResponse::error('Mot de passe actuel incorrect');
        exit();
    }

    // Update password
    $hashedPassword = password_hash($newPassword, PASSWORD_BCRYPT);
    $updateStmt = $db->prepare("UPDATE users SET password = :password WHERE id = :id");
    $updateStmt->bindParam(':password', $hashedPassword);
    $updateStmt->bindParam(':id', $userId, PDO::PARAM_INT);
    $updateStmt->execute();

    echo json_encode(['success' => true, 'message' => 'Mot de passe modifié avec succès']);

} catch (PDOException $e) {
    error_log('Change Password Error: ' . $e->getMessage());
    echo ApiResponse::error('Erreur lors du changement de mot de passe', 500);
}
?>
